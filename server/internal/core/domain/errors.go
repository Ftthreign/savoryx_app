package domain

import "errors"

var (
	ErrInternal            = errors.New("internal server error")
	ErrDatabaseUnavailable = errors.New("database connection unavailable")
	ErrNotFound            = errors.New("resource not found")
	ErrInvalidInput        = errors.New("invalid input parameter")
	ErrAccountNotFound     = errors.New("account not found")
	ErrCategoryNotFound    = errors.New("category not found")
	ErrPreferenceNotFound  = errors.New("user preference not found")
	ErrDeviceNotFound      = errors.New("device not found")
	ErrDeviceRevoked       = errors.New("device authorization has been revoked")
	ErrInvalidToken        = errors.New("invalid or malformed authorization token")
	ErrTokenExpired        = errors.New("authorization token has expired")
	ErrUnauthorized        = errors.New("unauthorized: missing or invalid authentication credentials")
)

