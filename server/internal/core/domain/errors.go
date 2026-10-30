package domain

import "errors"

var (
	ErrInternal = errors.New("internal server error")
	ErrDatabaseUnavailable = errors.New("database connection unavailable")
	ErrNotFound = errors.New("resource not found")
	ErrInvalidInput = errors.New("invalid input parameter")
)
