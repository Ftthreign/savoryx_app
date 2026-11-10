package postgres

import (
	"context"
	"errors"
	"math"

	"github.com/ftthreign/savoryx_app/server/internal/adapter/repository/postgres/db"
	"github.com/ftthreign/savoryx_app/server/internal/core/domain"
	"github.com/ftthreign/savoryx_app/server/internal/port"
	"github.com/jackc/pgx/v5"
	"github.com/samber/oops"
)

type SyncLogRepository struct {
	q *db.Queries
}

func NewSyncLogRepository(d *DB) *SyncLogRepository {
	if d == nil || d.Pool == nil {
		return &SyncLogRepository{}
	}
	return &SyncLogRepository{
		q: db.New(d.Pool),
	}
}

func (r *SyncLogRepository) queries(ctx context.Context) *db.Queries {
	if tx := ExtractTx(ctx); tx != nil && r.q != nil {
		return r.q.WithTx(tx)
	}
	return r.q
}

func repoSyncLogErr() oops.OopsErrorBuilder {
	return oops.In("sync_log_repository").Tags("database", "postgres")
}

func (r *SyncLogRepository) Record(ctx context.Context, log *domain.SyncLog) error {
	if log == nil {
		return repoSyncLogErr().
			Code("ERR_SYNC_LOG_NIL").
			Wrap(domain.ErrInvalidInput)
	}

	if err := log.Validate(); err != nil {
		return repoSyncLogErr().
			Code("ERR_SYNC_LOG_INVALID").
			Wrap(err)
	}

	q := r.queries(ctx)
	if q == nil {
		return repoSyncLogErr().
			Code("ERR_SYNC_LOG_DB_UNAVAILABLE").
			Wrap(domain.ErrDatabaseUnavailable)
	}

	batchSize := log.BatchSize
	if batchSize > math.MaxInt32 {
		batchSize = math.MaxInt32
	}

	params := db.RecordSyncLogParams{
		ID:              toPgUUID(log.ID),
		DeviceID:        toPgUUID(log.DeviceID),
		Direction:       string(log.Direction),
		BatchSize:       int32(batchSize),
		Status:          string(log.Status),
		ClientTimestamp: toPgTimestamptz(log.ClientTimestamp),
		ServerTimestamp: toPgTimestamptz(log.ServerTimestamp),
		CreatedAt:       toPgTimestamptz(log.CreatedAt),
	}

	recorded, err := q.RecordSyncLog(ctx, params)
	if err != nil {
		return repoSyncLogErr().
			Code("ERR_SYNC_LOG_RECORD").
			With("sync_log_id", log.ID.String()).
			With("device_id", log.DeviceID.String()).
			Wrapf(err, "failed to record sync audit log")
	}

	populateDomainSyncLog(log, recorded)
	return nil
}

func (r *SyncLogRepository) GetByID(ctx context.Context, id domain.UUID) (*domain.SyncLog, error) {
	if id.IsZero() {
		return nil, repoSyncLogErr().
			Code("ERR_SYNC_LOG_ID_ZERO").
			Wrap(domain.ErrInvalidInput)
	}

	q := r.queries(ctx)
	if q == nil {
		return nil, repoSyncLogErr().
			Code("ERR_SYNC_LOG_DB_UNAVAILABLE").
			Wrap(domain.ErrDatabaseUnavailable)
	}

	row, err := q.GetSyncLogByID(ctx, toPgUUID(id))
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, repoSyncLogErr().
				Code("ERR_SYNC_LOG_NOT_FOUND").
				With("sync_log_id", id.String()).
				Wrap(domain.ErrNotFound)
		}
		return nil, repoSyncLogErr().
			Code("ERR_SYNC_LOG_GET").
			With("sync_log_id", id.String()).
			Wrapf(err, "failed to get sync log by id")
	}

	var out domain.SyncLog
	populateDomainSyncLog(&out, row)
	return &out, nil
}

func (r *SyncLogRepository) ListByDevice(ctx context.Context, deviceID domain.UUID, limit, offset int) ([]*domain.SyncLog, error) {
	if deviceID.IsZero() {
		return nil, repoSyncLogErr().
			Code("ERR_SYNC_LOG_DEVICE_ID_ZERO").
			Wrap(domain.ErrInvalidInput)
	}

	q := r.queries(ctx)
	if q == nil {
		return nil, repoSyncLogErr().
			Code("ERR_SYNC_LOG_DB_UNAVAILABLE").
			Wrap(domain.ErrDatabaseUnavailable)
	}

	safeLimit, safeOffset := clampPaginationInt32(limit, offset)
	rows, err := q.ListSyncLogsByDevice(ctx, db.ListSyncLogsByDeviceParams{
		DeviceID: toPgUUID(deviceID),
		Limit:    safeLimit,
		Offset:   safeOffset,
	})
	if err != nil {
		return nil, repoSyncLogErr().
			Code("ERR_SYNC_LOG_LIST_BY_DEVICE").
			With("device_id", deviceID.String()).
			Wrapf(err, "failed to list sync logs by device")
	}

	return toDomainSyncLogs(rows), nil
}

func (r *SyncLogRepository) CountByDevice(ctx context.Context, deviceID domain.UUID) (int, error) {
	if deviceID.IsZero() {
		return 0, repoSyncLogErr().
			Code("ERR_SYNC_LOG_DEVICE_ID_ZERO").
			Wrap(domain.ErrInvalidInput)
	}

	q := r.queries(ctx)
	if q == nil {
		return 0, repoSyncLogErr().
			Code("ERR_SYNC_LOG_DB_UNAVAILABLE").
			Wrap(domain.ErrDatabaseUnavailable)
	}

	total, err := q.CountSyncLogsByDevice(ctx, toPgUUID(deviceID))
	if err != nil {
		return 0, repoSyncLogErr().
			Code("ERR_SYNC_LOG_COUNT_BY_DEVICE").
			With("device_id", deviceID.String()).
			Wrapf(err, "failed to count sync logs by device")
	}

	return int(total), nil
}

func toDomainSyncLogs(rows []db.SyncLog) []*domain.SyncLog {
	n := len(rows)
	if n == 0 {
		return make([]*domain.SyncLog, 0)
	}

	values := make([]domain.SyncLog, n)
	ptrs := make([]*domain.SyncLog, n)
	for i := range rows {
		populateDomainSyncLog(&values[i], rows[i])
		ptrs[i] = &values[i]
	}
	return ptrs
}

func populateDomainSyncLog(dst *domain.SyncLog, row db.SyncLog) {
	*dst = domain.SyncLog{
		ID:              domain.FromBytes(row.ID.Bytes),
		DeviceID:        domain.FromBytes(row.DeviceID.Bytes),
		Direction:       domain.SyncDirection(row.Direction),
		BatchSize:       int(row.BatchSize),
		Status:          domain.SyncStatus(row.Status),
		ClientTimestamp: row.ClientTimestamp.Time,
		ServerTimestamp: row.ServerTimestamp.Time,
		CreatedAt:       row.CreatedAt.Time,
	}
}

var _ port.SyncLogRepository = (*SyncLogRepository)(nil)
