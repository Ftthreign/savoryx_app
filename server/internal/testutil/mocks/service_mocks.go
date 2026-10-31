package mocks

import (
	"context"

	"github.com/ftthreign/savoryx_app/server/internal/core/domain"
	"github.com/ftthreign/savoryx_app/server/internal/port"
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
