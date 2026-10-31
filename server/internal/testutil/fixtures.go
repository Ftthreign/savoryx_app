package testutil

import (
	"time"

	"github.com/ftthreign/savoryx_app/server/internal/core/domain"
)

var (
	DefaultDeviceID = domain.MustParseUUID("0192d6e2-5b9c-7000-8000-000000000001")
	DefaultDeviceIDStr = DefaultDeviceID.String()
)

func NewTestDevice(id domain.UUID, name, platform, version string) *domain.Device {
	return &domain.Device{
		ID:         id,
		DeviceName: name,
		Platform:         platform,
		AppVersion:       version,
		DeviceSecretHash: "mock-hash",
		CreatedAt:        time.Now().UTC(),
		LastActiveAt:     time.Now().UTC(),
	}
}
