package test

import (
	"net/http"
	"testing"

	"github.com/ftthreign/savoryx_app/server/internal/core/domain"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

func TestE2E_ValidationAndNegativePaths(t *testing.T) {
	env := setupTestEnvironment(t)
	token, _ := env.RegisterDevice(t, "Validation Test Device", "ios", "1.0.0")

	t.Run("Invalid Token Format Returns 401", func(t *testing.T) {
		req, _ := http.NewRequest(http.MethodGet, env.Server.URL+"/api/v1/accounts", nil)
		req.Header.Set("Authorization", "Bearer invalid-tampered-token")
		res, err := env.Client.Do(req)
		require.NoError(t, err)
		assert.Equal(t, http.StatusUnauthorized, res.StatusCode)
	})

	t.Run("Missing Bearer Prefix Returns 401", func(t *testing.T) {
		req, _ := http.NewRequest(http.MethodGet, env.Server.URL+"/api/v1/accounts", nil)
		req.Header.Set("Authorization", token)
		res, err := env.Client.Do(req)
		require.NoError(t, err)
		assert.Equal(t, http.StatusUnauthorized, res.StatusCode)
	})

	t.Run("Invalid UUID In Route Parameter Returns 400", func(t *testing.T) {
		res, err := env.DoAuthRequest(token, http.MethodGet, "/api/v1/accounts/not-a-valid-uuid", nil)
		require.NoError(t, err)
		assert.Equal(t, http.StatusBadRequest, res.StatusCode)
	})

	t.Run("Non-Existent UUID Returns 404", func(t *testing.T) {
		randomUUID := domain.NewUUIDv7().String()
		res, err := env.DoAuthRequest(token, http.MethodGet, "/api/v1/accounts/"+randomUUID, nil)
		require.NoError(t, err)
		assert.Equal(t, http.StatusNotFound, res.StatusCode)
	})

	t.Run("Account Creation with Invalid Type Returns 400", func(t *testing.T) {
		payload := map[string]string{
			"name":     "Crypto Wallet",
			"type":     "UNKNOWN_CRYPTO_TYPE",
			"currency": "IDR",
			"balance":  "1000",
		}
		res, err := env.DoAuthRequest(token, http.MethodPost, "/api/v1/accounts", payload)
		require.NoError(t, err)
		assert.Equal(t, http.StatusBadRequest, res.StatusCode)
	})

	t.Run("Account Creation with Invalid Balance Returns 400", func(t *testing.T) {
		payload := map[string]string{
			"name":     "Tabungan",
			"type":     "BANK",
			"currency": "IDR",
			"balance":  "not-a-number",
		}
		res, err := env.DoAuthRequest(token, http.MethodPost, "/api/v1/accounts", payload)
		require.NoError(t, err)
		assert.Equal(t, http.StatusBadRequest, res.StatusCode)
	})

	t.Run("Duplicate Account Name Returns 409 Conflict", func(t *testing.T) {
		payload := map[string]string{
			"name":     "Unique Account",
			"type":     "BANK",
			"currency": "IDR",
			"balance":  "1000",
		}
		res1, err := env.DoAuthRequest(token, http.MethodPost, "/api/v1/accounts", payload)
		require.NoError(t, err)
		assert.Equal(t, http.StatusCreated, res1.StatusCode)

		// Duplicate name attempt
		res2, err := env.DoAuthRequest(token, http.MethodPost, "/api/v1/accounts", payload)
		require.NoError(t, err)
		assert.Equal(t, http.StatusConflict, res2.StatusCode)
	})

	t.Run("Category Creation with Invalid Hex Color Returns 400", func(t *testing.T) {
		payload := map[string]interface{}{
			"name":     "Invalid Category",
			"icon":     "tag",
			"color":    "blue", // Not a valid hex code #RGB or #RRGGBB
			"is_wants": false,
		}
		res, err := env.DoAuthRequest(token, http.MethodPost, "/api/v1/categories", payload)
		require.NoError(t, err)
		assert.Equal(t, http.StatusBadRequest, res.StatusCode)
	})

	t.Run("Duplicate Category Name Returns 409 Conflict", func(t *testing.T) {
		payload := map[string]interface{}{
			"name":     "Unique Category",
			"icon":     "tag",
			"color":    "#112233",
			"is_wants": false,
		}
		res1, err := env.DoAuthRequest(token, http.MethodPost, "/api/v1/categories", payload)
		require.NoError(t, err)
		assert.Equal(t, http.StatusCreated, res1.StatusCode)

		// Duplicate category attempt
		res2, err := env.DoAuthRequest(token, http.MethodPost, "/api/v1/categories", payload)
		require.NoError(t, err)
		assert.Equal(t, http.StatusConflict, res2.StatusCode)
	})
}
