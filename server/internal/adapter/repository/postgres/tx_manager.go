package postgres

import (
	"context"
	"errors"

	"github.com/ftthreign/savoryx_app/server/internal/port"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/samber/oops"
)

type txContextKey struct{}

func InjectTx(ctx context.Context, tx pgx.Tx) context.Context {
	return context.WithValue(ctx, txContextKey{}, tx)
}

// ExtractTx extracts an active pgx.Tx from the context if present, or returns nil.
func ExtractTx(ctx context.Context) pgx.Tx {
	if tx, ok := ctx.Value(txContextKey{}).(pgx.Tx); ok {
		return tx
	}
	return nil
}

type TxManager struct {
	pool *pgxpool.Pool
}

func NewTxManager(d *DB) *TxManager {
	if d == nil || d.Pool == nil {
		return &TxManager{pool: nil}
	}
	return &TxManager{pool: d.Pool}
}

func (m *TxManager) RunInTx(ctx context.Context, fn func(ctx context.Context) error) error {
	if ExtractTx(ctx) != nil {
		return fn(ctx)
	}

	if m == nil || m.pool == nil {
		return oops.
			In("tx_manager").
			Code("ERR_POOL_NIL").
			Errorf("database connection pool is uninitialized")
	}

	tx, err := m.pool.BeginTx(ctx, pgx.TxOptions{
		IsoLevel: pgx.ReadCommitted,
	})
	if err != nil {
		return oops.
			In("tx_manager").
			Code("ERR_TX_BEGIN").
			Wrapf(err, "failed to begin database transaction")
	}

	defer func() {
		if p := recover(); p != nil {
			_ = tx.Rollback(ctx)
			panic(p)
		}
	}()

	txCtx := InjectTx(ctx, tx)

	if err := fn(txCtx); err != nil {
		if rbErr := tx.Rollback(ctx); rbErr != nil && !errors.Is(rbErr, pgx.ErrTxClosed) {
			return oops.
				In("tx_manager").
				Code("ERR_TX_ROLLBACK").
				Wrapf(err, "transaction rollback failed: %v", rbErr)
		}
		return err
	}

	if err := tx.Commit(ctx); err != nil {
		return oops.
			In("tx_manager").
			Code("ERR_TX_COMMIT").
			Wrapf(err, "failed to commit transaction")
	}

	return nil
}

var _ port.TxManager = (*TxManager)(nil)
