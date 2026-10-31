package service

import (
	"context"
	"errors"
	"testing"
	"time"

	"github.com/ftthreign/savoryx_app/server/internal/core/domain"
	"github.com/ftthreign/savoryx_app/server/internal/port"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

type mockDeviceRepo struct {
	registerFunc         func(ctx context.Context, dev *domain.Device) error
	getByIDFunc          func(ctx context.Context, id domain.UUID) (*domain.Device, error)
	updateLastActiveFunc func(ctx context.Context, id domain.UUID) error
	revokeFunc           func(ctx context.Context, id domain.UUID) error
}

func (m *mockDeviceRepo) Register(ctx context.Context, dev *domain.Device) error {
	if m.registerFunc != nil {
		return m.registerFunc(ctx, dev)
	}
	return nil
}

func (m *mockDeviceRepo) GetByID(ctx context.Context, id domain.UUID) (*domain.Device, error) {
	if m.getByIDFunc != nil {
		return m.getByIDFunc(ctx, id)
	}
	return nil, nil
}

func (m *mockDeviceRepo) UpdateLastActive(ctx context.Context, id domain.UUID) error {
	if m.updateLastActiveFunc != nil {
		return m.updateLastActiveFunc(ctx, id)
	}
	return nil
}

func (m *mockDeviceRepo) Revoke(ctx context.Context, id domain.UUID) error {
	if m.revokeFunc != nil {
		return m.revokeFunc(ctx, id)
	}
	return nil
}

var _ port.DeviceRepository = (*mockDeviceRepo)(nil)

type mockTokenManager struct {
	generateTokenFunc  func(deviceID domain.UUID, ttl time.Duration) (string, error)
	verifyTokenFunc    func(tokenString string) (*port.DeviceClaims, error)
	generateSecretFunc func() (string, error)
	hashSecretFunc     func(secret string) string
	verifySecretFunc   func(secret, expectedHash string) bool
}

func (m *mockTokenManager) GenerateDeviceToken(deviceID domain.UUID, ttl time.Duration) (string, error) {
	if m.generateTokenFunc != nil {
		return m.generateTokenFunc(deviceID, ttl)
	}
	return "mock.v4.local.token", nil
}

func (m *mockTokenManager) VerifyDeviceToken(tokenString string) (*port.DeviceClaims, error) {
	if m.verifyTokenFunc != nil {
		return m.verifyTokenFunc(tokenString)
	}
	return nil, nil
}

func (m *mockTokenManager) GenerateDeviceSecret() (string, error) {
	if m.generateSecretFunc != nil {
		return m.generateSecretFunc()
	}
	return "mock-secret-base64-string", nil
}

func (m *mockTokenManager) HashDeviceSecret(secret string) string {
	if m.hashSecretFunc != nil {
		return m.hashSecretFunc(secret)
	}
	return "mock-hashed-secret-hex"
}

func (m *mockTokenManager) VerifyDeviceSecret(secret, expectedHash string) bool {
	if m.verifySecretFunc != nil {
		return m.verifySecretFunc(secret, expectedHash)
	}
	return true
}

var _ port.TokenManager = (*mockTokenManager)(nil)

func TestAuthService_RegisterDevice_HappyPath(t *testing.T) {
	deviceID, err := domain.ParseUUID("0192d6e2-5b9c-7000-8000-000000000001")
	require.NoError(t, err)

	var registeredDevice *domain.Device
	repo := &mockDeviceRepo{
		registerFunc: func(ctx context.Context, dev *domain.Device) error {
			registeredDevice = dev
			return nil
		},
	}

	tokenMgr := &mockTokenManager{}
	svc := NewAuthService(repo, tokenMgr)

	ctx := context.Background()
	result, err := svc.RegisterDevice(ctx, deviceID, "Pixel 8 Pro", "android", "1.0.0")

	require.NoError(t, err)
	require.NotNil(t, result)
	assert.Equal(t, deviceID, result.Device.ID)
	assert.Equal(t, "Pixel 8 Pro", result.Device.DeviceName)
	assert.Equal(t, "android", result.Device.Platform)
	assert.Equal(t, "1.0.0", result.Device.AppVersion)
	assert.NotEmpty(t, result.Token)
	assert.NotEmpty(t, result.DeviceSecret)
	assert.True(t, result.ExpiresAt.After(time.Now()))
	assert.Equal(t, registeredDevice, result.Device)
}

func TestAuthService_RegisterDevice_ValidationGuards(t *testing.T) {
	validID, _ := domain.ParseUUID("0192d6e2-5b9c-7000-8000-000000000001")
	repo := &mockDeviceRepo{}
	tokenMgr := &mockTokenManager{}
	svc := NewAuthService(repo, tokenMgr)
	ctx := context.Background()

	t.Run("zero device ID", func(t *testing.T) {
		_, err := svc.RegisterDevice(ctx, domain.NilUUID, "Phone", "android", "1.0.0")
		assert.Error(t, err)
		assert.True(t, errors.Is(err, domain.ErrInvalidInput))
	})

	t.Run("empty device name", func(t *testing.T) {
		_, err := svc.RegisterDevice(ctx, validID, "   ", "android", "1.0.0")
		assert.Error(t, err)
		assert.True(t, errors.Is(err, domain.ErrInvalidInput))
	})

	t.Run("empty platform", func(t *testing.T) {
		_, err := svc.RegisterDevice(ctx, validID, "Phone", "   ", "1.0.0")
		assert.Error(t, err)
		assert.True(t, errors.Is(err, domain.ErrInvalidInput))
	})

	t.Run("empty app version", func(t *testing.T) {
		_, err := svc.RegisterDevice(ctx, validID, "Phone", "android", "   ")
		assert.Error(t, err)
		assert.True(t, errors.Is(err, domain.ErrInvalidInput))
	})
}

func TestAuthService_RegisterDevice_RepoError(t *testing.T) {
	validID, _ := domain.ParseUUID("0192d6e2-5b9c-7000-8000-000000000001")
	dbErr := errors.New("db connection lost")
	repo := &mockDeviceRepo{
		registerFunc: func(ctx context.Context, dev *domain.Device) error {
			return dbErr
		},
	}
	tokenMgr := &mockTokenManager{}
	svc := NewAuthService(repo, tokenMgr)

	_, err := svc.RegisterDevice(context.Background(), validID, "Phone", "android", "1.0.0")
	assert.Error(t, err)
	assert.True(t, errors.Is(err, dbErr))
}

func TestAuthService_RegisterDevice_TokenManagerError(t *testing.T) {
	validID, _ := domain.ParseUUID("0192d6e2-5b9c-7000-8000-000000000001")
	repo := &mockDeviceRepo{}
	tokenErr := errors.New("crypto entropy exhausted")
	tokenMgr := &mockTokenManager{
		generateTokenFunc: func(deviceID domain.UUID, ttl time.Duration) (string, error) {
			return "", tokenErr
		},
	}
	svc := NewAuthService(repo, tokenMgr)

	_, err := svc.RegisterDevice(context.Background(), validID, "Phone", "android", "1.0.0")
	assert.Error(t, err)
	assert.True(t, errors.Is(err, tokenErr))
}
