package mocks

import (
	"context"

	"github.com/ftthreign/savoryx_app/server/internal/core/domain"
	"github.com/ftthreign/savoryx_app/server/internal/port"
	"github.com/shopspring/decimal"
)

// MockHealthService implements port.HealthService for unit testing.
type MockHealthService struct {
	CheckHealthFunc func(ctx context.Context) (string, error)
	Status          string
	Err             error
}

func (m *MockHealthService) CheckHealth(ctx context.Context) (string, error) {
	if m.CheckHealthFunc != nil {
		return m.CheckHealthFunc(ctx)
	}
	return m.Status, m.Err
}

var _ port.HealthService = (*MockHealthService)(nil)

// MockAuthService implements port.AuthService for unit testing.
type MockAuthService struct {
	RegisterDeviceFunc func(ctx context.Context, id domain.UUID, deviceName, platform, appVersion string) (*port.DeviceRegistrationResult, error)
}

func (m *MockAuthService) RegisterDevice(ctx context.Context, id domain.UUID, deviceName, platform, appVersion string) (*port.DeviceRegistrationResult, error) {
	if m.RegisterDeviceFunc != nil {
		return m.RegisterDeviceFunc(ctx, id, deviceName, platform, appVersion)
	}
	return nil, nil
}

var _ port.AuthService = (*MockAuthService)(nil)

// MockAccountService implements port.AccountService for unit testing.
type MockAccountService struct {
	CreateAccountFunc func(ctx context.Context, acc *domain.Account) error
	GetAccountFunc    func(ctx context.Context, id domain.UUID) (*domain.Account, error)
	ListAccountsFunc  func(ctx context.Context) ([]*domain.Account, error)
	UpdateBalanceFunc func(ctx context.Context, id domain.UUID, newBalance decimal.Decimal) error
	DeleteAccountFunc func(ctx context.Context, id domain.UUID) error
}

func (m *MockAccountService) CreateAccount(ctx context.Context, acc *domain.Account) error {
	if m.CreateAccountFunc != nil {
		return m.CreateAccountFunc(ctx, acc)
	}
	return nil
}

func (m *MockAccountService) GetAccount(ctx context.Context, id domain.UUID) (*domain.Account, error) {
	if m.GetAccountFunc != nil {
		return m.GetAccountFunc(ctx, id)
	}
	return nil, nil
}

func (m *MockAccountService) ListAccounts(ctx context.Context) ([]*domain.Account, error) {
	if m.ListAccountsFunc != nil {
		return m.ListAccountsFunc(ctx)
	}
	return nil, nil
}

func (m *MockAccountService) UpdateBalance(ctx context.Context, id domain.UUID, newBalance decimal.Decimal) error {
	if m.UpdateBalanceFunc != nil {
		return m.UpdateBalanceFunc(ctx, id, newBalance)
	}
	return nil
}

func (m *MockAccountService) DeleteAccount(ctx context.Context, id domain.UUID) error {
	if m.DeleteAccountFunc != nil {
		return m.DeleteAccountFunc(ctx, id)
	}
	return nil
}

var _ port.AccountService = (*MockAccountService)(nil)

