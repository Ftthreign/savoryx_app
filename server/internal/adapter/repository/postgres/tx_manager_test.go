package postgres

import (
	"context"
	"testing"

	"github.com/ftthreign/savoryx_app/server/internal/adapter/repository/postgres/db"
	"github.com/jackc/pgx/v5"
	"github.com/samber/oops"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

type dummyTx struct {
	pgx.Tx
	commitCalled   bool
	rollbackCalled bool
}

func (d *dummyTx) Commit(ctx context.Context) error {
	d.commitCalled = true
	return nil
}

func (d *dummyTx) Rollback(ctx context.Context) error {
	d.rollbackCalled = true
	return nil
}

func TestTxContextPropagation(t *testing.T) {
	ctx := context.Background()

	t.Run("ExtractTx returns nil on empty context", func(t *testing.T) {
		tx := ExtractTx(ctx)
		assert.Nil(t, tx)
	})

	t.Run("ExtractTx returns injected tx", func(t *testing.T) {
		mock := &dummyTx{}
		txCtx := InjectTx(ctx, mock)
		extracted := ExtractTx(txCtx)
		assert.Equal(t, mock, extracted)
	})

	t.Run("ExtractTx returns nil when nil is injected", func(t *testing.T) {
		txCtx := InjectTx(ctx, nil)
		assert.Nil(t, ExtractTx(txCtx))
	})
}

func TestTxManager_Uninitialized(t *testing.T) {
	ctx := context.Background()

	t.Run("nil DB creates TxManager with nil pool", func(t *testing.T) {
		mgr := NewTxManager(nil)
		require.NotNil(t, mgr)
		assert.Nil(t, mgr.pool)

		err := mgr.RunInTx(ctx, func(txCtx context.Context) error {
			return nil
		})
		assert.Error(t, err)
		oopsErr, ok := oops.AsOops(err)
		require.True(t, ok)
		assert.Equal(t, "ERR_POOL_NIL", oopsErr.Code())
	})

	t.Run("nil TxManager returns ERR_POOL_NIL", func(t *testing.T) {
		var mgr *TxManager
		err := mgr.RunInTx(ctx, func(txCtx context.Context) error {
			return nil
		})
		assert.Error(t, err)
		oopsErr, ok := oops.AsOops(err)
		require.True(t, ok)
		assert.Equal(t, "ERR_POOL_NIL", oopsErr.Code())
	})
}

func TestTxManager_NestedTransactionReuse(t *testing.T) {
	ctx := context.Background()

	t.Run("nested transaction reuses active tx without error", func(t *testing.T) {
		mock := &dummyTx{}
		txCtx := InjectTx(ctx, mock)

		// Even with nil pool, nested transaction in context does not call pool.BeginTx
		mgr := &TxManager{pool: nil}
		executed := false
		err := mgr.RunInTx(txCtx, func(innerCtx context.Context) error {
			executed = true
			assert.Equal(t, mock, ExtractTx(innerCtx))
			return nil
		})
		assert.NoError(t, err)
		assert.True(t, executed)
	})
}

func TestAccountRepository_QueriesSelection(t *testing.T) {
	ctx := context.Background()

	t.Run("queries returns base q when no tx in context", func(t *testing.T) {
		baseQ := db.New(nil)
		repo := &AccountRepository{q: baseQ}
		q := repo.queries(ctx)
		assert.Same(t, baseQ, q)
	})

	t.Run("queries binds active tx when tx in context", func(t *testing.T) {
		mock := &dummyTx{}
		txCtx := InjectTx(ctx, mock)

		baseQ := db.New(nil)
		repo := &AccountRepository{q: baseQ}
		q := repo.queries(txCtx)
		require.NotNil(t, q)
		assert.NotSame(t, baseQ, q)
	})
}
