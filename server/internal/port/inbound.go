package port

import (
	"context"
	"time"

	"github.com/ftthreign/savoryx_app/server/internal/core/domain"
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
