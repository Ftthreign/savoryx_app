package http_test

import (
	"encoding/json"
	"errors"
	"fmt"
	"net/http"
	"net/http/httptest"
	"testing"

	httpAdapter "github.com/ftthreign/savoryx_app/server/internal/adapter/handler/http"
	"github.com/ftthreign/savoryx_app/server/internal/core/domain"
	"github.com/samber/oops"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

func TestWriteJSON(t *testing.T) {
	rec := httptest.NewRecorder()
	sampleData := map[string]string{"key": "value"}

	httpAdapter.WriteJSON(rec, http.StatusOK, sampleData)

	assert.Equal(t, http.StatusOK, rec.Code)
	assert.Equal(t, "application/json", rec.Header().Get("Content-Type"))

	var env httpAdapter.ResponseEnvelope
	err := json.Unmarshal(rec.Body.Bytes(), &env)
	require.NoError(t, err)

	dataMap, ok := env.Data.(map[string]any)
	require.True(t, ok)
	assert.Equal(t, "value", dataMap["key"])
}

func TestWriteJSONWithMeta(t *testing.T) {
	rec := httptest.NewRecorder()
	sampleData := []string{"item1", "item2"}
	sampleMeta := map[string]int{"total": 2}

	httpAdapter.WriteJSONWithMeta(rec, http.StatusCreated, sampleData, sampleMeta)

	assert.Equal(t, http.StatusCreated, rec.Code)

	var env httpAdapter.ResponseEnvelope
	err := json.Unmarshal(rec.Body.Bytes(), &env)
	require.NoError(t, err)

	dataList, ok := env.Data.([]any)
	require.True(t, ok)
	assert.Len(t, dataList, 2)

	metaMap, ok := env.Meta.(map[string]any)
	require.True(t, ok)
	assert.Equal(t, float64(2), metaMap["total"])
}

func TestWriteError(t *testing.T) {
	rec := httptest.NewRecorder()

	httpAdapter.WriteError(rec, http.StatusBadRequest, "INVALID_PARAM", "The provided parameter is invalid")

	assert.Equal(t, http.StatusBadRequest, rec.Code)

	var env httpAdapter.ErrorEnvelope
	err := json.Unmarshal(rec.Body.Bytes(), &env)
	require.NoError(t, err)

	assert.Equal(t, "INVALID_PARAM", env.Error.Code)
	assert.Equal(t, "The provided parameter is invalid", env.Error.Message)
}

func TestWriteDomainError_DeepWrappedChains(t *testing.T) {
	t.Run("Nil error produces no response", func(t *testing.T) {
		rec := httptest.NewRecorder()
		httpAdapter.WriteDomainError(rec, nil)
		assert.Equal(t, http.StatusOK, rec.Code)
		assert.Empty(t, rec.Body.Bytes())
	})

	t.Run("Bare Domain Error", func(t *testing.T) {
		rec := httptest.NewRecorder()
		httpAdapter.WriteDomainError(rec, domain.ErrAccountNotFound)

		assert.Equal(t, http.StatusNotFound, rec.Code)
		var env httpAdapter.ErrorEnvelope
		err := json.Unmarshal(rec.Body.Bytes(), &env)
		require.NoError(t, err)
		assert.Equal(t, "not_found", env.Error.Code)
		assert.Equal(t, "account not found", env.Error.Message)
	})

	t.Run("Oops wrapped error extracts custom oops code", func(t *testing.T) {
		rec := httptest.NewRecorder()
		oopsErr := oops.
			Code("ERR_ACCOUNT_SPECIFIC").
			In("account_repo").
			Wrap(domain.ErrAccountNotFound)

		httpAdapter.WriteDomainError(rec, oopsErr)

		assert.Equal(t, http.StatusNotFound, rec.Code)
		var env httpAdapter.ErrorEnvelope
		err := json.Unmarshal(rec.Body.Bytes(), &env)
		require.NoError(t, err)
		assert.Equal(t, "ERR_ACCOUNT_SPECIFIC", env.Error.Code)
	})

	t.Run("Deeply wrapped error chain inspected with errors.As", func(t *testing.T) {
		rec := httptest.NewRecorder()
		// Wrap oops error with standard fmt.Errorf %w multiple times
		innerOops := oops.
			Code("ERR_DEEP_CHAIN_INSPECTED").
			In("service_layer").
			Wrap(domain.ErrCategoryNotFound)

		wrapped1 := fmt.Errorf("middleware wrapper: %w", innerOops)
		wrapped2 := fmt.Errorf("outer handler wrapper: %w", wrapped1)

		httpAdapter.WriteDomainError(rec, wrapped2)

		assert.Equal(t, http.StatusNotFound, rec.Code)
		var env httpAdapter.ErrorEnvelope
		err := json.Unmarshal(rec.Body.Bytes(), &env)
		require.NoError(t, err)

		// errors.As finds innerOops in wrapped2 successfully
		assert.Equal(t, "ERR_DEEP_CHAIN_INSPECTED", env.Error.Code)
	})

	t.Run("Database unavailable error mapping", func(t *testing.T) {
		rec := httptest.NewRecorder()
		wrappedDBErr := fmt.Errorf("pool failure: %w", domain.ErrDatabaseUnavailable)

		httpAdapter.WriteDomainError(rec, wrappedDBErr)

		assert.Equal(t, http.StatusServiceUnavailable, rec.Code)
		var env httpAdapter.ErrorEnvelope
		err := json.Unmarshal(rec.Body.Bytes(), &env)
		require.NoError(t, err)
		assert.Equal(t, "service_unavailable", env.Error.Code)
		assert.Equal(t, "Database service is temporarily unavailable", env.Error.Message)
	})

	t.Run("Invalid input error mapping", func(t *testing.T) {
		rec := httptest.NewRecorder()
		httpAdapter.WriteDomainError(rec, domain.ErrInvalidInput)

		assert.Equal(t, http.StatusBadRequest, rec.Code)
		var env httpAdapter.ErrorEnvelope
		err := json.Unmarshal(rec.Body.Bytes(), &env)
		require.NoError(t, err)
		assert.Equal(t, "invalid_input", env.Error.Code)
		assert.Equal(t, "invalid input parameter", env.Error.Message)
	})

	t.Run("Unhandled raw error mapping to internal_error", func(t *testing.T) {
		rec := httptest.NewRecorder()
		httpAdapter.WriteDomainError(rec, errors.New("unexpected panic or network drop"))

		assert.Equal(t, http.StatusInternalServerError, rec.Code)
		var env httpAdapter.ErrorEnvelope
		err := json.Unmarshal(rec.Body.Bytes(), &env)
		require.NoError(t, err)
		assert.Equal(t, "internal_error", env.Error.Code)
		assert.Equal(t, "Internal server error", env.Error.Message)
	})
}
