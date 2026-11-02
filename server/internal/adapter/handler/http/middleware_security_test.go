package http_test

import (
	"bytes"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"

	httpAdapter "github.com/ftthreign/savoryx_app/server/internal/adapter/handler/http"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

func TestRequireJSONContentType(t *testing.T) {
	t.Parallel()

	dummyHandler := http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusOK)
		_, _ = w.Write([]byte(`{"status":"ok"}`))
	})

	middleware := httpAdapter.RequireJSONContentType(dummyHandler)

	t.Run("POST without Content-Type is rejected with 415", func(t *testing.T) {
		t.Parallel()
		req := httptest.NewRequest(http.MethodPost, "/test", strings.NewReader(`{"name":"test"}`))
		rec := httptest.NewRecorder()

		middleware.ServeHTTP(rec, req)

		assert.Equal(t, http.StatusUnsupportedMediaType, rec.Code)
		assert.Contains(t, rec.Body.String(), "unsupported_media_type")
	})

	t.Run("POST with text/plain is rejected with 415", func(t *testing.T) {
		t.Parallel()
		req := httptest.NewRequest(http.MethodPost, "/test", strings.NewReader("plain text"))
		req.Header.Set("Content-Type", "text/plain")
		rec := httptest.NewRecorder()

		middleware.ServeHTTP(rec, req)

		assert.Equal(t, http.StatusUnsupportedMediaType, rec.Code)
		assert.Contains(t, rec.Body.String(), "unsupported_media_type")
	})

	t.Run("PUT without Content-Type is rejected with 415", func(t *testing.T) {
		t.Parallel()
		req := httptest.NewRequest(http.MethodPut, "/test", strings.NewReader(`{}`))
		rec := httptest.NewRecorder()

		middleware.ServeHTTP(rec, req)

		assert.Equal(t, http.StatusUnsupportedMediaType, rec.Code)
	})

	t.Run("PATCH without Content-Type is rejected with 415", func(t *testing.T) {
		t.Parallel()
		req := httptest.NewRequest(http.MethodPatch, "/test", strings.NewReader(`{}`))
		rec := httptest.NewRecorder()

		middleware.ServeHTTP(rec, req)

		assert.Equal(t, http.StatusUnsupportedMediaType, rec.Code)
	})

	t.Run("POST with application/json passes through", func(t *testing.T) {
		t.Parallel()
		req := httptest.NewRequest(http.MethodPost, "/test", strings.NewReader(`{"name":"test"}`))
		req.Header.Set("Content-Type", "application/json")
		rec := httptest.NewRecorder()

		middleware.ServeHTTP(rec, req)

		assert.Equal(t, http.StatusOK, rec.Code)
	})

	t.Run("POST with application/json; charset=utf-8 passes through", func(t *testing.T) {
		t.Parallel()
		req := httptest.NewRequest(http.MethodPost, "/test", strings.NewReader(`{"name":"test"}`))
		req.Header.Set("Content-Type", "application/json; charset=utf-8")
		rec := httptest.NewRecorder()

		middleware.ServeHTTP(rec, req)

		assert.Equal(t, http.StatusOK, rec.Code)
	})

	t.Run("GET without Content-Type passes through without obstruction", func(t *testing.T) {
		t.Parallel()
		req := httptest.NewRequest(http.MethodGet, "/test", nil)
		rec := httptest.NewRecorder()

		middleware.ServeHTTP(rec, req)

		assert.Equal(t, http.StatusOK, rec.Code)
	})

	t.Run("DELETE without Content-Type passes through", func(t *testing.T) {
		t.Parallel()
		req := httptest.NewRequest(http.MethodDelete, "/test", nil)
		rec := httptest.NewRecorder()

		middleware.ServeHTTP(rec, req)

		assert.Equal(t, http.StatusOK, rec.Code)
	})
}

func TestDecodeJSON_BodyLimit(t *testing.T) {
	t.Parallel()

	type samplePayload struct {
		Data string `json:"data"`
	}

	testHandler := http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		var payload samplePayload
		if err := httpAdapter.DecodeJSON(w, r, &payload); err != nil {
			return
		}
		httpAdapter.WriteJSON(w, http.StatusOK, payload)
	})

	t.Run("payload within 64KB succeeds", func(t *testing.T) {
		t.Parallel()

		smallData := samplePayload{Data: strings.Repeat("A", 1024)} // 1 KB
		bodyBytes, err := json.Marshal(smallData)
		require.NoError(t, err)

		req := httptest.NewRequest(http.MethodPost, "/test", bytes.NewReader(bodyBytes))
		req.Header.Set("Content-Type", "application/json")
		rec := httptest.NewRecorder()

		testHandler.ServeHTTP(rec, req)

		assert.Equal(t, http.StatusOK, rec.Code)
	})

	t.Run("payload exceeding 64KB is rejected with 413 Payload Too Large", func(t *testing.T) {
		t.Parallel()

		// 70 KB payload
		oversizedData := samplePayload{Data: strings.Repeat("X", 70*1024)}
		bodyBytes, err := json.Marshal(oversizedData)
		require.NoError(t, err)

		req := httptest.NewRequest(http.MethodPost, "/test", bytes.NewReader(bodyBytes))
		req.Header.Set("Content-Type", "application/json")
		rec := httptest.NewRecorder()

		testHandler.ServeHTTP(rec, req)

		assert.Equal(t, http.StatusRequestEntityTooLarge, rec.Code)
		assert.Contains(t, rec.Body.String(), "payload_too_large")
	})

	t.Run("malformed json returns 400 Bad Request", func(t *testing.T) {
		t.Parallel()

		req := httptest.NewRequest(http.MethodPost, "/test", strings.NewReader("{invalid-json"))
		req.Header.Set("Content-Type", "application/json")
		rec := httptest.NewRecorder()

		testHandler.ServeHTTP(rec, req)

		assert.Equal(t, http.StatusBadRequest, rec.Code)
		assert.Contains(t, rec.Body.String(), "invalid_json")
	})
}
