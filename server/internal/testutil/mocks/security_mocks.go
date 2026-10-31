package mocks

import (
	"time"

	"github.com/ftthreign/savoryx_app/server/internal/core/domain"
	"github.com/ftthreign/savoryx_app/server/internal/port"
)

// MockTokenManager implements port.TokenManager for unit testing.
type MockTokenManager struct {
	GenerateDeviceTokenFunc func(deviceID domain.UUID, ttl time.Duration) (string, error)
	VerifyDeviceTokenFunc   func(tokenString string) (*port.DeviceClaims, error)
	GenerateDeviceSecretFunc func() (string, error)
	HashDeviceSecretFunc    func(secret string) string
	VerifyDeviceSecretFunc  func(secret, expectedHash string) bool
}

func (m *MockTokenManager) GenerateDeviceToken(deviceID domain.UUID, ttl time.Duration) (string, error) {
	if m.GenerateDeviceTokenFunc != nil {
		return m.GenerateDeviceTokenFunc(deviceID, ttl)
	}
	return "mock.v4.local.token", nil
}

func (m *MockTokenManager) VerifyDeviceToken(tokenString string) (*port.DeviceClaims, error) {
	if m.VerifyDeviceTokenFunc != nil {
		return m.VerifyDeviceTokenFunc(tokenString)
	}
	return nil, nil
}

func (m *MockTokenManager) GenerateDeviceSecret() (string, error) {
	if m.GenerateDeviceSecretFunc != nil {
		return m.GenerateDeviceSecretFunc()
	}
	return "mock-secret-base64-string", nil
}

func (m *MockTokenManager) HashDeviceSecret(secret string) string {
	if m.HashDeviceSecretFunc != nil {
		return m.HashDeviceSecretFunc(secret)
	}
	return "mock-hashed-secret-hex"
}

func (m *MockTokenManager) VerifyDeviceSecret(secret, expectedHash string) bool {
	if m.VerifyDeviceSecretFunc != nil {
		return m.VerifyDeviceSecretFunc(secret, expectedHash)
	}
	return true
}

var _ port.TokenManager = (*MockTokenManager)(nil)
