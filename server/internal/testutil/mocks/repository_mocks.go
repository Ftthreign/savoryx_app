package mocks

import (
	"context"

	"github.com/ftthreign/savoryx_app/server/internal/core/domain"
	"github.com/ftthreign/savoryx_app/server/internal/port"
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
