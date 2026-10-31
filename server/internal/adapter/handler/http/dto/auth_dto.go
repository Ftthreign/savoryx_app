package dto

import (
	"fmt"
	"strings"
	"time"

	"github.com/ftthreign/savoryx_app/server/internal/core/domain"
)

type RegisterDeviceRequest struct {
	DeviceID   string `json:"device_id"`
	DeviceName string `json:"device_name"`
	Platform   string `json:"platform"`
	AppVersion string `json:"app_version"`
}

func (r *RegisterDeviceRequest) Validate() (domain.UUID, error) {
	trimmedID := strings.TrimSpace(r.DeviceID)
	if trimmedID == "" {
		return domain.NilUUID, fmt.Errorf("device_id is required")
	}

	parsedID, err := domain.ParseUUID(trimmedID)
	if err != nil {
		return domain.NilUUID, fmt.Errorf("device_id must be a valid UUID: %w", err)
	}

	trimmedName := strings.TrimSpace(r.DeviceName)
	if trimmedName == "" {
		return domain.NilUUID, fmt.Errorf("device_name is required")
	}
	if len(trimmedName) > 128 {
		return domain.NilUUID, fmt.Errorf("device_name exceeds 128 characters")
	}

	trimmedPlatform := strings.TrimSpace(r.Platform)
	if trimmedPlatform == "" {
		return domain.NilUUID, fmt.Errorf("platform is required")
	}
	if len(trimmedPlatform) > 32 {
		return domain.NilUUID, fmt.Errorf("platform exceeds 32 characters")
	}

	trimmedVersion := strings.TrimSpace(r.AppVersion)
	if trimmedVersion == "" {
		return domain.NilUUID, fmt.Errorf("app_version is required")
	}
	if len(trimmedVersion) > 32 {
		return domain.NilUUID, fmt.Errorf("app_version exceeds 32 characters")
	}

	return parsedID, nil
}

type RegisterDeviceResponse struct {
	DeviceID     string    `json:"device_id"`
	Token        string    `json:"token"`
	DeviceSecret string    `json:"device_secret"`
	ExpiresAt    time.Time `json:"expires_at"`
}
