package service

import (
	"context"
	"strings"
	"time"

	"github.com/ftthreign/savoryx_app/server/internal/core/domain"
	"github.com/ftthreign/savoryx_app/server/internal/port"
	"github.com/samber/oops"
)

type syncService struct {
	accountRepo  port.AccountRepository
	categoryRepo port.CategoryRepository
	txRepo       port.TransactionRepository
	txManager    port.TxManager
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

	err := s.runInTx(ctx, func(txCtx context.Context) error {
		// 1. Upsert Categories (Last-Write-Wins based on updated_at)
		for _, cat := range payload.Categories {
			if err := s.categoryRepo.UpsertSync(txCtx, cat); err != nil {
				return svcSyncErr().
					Code("ERR_SYNC_PUSH_CATEGORY").
					With("category_id", cat.ID.String()).
					Wrapf(err, "failed to upsert category during sync push")
			}
		}

		// 2. Upsert Accounts (Last-Write-Wins based on updated_at)
		for _, acc := range payload.Accounts {
			if err := s.accountRepo.UpsertSync(txCtx, acc); err != nil {
				return svcSyncErr().
					Code("ERR_SYNC_PUSH_ACCOUNT").
					With("account_id", acc.ID.String()).
					Wrapf(err, "failed to upsert account during sync push")
			}
		}

		// 3. Upsert Transactions (Append-Only Ledger with Tombstone support)
		for _, tx := range payload.Transactions {
			if err := s.txRepo.Upsert(txCtx, tx); err != nil {
				return svcSyncErr().
					Code("ERR_SYNC_PUSH_TRANSACTION").
					With("transaction_id", tx.ID.String()).
					Wrapf(err, "failed to upsert transaction during sync push")
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
