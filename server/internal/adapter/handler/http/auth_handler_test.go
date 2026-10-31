package http

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"net/http"
	"net/http/httptest"
	"testing"
	"time"

	"github.com/ftthreign/savoryx_app/server/internal/core/domain"
	"github.com/ftthreign/savoryx_app/server/internal/port"
	"github.com/ftthreign/savoryx_app/server/internal/testutil"
	"github.com/ftthreign/savoryx_app/server/internal/testutil/mocks"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

func TestAuthHandler_RegisterDevice_HappyPath(t *testing.T) {
	deviceID := testutil.DefaultDeviceID
	deviceIDStr := testutil.DefaultDeviceIDStr

	mockSvc := &mocks.MockAuthService{
		RegisterDeviceFunc: func(ctx context.Context, id domain.UUID, deviceName, platform, appVersion string) (*port.DeviceRegistrationResult, error) {
			assert.Equal(t, deviceID, id)
			assert.Equal(t, "Pixel 8 Pro", deviceName)
			assert.Equal(t, "android", platform)
			assert.Equal(t, "1.0.0", appVersion)

			return &port.DeviceRegistrationResult{
				Device:       testutil.NewTestDevice(id, deviceName, platform, appVersion),
				Token:        "v4.local.mocked_token",
				DeviceSecret: "mock_device_secret_base64",
				ExpiresAt:    time.Now().UTC().Add(30 * 24 * time.Hour),
			}, nil
		},
	}

	router := SetupRouter(testutil.DiscardLogger(), nil, "1.0.0", "test", WithAuthService(mockSvc))

	reqBody := map[string]string{
		"device_id":   deviceIDStr,
		"device_name": "Pixel 8 Pro",
		"platform":    "android",
		"app_version": "1.0.0",
	}
	bodyBytes, _ := json.Marshal(reqBody)

	req := httptest.NewRequest(http.MethodPost, "/api/v1/auth/register-device", bytes.NewReader(bodyBytes))
	req.Header.Set("Content-Type", "application/json")
	w := httptest.NewRecorder()

	router.ServeHTTP(w, req)

	assert.Equal(t, http.StatusCreated, w.Code)
	assert.Equal(t, "/api/v1/devices/"+deviceIDStr, w.Header().Get("Location"))

	var resp struct {
		Data struct {
			DeviceID     string    `json:"device_id"`
			Token        string    `json:"token"`
			DeviceSecret string    `json:"device_secret"`
			ExpiresAt    time.Time `json:"expires_at"`
		} `json:"data"`
	}
	err := json.NewDecoder(w.Body).Decode(&resp)
	require.NoError(t, err)

	assert.Equal(t, deviceIDStr, resp.Data.DeviceID)
	assert.Equal(t, "v4.local.mocked_token", resp.Data.Token)
	assert.Equal(t, "mock_device_secret_base64", resp.Data.DeviceSecret)
	assert.False(t, resp.Data.ExpiresAt.IsZero())
}

func TestAuthHandler_RegisterDevice_InvalidJSON(t *testing.T) {
	mockSvc := &mocks.MockAuthService{}
	router := SetupRouter(testutil.DiscardLogger(), nil, "1.0.0", "test", WithAuthService(mockSvc))

	req := httptest.NewRequest(http.MethodPost, "/api/v1/auth/register-device", bytes.NewReader([]byte("{invalid json")))
	req.Header.Set("Content-Type", "application/json")
	w := httptest.NewRecorder()

	router.ServeHTTP(w, req)

	assert.Equal(t, http.StatusBadRequest, w.Code)

	var errResp ErrorEnvelope
	err := json.NewDecoder(w.Body).Decode(&errResp)
	require.NoError(t, err)
	assert.Equal(t, "invalid_json", errResp.Error.Code)
}

func TestAuthHandler_RegisterDevice_ValidationError(t *testing.T) {
	mockSvc := &mocks.MockAuthService{}
	router := SetupRouter(testutil.DiscardLogger(), nil, "1.0.0", "test", WithAuthService(mockSvc))

	t.Run("missing device ID", func(t *testing.T) {
		reqBody := map[string]string{
			"device_name": "Pixel 8 Pro",
			"platform":    "android",
			"app_version": "1.0.0",
		}
		bodyBytes, _ := json.Marshal(reqBody)

		req := httptest.NewRequest(http.MethodPost, "/api/v1/auth/register-device", bytes.NewReader(bodyBytes))
		w := httptest.NewRecorder()
		router.ServeHTTP(w, req)

		assert.Equal(t, http.StatusBadRequest, w.Code)
		var errResp ErrorEnvelope
		json.NewDecoder(w.Body).Decode(&errResp)
		assert.Equal(t, "validation_error", errResp.Error.Code)
	})

	t.Run("invalid UUID format", func(t *testing.T) {
		reqBody := map[string]string{
			"device_id":   "not-a-uuid",
			"device_name": "Pixel 8 Pro",
			"platform":    "android",
			"app_version": "1.0.0",
		}
		bodyBytes, _ := json.Marshal(reqBody)

		req := httptest.NewRequest(http.MethodPost, "/api/v1/auth/register-device", bytes.NewReader(bodyBytes))
		w := httptest.NewRecorder()
		router.ServeHTTP(w, req)

		assert.Equal(t, http.StatusBadRequest, w.Code)
	})
}

func TestAuthHandler_RegisterDevice_ServiceError(t *testing.T) {
	mockSvc := &mocks.MockAuthService{
		RegisterDeviceFunc: func(ctx context.Context, id domain.UUID, deviceName, platform, appVersion string) (*port.DeviceRegistrationResult, error) {
			return nil, errors.New("unexpected database dead-lock")
		},
	}
	router := SetupRouter(testutil.DiscardLogger(), nil, "1.0.0", "test", WithAuthService(mockSvc))

	reqBody := map[string]string{
		"device_id":   testutil.DefaultDeviceIDStr,
		"device_name": "Pixel 8 Pro",
		"platform":    "android",
		"app_version": "1.0.0",
	}
	bodyBytes, _ := json.Marshal(reqBody)

	req := httptest.NewRequest(http.MethodPost, "/api/v1/auth/register-device", bytes.NewReader(bodyBytes))
	w := httptest.NewRecorder()
	router.ServeHTTP(w, req)

	assert.Equal(t, http.StatusInternalServerError, w.Code)
}
