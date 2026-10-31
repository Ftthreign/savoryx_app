package service_test

import (
	"context"
	"errors"
	"testing"

	"github.com/ftthreign/savoryx_app/server/internal/core/domain"
	"github.com/ftthreign/savoryx_app/server/internal/core/service"
	"github.com/ftthreign/savoryx_app/server/internal/testutil/mocks"
)

func TestHealthService_CheckHealth(t *testing.T) {
	ctx := context.Background()

	t.Run("happy path - database is healthy", func(t *testing.T) {
		mockDB := &mocks.MockDatabasePinger{PingErr: nil}
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
		mockDB := &mocks.MockDatabasePinger{PingErr: errors.New("connection refused")}
		svc := service.NewHealthService(mockDB)

		status, err := svc.CheckHealth(ctx)
		if err == nil {
			t.Fatal("expected error, got nil")
		}
		if status != "degraded" {
			t.Errorf("expected status 'degraded', got %s", status)
		}
	})

	t.Run("degraded path - nil database pinger returns degraded and ErrDatabaseUnavailable", func(t *testing.T) {
		svc := service.NewHealthService(nil)

		status, err := svc.CheckHealth(ctx)
		if err == nil {
			t.Fatal("expected error, got nil")
		}
		if !errors.Is(err, domain.ErrDatabaseUnavailable) {
			t.Errorf("expected error domain.ErrDatabaseUnavailable, got %v", err)
		}
		if status != "degraded" {
			t.Errorf("expected status 'degraded', got %s", status)
		}
	})
}
