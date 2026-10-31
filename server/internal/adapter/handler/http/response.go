package http

import (
	"encoding/json"
	"errors"
	"fmt"
	"log/slog"
	"net/http"

	"github.com/ftthreign/savoryx_app/server/internal/core/domain"
	"github.com/samber/oops"
)

type ResponseEnvelope struct {
	Data any `json:"data"`
	Meta any `json:"meta,omitempty"`
}

type ErrorDetail struct {
	Field   string `json:"field"`
	Message string `json:"message"`
	Code    string `json:"code,omitempty"`
}

type ErrorEnvelope struct {
	Error ErrorBody `json:"error"`
}

type ErrorBody struct {
	Code    string        `json:"code"`
	Message string        `json:"message"`
	Details []ErrorDetail `json:"details,omitempty"`
}

func WriteJSON(w http.ResponseWriter, status int, data any) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)

	envelope := ResponseEnvelope{Data: data}
	if err := json.NewEncoder(w).Encode(envelope); err != nil {
		slog.Error("failed to encode response json", "status", status, "error", err)
	}
}

func WriteJSONWithMeta(w http.ResponseWriter, status int, data any, meta any) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)

	envelope := ResponseEnvelope{Data: data, Meta: meta}
	if err := json.NewEncoder(w).Encode(envelope); err != nil {
		slog.Error("failed to encode response json with meta", "status", status, "error", err)
	}
}

func WriteError(w http.ResponseWriter, status int, code, message string) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)

	envelope := ErrorEnvelope{
		Error: ErrorBody{
			Code:    code,
			Message: message,
		},
	}
	if err := json.NewEncoder(w).Encode(envelope); err != nil {
		slog.Error("failed to encode error response json", "status", status, "code", code, "error", err)
	}
}

func WriteDomainError(w http.ResponseWriter, err error) {
	if err == nil {
		return
	}

	statusCode := http.StatusInternalServerError
	errorCode := "internal_error"
	errorMessage := "An unexpected error occurred"

	var oopsErr oops.OopsError
	if errors.As(err, &oopsErr) {
		if code := fmt.Sprintf("%v", oopsErr.Code()); code != "" && code != "<nil>" {
			errorCode = code
		}
	}

	switch {
	case errors.Is(err, domain.ErrNotFound),
		errors.Is(err, domain.ErrAccountNotFound),
		errors.Is(err, domain.ErrCategoryNotFound),
		errors.Is(err, domain.ErrPreferenceNotFound),
		errors.Is(err, domain.ErrDeviceNotFound):
		statusCode = http.StatusNotFound
		if errorCode == "internal_error" {
			errorCode = "not_found"
		}
		errorMessage = err.Error()

	case errors.Is(err, domain.ErrDeviceRevoked):
		statusCode = http.StatusForbidden
		if errorCode == "internal_error" {
			errorCode = "forbidden"
		}
		errorMessage = err.Error()

	case errors.Is(err, domain.ErrInvalidToken),
		errors.Is(err, domain.ErrTokenExpired):
		statusCode = http.StatusUnauthorized
		if errorCode == "internal_error" {
			errorCode = "unauthorized"
		}
		errorMessage = err.Error()

	case errors.Is(err, domain.ErrInvalidInput):
		statusCode = http.StatusBadRequest
		if errorCode == "internal_error" {
			errorCode = "invalid_input"
		}
		errorMessage = err.Error()

	case errors.Is(err, domain.ErrDatabaseUnavailable):
		statusCode = http.StatusServiceUnavailable
		if errorCode == "internal_error" {
			errorCode = "service_unavailable"
		}
		errorMessage = "Database service is temporarily unavailable"

	default:
		statusCode = http.StatusInternalServerError
		errorCode = "internal_error"
		errorMessage = "Internal server error"
	}

	WriteError(w, statusCode, errorCode, errorMessage)
}
