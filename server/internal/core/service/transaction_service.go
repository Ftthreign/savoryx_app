package service

import (
	"bytes"
	"context"
	"strings"
	"time"

	"github.com/ftthreign/savoryx_app/server/internal/core/domain"
	"github.com/ftthreign/savoryx_app/server/internal/port"
	"github.com/samber/oops"
	"github.com/shopspring/decimal"
)

type transactionService struct {
	txRepo       port.TransactionRepository
	accountRepo  port.AccountRepository
	categoryRepo port.CategoryRepository
	txManager    port.TxManager
}

func NewTransactionService(
	txRepo port.TransactionRepository,
	accountRepo port.AccountRepository,
	categoryRepo port.CategoryRepository,
	txManager ...port.TxManager,
) port.TransactionService {
	var txMgr port.TxManager
	if len(txManager) > 0 {
		txMgr = txManager[0]
	}
	return &transactionService{
		txRepo:       txRepo,
		accountRepo:  accountRepo,
		categoryRepo: categoryRepo,
		txManager:    txMgr,
	}
}

func svcTxErr() oops.OopsErrorBuilder {
	return oops.In("transaction_service")
}

func (s *transactionService) runInTx(ctx context.Context, fn func(ctx context.Context) error) error {
	if s.txManager != nil {
		return s.txManager.RunInTx(ctx, fn)
	}
	return fn(ctx)
}

func (s *transactionService) CreateTransaction(ctx context.Context, tx *domain.Transaction) error {
	if tx == nil {
		return svcTxErr().
			Code("ERR_INVALID_TRANSACTION").
			Wrapf(domain.ErrInvalidInput, "transaction entity cannot be nil")
	}

	normalizeTransactionDefaults(tx)

	if err := tx.Validate(); err != nil {
		return svcTxErr().
			Code("ERR_TRANSACTION_VALIDATION").
			Wrap(err)
	}

	return s.runInTx(ctx, func(txCtx context.Context) error {
		if err := s.applyBalanceMutation(txCtx, tx); err != nil {
			return err
		}

		if err := s.txRepo.Create(txCtx, tx); err != nil {
			return svcTxErr().
				Code("ERR_TRANSACTION_CREATE_FAILED").
				With("transaction_id", tx.ID.String()).
				Wrapf(err, "failed to persist transaction")
		}

		return nil
	})
}

func (s *transactionService) GetTransaction(ctx context.Context, id domain.UUID) (*domain.Transaction, error) {
	if id.IsZero() {
		return nil, svcTxErr().
			Code("ERR_INVALID_TRANSACTION_ID").
			Wrapf(domain.ErrInvalidInput, "transaction ID cannot be zero")
	}

	tx, err := s.txRepo.GetByID(ctx, id)
	if err != nil {
		return nil, err
	}
	if tx == nil {
		return nil, svcTxErr().
			Code("ERR_TRANSACTION_NOT_FOUND").
			With("transaction_id", id.String()).
			Wrap(domain.ErrTransactionNotFound)
	}

	return tx, nil
}

func (s *transactionService) ListTransactions(
	ctx context.Context,
	accountID *domain.UUID,
	limit, offset int,
) ([]*domain.Transaction, int, error) {
	limit, offset = normalizePagination(limit, offset)

	if accountID != nil && !accountID.IsZero() {
		total, err := s.txRepo.CountByAccount(ctx, *accountID)
		if err != nil {
			return nil, 0, svcTxErr().
				Code("ERR_TRANSACTION_COUNT_BY_ACCOUNT_FAILED").
				With("account_id", accountID.String()).
				Wrapf(err, "failed to count transactions by account")
		}

		items, err := s.txRepo.ListByAccount(ctx, *accountID, limit, offset)
		if err != nil {
			return nil, 0, svcTxErr().
				Code("ERR_TRANSACTION_LIST_BY_ACCOUNT_FAILED").
				With("account_id", accountID.String()).
				Wrapf(err, "failed to list transactions by account")
		}
		if items == nil {
			items = make([]*domain.Transaction, 0)
		}
		return items, total, nil
	}

	total, err := s.txRepo.Count(ctx)
	if err != nil {
		return nil, 0, svcTxErr().
			Code("ERR_TRANSACTION_COUNT_FAILED").
			Wrapf(err, "failed to count transactions")
	}

	items, err := s.txRepo.List(ctx, limit, offset)
	if err != nil {
		return nil, 0, svcTxErr().
			Code("ERR_TRANSACTION_LIST_FAILED").
			Wrapf(err, "failed to list transactions")
	}
	if items == nil {
		items = make([]*domain.Transaction, 0)
	}
	return items, total, nil
}

func (s *transactionService) DeleteTransaction(ctx context.Context, id domain.UUID) error {
	if id.IsZero() {
		return svcTxErr().
			Code("ERR_INVALID_TRANSACTION_ID").
			Wrapf(domain.ErrInvalidInput, "transaction ID cannot be zero")
	}

	return s.runInTx(ctx, func(txCtx context.Context) error {
		existing, err := s.txRepo.GetByID(txCtx, id)
		if err != nil {
			return err
		}
		if existing == nil {
			return svcTxErr().
				Code("ERR_TRANSACTION_NOT_FOUND").
				With("transaction_id", id.String()).
				Wrap(domain.ErrTransactionNotFound)
		}

		if err := s.revertBalanceMutation(txCtx, existing); err != nil {
			return err
		}

		if err := s.txRepo.Delete(txCtx, id); err != nil {
			return svcTxErr().
				Code("ERR_TRANSACTION_DELETE_FAILED").
				With("transaction_id", id.String()).
				Wrapf(err, "failed to soft delete transaction")
		}

		return nil
	})
}

func normalizeTransactionDefaults(tx *domain.Transaction) {
	tx.Currency = strings.ToUpper(strings.TrimSpace(tx.Currency))
	if tx.Currency == "" {
		tx.Currency = "IDR"
	}

	if tx.ExchangeRateToBase.IsZero() {
		tx.ExchangeRateToBase = decimal.NewFromInt(1)
	}

	if tx.BaseAmount.IsZero() && tx.Amount.GreaterThan(decimal.Zero) && tx.ExchangeRateToBase.GreaterThan(decimal.Zero) {
		tx.BaseAmount = tx.Amount.Mul(tx.ExchangeRateToBase).Round(4)
	}

	tx.Note = strings.TrimSpace(tx.Note)

	now := time.Now().UTC()
	if tx.TransactionDate.IsZero() {
		tx.TransactionDate = now
	}
	if tx.CreatedAt.IsZero() {
		tx.CreatedAt = now
	}
	if tx.UpdatedAt.IsZero() {
		tx.UpdatedAt = now
	}
}

func normalizePagination(limit, offset int) (int, int) {
	if limit <= 0 {
		limit = 20
	} else if limit > 100 {
		limit = 100
	}
	if offset < 0 {
		offset = 0
	}
	return limit, offset
}

func (s *transactionService) applyBalanceMutation(ctx context.Context, tx *domain.Transaction) error {
	switch tx.Type {
	case domain.TransactionTypeIncome, domain.TransactionTypeExpense:
		if err := s.verifyCategoryExists(ctx, tx.CategoryID); err != nil {
			return err
		}

		acc, err := s.lockAccount(ctx, tx.AccountID)
		if err != nil {
			return err
		}

		var newBalance decimal.Decimal
		if tx.Type == domain.TransactionTypeIncome {
			newBalance = acc.Balance.Add(tx.Amount)
		} else {
			if err := ensureSufficientBalance(acc, tx.Amount); err != nil {
				return err
			}
			newBalance = acc.Balance.Sub(tx.Amount)
		}

		if err := s.accountRepo.UpdateBalance(ctx, acc.ID, newBalance); err != nil {
			return svcTxErr().
				Code("ERR_UPDATE_ACCOUNT_BALANCE").
				With("account_id", acc.ID.String()).
				Wrapf(err, "failed to update account balance")
		}
		return nil

	case domain.TransactionTypeTransfer:
		sourceAcc, destAcc, err := s.lockTransferAccounts(ctx, tx.AccountID, *tx.DestinationAccountID)
		if err != nil {
			return err
		}

		if err := ensureSufficientBalance(sourceAcc, tx.Amount); err != nil {
			return err
		}

		if err := s.accountRepo.UpdateBalance(ctx, sourceAcc.ID, sourceAcc.Balance.Sub(tx.Amount)); err != nil {
			return svcTxErr().
				Code("ERR_UPDATE_SOURCE_BALANCE").
				With("account_id", sourceAcc.ID.String()).
				Wrapf(err, "failed to update source account balance")
		}
		if err := s.accountRepo.UpdateBalance(ctx, destAcc.ID, destAcc.Balance.Add(tx.Amount)); err != nil {
			return svcTxErr().
				Code("ERR_UPDATE_DEST_BALANCE").
				With("account_id", destAcc.ID.String()).
				Wrapf(err, "failed to update destination account balance")
		}
		return nil

	default:
		return svcTxErr().
			Code("ERR_INVALID_TRANSACTION_TYPE").
			Wrap(domain.ErrInvalidInput)
	}
}

func (s *transactionService) revertBalanceMutation(ctx context.Context, existing *domain.Transaction) error {
	switch existing.Type {
	case domain.TransactionTypeIncome, domain.TransactionTypeExpense:
		acc, err := s.lockAccount(ctx, existing.AccountID)
		if err != nil {
			return err
		}

		var restoredBalance decimal.Decimal
		if existing.Type == domain.TransactionTypeIncome {
			restoredBalance = acc.Balance.Sub(existing.Amount)
		} else {
			restoredBalance = acc.Balance.Add(existing.Amount)
		}

		if err := s.accountRepo.UpdateBalance(ctx, acc.ID, restoredBalance); err != nil {
			return svcTxErr().
				Code("ERR_RESTORE_ACCOUNT_BALANCE").
				With("account_id", acc.ID.String()).
				Wrapf(err, "failed to restore account balance on delete")
		}
		return nil

	case domain.TransactionTypeTransfer:
		if existing.DestinationAccountID == nil {
			return svcTxErr().
				Code("ERR_INVALID_TRANSFER_RECORD").
				Wrap(domain.ErrInvalidInput)
		}
		sourceAcc, destAcc, err := s.lockTransferAccounts(ctx, existing.AccountID, *existing.DestinationAccountID)
		if err != nil {
			return err
		}

		if err := s.accountRepo.UpdateBalance(ctx, sourceAcc.ID, sourceAcc.Balance.Add(existing.Amount)); err != nil {
			return svcTxErr().
				Code("ERR_RESTORE_SOURCE_BALANCE").
				With("account_id", sourceAcc.ID.String()).
				Wrapf(err, "failed to restore source account balance")
		}
		if err := s.accountRepo.UpdateBalance(ctx, destAcc.ID, destAcc.Balance.Sub(existing.Amount)); err != nil {
			return svcTxErr().
				Code("ERR_RESTORE_DEST_BALANCE").
				With("account_id", destAcc.ID.String()).
				Wrapf(err, "failed to restore destination account balance")
		}
		return nil

	default:
		return svcTxErr().
			Code("ERR_INVALID_TRANSACTION_TYPE").
			Wrap(domain.ErrInvalidInput)
	}
}

func (s *transactionService) verifyCategoryExists(ctx context.Context, categoryID *domain.UUID) error {
	if s.categoryRepo == nil || categoryID == nil {
		return nil
	}
	cat, err := s.categoryRepo.GetByID(ctx, *categoryID)
	if err != nil {
		return err
	}
	if cat == nil {
		return svcTxErr().
			Code("ERR_CATEGORY_NOT_FOUND").
			With("category_id", categoryID.String()).
			Wrap(domain.ErrCategoryNotFound)
	}
	return nil
}

func ensureSufficientBalance(acc *domain.Account, amount decimal.Decimal) error {
	if acc.Type != domain.AccountTypeCreditCard && acc.Balance.LessThan(amount) {
		return svcTxErr().
			Code("ERR_INSUFFICIENT_BALANCE").
			With("account_id", acc.ID.String()).
			Wrap(domain.ErrInsufficientBalance)
	}
	return nil
}

func (s *transactionService) lockAccount(ctx context.Context, id domain.UUID) (*domain.Account, error) {
	acc, err := s.accountRepo.GetByIDForUpdate(ctx, id)
	if err != nil {
		return nil, err
	}
	if acc == nil {
		return nil, svcTxErr().
			Code("ERR_ACCOUNT_NOT_FOUND").
			With("account_id", id.String()).
			Wrap(domain.ErrAccountNotFound)
	}
	return acc, nil
}

// lockTransferAccounts locks two accounts in deterministic UUID byte order in O(1) time to prevent deadlocks.
func (s *transactionService) lockTransferAccounts(
	ctx context.Context,
	sourceID, destID domain.UUID,
) (*domain.Account, *domain.Account, error) {
	firstID, secondID := sourceID, destID
	swapped := false
	if bytes.Compare(sourceID[:], destID[:]) > 0 {
		firstID, secondID = destID, sourceID
		swapped = true
	}

	firstAcc, err := s.lockAccount(ctx, firstID)
	if err != nil {
		return nil, nil, err
	}

	secondAcc, err := s.lockAccount(ctx, secondID)
	if err != nil {
		return nil, nil, err
	}

	if swapped {
		return secondAcc, firstAcc, nil
	}
	return firstAcc, secondAcc, nil
}

var _ port.TransactionService = (*transactionService)(nil)
