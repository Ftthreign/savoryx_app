package service

import (
	"context"
	"strings"
	"time"

	"github.com/ftthreign/savoryx_app/server/internal/core/domain"
	"github.com/ftthreign/savoryx_app/server/internal/port"
	"github.com/samber/oops"
)

type AuthService struct {
	deviceRepo   port.DeviceRepository
	tokenManager port.TokenManager
}

func NewAuthService(deviceRepo port.DeviceRepository, tokenManager port.TokenManager) *AuthService {
	return &AuthService{
		deviceRepo:   deviceRepo,
		tokenManager: tokenManager,
	}
}

func (s *AuthService) RegisterDevice(
	ctx context.Context,
	id domain.UUID,
	deviceName, platform, appVersion string,
) (*port.DeviceRegistrationResult, error) {
	if id.IsZero() {
		return nil, oops.
			In("auth_service").
			Code("ERR_DEVICE_ID_REQUIRED").
			Wrap(domain.ErrInvalidInput)
	}

	trimmedName := strings.TrimSpace(deviceName)
	if trimmedName == "" {
		return nil, oops.
			In("auth_service").
			Code("ERR_DEVICE_NAME_REQUIRED").
			Wrap(domain.ErrInvalidInput)
	}

	trimmedPlatform := strings.TrimSpace(platform)
	if trimmedPlatform == "" {
		return nil, oops.
			In("auth_service").
			Code("ERR_PLATFORM_REQUIRED").
			Wrap(domain.ErrInvalidInput)
	}

	trimmedVersion := strings.TrimSpace(appVersion)
	if trimmedVersion == "" {
		return nil, oops.
			In("auth_service").
			Code("ERR_APP_VERSION_REQUIRED").
			Wrap(domain.ErrInvalidInput)
	}

	secret, err := s.tokenManager.GenerateDeviceSecret()
	if err != nil {
		return nil, oops.
			In("auth_service").
			Code("ERR_GENERATE_SECRET_FAILED").
			Wrapf(err, "failed to generate device secret")
	}

	secretHash := s.tokenManager.HashDeviceSecret(secret)

	dev := &domain.Device{
		ID:               id,
		DeviceName:       trimmedName,
		Platform:         trimmedPlatform,
		AppVersion:       trimmedVersion,
		DeviceSecretHash: secretHash,
	}

	if err := s.deviceRepo.Register(ctx, dev); err != nil {
		return nil, oops.
			In("auth_service").
			Code("ERR_REGISTER_DEVICE_FAILED").
			Wrap(err)
	}

	ttl := 30 * 24 * time.Hour
	token, err := s.tokenManager.GenerateDeviceToken(id, ttl)
	if err != nil {
		return nil, oops.
			In("auth_service").
			Code("ERR_GENERATE_TOKEN_FAILED").
			Wrapf(err, "failed to generate auth token")
	}

	return &port.DeviceRegistrationResult{
		Device:       dev,
		Token:        token,
		DeviceSecret: secret,
		ExpiresAt:    time.Now().UTC().Add(ttl),
	}, nil
}

var _ port.AuthService = (*AuthService)(nil)
