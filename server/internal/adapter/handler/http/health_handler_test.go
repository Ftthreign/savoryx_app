package http

import (
	"context"
	"encoding/json"
	"errors"
	"io"
	"log/slog"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/ftthreign/savoryx_app/server/internal/core/domain"
	"github.com/stretchr/testify/assert"
)

type mockHealthService struct {
	status string
	err    error
}

func (m *mockHealthService) CheckHealth(ctx context.Context) (string, error) {
	return m.status, m.err
}

func discardLogger() *slog.Logger {
	return slog.New(slog.NewTextHandler(io.Discard, nil))
}

func TestHealthHandler_Readiness_Healthy(t *testing.T) {
	mockService := &mockHealthService{status: "healthy", err: nil}
	r := SetupRouter(discardLogger(), mockService, "1.0.0", "test")

	req := httptest.NewRequest(http.MethodGet, "/healthz", nil)
	rec := httptest.NewRecorder()

	r.ServeHTTP(rec, req)

	assert.Equal(t, http.StatusOK, rec.Code)
	assert.Equal(t, "application/json", rec.Header().Get("Content-Type"))

	var res ResponseEnvelope
	err := json.Unmarshal(rec.Body.Bytes(), &res)
	assert.NoError(t, err)

	dataMap, ok := res.Data.(map[string]any)
	assert.True(t, ok)
	assert.Equal(t, "healthy", dataMap["status"])
	assert.Equal(t, "connected", dataMap["database"])
	assert.Equal(t, "savoryx-api", dataMap["service"])
	assert.Equal(t, "1.0.0", dataMap["version"])
}

func TestHealthHandler_Readiness_Degraded(t *testing.T) {
	mockService := &mockHealthService{status: "degraded", err: errors.New("db unreachable")}
	r := SetupRouter(discardLogger(), mockService, "1.0.0", "test")

	req := httptest.NewRequest(http.MethodGet, "/healthz", nil)
	rec := httptest.NewRecorder()

	r.ServeHTTP(rec, req)

	assert.Equal(t, http.StatusServiceUnavailable, rec.Code)

	var res ResponseEnvelope
	err := json.Unmarshal(rec.Body.Bytes(), &res)
	assert.NoError(t, err)

	dataMap, ok := res.Data.(map[string]any)
	assert.True(t, ok)
	assert.Equal(t, "degraded", dataMap["status"])
	assert.Equal(t, "disconnected", dataMap["database"])
}

func TestHealthHandler_Liveness(t *testing.T) {
	mockService := &mockHealthService{status: "healthy", err: nil}
	r := SetupRouter(discardLogger(), mockService, "1.0.0", "test")

	req := httptest.NewRequest(http.MethodGet, "/livez", nil)
	rec := httptest.NewRecorder()

	r.ServeHTTP(rec, req)

	assert.Equal(t, http.StatusOK, rec.Code)

	var res ResponseEnvelope
	err := json.Unmarshal(rec.Body.Bytes(), &res)
	assert.NoError(t, err)

	dataMap, ok := res.Data.(map[string]any)
	assert.True(t, ok)
	assert.Equal(t, "alive", dataMap["status"])
}

func TestHealthHandler_Ping(t *testing.T) {
	mockService := &mockHealthService{status: "healthy", err: nil}
	r := SetupRouter(discardLogger(), mockService, "1.0.0", "test")

	req := httptest.NewRequest(http.MethodGet, "/api/v1/ping", nil)
	rec := httptest.NewRecorder()

	r.ServeHTTP(rec, req)

	assert.Equal(t, http.StatusOK, rec.Code)

	var res ResponseEnvelope
	err := json.Unmarshal(rec.Body.Bytes(), &res)
	assert.NoError(t, err)

	dataMap, ok := res.Data.(map[string]any)
	assert.True(t, ok)
	assert.Equal(t, "pong", dataMap["message"])
	assert.NotEmpty(t, dataMap["timestamp"])
}

func TestWriteDomainError(t *testing.T) {
	t.Run("NotFound mapping", func(t *testing.T) {
		rec := httptest.NewRecorder()
		WriteDomainError(rec, domain.ErrAccountNotFound)

		assert.Equal(t, http.StatusNotFound, rec.Code)
		var errEnv ErrorEnvelope
		err := json.Unmarshal(rec.Body.Bytes(), &errEnv)
		assert.NoError(t, err)
		assert.Equal(t, "not_found", errEnv.Error.Code)
		assert.Equal(t, "account not found", errEnv.Error.Message)
	})

	t.Run("InvalidInput mapping", func(t *testing.T) {
		rec := httptest.NewRecorder()
		WriteDomainError(rec, domain.ErrInvalidInput)

		assert.Equal(t, http.StatusBadRequest, rec.Code)
		var errEnv ErrorEnvelope
		err := json.Unmarshal(rec.Body.Bytes(), &errEnv)
		assert.NoError(t, err)
		assert.Equal(t, "invalid_input", errEnv.Error.Code)
	})

	t.Run("Unknown internal error mapping", func(t *testing.T) {
		rec := httptest.NewRecorder()
		WriteDomainError(rec, errors.New("raw unhandled error"))

		assert.Equal(t, http.StatusInternalServerError, rec.Code)
		var errEnv ErrorEnvelope
		err := json.Unmarshal(rec.Body.Bytes(), &errEnv)
		assert.NoError(t, err)
		assert.Equal(t, "internal_error", errEnv.Error.Code)
		assert.Equal(t, "Internal server error", errEnv.Error.Message)
	})
}
