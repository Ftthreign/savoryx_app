package postgres

import (
	"context"
	"testing"
	"time"

	"github.com/ftthreign/savoryx_app/server/internal/adapter/repository/postgres/db"
	"github.com/ftthreign/savoryx_app/server/internal/core/domain"
	"github.com/jackc/pgx/v5/pgtype"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

func TestSyncLogRepository_ValidationAndNilGuards(t *testing.T) {
	t.Parallel()
	ctx := context.Background()

	repo := NewSyncLogRepository(nil)
	require.NotNil(t, repo)

	t.Run("Record rejects nil sync log", func(t *testing.T) {
		t.Parallel()
		err := repo.Record(ctx, nil)
		assert.ErrorIs(t, err, domain.ErrInvalidInput)
	})

	t.Run("Record rejects invalid sync log", func(t *testing.T) {
		t.Parallel()
		err := repo.Record(ctx, &domain.SyncLog{})
		assert.ErrorIs(t, err, domain.ErrInvalidInput)
	})

	t.Run("Record returns ErrDatabaseUnavailable when DB is nil", func(t *testing.T) {
		t.Parallel()
		validLog := &domain.SyncLog{
			ID:              domain.NewUUIDv7(),
			DeviceID:        domain.NewUUIDv7(),
			Direction:       domain.SyncDirectionPush,
			BatchSize:       10,
			Status:          domain.SyncStatusSuccess,
			ClientTimestamp: time.Now().UTC(),
		}
		err := repo.Record(ctx, validLog)
		assert.ErrorIs(t, err, domain.ErrDatabaseUnavailable)
	})

	t.Run("GetByID rejects zero UUID and returns ErrDatabaseUnavailable on nil DB", func(t *testing.T) {
		t.Parallel()
		_, err := repo.GetByID(ctx, domain.NilUUID)
		assert.ErrorIs(t, err, domain.ErrInvalidInput)

		_, err = repo.GetByID(ctx, domain.NewUUIDv7())
		assert.ErrorIs(t, err, domain.ErrDatabaseUnavailable)
	})

	t.Run("ListByDevice rejects zero UUID and returns ErrDatabaseUnavailable on nil DB", func(t *testing.T) {
		t.Parallel()
		_, err := repo.ListByDevice(ctx, domain.NilUUID, 10, 0)
		assert.ErrorIs(t, err, domain.ErrInvalidInput)

		_, err = repo.ListByDevice(ctx, domain.NewUUIDv7(), 10, 0)
		assert.ErrorIs(t, err, domain.ErrDatabaseUnavailable)
	})

	t.Run("CountByDevice rejects zero UUID and returns ErrDatabaseUnavailable on nil DB", func(t *testing.T) {
		t.Parallel()
		_, err := repo.CountByDevice(ctx, domain.NilUUID)
		assert.ErrorIs(t, err, domain.ErrInvalidInput)

		_, err = repo.CountByDevice(ctx, domain.NewUUIDv7())
		assert.ErrorIs(t, err, domain.ErrDatabaseUnavailable)
	})
}

func TestToDomainSyncLogs(t *testing.T) {
	t.Parallel()

	t.Run("empty slice returns non-nil zero-length slice", func(t *testing.T) {
		t.Parallel()
		out := toDomainSyncLogs(nil)
		require.NotNil(t, out)
		assert.Empty(t, out)
	})

	t.Run("maps db.SyncLog rows accurately to domain.SyncLog", func(t *testing.T) {
		t.Parallel()
		now := time.Now().UTC().Truncate(time.Microsecond)
		logID := domain.NewUUIDv7()
		devID := domain.NewUUIDv7()

		rows := []db.SyncLog{
			{
				ID:              pgtype.UUID{Bytes: logID.Bytes(), Valid: true},
				DeviceID:        pgtype.UUID{Bytes: devID.Bytes(), Valid: true},
				Direction:       "PUSH",
				BatchSize:       25,
				Status:          "SUCCESS",
				ClientTimestamp: pgtype.Timestamptz{Time: now.Add(-2 * time.Second), Valid: true},
				ServerTimestamp: pgtype.Timestamptz{Time: now, Valid: true},
				CreatedAt:       pgtype.Timestamptz{Time: now, Valid: true},
			},
		}

		out := toDomainSyncLogs(rows)
		require.Len(t, out, 1)
		assert.Equal(t, logID, out[0].ID)
		assert.Equal(t, devID, out[0].DeviceID)
		assert.Equal(t, domain.SyncDirectionPush, out[0].Direction)
		assert.Equal(t, 25, out[0].BatchSize)
		assert.Equal(t, domain.SyncStatusSuccess, out[0].Status)
		assert.Equal(t, now.Add(-2*time.Second), out[0].ClientTimestamp)
		assert.Equal(t, now, out[0].ServerTimestamp)
		assert.Equal(t, now, out[0].CreatedAt)
	})
}
