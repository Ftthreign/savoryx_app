package port

import (
	"context"
	"time"

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
	Update(ctx context.Context, acc *domain.Account) error
	UpdateBalance(ctx context.Context, id domain.UUID, balance decimal.Decimal) error
	Delete(ctx context.Context, id domain.UUID) error
}

type CategoryRepository interface {
	Create(ctx context.Context, cat *domain.Category) error
	GetByID(ctx context.Context, id domain.UUID) (*domain.Category, error)
	List(ctx context.Context) ([]*domain.Category, error)
	Update(ctx context.Context, cat *domain.Category) error
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

type DeviceClaims struct {
	DeviceID  domain.UUID
	IssuedAt  time.Time
	ExpiresAt time.Time
}

type TokenManager interface {
	GenerateDeviceToken(deviceID domain.UUID, ttl time.Duration) (string, error)
	VerifyDeviceToken(tokenString string) (*DeviceClaims, error)
	GenerateDeviceSecret() (string, error)
	HashDeviceSecret(secret string) string
	VerifyDeviceSecret(secret, expectedHash string) bool
}

type TxManager interface {
	RunInTx(ctx context.Context, fn func(ctx context.Context) error) error
}

type ExchangeRateRepository interface {
	UpsertRate(ctx context.Context, rate *domain.ExchangeRate) error
	GetLatestRate(ctx context.Context, base, target string) (*domain.ExchangeRate, error)
	GetHistoricalRate(ctx context.Context, base, target string, date time.Time) (*domain.ExchangeRate, error)
	ListLatestRates(ctx context.Context, base string) ([]*domain.ExchangeRate, error)
	ListSupportedCurrencies(ctx context.Context) ([]*domain.Currency, error)
	GetCurrency(ctx context.Context, code string) (*domain.Currency, error)
}

type FXProvider interface {
	FetchLatestRates(ctx context.Context, base string) ([]*domain.ExchangeRate, error)
	FetchHistoricalRates(ctx context.Context, base string, date time.Time) ([]*domain.ExchangeRate, error)
}

type FXCache interface {
	GetRate(ctx context.Context, base, target string) (*domain.ExchangeRate, bool)
	SetRate(ctx context.Context, rate *domain.ExchangeRate, ttl time.Duration)
	GetLatestRates(ctx context.Context, base string) ([]*domain.ExchangeRate, bool)
	SetLatestRates(ctx context.Context, base string, rates []*domain.ExchangeRate, ttl time.Duration)
	Invalidate(ctx context.Context, base string)
	InvalidateAll(ctx context.Context)
}

