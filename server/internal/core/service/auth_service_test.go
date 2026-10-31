package service_test

import (
	"context"
	"errors"
	"testing"
	"time"

	"github.com/ftthreign/savoryx_app/server/internal/core/domain"
	"github.com/ftthreign/savoryx_app/server/internal/core/service"
	"github.com/ftthreign/savoryx_app/server/internal/testutil"
	"github.com/ftthreign/savoryx_app/server/internal/testutil/mocks"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

func TestAuthService_RegisterDevice_HappyPath(t *testing.T) {
	deviceID := testutil.DefaultDeviceID

	var registeredDevice *domain.Device
	repo := &mocks.MockDeviceRepository{
		RegisterFunc: func(ctx context.Context, dev *domain.Device) error {
			registeredDevice = dev
			return nil
		},
	}

	tokenMgr := &mocks.MockTokenManager{}
	svc := service.NewAuthService(repo, tokenMgr)

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
	validID := testutil.DefaultDeviceID
	repo := &mocks.MockDeviceRepository{}
	tokenMgr := &mocks.MockTokenManager{}
	svc := service.NewAuthService(repo, tokenMgr)
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
	validID := testutil.DefaultDeviceID
	dbErr := errors.New("db connection lost")
	repo := &mocks.MockDeviceRepository{
		RegisterFunc: func(ctx context.Context, dev *domain.Device) error {
			return dbErr
		},
	}
	tokenMgr := &mocks.MockTokenManager{}
	svc := service.NewAuthService(repo, tokenMgr)

	_, err := svc.RegisterDevice(context.Background(), validID, "Phone", "android", "1.0.0")
	assert.Error(t, err)
	assert.True(t, errors.Is(err, dbErr))
}

func TestAuthService_RegisterDevice_TokenManagerError(t *testing.T) {
	validID := testutil.DefaultDeviceID
	repo := &mocks.MockDeviceRepository{}
	tokenErr := errors.New("crypto entropy exhausted")
	tokenMgr := &mocks.MockTokenManager{
		GenerateDeviceTokenFunc: func(deviceID domain.UUID, ttl time.Duration) (string, error) {
			return "", tokenErr
		},
	}
	svc := service.NewAuthService(repo, tokenMgr)

	_, err := svc.RegisterDevice(context.Background(), validID, "Phone", "android", "1.0.0")
	assert.Error(t, err)
	assert.True(t, errors.Is(err, tokenErr))
}
