package test

import (
	"encoding/json"
	"net/http"
	"strings"
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

func TestE2E_FullLifecycleFlow(t *testing.T) {
	env := setupTestEnvironment(t)

	// Step 1: Healthcheck Endpoints
	t.Run("Healthcheck and Ping Endpoints", func(t *testing.T) {
		resHealth, err := env.Client.Get(env.Server.URL + "/healthz")
		require.NoError(t, err)
		assert.Equal(t, http.StatusOK, resHealth.StatusCode)

		resLive, err := env.Client.Get(env.Server.URL + "/livez")
		require.NoError(t, err)
		assert.Equal(t, http.StatusOK, resLive.StatusCode)

		resPing, err := env.Client.Get(env.Server.URL + "/api/v1/ping")
		require.NoError(t, err)
		assert.Equal(t, http.StatusOK, resPing.StatusCode)
	})

	// Step 2: Unauthenticated Access Guard
	t.Run("Unauthenticated Access Returns 401", func(t *testing.T) {
		res, err := env.DoAuthRequest("", http.MethodGet, "/api/v1/accounts", nil)
		require.NoError(t, err)
		assert.Equal(t, http.StatusUnauthorized, res.StatusCode)

		var errEnvelope struct {
			Error struct {
				Code string `json:"code"`
			} `json:"error"`
		}
		err = json.NewDecoder(res.Body).Decode(&errEnvelope)
		require.NoError(t, err)
		assert.Equal(t, "unauthorized", errEnvelope.Error.Code)
	})

	// Step 3: Device Registration Handshake
	token, _ := env.RegisterDevice(t, "Google Pixel 8 Pro", "android", "1.0.0")

	// Step 4: Initially Empty Accounts List
	t.Run("List Accounts Initially Empty", func(t *testing.T) {
		res, err := env.DoAuthRequest(token, http.MethodGet, "/api/v1/accounts", nil)
		require.NoError(t, err)
		assert.Equal(t, http.StatusOK, res.StatusCode)

		var resp struct {
			Data []map[string]interface{} `json:"data"`
		}
		err = json.NewDecoder(res.Body).Decode(&resp)
		require.NoError(t, err)
		assert.Empty(t, resp.Data)
	})

	// Step 5: Create Account 1 (BCA)
	var account1ID string
	t.Run("Create Account 1 (Bank)", func(t *testing.T) {
		payload := map[string]string{
			"name":     "Bank BCA",
			"type":     "BANK",
			"currency": "IDR",
			"balance":  "1500000.00",
		}
		res, err := env.DoAuthRequest(token, http.MethodPost, "/api/v1/accounts", payload)
		require.NoError(t, err)
		assert.Equal(t, http.StatusCreated, res.StatusCode)

		loc := res.Header.Get("Location")
		assert.NotEmpty(t, loc)
		assert.True(t, strings.HasPrefix(loc, "/api/v1/accounts/"))

		var resp struct {
			Data struct {
				ID       string `json:"id"`
				Name     string `json:"name"`
				Type     string `json:"type"`
				Currency string `json:"currency"`
				Balance  string `json:"balance"`
			} `json:"data"`
		}
		err = json.NewDecoder(res.Body).Decode(&resp)
		require.NoError(t, err)

		account1ID = resp.Data.ID
		assert.NotEmpty(t, account1ID)
		assert.Equal(t, "Bank BCA", resp.Data.Name)
		assert.Equal(t, "BANK", resp.Data.Type)
		assert.Equal(t, "IDR", resp.Data.Currency)
		assert.Equal(t, "1500000.00", resp.Data.Balance)
	})

	// Step 6: Create Account 2 (Dompet Tunai)
	t.Run("Create Account 2 (Cash)", func(t *testing.T) {
		payload := map[string]string{
			"name":     "Dompet Tunai",
			"type":     "CASH",
			"currency": "IDR",
			"balance":  "250000.50",
		}
		res, err := env.DoAuthRequest(token, http.MethodPost, "/api/v1/accounts", payload)
		require.NoError(t, err)
		assert.Equal(t, http.StatusCreated, res.StatusCode)
	})

	// Step 7: List Accounts Returns Both
	t.Run("List Accounts Returns Created Accounts", func(t *testing.T) {
		res, err := env.DoAuthRequest(token, http.MethodGet, "/api/v1/accounts", nil)
		require.NoError(t, err)
		assert.Equal(t, http.StatusOK, res.StatusCode)

		var resp struct {
			Data []struct {
				ID   string `json:"id"`
				Name string `json:"name"`
			} `json:"data"`
		}
		err = json.NewDecoder(res.Body).Decode(&resp)
		require.NoError(t, err)
		assert.Len(t, resp.Data, 2)
	})

	// Step 8: Get Account Detail
	t.Run("Get Account Detail by ID", func(t *testing.T) {
		res, err := env.DoAuthRequest(token, http.MethodGet, "/api/v1/accounts/"+account1ID, nil)
		require.NoError(t, err)
		assert.Equal(t, http.StatusOK, res.StatusCode)

		var resp struct {
			Data struct {
				ID   string `json:"id"`
				Name string `json:"name"`
			} `json:"data"`
		}
		err = json.NewDecoder(res.Body).Decode(&resp)
		require.NoError(t, err)
		assert.Equal(t, account1ID, resp.Data.ID)
		assert.Equal(t, "Bank BCA", resp.Data.Name)
	})

	// Step 9: Update Account Metadata via PUT
	t.Run("Update Account Metadata via PUT", func(t *testing.T) {
		payload := map[string]string{
			"name": "BCA Rekening Utama",
			"type": "BANK",
		}
		res, err := env.DoAuthRequest(token, http.MethodPut, "/api/v1/accounts/"+account1ID, payload)
		require.NoError(t, err)
		assert.Equal(t, http.StatusOK, res.StatusCode)

		var resp struct {
			Data struct {
				Name    string `json:"name"`
				Balance string `json:"balance"`
			} `json:"data"`
		}
		err = json.NewDecoder(res.Body).Decode(&resp)
		require.NoError(t, err)
		assert.Equal(t, "BCA Rekening Utama", resp.Data.Name)
		assert.Equal(t, "1500000.00", resp.Data.Balance) // Balance is strictly preserved!
	})

	// Step 10: Update Account Balance
	t.Run("Update Account Balance via PUT /balance", func(t *testing.T) {
		payload := map[string]string{
			"balance": "2000000.00",
		}
		res, err := env.DoAuthRequest(token, http.MethodPut, "/api/v1/accounts/"+account1ID+"/balance", payload)
		require.NoError(t, err)
		assert.Equal(t, http.StatusOK, res.StatusCode)

		var resp struct {
			Data struct {
				Balance string `json:"balance"`
			} `json:"data"`
		}
		err = json.NewDecoder(res.Body).Decode(&resp)
		require.NoError(t, err)
		assert.Equal(t, "2000000.00", resp.Data.Balance)
	})

	// Step 11: Create Category 1 (Needs)
	var category1ID string
	t.Run("Create Category 1 (Needs)", func(t *testing.T) {
		payload := map[string]interface{}{
			"name":     "Makan Pokok",
			"icon":     "utensils",
			"color":    "#8DB355",
			"is_wants": false,
		}
		res, err := env.DoAuthRequest(token, http.MethodPost, "/api/v1/categories", payload)
		require.NoError(t, err)
		assert.Equal(t, http.StatusCreated, res.StatusCode)

		loc := res.Header.Get("Location")
		assert.NotEmpty(t, loc)

		var resp struct {
			Data struct {
				ID      string `json:"id"`
				Name    string `json:"name"`
				Color   string `json:"color"`
				IsWants bool   `json:"is_wants"`
			} `json:"data"`
		}
		err = json.NewDecoder(res.Body).Decode(&resp)
		require.NoError(t, err)

		category1ID = resp.Data.ID
		assert.NotEmpty(t, category1ID)
		assert.Equal(t, "Makan Pokok", resp.Data.Name)
		assert.Equal(t, "#8DB355", resp.Data.Color)
		assert.False(t, resp.Data.IsWants)
	})

	// Step 12: Create Category 2 (Wants)
	t.Run("Create Category 2 (Wants)", func(t *testing.T) {
		payload := map[string]interface{}{
			"name":     "Ngopi & Kafe",
			"icon":     "coffee",
			"color":    "#FFEA93",
			"is_wants": true,
		}
		res, err := env.DoAuthRequest(token, http.MethodPost, "/api/v1/categories", payload)
		require.NoError(t, err)
		assert.Equal(t, http.StatusCreated, res.StatusCode)

		var resp struct {
			Data struct {
				IsWants bool `json:"is_wants"`
			} `json:"data"`
		}
		err = json.NewDecoder(res.Body).Decode(&resp)
		require.NoError(t, err)
		assert.True(t, resp.Data.IsWants)
	})

	// Step 13: List Categories
	t.Run("List Categories", func(t *testing.T) {
		res, err := env.DoAuthRequest(token, http.MethodGet, "/api/v1/categories", nil)
		require.NoError(t, err)
		assert.Equal(t, http.StatusOK, res.StatusCode)

		var resp struct {
			Data []map[string]interface{} `json:"data"`
		}
		err = json.NewDecoder(res.Body).Decode(&resp)
		require.NoError(t, err)
		assert.Len(t, resp.Data, 2)
	})

	// Step 14: Update Category
	t.Run("Update Category Metadata via PUT", func(t *testing.T) {
		payload := map[string]interface{}{
			"name":     "Makan & Minum Pokok",
			"icon":     "bowl-food",
			"color":    "#D90000",
			"is_wants": false,
		}
		res, err := env.DoAuthRequest(token, http.MethodPut, "/api/v1/categories/"+category1ID, payload)
		require.NoError(t, err)
		assert.Equal(t, http.StatusOK, res.StatusCode)

		var resp struct {
			Data struct {
				Name    string `json:"name"`
				Icon    string `json:"icon"`
				Color   string `json:"color"`
				IsWants bool   `json:"is_wants"`
			} `json:"data"`
		}
		err = json.NewDecoder(res.Body).Decode(&resp)
		require.NoError(t, err)
		assert.Equal(t, "Makan & Minum Pokok", resp.Data.Name)
		assert.Equal(t, "bowl-food", resp.Data.Icon)
		assert.Equal(t, "#D90000", resp.Data.Color)
	})

	// Step 15: Soft Delete Account
	t.Run("Soft Delete Account", func(t *testing.T) {
		res, err := env.DoAuthRequest(token, http.MethodDelete, "/api/v1/accounts/"+account1ID, nil)
		require.NoError(t, err)
		assert.Equal(t, http.StatusNoContent, res.StatusCode)

		// Subsequent GET returns 404
		resGet, err := env.DoAuthRequest(token, http.MethodGet, "/api/v1/accounts/"+account1ID, nil)
		require.NoError(t, err)
		assert.Equal(t, http.StatusNotFound, resGet.StatusCode)

		// Listing accounts only returns 1 remaining account
		resList, err := env.DoAuthRequest(token, http.MethodGet, "/api/v1/accounts", nil)
		require.NoError(t, err)
		var resp struct {
			Data []map[string]interface{} `json:"data"`
		}
		err = json.NewDecoder(resList.Body).Decode(&resp)
		require.NoError(t, err)
		assert.Len(t, resp.Data, 1)
	})

	// Step 16: Soft Delete Category
	t.Run("Soft Delete Category", func(t *testing.T) {
		res, err := env.DoAuthRequest(token, http.MethodDelete, "/api/v1/categories/"+category1ID, nil)
		require.NoError(t, err)
		assert.Equal(t, http.StatusNoContent, res.StatusCode)

		// Subsequent GET returns 404
		resGet, err := env.DoAuthRequest(token, http.MethodGet, "/api/v1/categories/"+category1ID, nil)
		require.NoError(t, err)
		assert.Equal(t, http.StatusNotFound, resGet.StatusCode)

		// Listing categories only returns 1 remaining category
		resList, err := env.DoAuthRequest(token, http.MethodGet, "/api/v1/categories", nil)
		require.NoError(t, err)
		var resp struct {
			Data []map[string]interface{} `json:"data"`
		}
		err = json.NewDecoder(resList.Body).Decode(&resp)
		require.NoError(t, err)
		assert.Len(t, resp.Data, 1)
	})
}
