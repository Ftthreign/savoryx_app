package security

import (
	"crypto/rand"
	"crypto/sha256"
	"crypto/subtle"
	"encoding/base64"
	"encoding/hex"
	"errors"
	"fmt"
	"strings"
	"time"

	"aidanwoods.dev/go-paseto"
	"github.com/ftthreign/savoryx_app/server/internal/core/domain"
	"github.com/ftthreign/savoryx_app/server/internal/port"
	"github.com/samber/oops"
)

type PasetoTokenManager struct {
	key paseto.V4SymmetricKey
}

func NewPasetoTokenManager(symmetricKeyHex string) (*PasetoTokenManager, error) {
	if symmetricKeyHex == "" {
		key := paseto.NewV4SymmetricKey()
		return &PasetoTokenManager{key: key}, nil
	}

	key, err := paseto.V4SymmetricKeyFromHex(symmetricKeyHex)
	if err != nil {
		return nil, oops.
			In("security").
			Tags("paseto", "crypto").
			Code("ERR_INVALID_SYMMETRIC_KEY").
			Wrapf(err, "invalid 256-bit hex symmetric key for PASETO v4 local")
	}

	return &PasetoTokenManager{key: key}, nil
}

func (m *PasetoTokenManager) GenerateDeviceToken(deviceID domain.UUID, ttl time.Duration) (string, error) {
	if deviceID.IsZero() {
		return "", oops.
			In("security").
			Tags("paseto").
			Code("ERR_DEVICE_ID_ZERO").
			Wrap(domain.ErrInvalidInput)
	}

	if ttl == 0 {
		ttl = 30 * 24 * time.Hour
	}

	token := paseto.NewToken()
	now := time.Now().UTC()
	token.SetIssuedAt(now)
	token.SetNotBefore(now)
	token.SetExpiration(now.Add(ttl))

	err := token.Set("device_id", deviceID.String())
	if err != nil {
		return "", oops.
			In("security").
			Tags("paseto").
			Code("ERR_SET_CLAIM").
			Wrapf(err, "failed to set device_id claim")
	}

	encrypted := token.V4Encrypt(m.key, nil)
	return encrypted, nil
}

func (m *PasetoTokenManager) VerifyDeviceToken(tokenString string) (*port.DeviceClaims, error) {
	trimmed := strings.TrimSpace(tokenString)
	if trimmed == "" {
		return nil, oops.
			In("security").
			Tags("paseto").
			Code("ERR_TOKEN_EMPTY").
			Wrap(domain.ErrInvalidToken)
	}

	parser := paseto.NewParser()
	parsedToken, err := parser.ParseV4Local(m.key, trimmed, nil)
	if err != nil {
		errLower := strings.ToLower(err.Error())
		if strings.Contains(errLower, "expired") || strings.Contains(errLower, "past") {
			return nil, oops.
				In("security").
				Tags("paseto").
				Code("ERR_TOKEN_EXPIRED").
				Wrap(domain.ErrTokenExpired)
		}
		return nil, oops.
			In("security").
			Tags("paseto").
			Code("ERR_TOKEN_VERIFICATION_FAILED").
			Wrap(errors.Join(domain.ErrInvalidToken, err))
	}

	var deviceIDStr string
	err = parsedToken.Get("device_id", &deviceIDStr)
	if err != nil || deviceIDStr == "" {
		return nil, oops.
			In("security").
			Tags("paseto").
			Code("ERR_MISSING_DEVICE_ID_CLAIM").
			Wrap(domain.ErrInvalidToken)
	}

	parsedID, err := domain.ParseUUID(deviceIDStr)
	if err != nil {
		return nil, oops.
			In("security").
			Tags("paseto").
			Code("ERR_MALFORMED_DEVICE_ID_CLAIM").
			Wrap(domain.ErrInvalidToken)
	}

	issuedAt, err := parsedToken.GetIssuedAt()
	if err != nil {
		issuedAt = time.Now().UTC()
	}

	expiresAt, err := parsedToken.GetExpiration()
	if err != nil {
		expiresAt = time.Now().UTC()
	}

	return &port.DeviceClaims{
		DeviceID:  parsedID,
		IssuedAt:  issuedAt,
		ExpiresAt: expiresAt,
	}, nil
}

func (m *PasetoTokenManager) ExportKeyHex() string {
	return m.key.ExportHex()
}

func GenerateDeviceSecret() (string, error) {
	buf := make([]byte, 32)
	_, err := rand.Read(buf)
	if err != nil {
		return "", fmt.Errorf("failed to read secure random bytes: %w", err)
	}
	return base64.StdEncoding.EncodeToString(buf), nil
}

func HashDeviceSecret(secret string) string {
	h := sha256.Sum256([]byte(secret))
	return hex.EncodeToString(h[:])
}

func VerifyDeviceSecret(secret, expectedHash string) bool {
	computedHash := HashDeviceSecret(secret)
	return subtle.ConstantTimeCompare([]byte(computedHash), []byte(expectedHash)) == 1
}

var _ port.TokenManager = (*PasetoTokenManager)(nil)
