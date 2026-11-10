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
	ListAccounts(ctx context.Context, limit, offset int) ([]*domain.Account, int, error)
	UpdateAccount(ctx context.Context, id domain.UUID, name string, accType domain.AccountType) (*domain.Account, error)
	UpdateBalance(ctx context.Context, id domain.UUID, newBalance decimal.Decimal) error
	DeleteAccount(ctx context.Context, id domain.UUID) error
}

type CategoryService interface {
	CreateCategory(ctx context.Context, cat *domain.Category) error
	GetCategory(ctx context.Context, id domain.UUID) (*domain.Category, error)
	ListCategories(ctx context.Context, limit, offset int) ([]*domain.Category, int, error)
	UpdateCategory(ctx context.Context, id domain.UUID, name, icon, color string, isWants bool) (*domain.Category, error)
	DeleteCategory(ctx context.Context, id domain.UUID) error
}

type TransactionService interface {
	CreateTransaction(ctx context.Context, tx *domain.Transaction) error
	GetTransaction(ctx context.Context, id domain.UUID) (*domain.Transaction, error)
	ListTransactions(ctx context.Context, accountID *domain.UUID, limit, offset int) ([]*domain.Transaction, int, error)
	DeleteTransaction(ctx context.Context, id domain.UUID) error
}

type SyncPullResult struct {
	Accounts     []*domain.Account     `json:"accounts"`
	Categories   []*domain.Category    `json:"categories"`
	Transactions []*domain.Transaction `json:"transactions"`
	PulledAt     time.Time             `json:"pulled_at"`
}

type SyncPushPayload struct {
	DeviceID        domain.UUID           `json:"-"`
	ClientTimestamp time.Time             `json:"-"`
	Accounts        []*domain.Account     `json:"accounts"`
	Categories      []*domain.Category    `json:"categories"`
	Transactions    []*domain.Transaction `json:"transactions"`
}

type SyncPushResult struct {
	AccountsApplied     int       `json:"accounts_applied"`
	CategoriesApplied   int       `json:"categories_applied"`
	TransactionsApplied int       `json:"transactions_applied"`
	SyncedAt            time.Time `json:"synced_at"`
}

type SyncService interface {
	PullChanges(ctx context.Context, lastPulledAt time.Time) (*SyncPullResult, error)
	PushChanges(ctx context.Context, payload *SyncPushPayload) (*SyncPushResult, error)
}

type ExchangeRateService interface {
	GetLatestRate(ctx context.Context, base, target string) (*domain.ExchangeRate, error)
	GetHistoricalRate(ctx context.Context, base, target string, date time.Time) (*domain.ExchangeRate, error)
	ListLatestRates(ctx context.Context, base string) ([]*domain.ExchangeRate, error)
	ListSupportedCurrencies(ctx context.Context) ([]*domain.Currency, error)
}
