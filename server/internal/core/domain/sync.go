package domain

import (
	"fmt"
	"strings"
	"time"
)

type SyncDirection string

const (
	SyncDirectionPush SyncDirection = "PUSH"
	SyncDirectionPull SyncDirection = "PULL"
)

func (d SyncDirection) IsValid() bool {
	switch d {
	case SyncDirectionPush, SyncDirectionPull:
		return true
	default:
		return false
	}
}

type SyncStatus string

const (
	SyncStatusSuccess SyncStatus = "SUCCESS"
	SyncStatusPartial SyncStatus = "PARTIAL"
	SyncStatusFailed  SyncStatus = "FAILED"
)

func (s SyncStatus) IsValid() bool {
	switch s {
	case SyncStatusSuccess, SyncStatusPartial, SyncStatusFailed:
		return true
	default:
		return false
	}
}

type SyncLog struct {
	ID              UUID          `json:"id"`
	DeviceID        UUID          `json:"device_id"`
	Direction       SyncDirection `json:"direction"`
	BatchSize       int           `json:"batch_size"`
	Status          SyncStatus    `json:"status"`
	ClientTimestamp time.Time     `json:"client_timestamp"`
	ServerTimestamp time.Time     `json:"server_timestamp"`
	CreatedAt       time.Time     `json:"created_at"`
}

func (l *SyncLog) Validate() error {
	if l == nil {
		return fmt.Errorf("%w: sync log entity cannot be nil", ErrInvalidInput)
	}
	if l.ID.IsZero() {
		return fmt.Errorf("%w: sync log ID cannot be zero", ErrInvalidInput)
	}
	if l.DeviceID.IsZero() {
		return fmt.Errorf("%w: device ID cannot be zero", ErrInvalidInput)
	}

	dir := SyncDirection(strings.ToUpper(strings.TrimSpace(string(l.Direction))))
	if !dir.IsValid() {
		return fmt.Errorf("%w: invalid sync direction %q", ErrInvalidInput, l.Direction)
	}
	l.Direction = dir

	if l.BatchSize < 0 {
		return fmt.Errorf("%w: batch size cannot be negative", ErrInvalidInput)
	}

	status := SyncStatus(strings.ToUpper(strings.TrimSpace(string(l.Status))))
	if !status.IsValid() {
		return fmt.Errorf("%w: invalid sync status %q", ErrInvalidInput, l.Status)
	}
	l.Status = status

	if l.ClientTimestamp.IsZero() {
		return fmt.Errorf("%w: client timestamp cannot be zero", ErrInvalidInput)
	}

	now := time.Now().UTC()
	if l.ServerTimestamp.IsZero() {
		l.ServerTimestamp = now
	} else {
		l.ServerTimestamp = l.ServerTimestamp.UTC()
	}

	if l.CreatedAt.IsZero() {
		l.CreatedAt = l.ServerTimestamp
	} else {
		l.CreatedAt = l.CreatedAt.UTC()
	}
	l.ClientTimestamp = l.ClientTimestamp.UTC()

	return nil
}
