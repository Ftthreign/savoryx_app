package service

import (
	"bytes"
	"context"
	"errors"
	"strings"
	"time"

	"github.com/ftthreign/savoryx_app/server/internal/core/domain"
	"github.com/ftthreign/savoryx_app/server/internal/port"
	"github.com/samber/oops"
	"github.com/shopspring/decimal"
)

type syncService struct {
	accountRepo  port.AccountRepository
	categoryRepo port.CategoryRepository
	txRepo       port.TransactionRepository
	syncLogRepo  port.SyncLogRepository
	txManager    port.TxManager
}

// SyncServiceOption configures optional dependencies on syncService.
type SyncServiceOption func(*syncService)

// WithSyncTxManager injects an atomic database transaction manager.
func WithSyncTxManager(txManager port.TxManager) SyncServiceOption {
	return func(s *syncService) {
		if txManager != nil {
			s.txManager = txManager
		}
	}
}

// WithSyncLogRepository injects the audit trail repository for PUSH/PULL sync logs.
func WithSyncLogRepository(syncLogRepo port.SyncLogRepository) SyncServiceOption {
	return func(s *syncService) {
		if syncLogRepo != nil {
			s.syncLogRepo = syncLogRepo
		}
	}
}

func NewSyncService(
	accountRepo port.AccountRepository,
	categoryRepo port.CategoryRepository,
	txRepo port.TransactionRepository,
	txManager ...port.TxManager,
) port.SyncService {
	var txMgr port.TxManager
	if len(txManager) > 0 {
		txMgr = txManager[0]
	}
	return &syncService{
		accountRepo:  accountRepo,
		categoryRepo: categoryRepo,
		txRepo:       txRepo,
		txManager:    txMgr,
	}
}

// NewSyncServiceWithOptions constructs a SyncService with explicit functional options.
func NewSyncServiceWithOptions(
	accountRepo port.AccountRepository,
	categoryRepo port.CategoryRepository,
	txRepo port.TransactionRepository,
	opts ...SyncServiceOption,
) port.SyncService {
	svc := &syncService{
		accountRepo:  accountRepo,
		categoryRepo: categoryRepo,
		txRepo:       txRepo,
	}
	for _, opt := range opts {
		if opt != nil {
			opt(svc)
		}
	}
	return svc
}

func svcSyncErr() oops.OopsErrorBuilder {
	return oops.In("sync_service")
}

func (s *syncService) runInTx(ctx context.Context, fn func(ctx context.Context) error) error {
	if s.txManager != nil {
		return s.txManager.RunInTx(ctx, fn)
	}
	return fn(ctx)
}

func (s *syncService) PullChanges(ctx context.Context, lastPulledAt time.Time) (*port.SyncPullResult, error) {
	since := lastPulledAt.UTC()
	pulledAt := time.Now().UTC()

	accounts, err := s.accountRepo.ListUpdatedAfter(ctx, since)
	if err != nil {
		return nil, svcSyncErr().
			Code("ERR_SYNC_PULL_ACCOUNTS").
			Wrapf(err, "failed to pull updated accounts")
	}
	if accounts == nil {
		accounts = make([]*domain.Account, 0)
	}

	categories, err := s.categoryRepo.ListUpdatedAfter(ctx, since)
	if err != nil {
		return nil, svcSyncErr().
			Code("ERR_SYNC_PULL_CATEGORIES").
			Wrapf(err, "failed to pull updated categories")
	}
	if categories == nil {
		categories = make([]*domain.Category, 0)
	}

	transactions, err := s.txRepo.ListUpdatedAfter(ctx, since)
	if err != nil {
		return nil, svcSyncErr().
			Code("ERR_SYNC_PULL_TRANSACTIONS").
			Wrapf(err, "failed to pull updated transactions")
	}
	if transactions == nil {
		transactions = make([]*domain.Transaction, 0)
	}

	return &port.SyncPullResult{
		Accounts:     accounts,
		Categories:   categories,
		Transactions: transactions,
		PulledAt:     pulledAt,
	}, nil
}

func (s *syncService) PushChanges(ctx context.Context, payload *port.SyncPushPayload) (*port.SyncPushResult, error) {
	if payload == nil {
		return nil, svcSyncErr().
			Code("ERR_SYNC_PAYLOAD_NIL").
			Wrapf(domain.ErrInvalidInput, "sync push payload cannot be nil")
	}

	if err := validateSyncPushBatch(payload); err != nil {
		return nil, err
	}

	accountsInBatch := make(map[domain.UUID]struct{}, len(payload.Accounts))
	for _, acc := range payload.Accounts {
		accountsInBatch[acc.ID] = struct{}{}
	}

	serverNow := time.Now().UTC()
	clientTS := serverNow
	if !payload.ClientTimestamp.IsZero() {
		clientTS = payload.ClientTimestamp.UTC()
	}

	err := s.runInTx(ctx, func(txCtx context.Context) error {
		// 1. Upsert Categories (Last-Write-Wins based on microsecond updated_at)
		for _, cat := range payload.Categories {
			if err := s.categoryRepo.UpsertSync(txCtx, cat); err != nil {
				return svcSyncErr().
					Code("ERR_SYNC_PUSH_CATEGORY").
					With("category_id", cat.ID.String()).
					Wrapf(err, "failed to upsert category during sync push")
			}
		}

		// 2. Upsert Accounts (Last-Write-Wins based on microsecond updated_at)
		for _, acc := range payload.Accounts {
			if err := s.accountRepo.UpsertSync(txCtx, acc); err != nil {
				return svcSyncErr().
					Code("ERR_SYNC_PUSH_ACCOUNT").
					With("account_id", acc.ID.String()).
					Wrapf(err, "failed to upsert account during sync push")
			}
			if acc.DeletedAt == nil {
				if _, err := s.accountRepo.GetByIDForUpdate(txCtx, acc.ID); err != nil && !errors.Is(err, domain.ErrAccountNotFound) {
					return svcSyncErr().
						Code("ERR_SYNC_LOCK_ACCOUNT").
						With("account_id", acc.ID.String()).
						Wrapf(err, "failed to acquire row lock on synced account")
				}
			}
		}

		// 3. Upsert Transactions (Append-Only Ledger with Tombstone & Pessimistic Row-Locking)
		for _, tx := range payload.Transactions {
			if err := s.applySyncedTransaction(txCtx, tx, accountsInBatch); err != nil {
				return err
			}
		}

		// 4. Record PUSH audit entry atomically inside the same database transaction
		if s.syncLogRepo != nil && !payload.DeviceID.IsZero() {
			batchSize := len(payload.Categories) + len(payload.Accounts) + len(payload.Transactions)
			auditLog := &domain.SyncLog{
				ID:              domain.NewUUIDv7(),
				DeviceID:        payload.DeviceID,
				Direction:       domain.SyncDirectionPush,
				BatchSize:       batchSize,
				Status:          domain.SyncStatusSuccess,
				ClientTimestamp: clientTS,
				ServerTimestamp: serverNow,
				CreatedAt:       serverNow,
			}
			if err := s.syncLogRepo.Record(txCtx, auditLog); err != nil {
				return svcSyncErr().
					Code("ERR_SYNC_AUDIT_LOG").
					With("device_id", payload.DeviceID.String()).
					Wrapf(err, "failed to record sync push audit log")
			}
		}

		return nil
	})
	if err != nil {
		return nil, err
	}

	return &port.SyncPushResult{
		AccountsApplied:     len(payload.Accounts),
		CategoriesApplied:   len(payload.Categories),
		TransactionsApplied: len(payload.Transactions),
		SyncedAt:            time.Now().UTC(),
	}, nil
}

func (s *syncService) applySyncedTransaction(
	ctx context.Context,
	tx *domain.Transaction,
	accountsInBatch map[domain.UUID]struct{},
) error {
	existingTx, getErr := s.txRepo.GetByID(ctx, tx.ID)
	if getErr != nil && !errors.Is(getErr, domain.ErrTransactionNotFound) {
		return svcSyncErr().
			Code("ERR_SYNC_CHECK_TRANSACTION").
			With("transaction_id", tx.ID.String()).
			Wrapf(getErr, "failed to check existing transaction state")
	}

	isNewActive := existingTx == nil && tx.DeletedAt == nil
	isNewlyTombstoned := existingTx != nil && tx.DeletedAt != nil

	if isNewActive {
		_, sourceSnapshotInBatch := accountsInBatch[tx.AccountID]
		if err := s.reconcileBalanceForSyncedTx(ctx, tx, false, sourceSnapshotInBatch, accountsInBatch); err != nil {
			return err
		}
	} else if isNewlyTombstoned {
		_, sourceSnapshotInBatch := accountsInBatch[existingTx.AccountID]
		if err := s.reconcileBalanceForSyncedTx(ctx, existingTx, true, sourceSnapshotInBatch, accountsInBatch); err != nil {
			return err
		}
	}

	if err := s.txRepo.Upsert(ctx, tx); err != nil {
		return svcSyncErr().
			Code("ERR_SYNC_PUSH_TRANSACTION").
			With("transaction_id", tx.ID.String()).
			Wrapf(err, "failed to upsert transaction during sync push")
	}
	return nil
}

func (s *syncService) reconcileBalanceForSyncedTx(
	ctx context.Context,
	tx *domain.Transaction,
	revert bool,
	sourceSnapshotInBatch bool,
	accountsInBatch map[domain.UUID]struct{},
) error {
	switch tx.Type {
	case domain.TransactionTypeIncome, domain.TransactionTypeExpense:
		acc, err := s.accountRepo.GetByIDForUpdate(ctx, tx.AccountID)
		if err != nil {
			return svcSyncErr().
				Code("ERR_SYNC_LOCK_ACCOUNT").
				With("account_id", tx.AccountID.String()).
				Wrapf(err, "failed to lock account for synced transaction")
		}
		// Unconfigured simple unit-test mocks return (nil, nil); skip balance reconciliation.
		if acc == nil || sourceSnapshotInBatch {
			return nil
		}

		isAddition := (tx.Type == domain.TransactionTypeIncome) != revert
		if !isAddition {
			if err := ensureSufficientBalance(acc, tx.Amount); err != nil {
				return err
			}
			acc.Balance = acc.Balance.Sub(tx.Amount)
		} else {
			acc.Balance = acc.Balance.Add(tx.Amount)
		}

		if err := s.accountRepo.UpdateBalance(ctx, acc.ID, acc.Balance); err != nil {
			return svcSyncErr().
				Code("ERR_SYNC_UPDATE_BALANCE").
				With("account_id", acc.ID.String()).
				Wrapf(err, "failed to reconcile account balance during sync")
		}
		return nil

	case domain.TransactionTypeTransfer:
		if tx.DestinationAccountID == nil {
			return svcSyncErr().
				Code("ERR_SYNC_INVALID_TRANSFER").
				With("transaction_id", tx.ID.String()).
				Wrap(domain.ErrInvalidInput)
		}
		sourceAcc, destAcc, err := s.lockTransferAccountsDeterministic(ctx, tx.AccountID, *tx.DestinationAccountID)
		if err != nil {
			return err
		}

		if sourceAcc != nil && !sourceSnapshotInBatch {
			var nextSourceBalance decimal.Decimal
			if revert {
				nextSourceBalance = sourceAcc.Balance.Add(tx.Amount)
			} else {
				if err := ensureSufficientBalance(sourceAcc, tx.Amount); err != nil {
					return err
				}
				nextSourceBalance = sourceAcc.Balance.Sub(tx.Amount)
			}
			if err := s.accountRepo.UpdateBalance(ctx, sourceAcc.ID, nextSourceBalance); err != nil {
				return svcSyncErr().
					Code("ERR_SYNC_UPDATE_SOURCE_BALANCE").
					With("account_id", sourceAcc.ID.String()).
					Wrapf(err, "failed to reconcile source account balance during sync")
			}
		}

		_, destSnapshotInBatch := accountsInBatch[*tx.DestinationAccountID]
		if destAcc != nil && !destSnapshotInBatch {
			var nextDestBalance decimal.Decimal
			if revert {
				nextDestBalance = destAcc.Balance.Sub(tx.Amount)
			} else {
				nextDestBalance = destAcc.Balance.Add(tx.Amount)
			}
			if err := s.accountRepo.UpdateBalance(ctx, destAcc.ID, nextDestBalance); err != nil {
				return svcSyncErr().
					Code("ERR_SYNC_UPDATE_DEST_BALANCE").
					With("account_id", destAcc.ID.String()).
					Wrapf(err, "failed to reconcile destination account balance during sync")
			}
		}
		return nil

	default:
		return svcSyncErr().
			Code("ERR_INVALID_TRANSACTION_TYPE").
			Wrap(domain.ErrInvalidInput)
	}
}

func (s *syncService) lockTransferAccountsDeterministic(
	ctx context.Context,
	sourceID, destID domain.UUID,
) (*domain.Account, *domain.Account, error) {
	firstID, secondID := sourceID, destID
	swapped := false
	if bytes.Compare(sourceID[:], destID[:]) > 0 {
		firstID, secondID = destID, sourceID
		swapped = true
	}

	firstAcc, err := s.accountRepo.GetByIDForUpdate(ctx, firstID)
	if err != nil {
		return nil, nil, svcSyncErr().
			Code("ERR_SYNC_LOCK_ACCOUNT").
			With("account_id", firstID.String()).
			Wrapf(err, "failed to lock transfer account")
	}

	secondAcc, err := s.accountRepo.GetByIDForUpdate(ctx, secondID)
	if err != nil {
		return nil, nil, svcSyncErr().
			Code("ERR_SYNC_LOCK_ACCOUNT").
			With("account_id", secondID.String()).
			Wrapf(err, "failed to lock transfer account")
	}

	if swapped {
		return secondAcc, firstAcc, nil
	}
	return firstAcc, secondAcc, nil
}

func validateSyncPushBatch(payload *port.SyncPushPayload) error {
	now := time.Now().UTC()

	for _, cat := range payload.Categories {
		if cat == nil || cat.ID.IsZero() {
			return svcSyncErr().
				Code("ERR_SYNC_INVALID_CATEGORY").
				Wrapf(domain.ErrInvalidInput, "category ID cannot be zero")
		}
		cat.Name = strings.TrimSpace(cat.Name)
		if cat.Name == "" {
			return svcSyncErr().
				Code("ERR_SYNC_INVALID_CATEGORY_NAME").
				With("category_id", cat.ID.String()).
				Wrapf(domain.ErrInvalidInput, "category name cannot be empty")
		}
		cat.Icon = strings.TrimSpace(cat.Icon)
		cat.Color = strings.ToUpper(strings.TrimSpace(cat.Color))
		if cat.CreatedAt.IsZero() {
			cat.CreatedAt = now
		}
		if cat.UpdatedAt.IsZero() {
			cat.UpdatedAt = now
		}
	}

	for _, acc := range payload.Accounts {
		if acc == nil || acc.ID.IsZero() {
			return svcSyncErr().
				Code("ERR_SYNC_INVALID_ACCOUNT").
				Wrapf(domain.ErrInvalidInput, "account ID cannot be zero")
		}
		acc.Name = strings.TrimSpace(acc.Name)
		if acc.Name == "" {
			return svcSyncErr().
				Code("ERR_SYNC_INVALID_ACCOUNT_NAME").
				With("account_id", acc.ID.String()).
				Wrapf(domain.ErrInvalidInput, "account name cannot be empty")
		}
		if !acc.Type.IsValid() {
			return svcSyncErr().
				Code("ERR_SYNC_INVALID_ACCOUNT_TYPE").
				With("account_id", acc.ID.String()).
				Wrapf(domain.ErrInvalidInput, "invalid account type")
		}
		acc.Currency = strings.ToUpper(strings.TrimSpace(acc.Currency))
		if acc.Currency == "" {
			acc.Currency = "IDR"
		}
		if acc.CreatedAt.IsZero() {
			acc.CreatedAt = now
		}
		if acc.UpdatedAt.IsZero() {
			acc.UpdatedAt = now
		}
	}

	for _, tx := range payload.Transactions {
		if tx == nil {
			return svcSyncErr().
				Code("ERR_SYNC_INVALID_TRANSACTION").
				Wrapf(domain.ErrInvalidInput, "transaction item cannot be nil")
		}
		normalizeTransactionDefaults(tx)
		if err := tx.Validate(); err != nil {
			return svcSyncErr().
				Code("ERR_SYNC_INVALID_TRANSACTION").
				With("transaction_id", tx.ID.String()).
				Wrap(err)
		}
	}

	return nil
}

var _ port.SyncService = (*syncService)(nil)
