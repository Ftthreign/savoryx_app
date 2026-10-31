package mocks

import (
	"context"

	"github.com/ftthreign/savoryx_app/server/internal/core/domain"
	"github.com/ftthreign/savoryx_app/server/internal/port"
	"github.com/shopspring/decimal"
)

// MockDatabasePinger implements port.DatabasePinger for unit testing.
type MockDatabasePinger struct {
	PingFunc func(ctx context.Context) error
	PingErr  error
}

func (m *MockDatabasePinger) Ping(ctx context.Context) error {
	if m.PingFunc != nil {
		return m.PingFunc(ctx)
	}
	return m.PingErr
}

var _ port.DatabasePinger = (*MockDatabasePinger)(nil)

// MockDeviceRepository implements port.DeviceRepository for unit testing.
type MockDeviceRepository struct {
	RegisterFunc         func(ctx context.Context, dev *domain.Device) error
	GetByIDFunc          func(ctx context.Context, id domain.UUID) (*domain.Device, error)
	UpdateLastActiveFunc func(ctx context.Context, id domain.UUID) error
	RevokeFunc           func(ctx context.Context, id domain.UUID) error
}

func (m *MockDeviceRepository) Register(ctx context.Context, dev *domain.Device) error {
	if m.RegisterFunc != nil {
		return m.RegisterFunc(ctx, dev)
	}
	return nil
}

func (m *MockDeviceRepository) GetByID(ctx context.Context, id domain.UUID) (*domain.Device, error) {
	if m.GetByIDFunc != nil {
		return m.GetByIDFunc(ctx, id)
	}
	return nil, nil
}

func (m *MockDeviceRepository) UpdateLastActive(ctx context.Context, id domain.UUID) error {
	if m.UpdateLastActiveFunc != nil {
		return m.UpdateLastActiveFunc(ctx, id)
	}
	return nil
}

func (m *MockDeviceRepository) Revoke(ctx context.Context, id domain.UUID) error {
	if m.RevokeFunc != nil {
		return m.RevokeFunc(ctx, id)
	}
	return nil
}

var _ port.DeviceRepository = (*MockDeviceRepository)(nil)

// MockAccountRepository implements port.AccountRepository for unit testing.
type MockAccountRepository struct {
	CreateFunc           func(ctx context.Context, acc *domain.Account) error
	GetByIDFunc          func(ctx context.Context, id domain.UUID) (*domain.Account, error)
	GetByIDForUpdateFunc func(ctx context.Context, id domain.UUID) (*domain.Account, error)
	ListFunc             func(ctx context.Context) ([]*domain.Account, error)
	UpdateBalanceFunc    func(ctx context.Context, id domain.UUID, balance decimal.Decimal) error
	DeleteFunc           func(ctx context.Context, id domain.UUID) error
}

func (m *MockAccountRepository) Create(ctx context.Context, acc *domain.Account) error {
	if m.CreateFunc != nil {
		return m.CreateFunc(ctx, acc)
	}
	return nil
}

func (m *MockAccountRepository) GetByID(ctx context.Context, id domain.UUID) (*domain.Account, error) {
	if m.GetByIDFunc != nil {
		return m.GetByIDFunc(ctx, id)
	}
	return nil, nil
}

func (m *MockAccountRepository) GetByIDForUpdate(ctx context.Context, id domain.UUID) (*domain.Account, error) {
	if m.GetByIDForUpdateFunc != nil {
		return m.GetByIDForUpdateFunc(ctx, id)
	}
	return nil, nil
}

func (m *MockAccountRepository) List(ctx context.Context) ([]*domain.Account, error) {
	if m.ListFunc != nil {
		return m.ListFunc(ctx)
	}
	return nil, nil
}

func (m *MockAccountRepository) UpdateBalance(ctx context.Context, id domain.UUID, balance decimal.Decimal) error {
	if m.UpdateBalanceFunc != nil {
		return m.UpdateBalanceFunc(ctx, id, balance)
	}
	return nil
}

func (m *MockAccountRepository) Delete(ctx context.Context, id domain.UUID) error {
	if m.DeleteFunc != nil {
		return m.DeleteFunc(ctx, id)
	}
	return nil
}

var _ port.AccountRepository = (*MockAccountRepository)(nil)

// MockCategoryRepository implements port.CategoryRepository for unit testing.
type MockCategoryRepository struct {
	CreateFunc  func(ctx context.Context, cat *domain.Category) error
	GetByIDFunc func(ctx context.Context, id domain.UUID) (*domain.Category, error)
	ListFunc    func(ctx context.Context) ([]*domain.Category, error)
	DeleteFunc  func(ctx context.Context, id domain.UUID) error
}

func (m *MockCategoryRepository) Create(ctx context.Context, cat *domain.Category) error {
	if m.CreateFunc != nil {
		return m.CreateFunc(ctx, cat)
	}
	return nil
}

func (m *MockCategoryRepository) GetByID(ctx context.Context, id domain.UUID) (*domain.Category, error) {
	if m.GetByIDFunc != nil {
		return m.GetByIDFunc(ctx, id)
	}
	return nil, nil
}

func (m *MockCategoryRepository) List(ctx context.Context) ([]*domain.Category, error) {
	if m.ListFunc != nil {
		return m.ListFunc(ctx)
	}
	return nil, nil
}

func (m *MockCategoryRepository) Delete(ctx context.Context, id domain.UUID) error {
	if m.DeleteFunc != nil {
		return m.DeleteFunc(ctx, id)
	}
	return nil
}

var _ port.CategoryRepository = (*MockCategoryRepository)(nil)

