package security

import (
	"errors"
	"strings"
	"testing"
	"time"

	"github.com/ftthreign/savoryx_app/server/internal/core/domain"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

func TestPasetoTokenManager_GenerateAndVerify_HappyPath(t *testing.T) {
	manager, err := NewPasetoTokenManager("")
	require.NoError(t, err)
	require.NotNil(t, manager)

	deviceID, err := domain.ParseUUID("0192d6e2-5b9c-7000-8000-000000000001")
	require.NoError(t, err)
	ttl := 2 * time.Hour

	tokenString, err := manager.GenerateDeviceToken(deviceID, ttl)
	require.NoError(t, err)
	assert.NotEmpty(t, tokenString)
	assert.True(t, strings.HasPrefix(tokenString, "v4.local."), "PASETO v4 local tokens must have prefix v4.local.")

	claims, err := manager.VerifyDeviceToken(tokenString)
	require.NoError(t, err)
	require.NotNil(t, claims)

	assert.Equal(t, deviceID, claims.DeviceID)
	assert.False(t, claims.IssuedAt.IsZero())
	assert.False(t, claims.ExpiresAt.IsZero())
	assert.True(t, claims.ExpiresAt.After(claims.IssuedAt))
}

func TestPasetoTokenManager_KeyExportAndReload(t *testing.T) {
	manager1, err := NewPasetoTokenManager("")
	require.NoError(t, err)

	hexKey := manager1.ExportKeyHex()
	assert.NotEmpty(t, hexKey)
	assert.Equal(t, 64, len(hexKey), "256-bit key in hex must be 64 characters")

	manager2, err := NewPasetoTokenManager(hexKey)
	require.NoError(t, err)

	deviceID, err := domain.ParseUUID("0192d6e2-5b9c-7000-8000-000000000001")
	require.NoError(t, err)
	token, err := manager1.GenerateDeviceToken(deviceID, 1*time.Hour)
	require.NoError(t, err)

	claims, err := manager2.VerifyDeviceToken(token)
	require.NoError(t, err)
	assert.Equal(t, deviceID, claims.DeviceID)
}

func TestPasetoTokenManager_InvalidHexKey(t *testing.T) {
	_, err := NewPasetoTokenManager("invalid_hex_string_not_64_chars")
	assert.Error(t, err)
}

func TestPasetoTokenManager_ZeroDeviceID(t *testing.T) {
	manager, err := NewPasetoTokenManager("")
	require.NoError(t, err)

	zeroID := domain.UUID{}
	_, err = manager.GenerateDeviceToken(zeroID, 1*time.Hour)
	require.Error(t, err)
	assert.True(t, errors.Is(err, domain.ErrInvalidInput))
}

func TestPasetoTokenManager_ExpiredToken(t *testing.T) {
	manager, err := NewPasetoTokenManager("")
	require.NoError(t, err)

	deviceID, err := domain.ParseUUID("0192d6e2-5b9c-7000-8000-000000000001")
	require.NoError(t, err)
	// Generate token with negative duration so it expires immediately
	tokenString, err := manager.GenerateDeviceToken(deviceID, -1*time.Minute)
	require.NoError(t, err)

	// Sleep tiny moment to guarantee expiration
	time.Sleep(5 * time.Millisecond)

	claims, err := manager.VerifyDeviceToken(tokenString)
	assert.Error(t, err)
	assert.Nil(t, claims)
	assert.True(t, errors.Is(err, domain.ErrTokenExpired), "expected ErrTokenExpired, got: %v", err)
}

func TestPasetoTokenManager_TamperedToken(t *testing.T) {
	manager, err := NewPasetoTokenManager("")
	require.NoError(t, err)

	deviceID, err := domain.ParseUUID("0192d6e2-5b9c-7000-8000-000000000001")
	require.NoError(t, err)
	tokenString, err := manager.GenerateDeviceToken(deviceID, 1*time.Hour)
	require.NoError(t, err)

	// Tamper token payload by replacing last character
	runes := []rune(tokenString)
	if runes[len(runes)-1] == 'a' {
		runes[len(runes)-1] = 'b'
	} else {
		runes[len(runes)-1] = 'a'
	}
	tampered := string(runes)

	claims, err := manager.VerifyDeviceToken(tampered)
	assert.Error(t, err)
	assert.Nil(t, claims)
	assert.True(t, errors.Is(err, domain.ErrInvalidToken))
}

func TestPasetoTokenManager_DifferentKey(t *testing.T) {
	managerA, err := NewPasetoTokenManager("")
	require.NoError(t, err)

	managerB, err := NewPasetoTokenManager("")
	require.NoError(t, err)

	deviceID, err := domain.ParseUUID("0192d6e2-5b9c-7000-8000-000000000001")
	require.NoError(t, err)
	tokenFromA, err := managerA.GenerateDeviceToken(deviceID, 1*time.Hour)
	require.NoError(t, err)

	claims, err := managerB.VerifyDeviceToken(tokenFromA)
	assert.Error(t, err)
	assert.Nil(t, claims)
	assert.True(t, errors.Is(err, domain.ErrInvalidToken))
}

func TestPasetoTokenManager_EmptyToken(t *testing.T) {
	manager, err := NewPasetoTokenManager("")
	require.NoError(t, err)

	claims, err := manager.VerifyDeviceToken("   ")
	assert.Error(t, err)
	assert.Nil(t, claims)
	assert.True(t, errors.Is(err, domain.ErrInvalidToken))
}

func TestDeviceSecret_Utilities(t *testing.T) {
	secret1, err := GenerateDeviceSecret()
	require.NoError(t, err)
	assert.NotEmpty(t, secret1)
	assert.Equal(t, 44, len(secret1), "32 bytes base64 encoded should be 44 characters")

	secret2, err := GenerateDeviceSecret()
	require.NoError(t, err)
	assert.NotEqual(t, secret1, secret2, "two generated secrets must be distinct")

	hash1 := HashDeviceSecret(secret1)
	assert.Equal(t, 64, len(hash1), "SHA-256 hex string must be 64 characters")

	// Verification
	assert.True(t, VerifyDeviceSecret(secret1, hash1))
	assert.False(t, VerifyDeviceSecret(secret2, hash1))
	assert.False(t, VerifyDeviceSecret("wrong-secret", hash1))
}
