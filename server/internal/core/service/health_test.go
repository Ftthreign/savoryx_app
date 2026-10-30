package service_test

import (
	"context"
	"errors"
	"testing"

	"github.com/ftthreign/savoryx_app/server/internal/core/service"
)

type mockDatabasePinger struct {
	pingErr error
}

func (m *mockDatabasePinger) Ping(ctx context.Context) error {
	return m.pingErr
}

func TestHealthService_CheckHealth(t *testing.T) {
	ctx := context.Background()

	t.Run("happy path - database is healthy", func(t *testing.T) {
		mockDB := &mockDatabasePinger{pingErr: nil}
		svc := service.NewHealthService(mockDB)

		status, err := svc.CheckHealth(ctx)
		if err != nil {
			t.Fatalf("expected nil error, got %v", err)
		}
		if status != "healthy" {
			t.Errorf("expected status 'healthy', got %s", status)
		}
	})

	t.Run("failure path - database is unavailable", func(t *testing.T) {
		mockDB := &mockDatabasePinger{pingErr: errors.New("connection refused")}
		svc := service.NewHealthService(mockDB)

		status, err := svc.CheckHealth(ctx)
		if err == nil {
			t.Fatal("expected error, got nil")
		}
		if status != "degraded" {
			t.Errorf("expected status 'degraded', got %s", status)
		}
	})

	t.Run("happy path - nil database pinger returns healthy", func(t *testing.T) {
		svc := service.NewHealthService(nil)

		status, err := svc.CheckHealth(ctx)
		if err != nil {
			t.Fatalf("expected nil error, got %v", err)
		}
		if status != "healthy" {
			t.Errorf("expected status 'healthy', got %s", status)
		}
	})
}
