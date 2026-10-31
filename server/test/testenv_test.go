package test

import (
	"bytes"
	"encoding/json"
	"io"
	"log/slog"
	"net/http"
	"net/http/httptest"
	"testing"

	httpAdapter "github.com/ftthreign/savoryx_app/server/internal/adapter/handler/http"
	"github.com/ftthreign/savoryx_app/server/internal/adapter/security"
	"github.com/ftthreign/savoryx_app/server/internal/core/domain"
	"github.com/ftthreign/savoryx_app/server/internal/core/service"
	"github.com/ftthreign/savoryx_app/server/internal/port"
	"github.com/ftthreign/savoryx_app/server/internal/testutil/fakes"
	"github.com/ftthreign/savoryx_app/server/internal/testutil/mocks"
	"github.com/stretchr/testify/require"
)

type TestEnv struct {
	Server       *httptest.Server
	Client       *http.Client
	TokenManager port.TokenManager
	LogBuffer    *bytes.Buffer
}

func setupTestEnvironment(t *testing.T) *TestEnv {
	logBuffer := &bytes.Buffer{}
	logger := slog.New(slog.NewJSONHandler(logBuffer, &slog.HandlerOptions{
		Level: slog.LevelInfo,
	}))

	deviceRepo := fakes.NewInMemoryDeviceRepository()
	accountRepo := fakes.NewInMemoryAccountRepository()
	categoryRepo := fakes.NewInMemoryCategoryRepository()

	tokenManager, err := security.NewPasetoTokenManager("")
	require.NoError(t, err)

	authService := service.NewAuthService(deviceRepo, tokenManager)
	accountService := service.NewAccountService(accountRepo)
	categoryService := service.NewCategoryService(categoryRepo)
	healthService := service.NewHealthService(&mocks.MockDatabasePinger{})

	router := httpAdapter.SetupRouter(
		logger,
		healthService,
		"1.0.0-test",
		"test",
		httpAdapter.WithAuthService(authService),
		httpAdapter.WithAccountService(accountService),
		httpAdapter.WithCategoryService(categoryService),
		httpAdapter.WithTokenManager(tokenManager),
	)

	server := httptest.NewServer(router)
	t.Cleanup(func() {
		server.Close()
	})

	return &TestEnv{
		Server:       server,
		Client:       server.Client(),
		TokenManager: tokenManager,
		LogBuffer:    logBuffer,
	}
}

func (e *TestEnv) RegisterDevice(t *testing.T, name, platform, version string) (string, string) {
	deviceID := domain.NewUUIDv7().String()
	payload := map[string]string{
		"device_id":   deviceID,
		"device_name": name,
		"platform":    platform,
		"app_version": version,
	}
	bodyBytes, err := json.Marshal(payload)
	require.NoError(t, err)

	res, err := e.Client.Post(e.Server.URL+"/api/v1/auth/register-device", "application/json", bytes.NewReader(bodyBytes))
	require.NoError(t, err)
	require.Equal(t, http.StatusCreated, res.StatusCode)

	var resp struct {
		Data struct {
			DeviceID     string `json:"device_id"`
			DeviceSecret string `json:"device_secret"`
			Token        string `json:"token"`
		} `json:"data"`
	}
	err = json.NewDecoder(res.Body).Decode(&resp)
	require.NoError(t, err)
	require.NotEmpty(t, resp.Data.Token)

	return resp.Data.Token, resp.Data.DeviceID
}

func (e *TestEnv) DoAuthRequest(token, method, path string, body interface{}) (*http.Response, error) {
	var bodyReader io.Reader
	if body != nil {
		b, err := json.Marshal(body)
		if err != nil {
			return nil, err
		}
		bodyReader = bytes.NewReader(b)
	}

	req, err := http.NewRequest(method, e.Server.URL+path, bodyReader)
	if err != nil {
		return nil, err
	}

	if token != "" {
		req.Header.Set("Authorization", "Bearer "+token)
	}
	if body != nil {
		req.Header.Set("Content-Type", "application/json")
	}

	return e.Client.Do(req)
}
