package service_test

import (
	"context"
	"errors"
	"testing"
	"time"

	"github.com/ftthreign/savoryx_app/server/internal/core/domain"
	"github.com/ftthreign/savoryx_app/server/internal/core/service"
	"github.com/ftthreign/savoryx_app/server/internal/port"
	"github.com/ftthreign/savoryx_app/server/internal/testutil/mocks"
	"github.com/shopspring/decimal"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

func TestSyncService_PullChanges(t *testing.T) {
	ctx := context.Background()
	since := time.Date(2026, 11, 1, 0, 0, 0, 0, time.UTC)
	deletedTime := since.Add(2 * time.Hour)

	t.Run("happy path - pulls delta accounts, categories, and transactions including tombstones", func(t *testing.T) {
		accID := domain.NewUUIDv7()
		catID := domain.NewUUIDv7()
		txID := domain.NewUUIDv7()

		accRepo := &mocks.MockAccountRepository{
			ListUpdatedAfterFunc: func(ctx context.Context, s time.Time) ([]*domain.Account, error) {
				assert.Equal(t, since, s)
				return []*domain.Account{
					{
						ID:        accID,
						Name:      "BCA",
						Type:      domain.AccountTypeBank,
						Currency:  "IDR",
						Balance:   decimal.NewFromInt(1000000),
						UpdatedAt: since.Add(time.Hour),
					},
				}, nil
			},
		}
		catRepo := &mocks.MockCategoryRepository{
			ListUpdatedAfterFunc: func(ctx context.Context, s time.Time) ([]*domain.Category, error) {
				assert.Equal(t, since, s)
				return []*domain.Category{
					{
						ID:        catID,
						Name:      "Archived Category",
						Icon:      "archive",
						Color:     "#FF0000",
						UpdatedAt: deletedTime,
						DeletedAt: &deletedTime,
					},
				}, nil
			},
		}
		txRepo := &mocks.MockTransactionRepository{
			ListUpdatedAfterFunc: func(ctx context.Context, s time.Time) ([]*domain.Transaction, error) {
				assert.Equal(t, since, s)
				c := catID
				return []*domain.Transaction{
					{
						ID:              txID,
						AccountID:       accID,
						CategoryID:      &c,
						Type:            domain.TransactionTypeExpense,
						Amount:          decimal.NewFromInt(50000),
						Currency:        "IDR",
						TransactionDate: since.Add(time.Hour),
						UpdatedAt:       since.Add(time.Hour),
					},
				}, nil
			},
		}

		svc := service.NewSyncService(accRepo, catRepo, txRepo)
		res, err := svc.PullChanges(ctx, since)
		require.NoError(t, err)
		require.NotNil(t, res)
		assert.Len(t, res.Accounts, 1)
		assert.Len(t, res.Categories, 1)
		assert.NotNil(t, res.Categories[0].DeletedAt, "tombstone deleted_at must be preserved")
		assert.Len(t, res.Transactions, 1)
		assert.False(t, res.PulledAt.IsZero())
	})

	t.Run("empty delta returns non-nil slices", func(t *testing.T) {
		svc := service.NewSyncService(
			&mocks.MockAccountRepository{},
			&mocks.MockCategoryRepository{},
			&mocks.MockTransactionRepository{},
		)
		res, err := svc.PullChanges(ctx, since)
		require.NoError(t, err)
		assert.NotNil(t, res.Accounts)
		assert.NotNil(t, res.Categories)
		assert.NotNil(t, res.Transactions)
		assert.Empty(t, res.Accounts)
		assert.Empty(t, res.Categories)
		assert.Empty(t, res.Transactions)
	})
}

func TestSyncService_PushChanges(t *testing.T) {
	ctx := context.Background()
	now := time.Now().UTC()
	accID := domain.NewUUIDv7()
	catID := domain.NewUUIDv7()
	txID := domain.NewUUIDv7()

	t.Run("happy path - executes batch push atomically inside RunInTx", func(t *testing.T) {
		txExecuted := false
		catsUpserted := 0
		accsUpserted := 0
		txsUpserted := 0

		txMgr := &mocks.MockTxManager{
			RunInTxFunc: func(ctx context.Context, fn func(ctx context.Context) error) error {
				txExecuted = true
				return fn(ctx)
			},
		}
		accRepo := &mocks.MockAccountRepository{
			UpsertSyncFunc: func(ctx context.Context, acc *domain.Account) error {
				accsUpserted++
				return nil
			},
		}
		catRepo := &mocks.MockCategoryRepository{
			UpsertSyncFunc: func(ctx context.Context, cat *domain.Category) error {
				catsUpserted++
				return nil
			},
		}
		txRepo := &mocks.MockTransactionRepository{
			UpsertFunc: func(ctx context.Context, tx *domain.Transaction) error {
				txsUpserted++
				return nil
			},
		}

		svc := service.NewSyncService(accRepo, catRepo, txRepo, txMgr)
		c := catID
		payload := &port.SyncPushPayload{
			Accounts: []*domain.Account{
				{
					ID:        accID,
					Name:      "Cash Wallet",
					Type:      domain.AccountTypeCash,
					Currency:  "IDR",
					Balance:   decimal.NewFromInt(250000),
					UpdatedAt: now,
				},
			},
			Categories: []*domain.Category{
				{
					ID:        catID,
					Name:      "Coffee",
					Icon:      "coffee",
					Color:     "#8DB355",
					IsWants:   true,
					UpdatedAt: now,
				},
			},
			Transactions: []*domain.Transaction{
				{
					ID:              txID,
					AccountID:       accID,
					CategoryID:      &c,
					Type:            domain.TransactionTypeExpense,
					Amount:          decimal.NewFromInt(25000),
					Currency:        "IDR",
					TransactionDate: now,
					UpdatedAt:       now,
				},
			},
		}

		res, err := svc.PushChanges(ctx, payload)
		require.NoError(t, err)
		assert.True(t, txExecuted)
		assert.Equal(t, 1, catsUpserted)
		assert.Equal(t, 1, accsUpserted)
		assert.Equal(t, 1, txsUpserted)
		assert.Equal(t, 1, res.AccountsApplied)
		assert.Equal(t, 1, res.CategoriesApplied)
		assert.Equal(t, 1, res.TransactionsApplied)
	})

	t.Run("validation failure - nil payload or invalid transaction aborts before DB transaction", func(t *testing.T) {
		txMgr := &mocks.MockTxManager{
			RunInTxFunc: func(ctx context.Context, fn func(ctx context.Context) error) error {
				t.Fatal("RunInTx must not be called when validation fails")
				return nil
			},
		}
		svc := service.NewSyncService(
			&mocks.MockAccountRepository{},
			&mocks.MockCategoryRepository{},
			&mocks.MockTransactionRepository{},
			txMgr,
		)

		_, err := svc.PushChanges(ctx, nil)
		require.Error(t, err)
		assert.True(t, errors.Is(err, domain.ErrInvalidInput))

		badPayload := &port.SyncPushPayload{
			Transactions: []*domain.Transaction{
				{
					ID:        txID,
					AccountID: accID,
					Type:      domain.TransactionTypeExpense,
					Amount:    decimal.NewFromInt(-100), // invalid negative amount
				},
			},
		}
		_, err = svc.PushChanges(ctx, badPayload)
		require.Error(t, err)
		assert.True(t, errors.Is(err, domain.ErrInvalidInput))
	})
}
