package http_test

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"io"
	"log/slog"
	"net/http"
	"net/http/httptest"
	"testing"
	"time"

	httpAdapter "github.com/ftthreign/savoryx_app/server/internal/adapter/handler/http"
	"github.com/ftthreign/savoryx_app/server/internal/core/domain"
	"github.com/ftthreign/savoryx_app/server/internal/port"
	"github.com/ftthreign/savoryx_app/server/internal/testutil"
	"github.com/ftthreign/savoryx_app/server/internal/testutil/mocks"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

func TestSecurityHeaders(t *testing.T) {
	handler := httpAdapter.SecurityHeaders(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusOK)
		_, _ = w.Write([]byte("ok"))
	}))

	req := httptest.NewRequest(http.MethodGet, "/test", nil)
	rec := httptest.NewRecorder()

	handler.ServeHTTP(rec, req)

	assert.Equal(t, http.StatusOK, rec.Code)
	assert.Equal(t, "nosniff", rec.Header().Get("X-Content-Type-Options"))
	assert.Equal(t, "DENY", rec.Header().Get("X-Frame-Options"))
	assert.Equal(t, "strict-origin-when-cross-origin", rec.Header().Get("Referrer-Policy"))
}

func TestCORS(t *testing.T) {
	t.Run("OPTIONS preflight returns 204", func(t *testing.T) {
		handler := httpAdapter.CORS(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			t.Fatal("handler should not be called on OPTIONS")
		}))

		req := httptest.NewRequest(http.MethodOptions, "/api/v1/ping", nil)
		rec := httptest.NewRecorder()

		handler.ServeHTTP(rec, req)

		assert.Equal(t, http.StatusNoContent, rec.Code)
		assert.Equal(t, "*", rec.Header().Get("Access-Control-Allow-Origin"))
		assert.Equal(t, "GET, POST, PUT, PATCH, DELETE, OPTIONS", rec.Header().Get("Access-Control-Allow-Methods"))
		assert.Equal(t, "Accept, Authorization, Content-Type, X-Request-ID, X-Signature", rec.Header().Get("Access-Control-Allow-Headers"))
		assert.Equal(t, "300", rec.Header().Get("Access-Control-Max-Age"))
	})

	t.Run("Standard request passes through with CORS headers", func(t *testing.T) {
		called := false
		handler := httpAdapter.CORS(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			called = true
			w.WriteHeader(http.StatusOK)
		}))

		req := httptest.NewRequest(http.MethodGet, "/api/v1/ping", nil)
		rec := httptest.NewRecorder()

		handler.ServeHTTP(rec, req)

		assert.True(t, called)
		assert.Equal(t, http.StatusOK, rec.Code)
		assert.Equal(t, "*", rec.Header().Get("Access-Control-Allow-Origin"))
	})
}

func TestOopsRecoverer(t *testing.T) {
	var buf bytes.Buffer
	logger := slog.New(slog.NewTextHandler(&buf, nil))

	handler := httpAdapter.OopsRecoverer(logger)(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		panic("simulated critical runtime panic")
	}))

	req := httptest.NewRequest(http.MethodGet, "/panic", nil)
	rec := httptest.NewRecorder()

	assert.NotPanics(t, func() {
		handler.ServeHTTP(rec, req)
	})

	assert.Equal(t, http.StatusInternalServerError, rec.Code)
	assert.Contains(t, rec.Body.String(), "internal_server_error")
}

func TestStructuredLogger(t *testing.T) {
	var buf bytes.Buffer
	logger := slog.New(slog.NewTextHandler(&buf, nil))

	handler := httpAdapter.StructuredLogger(logger)(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusOK)
		_, _ = io.WriteString(w, "hello")
	}))

	req := httptest.NewRequest(http.MethodGet, "/logged", nil)
	rec := httptest.NewRecorder()

	handler.ServeHTTP(rec, req)

	assert.Equal(t, http.StatusOK, rec.Code)
	assert.Contains(t, buf.String(), "http request completed")
	assert.Contains(t, buf.String(), "/logged")
}

func TestAuthMiddleware(t *testing.T) {
	dummyNextHandler := func(capturedID *domain.UUID) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			id, err := httpAdapter.GetDeviceIDFromContext(r.Context())
			if err != nil {
				http.Error(w, err.Error(), http.StatusInternalServerError)
				return
			}
			*capturedID = id
			w.WriteHeader(http.StatusOK)
		})
	}

	t.Run("nil token manager returns 500", func(t *testing.T) {
		var captured domain.UUID
		handler := httpAdapter.AuthMiddleware(nil)(dummyNextHandler(&captured))

		req := httptest.NewRequest(http.MethodGet, "/protected", nil)
		req.Header.Set("Authorization", "Bearer valid.token")
		rec := httptest.NewRecorder()

		handler.ServeHTTP(rec, req)

		assert.Equal(t, http.StatusInternalServerError, rec.Code)
	})

	t.Run("missing authorization header returns 401", func(t *testing.T) {
		var captured domain.UUID
		mockTM := &mocks.MockTokenManager{}
		handler := httpAdapter.AuthMiddleware(mockTM)(dummyNextHandler(&captured))

		req := httptest.NewRequest(http.MethodGet, "/protected", nil)
		rec := httptest.NewRecorder()

		handler.ServeHTTP(rec, req)

		assert.Equal(t, http.StatusUnauthorized, rec.Code)
		var errResp httpAdapter.ErrorEnvelope
		err := json.Unmarshal(rec.Body.Bytes(), &errResp)
		require.NoError(t, err)
		assert.Equal(t, "unauthorized", errResp.Error.Code)
		assert.Equal(t, "Missing Authorization header", errResp.Error.Message)
	})

	t.Run("invalid scheme (non-Bearer) returns 401", func(t *testing.T) {
		var captured domain.UUID
		mockTM := &mocks.MockTokenManager{}
		handler := httpAdapter.AuthMiddleware(mockTM)(dummyNextHandler(&captured))

		req := httptest.NewRequest(http.MethodGet, "/protected", nil)
		req.Header.Set("Authorization", "Basic some-base64-credentials")
		rec := httptest.NewRecorder()

		handler.ServeHTTP(rec, req)

		assert.Equal(t, http.StatusUnauthorized, rec.Code)
		var errResp httpAdapter.ErrorEnvelope
		err := json.Unmarshal(rec.Body.Bytes(), &errResp)
		require.NoError(t, err)
		assert.Equal(t, "unauthorized", errResp.Error.Code)
		assert.Equal(t, "Authorization header must use Bearer scheme", errResp.Error.Message)
	})

	t.Run("empty bearer token returns 401", func(t *testing.T) {
		var captured domain.UUID
		mockTM := &mocks.MockTokenManager{}
		handler := httpAdapter.AuthMiddleware(mockTM)(dummyNextHandler(&captured))

		req := httptest.NewRequest(http.MethodGet, "/protected", nil)
		req.Header.Set("Authorization", "Bearer    ")
		rec := httptest.NewRecorder()

		handler.ServeHTTP(rec, req)

		assert.Equal(t, http.StatusUnauthorized, rec.Code)
		var errResp httpAdapter.ErrorEnvelope
		err := json.Unmarshal(rec.Body.Bytes(), &errResp)
		require.NoError(t, err)
		assert.Equal(t, "unauthorized", errResp.Error.Code)
		assert.Equal(t, "Authorization token must not be empty", errResp.Error.Message)
	})

	t.Run("expired token returns 401 token_expired", func(t *testing.T) {
		var captured domain.UUID
		mockTM := &mocks.MockTokenManager{
			VerifyDeviceTokenFunc: func(tokenString string) (*port.DeviceClaims, error) {
				return nil, domain.ErrTokenExpired
			},
		}
		handler := httpAdapter.AuthMiddleware(mockTM)(dummyNextHandler(&captured))

		req := httptest.NewRequest(http.MethodGet, "/protected", nil)
		req.Header.Set("Authorization", "Bearer expired.v4.token")
		rec := httptest.NewRecorder()

		handler.ServeHTTP(rec, req)

		assert.Equal(t, http.StatusUnauthorized, rec.Code)
		var errResp httpAdapter.ErrorEnvelope
		err := json.Unmarshal(rec.Body.Bytes(), &errResp)
		require.NoError(t, err)
		assert.Equal(t, "token_expired", errResp.Error.Code)
		assert.Equal(t, "Authorization token has expired", errResp.Error.Message)
	})

	t.Run("invalid token error returns 401 unauthorized", func(t *testing.T) {
		var captured domain.UUID
		mockTM := &mocks.MockTokenManager{
			VerifyDeviceTokenFunc: func(tokenString string) (*port.DeviceClaims, error) {
				return nil, errors.New("tampered token signature")
			},
		}
		handler := httpAdapter.AuthMiddleware(mockTM)(dummyNextHandler(&captured))

		req := httptest.NewRequest(http.MethodGet, "/protected", nil)
		req.Header.Set("Authorization", "Bearer tampered.v4.token")
		rec := httptest.NewRecorder()

		handler.ServeHTTP(rec, req)

		assert.Equal(t, http.StatusUnauthorized, rec.Code)
		var errResp httpAdapter.ErrorEnvelope
		err := json.Unmarshal(rec.Body.Bytes(), &errResp)
		require.NoError(t, err)
		assert.Equal(t, "unauthorized", errResp.Error.Code)
	})

	t.Run("token with zero device ID claims returns 401 unauthorized", func(t *testing.T) {
		var captured domain.UUID
		mockTM := &mocks.MockTokenManager{
			VerifyDeviceTokenFunc: func(tokenString string) (*port.DeviceClaims, error) {
				return &port.DeviceClaims{
					DeviceID:  domain.NilUUID,
					IssuedAt:  time.Now(),
					ExpiresAt: time.Now().Add(time.Hour),
				}, nil
			},
		}
		handler := httpAdapter.AuthMiddleware(mockTM)(dummyNextHandler(&captured))

		req := httptest.NewRequest(http.MethodGet, "/protected", nil)
		req.Header.Set("Authorization", "Bearer valid.token.zero.id")
		rec := httptest.NewRecorder()

		handler.ServeHTTP(rec, req)

		assert.Equal(t, http.StatusUnauthorized, rec.Code)
		var errResp httpAdapter.ErrorEnvelope
		err := json.Unmarshal(rec.Body.Bytes(), &errResp)
		require.NoError(t, err)
		assert.Equal(t, "unauthorized", errResp.Error.Code)
	})

	t.Run("valid token injects device ID into context and calls next handler", func(t *testing.T) {
		expectedID := testutil.DefaultDeviceID
		var captured domain.UUID
		mockTM := &mocks.MockTokenManager{
			VerifyDeviceTokenFunc: func(tokenString string) (*port.DeviceClaims, error) {
				assert.Equal(t, "valid.paseto.token", tokenString)
				return &port.DeviceClaims{
					DeviceID:  expectedID,
					IssuedAt:  time.Now().UTC(),
					ExpiresAt: time.Now().UTC().Add(24 * time.Hour),
				}, nil
			},
		}
		handler := httpAdapter.AuthMiddleware(mockTM)(dummyNextHandler(&captured))

		req := httptest.NewRequest(http.MethodGet, "/protected", nil)
		req.Header.Set("Authorization", "Bearer valid.paseto.token")
		rec := httptest.NewRecorder()

		handler.ServeHTTP(rec, req)

		assert.Equal(t, http.StatusOK, rec.Code)
		assert.Equal(t, expectedID, captured)
	})
}

func TestGetDeviceIDFromContext(t *testing.T) {
	t.Run("nil context or missing key returns ErrUnauthorized", func(t *testing.T) {
		id, err := httpAdapter.GetDeviceIDFromContext(context.Background())
		assert.Error(t, err)
		assert.True(t, errors.Is(err, domain.ErrUnauthorized))
		assert.Equal(t, domain.NilUUID, id)
	})

	t.Run("context with wrong value type returns ErrUnauthorized", func(t *testing.T) {
		// Context with an unexported key or string instead of domain.UUID
		type otherKey string
		ctx := context.WithValue(context.Background(), otherKey("device_id"), "not-a-uuid")
		id, err := httpAdapter.GetDeviceIDFromContext(ctx)
		assert.Error(t, err)
		assert.True(t, errors.Is(err, domain.ErrUnauthorized))
		assert.Equal(t, domain.NilUUID, id)
	})
}
