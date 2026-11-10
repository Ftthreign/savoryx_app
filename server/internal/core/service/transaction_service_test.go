package service_test

import (
	"context"
	"errors"
	"testing"
	"time"

	"github.com/ftthreign/savoryx_app/server/internal/core/domain"
	"github.com/ftthreign/savoryx_app/server/internal/core/service"
	"github.com/ftthreign/savoryx_app/server/internal/testutil/mocks"
	"github.com/shopspring/decimal"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

func TestTransactionService_CreateTransaction(t *testing.T) {
	ctx := context.Background()
	txID := domain.MustParseUUID("0192d6e2-5b9c-7000-8000-000000000101")
	accA := domain.MustParseUUID("0192d6e2-5b9c-7000-8000-000000000001")
	accB := domain.MustParseUUID("0192d6e2-5b9c-7000-8000-000000000002")
	catID := domain.MustParseUUID("0192d6e2-5b9c-7000-8000-000000000010")

	t.Run("happy path - creates expense, locks account, deducts balance inside tx", func(t *testing.T) {
		txExecuted := false
		var updatedBalance decimal.Decimal
		var createdTx *domain.Transaction

		txMgr := &mocks.MockTxManager{
			RunInTxFunc: func(ctx context.Context, fn func(ctx context.Context) error) error {
				txExecuted = true
				return fn(ctx)
			},
		}
		accRepo := &mocks.MockAccountRepository{
			GetByIDForUpdateFunc: func(ctx context.Context, id domain.UUID) (*domain.Account, error) {
				assert.Equal(t, accA, id)
				return &domain.Account{
					ID:       accA,
					Name:     "Main Bank",
					Type:     domain.AccountTypeBank,
					Currency: "IDR",
					Balance:  decimal.NewFromInt(1000000),
				}, nil
			},
			UpdateBalanceFunc: func(ctx context.Context, id domain.UUID, balance decimal.Decimal) error {
				assert.Equal(t, accA, id)
				updatedBalance = balance
				return nil
			},
		}
		catRepo := &mocks.MockCategoryRepository{
			GetByIDFunc: func(ctx context.Context, id domain.UUID) (*domain.Category, error) {
				assert.Equal(t, catID, id)
				return &domain.Category{ID: catID, Name: "Food"}, nil
			},
		}
		txRepo := &mocks.MockTransactionRepository{
			CreateFunc: func(ctx context.Context, tx *domain.Transaction) error {
				createdTx = tx
				return nil
			},
		}

		svc := service.NewTransactionService(txRepo, accRepo, catRepo, txMgr)
		c := catID
		tx := &domain.Transaction{
			ID:         txID,
			AccountID:  accA,
			CategoryID: &c,
			Type:       domain.TransactionTypeExpense,
			Amount:     decimal.NewFromInt(150000),
			Note:       "  Groceries  ",
		}

		err := svc.CreateTransaction(ctx, tx)
		require.NoError(t, err)
		assert.True(t, txExecuted)
		assert.True(t, decimal.NewFromInt(850000).Equal(updatedBalance))
		require.NotNil(t, createdTx)
		assert.Equal(t, "IDR", createdTx.Currency)
		assert.Equal(t, "Groceries", createdTx.Note)
		assert.True(t, decimal.NewFromInt(150000).Equal(createdTx.BaseAmount))
	})

	t.Run("happy path - creates income and increments account balance", func(t *testing.T) {
		var updatedBalance decimal.Decimal
		accRepo := &mocks.MockAccountRepository{
			GetByIDForUpdateFunc: func(ctx context.Context, id domain.UUID) (*domain.Account, error) {
				return &domain.Account{
					ID:      accA,
					Type:    domain.AccountTypeBank,
					Balance: decimal.NewFromInt(500000),
				}, nil
			},
			UpdateBalanceFunc: func(ctx context.Context, id domain.UUID, balance decimal.Decimal) error {
				updatedBalance = balance
				return nil
			},
		}
		catRepo := &mocks.MockCategoryRepository{
			GetByIDFunc: func(ctx context.Context, id domain.UUID) (*domain.Category, error) {
				return &domain.Category{ID: id, Name: "Salary"}, nil
			},
		}
		txRepo := &mocks.MockTransactionRepository{}

		svc := service.NewTransactionService(txRepo, accRepo, catRepo)
		c := catID
		tx := &domain.Transaction{
			ID:         txID,
			AccountID:  accA,
			CategoryID: &c,
			Type:       domain.TransactionTypeIncome,
			Amount:     decimal.NewFromInt(2000000),
		}

		err := svc.CreateTransaction(ctx, tx)
		require.NoError(t, err)
		assert.True(t, decimal.NewFromInt(2500000).Equal(updatedBalance))
	})

	t.Run("happy path - transfer locks accounts in deterministic UUID order", func(t *testing.T) {
		var lockedOrder []domain.UUID
		balances := map[domain.UUID]decimal.Decimal{
			accA: decimal.NewFromInt(300000),
			accB: decimal.NewFromInt(700000),
		}

		accRepo := &mocks.MockAccountRepository{
			GetByIDForUpdateFunc: func(ctx context.Context, id domain.UUID) (*domain.Account, error) {
				lockedOrder = append(lockedOrder, id)
				return &domain.Account{
					ID:      id,
					Type:    domain.AccountTypeBank,
					Balance: balances[id],
				}, nil
			},
			UpdateBalanceFunc: func(ctx context.Context, id domain.UUID, balance decimal.Decimal) error {
				balances[id] = balance
				return nil
			},
		}
		txRepo := &mocks.MockTransactionRepository{}
		svc := service.NewTransactionService(txRepo, accRepo, nil)

		// Transfer from accB (higher UUID) to accA (lower UUID): should lock accA first, then accB!
		dest := accA
		tx := &domain.Transaction{
			ID:                   txID,
			AccountID:            accB,
			DestinationAccountID: &dest,
			Type:                 domain.TransactionTypeTransfer,
			Amount:               decimal.NewFromInt(200000),
		}

		err := svc.CreateTransaction(ctx, tx)
		require.NoError(t, err)
		require.Len(t, lockedOrder, 2)
		assert.Equal(t, accA, lockedOrder[0], "lower UUID must be locked first to prevent deadlock")
		assert.Equal(t, accB, lockedOrder[1], "higher UUID must be locked second")
		assert.True(t, decimal.NewFromInt(500000).Equal(balances[accB]))
		assert.True(t, decimal.NewFromInt(500000).Equal(balances[accA]))
	})

	t.Run("failure path - insufficient balance on non-credit-card account", func(t *testing.T) {
		accRepo := &mocks.MockAccountRepository{
			GetByIDForUpdateFunc: func(ctx context.Context, id domain.UUID) (*domain.Account, error) {
				return &domain.Account{
					ID:      accA,
					Type:    domain.AccountTypeCash,
					Balance: decimal.NewFromInt(50000),
				}, nil
			},
		}
		catRepo := &mocks.MockCategoryRepository{
			GetByIDFunc: func(ctx context.Context, id domain.UUID) (*domain.Category, error) {
				return &domain.Category{ID: id}, nil
			},
		}
		txRepo := &mocks.MockTransactionRepository{
			CreateFunc: func(ctx context.Context, tx *domain.Transaction) error {
				t.Fatal("Create should not be called when balance is insufficient")
				return nil
			},
		}

		svc := service.NewTransactionService(txRepo, accRepo, catRepo)
		c := catID
		tx := &domain.Transaction{
			ID:         txID,
			AccountID:  accA,
			CategoryID: &c,
			Type:       domain.TransactionTypeExpense,
			Amount:     decimal.NewFromInt(100000),
		}

		err := svc.CreateTransaction(ctx, tx)
		require.Error(t, err)
		assert.ErrorIs(t, err, domain.ErrInsufficientBalance)
	})

	t.Run("happy path - credit card account allows negative balance", func(t *testing.T) {
		var updatedBalance decimal.Decimal
		accRepo := &mocks.MockAccountRepository{
			GetByIDForUpdateFunc: func(ctx context.Context, id domain.UUID) (*domain.Account, error) {
				return &domain.Account{
					ID:      accA,
					Type:    domain.AccountTypeCreditCard,
					Balance: decimal.Zero,
				}, nil
			},
			UpdateBalanceFunc: func(ctx context.Context, id domain.UUID, balance decimal.Decimal) error {
				updatedBalance = balance
				return nil
			},
		}
		catRepo := &mocks.MockCategoryRepository{
			GetByIDFunc: func(ctx context.Context, id domain.UUID) (*domain.Category, error) {
				return &domain.Category{ID: id}, nil
			},
		}
		txRepo := &mocks.MockTransactionRepository{}

		svc := service.NewTransactionService(txRepo, accRepo, catRepo)
		c := catID
		tx := &domain.Transaction{
			ID:         txID,
			AccountID:  accA,
			CategoryID: &c,
			Type:       domain.TransactionTypeExpense,
			Amount:     decimal.NewFromInt(350000),
		}

		err := svc.CreateTransaction(ctx, tx)
		require.NoError(t, err)
		assert.True(t, decimal.NewFromInt(-350000).Equal(updatedBalance))
	})
}

func TestTransactionService_DeleteTransaction(t *testing.T) {
	ctx := context.Background()
	txID := domain.MustParseUUID("0192d6e2-5b9c-7000-8000-000000000101")
	accA := domain.MustParseUUID("0192d6e2-5b9c-7000-8000-000000000001")
	catID := domain.MustParseUUID("0192d6e2-5b9c-7000-8000-000000000010")

	t.Run("happy path - soft deletes expense and restores account balance", func(t *testing.T) {
		var restoredBalance decimal.Decimal
		deleted := false

		txRepo := &mocks.MockTransactionRepository{
			GetByIDFunc: func(ctx context.Context, id domain.UUID) (*domain.Transaction, error) {
				c := catID
				return &domain.Transaction{
					ID:              txID,
					AccountID:       accA,
					CategoryID:      &c,
					Type:            domain.TransactionTypeExpense,
					Amount:          decimal.NewFromInt(125000),
					TransactionDate: time.Now().UTC(),
				}, nil
			},
			DeleteFunc: func(ctx context.Context, id domain.UUID) error {
				assert.Equal(t, txID, id)
				deleted = true
				return nil
			},
		}
		accRepo := &mocks.MockAccountRepository{
			GetByIDForUpdateFunc: func(ctx context.Context, id domain.UUID) (*domain.Account, error) {
				return &domain.Account{
					ID:      accA,
					Type:    domain.AccountTypeBank,
					Balance: decimal.NewFromInt(875000),
				}, nil
			},
			UpdateBalanceFunc: func(ctx context.Context, id domain.UUID, balance decimal.Decimal) error {
				restoredBalance = balance
				return nil
			},
		}

		svc := service.NewTransactionService(txRepo, accRepo, nil)
		err := svc.DeleteTransaction(ctx, txID)
		require.NoError(t, err)
		assert.True(t, deleted)
		assert.True(t, decimal.NewFromInt(1000000).Equal(restoredBalance))
	})

	t.Run("failure path - transaction not found", func(t *testing.T) {
		txRepo := &mocks.MockTransactionRepository{
			GetByIDFunc: func(ctx context.Context, id domain.UUID) (*domain.Transaction, error) {
				return nil, nil
			},
		}
		svc := service.NewTransactionService(txRepo, &mocks.MockAccountRepository{}, nil)
		err := svc.DeleteTransaction(ctx, txID)
		require.Error(t, err)
		assert.True(t, errors.Is(err, domain.ErrTransactionNotFound))
	})
}

func TestTransactionService_ListTransactions(t *testing.T) {
	ctx := context.Background()
	accA := domain.MustParseUUID("0192d6e2-5b9c-7000-8000-000000000001")

	t.Run("lists transactions filtered by account with pagination", func(t *testing.T) {
		txRepo := &mocks.MockTransactionRepository{
			CountByAccountFunc: func(ctx context.Context, accountID domain.UUID) (int, error) {
				assert.Equal(t, accA, accountID)
				return 1, nil
			},
			ListByAccountFunc: func(ctx context.Context, accountID domain.UUID, limit, offset int) ([]*domain.Transaction, error) {
				assert.Equal(t, accA, accountID)
				assert.Equal(t, 20, limit)
				assert.Equal(t, 0, offset)
				return []*domain.Transaction{{AccountID: accA}}, nil
			},
		}

		svc := service.NewTransactionService(txRepo, &mocks.MockAccountRepository{}, nil)
		items, total, err := svc.ListTransactions(ctx, &accA, 0, -5)
		require.NoError(t, err)
		assert.Equal(t, 1, total)
		assert.Len(t, items, 1)
	})
}
