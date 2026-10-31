package postgres

import (
	"context"
	"fmt"
	"time"

	"github.com/ftthreign/savoryx_app/server/internal/core/domain"
	"github.com/ftthreign/savoryx_app/server/internal/port"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/samber/oops"
)

type DB struct {
	Pool *pgxpool.Pool
}

func NewDB(ctx context.Context, databaseURL string) (*DB, error) {
	config, err := pgxpool.ParseConfig(databaseURL)
	if err != nil {
		return nil, oops.
			Code("ERR_DATABASE_CONFIG").
			In("postgres_pool").
			Wrapf(err, "invalid postgres database url")
	}

	// Performance & Resilience Tuning
	config.MaxConns = 25
	config.MinConns = 5
	config.MaxConnLifetime = 1 * time.Hour
	config.MaxConnIdleTime = 30 * time.Minute
	config.HealthCheckPeriod = 1 * time.Minute

	pool, err := pgxpool.NewWithConfig(ctx, config)
	if err != nil {
		return nil, oops.
			Code("ERR_DATABASE_POOL_INIT").
			In("postgres_pool").
			Wrapf(err, "failed to initialize pgx connection pool")
	}

	// Verify connectivity
	pingCtx, cancel := context.WithTimeout(ctx, 5*time.Second)
	defer cancel()

	if err := pool.Ping(pingCtx); err != nil {
		pool.Close()
		return nil, oops.
			Code("ERR_DATABASE_PING").
			In("postgres_pool").
			Wrapf(err, "initial database ping check failed")
	}

	return &DB{Pool: pool}, nil
}

func (d *DB) Ping(ctx context.Context) error {
	if d == nil || d.Pool == nil {
		return fmt.Errorf("%w: connection pool is uninitialized", domain.ErrDatabaseUnavailable)
	}
	return d.Pool.Ping(ctx)
}

func (d *DB) Close() {
	if d.Pool != nil {
		d.Pool.Close()
	}
}

var _ port.DatabasePinger = (*DB)(nil)
