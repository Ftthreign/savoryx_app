package test

import (
	"encoding/json"
	"net/http"
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

// TestE2E_ZeroFinancialPrivacyInLogs enforces AGENTS.md Section 4.2:
// Zero Financial Detail in Logs. Monetary values, account balances, secrets,
// and private financial identifiers must NEVER be leaked to structured server logs.
func TestE2E_ZeroFinancialPrivacyInLogs(t *testing.T) {
	env := setupTestEnvironment(t)
	token, _ := env.RegisterDevice(t, "Privacy Audit Phone", "android", "1.0.0")

	// Create account with distinct secret balance and vault name
	distinctBalance := "87654321.99"
	distinctAccountName := "Secret Hidden Vault"
	accPayload := map[string]string{
		"name":     distinctAccountName,
		"type":     "BANK",
		"currency": "IDR",
		"balance":  distinctBalance,
	}

	resAcc, err := env.DoAuthRequest(token, http.MethodPost, "/api/v1/accounts", accPayload)
	require.NoError(t, err)
	assert.Equal(t, http.StatusCreated, resAcc.StatusCode)

	// Fetch account detail
	var createResp struct {
		Data struct {
			ID string `json:"id"`
		} `json:"data"`
	}
	err = json.NewDecoder(resAcc.Body).Decode(&createResp)
	require.NoError(t, err)

	resGet, err := env.DoAuthRequest(token, http.MethodGet, "/api/v1/accounts/"+createResp.Data.ID, nil)
	require.NoError(t, err)
	assert.Equal(t, http.StatusOK, resGet.StatusCode)

	// Audit captured logs from logBuffer
	loggedContent := env.LogBuffer.String()

	// ASSERTION 1: Zero monetary amounts leaked in logs
	assert.NotContains(t, loggedContent, distinctBalance, "Log MUST NOT leak monetary balances or values")

	// ASSERTION 2: Zero user financial names leaked in logs
	assert.NotContains(t, loggedContent, distinctAccountName, "Log MUST NOT leak user account names or descriptions")

	// ASSERTION 3: Only standard HTTP access metadata is logged
	assert.Contains(t, loggedContent, "http request completed")
	assert.Contains(t, loggedContent, "request_id")
	assert.Contains(t, loggedContent, "method")
	assert.Contains(t, loggedContent, "status")
	assert.Contains(t, loggedContent, "duration")
}
