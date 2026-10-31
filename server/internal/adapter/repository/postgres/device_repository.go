package postgres

import (
	"context"
	"errors"
	"time"

	"github.com/ftthreign/savoryx_app/server/internal/adapter/repository/postgres/db"
	"github.com/ftthreign/savoryx_app/server/internal/core/domain"
	"github.com/ftthreign/savoryx_app/server/internal/port"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgconn"
	"github.com/jackc/pgx/v5/pgtype"
	"github.com/samber/oops"
)

type DeviceRepository struct {
	q *db.Queries
}

func NewDeviceRepository(d *DB) *DeviceRepository {
	return &DeviceRepository{
		q: db.New(d.Pool),
	}
}

func (r *DeviceRepository) Register(ctx context.Context, dev *domain.Device) error {
	if dev == nil {
		return oops.
			In("device_repository").
			Tags("database", "postgres").
			Code("ERR_DEVICE_INVALID_INPUT").
			Wrap(domain.ErrInvalidInput)
	}

	params := db.RegisterDeviceParams{
		ID:               pgtype.UUID{Bytes: dev.ID.Bytes(), Valid: true},
		DeviceName:       dev.DeviceName,
		Platform:         dev.Platform,
		AppVersion:       dev.AppVersion,
		DeviceSecretHash: dev.DeviceSecretHash,
	}

	registered, err := r.q.RegisterDevice(ctx, params)
	if err != nil {
		var pgErr *pgconn.PgError
		if errors.As(err, &pgErr) && pgErr.Code == "23505" {
			return oops.
				In("device_repository").
				Tags("database", "postgres").
				Code("ERR_DEVICE_ALREADY_EXISTS").
				With("device_id", dev.ID.String()).
				Wrap(domain.ErrConflict)
		}

		return oops.
			In("device_repository").
			Tags("database", "postgres").
			Code("ERR_DEVICE_REGISTER").
			With("device_id", dev.ID.String()).
			Wrapf(err, "failed to register device record")
	}

	*dev = *toDomainDevice(registered)
	return nil
}

func (r *DeviceRepository) GetByID(ctx context.Context, id domain.UUID) (*domain.Device, error) {
	pgID := pgtype.UUID{Bytes: id.Bytes(), Valid: true}
	row, err := r.q.GetDeviceByID(ctx, pgID)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, oops.
				In("device_repository").
				Tags("database", "postgres").
				Code("ERR_DEVICE_NOT_FOUND").
				With("device_id", id.String()).
				Wrap(domain.ErrDeviceNotFound)
		}
		return nil, oops.
			In("device_repository").
			Tags("database", "postgres").
			Code("ERR_DEVICE_GET").
			With("device_id", id.String()).
			Wrapf(err, "failed to get device by id")
	}

	return toDomainDevice(row), nil
}

func (r *DeviceRepository) UpdateLastActive(ctx context.Context, id domain.UUID) error {
	pgID := pgtype.UUID{Bytes: id.Bytes(), Valid: true}
	err := r.q.UpdateDeviceLastActive(ctx, pgID)
	if err != nil {
		return oops.
			In("device_repository").
			Tags("database", "postgres").
			Code("ERR_DEVICE_UPDATE_ACTIVE").
			With("device_id", id.String()).
			Wrapf(err, "failed to update device last active timestamp")
	}

	return nil
}

func (r *DeviceRepository) Revoke(ctx context.Context, id domain.UUID) error {
	pgID := pgtype.UUID{Bytes: id.Bytes(), Valid: true}
	err := r.q.RevokeDevice(ctx, pgID)
	if err != nil {
		return oops.
			In("device_repository").
			Tags("database", "postgres").
			Code("ERR_DEVICE_REVOKE").
			With("device_id", id.String()).
			Wrapf(err, "failed to revoke device authorization")
	}

	return nil
}

func toDomainDevice(row db.Device) *domain.Device {
	var revokedAt *time.Time
	if row.RevokedAt.Valid {
		t := row.RevokedAt.Time
		revokedAt = &t
	}

	return &domain.Device{
		ID:               domain.FromBytes(row.ID.Bytes),
		DeviceName:       row.DeviceName,
		Platform:         row.Platform,
		AppVersion:       row.AppVersion,
		DeviceSecretHash: row.DeviceSecretHash,
		CreatedAt:        row.CreatedAt.Time,
		LastActiveAt:     row.LastActiveAt.Time,
		RevokedAt:        revokedAt,
	}
}

var _ port.DeviceRepository = (*DeviceRepository)(nil)
