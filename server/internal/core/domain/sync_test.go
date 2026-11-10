package domain

import (
	"errors"
	"testing"
	"time"
)

func TestSyncDirection_IsValid(t *testing.T) {
	t.Parallel()

	tests := []struct {
		name string
		dir  SyncDirection
		want bool
	}{
		{name: "valid push", dir: SyncDirectionPush, want: true},
		{name: "valid pull", dir: SyncDirectionPull, want: true},
		{name: "invalid empty", dir: "", want: false},
		{name: "invalid unknown", dir: "SYNC", want: false},
	}

	for _, tc := range tests {
		t.Run(tc.name, func(t *testing.T) {
			t.Parallel()
			if got := tc.dir.IsValid(); got != tc.want {
				t.Fatalf("IsValid() = %v, want %v", got, tc.want)
			}
		})
	}
}

func TestSyncStatus_IsValid(t *testing.T) {
	t.Parallel()

	tests := []struct {
		name   string
		status SyncStatus
		want   bool
	}{
		{name: "valid success", status: SyncStatusSuccess, want: true},
		{name: "valid partial", status: SyncStatusPartial, want: true},
		{name: "valid failed", status: SyncStatusFailed, want: true},
		{name: "invalid empty", status: "", want: false},
		{name: "invalid unknown", status: "PENDING", want: false},
	}

	for _, tc := range tests {
		t.Run(tc.name, func(t *testing.T) {
			t.Parallel()
			if got := tc.status.IsValid(); got != tc.want {
				t.Fatalf("IsValid() = %v, want %v", got, tc.want)
			}
		})
	}
}

func TestSyncLog_Validate(t *testing.T) {
	t.Parallel()

	validID := NewUUIDv7()
	validDeviceID := NewUUIDv7()
	now := time.Now().UTC().Truncate(time.Microsecond)

	t.Run("valid sync log normalizes timestamps and enums", func(t *testing.T) {
		t.Parallel()

		log := &SyncLog{
			ID:              validID,
			DeviceID:        validDeviceID,
			Direction:       SyncDirection(" push "),
			BatchSize:       15,
			Status:          SyncStatus(" success "),
			ClientTimestamp: now,
		}

		if err := log.Validate(); err != nil {
			t.Fatalf("expected no error, got %v", err)
		}
		if log.Direction != SyncDirectionPush {
			t.Fatalf("expected direction PUSH, got %s", log.Direction)
		}
		if log.Status != SyncStatusSuccess {
			t.Fatalf("expected status SUCCESS, got %s", log.Status)
		}
		if log.ServerTimestamp.IsZero() {
			t.Fatal("expected ServerTimestamp to be populated")
		}
		if log.CreatedAt.IsZero() {
			t.Fatal("expected CreatedAt to be populated")
		}
	})

	t.Run("nil entity returns ErrInvalidInput", func(t *testing.T) {
		t.Parallel()

		var log *SyncLog
		if err := log.Validate(); !errors.Is(err, ErrInvalidInput) {
			t.Fatalf("expected ErrInvalidInput, got %v", err)
		}
	})

	t.Run("zero ID returns ErrInvalidInput", func(t *testing.T) {
		t.Parallel()

		log := &SyncLog{
			DeviceID:        validDeviceID,
			Direction:       SyncDirectionPush,
			BatchSize:       1,
			Status:          SyncStatusSuccess,
			ClientTimestamp: now,
		}
		if err := log.Validate(); !errors.Is(err, ErrInvalidInput) {
			t.Fatalf("expected ErrInvalidInput, got %v", err)
		}
	})

	t.Run("zero DeviceID returns ErrInvalidInput", func(t *testing.T) {
		t.Parallel()

		log := &SyncLog{
			ID:              validID,
			Direction:       SyncDirectionPush,
			BatchSize:       1,
			Status:          SyncStatusSuccess,
			ClientTimestamp: now,
		}
		if err := log.Validate(); !errors.Is(err, ErrInvalidInput) {
			t.Fatalf("expected ErrInvalidInput, got %v", err)
		}
	})

	t.Run("invalid direction returns ErrInvalidInput", func(t *testing.T) {
		t.Parallel()

		log := &SyncLog{
			ID:              validID,
			DeviceID:        validDeviceID,
			Direction:       "INVALID",
			BatchSize:       1,
			Status:          SyncStatusSuccess,
			ClientTimestamp: now,
		}
		if err := log.Validate(); !errors.Is(err, ErrInvalidInput) {
			t.Fatalf("expected ErrInvalidInput, got %v", err)
		}
	})

	t.Run("negative batch size returns ErrInvalidInput", func(t *testing.T) {
		t.Parallel()

		log := &SyncLog{
			ID:              validID,
			DeviceID:        validDeviceID,
			Direction:       SyncDirectionPull,
			BatchSize:       -1,
			Status:          SyncStatusSuccess,
			ClientTimestamp: now,
		}
		if err := log.Validate(); !errors.Is(err, ErrInvalidInput) {
			t.Fatalf("expected ErrInvalidInput, got %v", err)
		}
	})

	t.Run("invalid status returns ErrInvalidInput", func(t *testing.T) {
		t.Parallel()

		log := &SyncLog{
			ID:              validID,
			DeviceID:        validDeviceID,
			Direction:       SyncDirectionPull,
			BatchSize:       0,
			Status:          "UNKNOWN",
			ClientTimestamp: now,
		}
		if err := log.Validate(); !errors.Is(err, ErrInvalidInput) {
			t.Fatalf("expected ErrInvalidInput, got %v", err)
		}
	})

	t.Run("zero client timestamp returns ErrInvalidInput", func(t *testing.T) {
		t.Parallel()

		log := &SyncLog{
			ID:        validID,
			DeviceID:  validDeviceID,
			Direction: SyncDirectionPull,
			BatchSize: 0,
			Status:    SyncStatusSuccess,
		}
		if err := log.Validate(); !errors.Is(err, ErrInvalidInput) {
			t.Fatalf("expected ErrInvalidInput, got %v", err)
		}
	})
}
