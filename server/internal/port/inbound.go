package port

import (
	"context"
	"time"

	"github.com/ftthreign/savoryx_app/server/internal/core/domain"
	"github.com/shopspring/decimal"
)

type HealthService interface {
	CheckHealth(ctx context.Context) (status string, err error)
}

type DeviceRegistrationResult struct {
	Device       *domain.Device
	Token        string
	DeviceSecret string
	ExpiresAt    time.Time
}

type AuthService interface {
	RegisterDevice(ctx context.Context, id domain.UUID, deviceName, platform, appVersion string) (*DeviceRegistrationResult, error)
}

type AccountService interface {
	CreateAccount(ctx context.Context, acc *domain.Account) error
	GetAccount(ctx context.Context, id domain.UUID) (*domain.Account, error)
	ListAccounts(ctx context.Context) ([]*domain.Account, error)
	UpdateAccount(ctx context.Context, id domain.UUID, name string, accType domain.AccountType) (*domain.Account, error)
	UpdateBalance(ctx context.Context, id domain.UUID, newBalance decimal.Decimal) error
	DeleteAccount(ctx context.Context, id domain.UUID) error
}

type CategoryService interface {
	CreateCategory(ctx context.Context, cat *domain.Category) error
	GetCategory(ctx context.Context, id domain.UUID) (*domain.Category, error)
	ListCategories(ctx context.Context) ([]*domain.Category, error)
	UpdateCategory(ctx context.Context, id domain.UUID, name, icon, color string, isWants bool) (*domain.Category, error)
	DeleteCategory(ctx context.Context, id domain.UUID) error
}

