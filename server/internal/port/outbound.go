package port

import (
	"context"

	"github.com/ftthreign/savoryx_app/server/internal/core/domain"
	"github.com/shopspring/decimal"
)

type DatabasePinger interface {
	Ping(ctx context.Context) error
}

type AccountRepository interface {
	Create(ctx context.Context, acc *domain.Account) error
	GetByID(ctx context.Context, id domain.UUID) (*domain.Account, error)
	GetByIDForUpdate(ctx context.Context, id domain.UUID) (*domain.Account, error)
	List(ctx context.Context) ([]*domain.Account, error)
	UpdateBalance(ctx context.Context, id domain.UUID, balance decimal.Decimal) error
	Delete(ctx context.Context, id domain.UUID) error
}

type CategoryRepository interface {
	Create(ctx context.Context, cat *domain.Category) error
	GetByID(ctx context.Context, id domain.UUID) (*domain.Category, error)
	List(ctx context.Context) ([]*domain.Category, error)
	Delete(ctx context.Context, id domain.UUID) error
}

type PreferenceRepository interface {
	Get(ctx context.Context, id domain.UUID) (*domain.UserPreference, error)
	Upsert(ctx context.Context, pref *domain.UserPreference) error
}

type DeviceRepository interface {
	Register(ctx context.Context, dev *domain.Device) error
	GetByID(ctx context.Context, id domain.UUID) (*domain.Device, error)
	UpdateLastActive(ctx context.Context, id domain.UUID) error
	Revoke(ctx context.Context, id domain.UUID) error
}

