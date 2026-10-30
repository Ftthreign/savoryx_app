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
	GetByID(ctx context.Context, id [16]byte) (*domain.Account, error)
	List(ctx context.Context) ([]*domain.Account, error)
	UpdateBalance(ctx context.Context, id [16]byte, balance decimal.Decimal) error
	Delete(ctx context.Context, id [16]byte) error
}

type CategoryRepository interface {
	Create(ctx context.Context, cat *domain.Category) error
	GetByID(ctx context.Context, id [16]byte) (*domain.Category, error)
	List(ctx context.Context) ([]*domain.Category, error)
	Delete(ctx context.Context, id [16]byte) error
}

type PreferenceRepository interface {
	Get(ctx context.Context, id [16]byte) (*domain.UserPreference, error)
	Upsert(ctx context.Context, pref *domain.UserPreference) error
}
