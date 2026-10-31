package domain

import (
	"time"
)

type Device struct {
	ID               UUID       `json:"id"`
	DeviceName       string     `json:"device_name"`
	Platform         string     `json:"platform"`
	AppVersion       string     `json:"app_version"`
	DeviceSecretHash string     `json:"device_secret_hash"`
	CreatedAt        time.Time  `json:"created_at"`
	LastActiveAt     time.Time  `json:"last_active_at"`
	RevokedAt        *time.Time `json:"revoked_at,omitempty"`
}

func (d *Device) IsActive() bool {
	return d.RevokedAt == nil
}
