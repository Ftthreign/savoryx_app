package http

import (
	"encoding/json"
	"errors"
	"fmt"
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
	_ = json.NewEncoder(w).Encode(envelope)
}

func WriteJSONWithMeta(w http.ResponseWriter, status int, data any, meta any) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)

	envelope := ResponseEnvelope{Data: data, Meta: meta}
	_ = json.NewEncoder(w).Encode(envelope)
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
	_ = json.NewEncoder(w).Encode(envelope)
}

func WriteDomainError(w http.ResponseWriter, err error) {
	if err == nil {
		return
	}

	statusCode := http.StatusInternalServerError
	errorCode := "internal_error"
	errorMessage := "An unexpected error occurred"

	if oopsErr, ok := err.(oops.OopsError); ok {
		if code := fmt.Sprintf("%v", oopsErr.Code()); code != "" && code != "<nil>" {
			errorCode = code
		}
	}

	switch {
	case errors.Is(err, domain.ErrNotFound),
		errors.Is(err, domain.ErrAccountNotFound),
		errors.Is(err, domain.ErrCategoryNotFound),
		errors.Is(err, domain.ErrPreferenceNotFound):
		statusCode = http.StatusNotFound
		if errorCode == "internal_error" {
			errorCode = "not_found"
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
