package http_test

import (
	"bytes"
	"encoding/json"
	"io"
	"net/http"
	"net/http/httptest"
	"strconv"
	"testing"
	"time"

	httpAdapter "github.com/ftthreign/savoryx_app/server/internal/adapter/handler/http"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

func TestVerifyHMACSignature(t *testing.T) {
	t.Parallel()

	const testSecret = "savoryx-super-secret-hmac-key-2026"

	echoBodyHandler := http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		body, err := io.ReadAll(r.Body)
		if err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}
		w.WriteHeader(http.StatusOK)
		_, _ = w.Write(body)
	})

	t.Run("GET requests bypass HMAC verification without headers", func(t *testing.T) {
		t.Parallel()

		handler := httpAdapter.VerifyHMACSignature(testSecret)(echoBodyHandler)
		req := httptest.NewRequest(http.MethodGet, "/api/v1/accounts", nil)
		rec := httptest.NewRecorder()

		handler.ServeHTTP(rec, req)

		assert.Equal(t, http.StatusOK, rec.Code)
	})

	t.Run("unconfigured empty secret returns 500 on mutation", func(t *testing.T) {
		t.Parallel()

		handler := httpAdapter.VerifyHMACSignature("   ")(echoBodyHandler)
		req := httptest.NewRequest(http.MethodPost, "/api/v1/accounts", bytes.NewBufferString(`{"name":"Cash"}`))
		rec := httptest.NewRecorder()

		handler.ServeHTTP(rec, req)

		assert.Equal(t, http.StatusInternalServerError, rec.Code)
		var env httpAdapter.ErrorEnvelope
		require.NoError(t, json.Unmarshal(rec.Body.Bytes(), &env))
		assert.Equal(t, "internal_error", env.Error.Code)
	})

	t.Run("missing X-Signature or X-Timestamp header returns 401 missing_signature", func(t *testing.T) {
		t.Parallel()

		handler := httpAdapter.VerifyHMACSignature(testSecret)(echoBodyHandler)

		// Missing both
		req1 := httptest.NewRequest(http.MethodPost, "/api/v1/accounts", bytes.NewBufferString(`{"name":"Cash"}`))
		rec1 := httptest.NewRecorder()
		handler.ServeHTTP(rec1, req1)
		assert.Equal(t, http.StatusUnauthorized, rec1.Code)
		var env1 httpAdapter.ErrorEnvelope
		require.NoError(t, json.Unmarshal(rec1.Body.Bytes(), &env1))
		assert.Equal(t, "missing_signature", env1.Error.Code)

		// Missing X-Timestamp
		req2 := httptest.NewRequest(http.MethodPost, "/api/v1/accounts", bytes.NewBufferString(`{"name":"Cash"}`))
		req2.Header.Set("X-Signature", "deadbeef")
		rec2 := httptest.NewRecorder()
		handler.ServeHTTP(rec2, req2)
		assert.Equal(t, http.StatusUnauthorized, rec2.Code)
		var env2 httpAdapter.ErrorEnvelope
		require.NoError(t, json.Unmarshal(rec2.Body.Bytes(), &env2))
		assert.Equal(t, "missing_signature", env2.Error.Code)
	})

	t.Run("invalid X-Timestamp format returns 401 invalid_timestamp", func(t *testing.T) {
		t.Parallel()

		handler := httpAdapter.VerifyHMACSignature(testSecret)(echoBodyHandler)
		req := httptest.NewRequest(http.MethodPost, "/api/v1/accounts", bytes.NewBufferString(`{"name":"Cash"}`))
		req.Header.Set("X-Timestamp", "not-a-timestamp")
		req.Header.Set("X-Signature", "deadbeef")
		rec := httptest.NewRecorder()

		handler.ServeHTTP(rec, req)

		assert.Equal(t, http.StatusUnauthorized, rec.Code)
		var env httpAdapter.ErrorEnvelope
		require.NoError(t, json.Unmarshal(rec.Body.Bytes(), &env))
		assert.Equal(t, "invalid_timestamp", env.Error.Code)
	})

	t.Run("expired and future timestamps beyond 60s return 401 clock_skew_exceeded", func(t *testing.T) {
		t.Parallel()

		handler := httpAdapter.VerifyHMACSignature(testSecret)(echoBodyHandler)
		payload := []byte(`{"name":"BCA","balance":"100000.00"}`)

		// 90 seconds in the past
		expiredTS := time.Now().UTC().Add(-90 * time.Second).Format(time.RFC3339)
		sigPast := httpAdapter.ComputeHMACSignature(testSecret, expiredTS, http.MethodPost, "/api/v1/accounts", payload)
		reqPast := httptest.NewRequest(http.MethodPost, "/api/v1/accounts", bytes.NewReader(payload))
		reqPast.Header.Set("X-Timestamp", expiredTS)
		reqPast.Header.Set("X-Signature", sigPast)
		recPast := httptest.NewRecorder()
		handler.ServeHTTP(recPast, reqPast)
		assert.Equal(t, http.StatusUnauthorized, recPast.Code)
		var envPast httpAdapter.ErrorEnvelope
		require.NoError(t, json.Unmarshal(recPast.Body.Bytes(), &envPast))
		assert.Equal(t, "clock_skew_exceeded", envPast.Error.Code)

		// 120 seconds in the future
		futureTS := time.Now().UTC().Add(120 * time.Second).Format(time.RFC3339)
		sigFuture := httpAdapter.ComputeHMACSignature(testSecret, futureTS, http.MethodPost, "/api/v1/accounts", payload)
		reqFuture := httptest.NewRequest(http.MethodPost, "/api/v1/accounts", bytes.NewReader(payload))
		reqFuture.Header.Set("X-Timestamp", futureTS)
		reqFuture.Header.Set("X-Signature", sigFuture)
		recFuture := httptest.NewRecorder()
		handler.ServeHTTP(recFuture, reqFuture)
		assert.Equal(t, http.StatusUnauthorized, recFuture.Code)
		var envFuture httpAdapter.ErrorEnvelope
		require.NoError(t, json.Unmarshal(recFuture.Body.Bytes(), &envFuture))
		assert.Equal(t, "clock_skew_exceeded", envFuture.Error.Code)
	})

	t.Run("valid canonical HMAC-SHA256 signature succeeds and preserves request body", func(t *testing.T) {
		t.Parallel()

		handler := httpAdapter.VerifyHMACSignature(testSecret)(echoBodyHandler)
		payload := []byte(`{"name":"BCA Primary","type":"BANK","currency":"IDR","balance":"2500000.00"}`)
		ts := time.Now().UTC().Format(time.RFC3339)
		sig := httpAdapter.ComputeHMACSignature(testSecret, ts, http.MethodPost, "/api/v1/accounts", payload)

		req := httptest.NewRequest(http.MethodPost, "/api/v1/accounts", bytes.NewReader(payload))
		req.Header.Set("X-Timestamp", ts)
		req.Header.Set("X-Signature", sig)
		rec := httptest.NewRecorder()

		handler.ServeHTTP(rec, req)

		assert.Equal(t, http.StatusOK, rec.Code)
		assert.Equal(t, string(payload), rec.Body.String(), "downstream handler must receive full request body")
	})

	t.Run("valid signature with unix epoch seconds and sha256= prefix succeeds", func(t *testing.T) {
		t.Parallel()

		handler := httpAdapter.VerifyHMACSignature(testSecret)(echoBodyHandler)
		payload := []byte(`{"balance":"750000.00"}`)
		ts := strconv.FormatInt(time.Now().UTC().Unix(), 10)
		sig := httpAdapter.ComputeHMACSignature(testSecret, ts, http.MethodPut, "/api/v1/accounts/123/balance", payload)

		req := httptest.NewRequest(http.MethodPut, "/api/v1/accounts/123/balance", bytes.NewReader(payload))
		req.Header.Set("X-Timestamp", ts)
		req.Header.Set("X-Signature", "sha256="+sig)
		rec := httptest.NewRecorder()

		handler.ServeHTTP(rec, req)

		assert.Equal(t, http.StatusOK, rec.Code)
		assert.Equal(t, string(payload), rec.Body.String())
	})

	t.Run("tampered payload body is rejected with 401 invalid_signature", func(t *testing.T) {
		t.Parallel()

		handler := httpAdapter.VerifyHMACSignature(testSecret)(echoBodyHandler)
		originalPayload := []byte(`{"amount":"50000.00"}`)
		tamperedPayload := []byte(`{"amount":"99999999.00"}`)
		ts := time.Now().UTC().Format(time.RFC3339)
		sig := httpAdapter.ComputeHMACSignature(testSecret, ts, http.MethodPost, "/api/v1/transactions", originalPayload)

		req := httptest.NewRequest(http.MethodPost, "/api/v1/transactions", bytes.NewReader(tamperedPayload))
		req.Header.Set("X-Timestamp", ts)
		req.Header.Set("X-Signature", sig)
		rec := httptest.NewRecorder()

		handler.ServeHTTP(rec, req)

		assert.Equal(t, http.StatusUnauthorized, rec.Code)
		var env httpAdapter.ErrorEnvelope
		require.NoError(t, json.Unmarshal(rec.Body.Bytes(), &env))
		assert.Equal(t, "invalid_signature", env.Error.Code)
	})

	t.Run("tampered HTTP method or path is rejected with 401 invalid_signature", func(t *testing.T) {
		t.Parallel()

		handler := httpAdapter.VerifyHMACSignature(testSecret)(echoBodyHandler)
		payload := []byte(`{}`)
		ts := time.Now().UTC().Format(time.RFC3339)
		sig := httpAdapter.ComputeHMACSignature(testSecret, ts, http.MethodPut, "/api/v1/accounts/acc-1", payload)

		// Attacker replays signature on DELETE /api/v1/accounts/acc-2
		req := httptest.NewRequest(http.MethodDelete, "/api/v1/accounts/acc-2", bytes.NewReader(payload))
		req.Header.Set("X-Timestamp", ts)
		req.Header.Set("X-Signature", sig)
		rec := httptest.NewRecorder()

		handler.ServeHTTP(rec, req)

		assert.Equal(t, http.StatusUnauthorized, rec.Code)
		var env httpAdapter.ErrorEnvelope
		require.NoError(t, json.Unmarshal(rec.Body.Bytes(), &env))
		assert.Equal(t, "invalid_signature", env.Error.Code)
	})
}
