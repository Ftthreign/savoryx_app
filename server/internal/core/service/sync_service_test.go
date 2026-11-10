package service_test

import (
	"bytes"
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

	t.Run("atomic rollback - mid-batch failure rolls back entire transaction and skips audit commit", func(t *testing.T) {
		committed := false
		rolledBack := false
		tx1ID := domain.NewUUIDv7()
		tx2ID := domain.NewUUIDv7()
		devID := domain.NewUUIDv7()

		txMgr := &mocks.MockTxManager{
			RunInTxFunc: func(ctx context.Context, fn func(ctx context.Context) error) error {
				err := fn(ctx)
				if err != nil {
					rolledBack = true
					return err
				}
				committed = true
				return nil
			},
		}

		boom := errors.New("simulated constraint violation on 2nd transaction")
		upsertedTxCount := 0
		syncLogCalls := 0

		accRepo := &mocks.MockAccountRepository{
			GetByIDForUpdateFunc: func(ctx context.Context, id domain.UUID) (*domain.Account, error) {
				return &domain.Account{
					ID:      id,
					Name:    "Main Wallet",
					Type:    domain.AccountTypeCash,
					Balance: decimal.NewFromInt(100000),
				}, nil
			},
		}
		txRepo := &mocks.MockTransactionRepository{
			GetByIDFunc: func(ctx context.Context, id domain.UUID) (*domain.Transaction, error) {
				return nil, domain.ErrTransactionNotFound
			},
			UpsertFunc: func(ctx context.Context, tx *domain.Transaction) error {
				upsertedTxCount++
				if upsertedTxCount == 2 {
					return boom
				}
				return nil
			},
		}
		syncLogRepo := &mocks.MockSyncLogRepository{
			RecordFunc: func(ctx context.Context, log *domain.SyncLog) error {
				syncLogCalls++
				return nil
			},
		}

		svc := service.NewSyncServiceWithOptions(
			accRepo,
			&mocks.MockCategoryRepository{},
			txRepo,
			service.WithSyncTxManager(txMgr),
			service.WithSyncLogRepository(syncLogRepo),
		)

		c := catID
		payload := &port.SyncPushPayload{
			DeviceID:        devID,
			ClientTimestamp: now,
			Categories: []*domain.Category{
				{ID: catID, Name: "Transport", Icon: "car", Color: "#112233", UpdatedAt: now},
			},
			Accounts: []*domain.Account{
				{ID: accID, Name: "Main Wallet", Type: domain.AccountTypeCash, Currency: "IDR", Balance: decimal.NewFromInt(100000), UpdatedAt: now},
			},
			Transactions: []*domain.Transaction{
				{ID: tx1ID, AccountID: accID, CategoryID: &c, Type: domain.TransactionTypeExpense, Amount: decimal.NewFromInt(10000), Currency: "IDR", TransactionDate: now, UpdatedAt: now},
				{ID: tx2ID, AccountID: accID, CategoryID: &c, Type: domain.TransactionTypeExpense, Amount: decimal.NewFromInt(20000), Currency: "IDR", TransactionDate: now, UpdatedAt: now},
			},
		}

		res, err := svc.PushChanges(ctx, payload)
		require.Error(t, err)
		assert.Nil(t, res)
		assert.ErrorIs(t, err, boom)
		assert.True(t, rolledBack, "entire batch transaction must roll back on error")
		assert.False(t, committed, "failed batch must never commit")
		assert.Equal(t, 0, syncLogCalls, "sync_logs must not be written when batch aborts")
	})

	t.Run("pessimistic row locking & decimal balance reconciliation across transactions and tombstone reversal", func(t *testing.T) {
		devID := domain.NewUUIDv7()
		srcID := domain.NewUUIDv7()
		dstID := domain.NewUUIDv7()
		expID := domain.NewUUIDv7()
		incID := domain.NewUUIDv7()
		trfID := domain.NewUUIDv7()

		balances := map[domain.UUID]decimal.Decimal{
			srcID: decimal.RequireFromString("500000.55"),
			dstID: decimal.RequireFromString("100000.00"),
		}
		lockedOrder := make([]domain.UUID, 0)
		persistedTxs := make(map[domain.UUID]*domain.Transaction)
		var recordedLog *domain.SyncLog

		accRepo := &mocks.MockAccountRepository{
			GetByIDForUpdateFunc: func(ctx context.Context, id domain.UUID) (*domain.Account, error) {
				bal, ok := balances[id]
				if !ok {
					return nil, domain.ErrAccountNotFound
				}
				lockedOrder = append(lockedOrder, id)
				return &domain.Account{
					ID:       id,
					Name:     "Account",
					Type:     domain.AccountTypeBank,
					Currency: "IDR",
					Balance:  bal,
				}, nil
			},
			UpdateBalanceFunc: func(ctx context.Context, id domain.UUID, balance decimal.Decimal) error {
				balances[id] = balance
				return nil
			},
		}
		txRepo := &mocks.MockTransactionRepository{
			GetByIDFunc: func(ctx context.Context, id domain.UUID) (*domain.Transaction, error) {
				existing, ok := persistedTxs[id]
				if !ok || existing.DeletedAt != nil {
					return nil, domain.ErrTransactionNotFound
				}
				return existing, nil
			},
			UpsertFunc: func(ctx context.Context, tx *domain.Transaction) error {
				copyTx := *tx
				persistedTxs[tx.ID] = &copyTx
				return nil
			},
		}
		syncLogRepo := &mocks.MockSyncLogRepository{
			RecordFunc: func(ctx context.Context, log *domain.SyncLog) error {
				recordedLog = log
				return nil
			},
		}

		svc := service.NewSyncServiceWithOptions(
			accRepo,
			&mocks.MockCategoryRepository{},
			txRepo,
			service.WithSyncTxManager(&mocks.MockTxManager{}),
			service.WithSyncLogRepository(syncLogRepo),
		)

		// Batch 1: Expense (-125000.30), Income (+25000.25), Transfer src -> dst (50000.00)
		c := catID
		payload1 := &port.SyncPushPayload{
			DeviceID:        devID,
			ClientTimestamp: now,
			Transactions: []*domain.Transaction{
				{ID: expID, AccountID: srcID, CategoryID: &c, Type: domain.TransactionTypeExpense, Amount: decimal.RequireFromString("125000.30"), Currency: "IDR", TransactionDate: now, UpdatedAt: now},
				{ID: incID, AccountID: srcID, CategoryID: &c, Type: domain.TransactionTypeIncome, Amount: decimal.RequireFromString("25000.25"), Currency: "IDR", TransactionDate: now, UpdatedAt: now},
				{ID: trfID, AccountID: srcID, DestinationAccountID: &dstID, Type: domain.TransactionTypeTransfer, Amount: decimal.RequireFromString("50000.00"), Currency: "IDR", TransactionDate: now, UpdatedAt: now},
			},
		}

		res1, err := svc.PushChanges(ctx, payload1)
		require.NoError(t, err)
		assert.Equal(t, 3, res1.TransactionsApplied)
		// 500000.55 - 125000.30 + 25000.25 - 50000.00 = 350000.50
		assert.True(t, decimal.RequireFromString("350000.50").Equal(balances[srcID]), "got %s", balances[srcID])
		assert.True(t, decimal.RequireFromString("150000.00").Equal(balances[dstID]), "got %s", balances[dstID])

		// Verify deterministic UUID byte lock order on the transfer (last 2 locks)
		require.GreaterOrEqual(t, len(lockedOrder), 4)
		transferLockFirst := lockedOrder[len(lockedOrder)-2]
		transferLockSecond := lockedOrder[len(lockedOrder)-1]
		assert.True(t, bytes.Compare(transferLockFirst[:], transferLockSecond[:]) <= 0, "transfer locks must follow ascending UUID byte order")

		// Verify PUSH audit log recorded atomically
		require.NotNil(t, recordedLog)
		assert.Equal(t, devID, recordedLog.DeviceID)
		assert.Equal(t, domain.SyncDirectionPush, recordedLog.Direction)
		assert.Equal(t, domain.SyncStatusSuccess, recordedLog.Status)
		assert.Equal(t, 3, recordedLog.BatchSize)

		// Batch 2: Tombstone the earlier expense (-125000.30) -> reverts +125000.30 => 475000.80
		delTS := now.Add(time.Minute)
		payload2 := &port.SyncPushPayload{
			DeviceID:        devID,
			ClientTimestamp: delTS,
			Transactions: []*domain.Transaction{
				{ID: expID, AccountID: srcID, CategoryID: &c, Type: domain.TransactionTypeExpense, Amount: decimal.RequireFromString("125000.30"), Currency: "IDR", TransactionDate: now, UpdatedAt: delTS, DeletedAt: &delTS},
			},
		}
		_, err = svc.PushChanges(ctx, payload2)
		require.NoError(t, err)
		assert.True(t, decimal.RequireFromString("475000.80").Equal(balances[srcID]), "got %s", balances[srcID])
	})

	t.Run("LWW microsecond conflict resolution ignores older account snapshot and keeps newer", func(t *testing.T) {
		tNew := time.Date(2026, 11, 10, 12, 0, 0, 500000000, time.UTC) // .500s
		tOld := time.Date(2026, 11, 10, 12, 0, 0, 499000000, time.UTC) // .499s (1ms older)

		stored := map[domain.UUID]*domain.Account{
			accID: {
				ID:        accID,
				Name:      "Latest Server Name",
				Type:      domain.AccountTypeBank,
				Currency:  "IDR",
				Balance:   decimal.NewFromInt(900000),
				UpdatedAt: tNew,
			},
		}

		accRepo := &mocks.MockAccountRepository{
			UpsertSyncFunc: func(ctx context.Context, acc *domain.Account) error {
				if cur, ok := stored[acc.ID]; ok && !acc.UpdatedAt.After(cur.UpdatedAt) {
					return nil
				}
				c := *acc
				stored[acc.ID] = &c
				return nil
			},
			GetByIDForUpdateFunc: func(ctx context.Context, id domain.UUID) (*domain.Account, error) {
				return stored[id], nil
			},
		}

		svc := service.NewSyncService(accRepo, &mocks.MockCategoryRepository{}, &mocks.MockTransactionRepository{}, &mocks.MockTxManager{})
		_, err := svc.PushChanges(ctx, &port.SyncPushPayload{
			Accounts: []*domain.Account{
				{ID: accID, Name: "Stale Name", Type: domain.AccountTypeBank, Currency: "IDR", Balance: decimal.NewFromInt(100), UpdatedAt: tOld},
			},
		})
		require.NoError(t, err)
		assert.Equal(t, "Latest Server Name", stored[accID].Name)
	})
}
