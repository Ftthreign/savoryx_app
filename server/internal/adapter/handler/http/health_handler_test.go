package http

import (
	"encoding/json"
	"errors"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/ftthreign/savoryx_app/server/internal/core/domain"
	"github.com/ftthreign/savoryx_app/server/internal/testutil"
	"github.com/ftthreign/savoryx_app/server/internal/testutil/mocks"
	"github.com/stretchr/testify/assert"
)

func TestHealthHandler_Readiness_Healthy(t *testing.T) {
	mockService := &mocks.MockHealthService{Status: "healthy", Err: nil}
	r := SetupRouter(testutil.DiscardLogger(), mockService, "1.0.0", "test")

	req := httptest.NewRequest(http.MethodGet, "/healthz", nil)
	rec := httptest.NewRecorder()

	r.ServeHTTP(rec, req)

	assert.Equal(t, http.StatusOK, rec.Code)
	assert.Equal(t, "application/json", rec.Header().Get("Content-Type"))
	assert.Equal(t, "nosniff", rec.Header().Get("X-Content-Type-Options"))
	assert.Equal(t, "DENY", rec.Header().Get("X-Frame-Options"))
	assert.Equal(t, "strict-origin-when-cross-origin", rec.Header().Get("Referrer-Policy"))

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
	mockService := &mocks.MockHealthService{Status: "degraded", Err: errors.New("db unreachable")}
	r := SetupRouter(testutil.DiscardLogger(), mockService, "1.0.0", "test")

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

func TestHealthHandler_Readiness_DatabaseUnavailable(t *testing.T) {
	mockService := &mocks.MockHealthService{Status: "degraded", Err: domain.ErrDatabaseUnavailable}
	r := SetupRouter(testutil.DiscardLogger(), mockService, "1.0.0", "test")

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
	mockService := &mocks.MockHealthService{Status: "healthy", Err: nil}
	r := SetupRouter(testutil.DiscardLogger(), mockService, "1.0.0", "test")

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
	mockService := &mocks.MockHealthService{Status: "healthy", Err: nil}
	r := SetupRouter(testutil.DiscardLogger(), mockService, "1.0.0", "test")

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
