package http

import (
	"encoding/json"
	"fmt"
	"net/http"

	"github.com/ftthreign/savoryx_app/server/internal/adapter/handler/http/dto"
	"github.com/ftthreign/savoryx_app/server/internal/port"
)

type AuthHandler struct {
	authService port.AuthService
}

func NewAuthHandler(authService port.AuthService) *AuthHandler {
	return &AuthHandler{
		authService: authService,
	}
}

func (h *AuthHandler) RegisterDevice(w http.ResponseWriter, r *http.Request) {
	var req dto.RegisterDeviceRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		WriteError(w, http.StatusBadRequest, "invalid_json", "Failed to parse request JSON body")
		return
	}

	deviceID, err := req.Validate()
	if err != nil {
		WriteError(w, http.StatusBadRequest, "validation_error", err.Error())
		return
	}

	result, err := h.authService.RegisterDevice(
		r.Context(),
		deviceID,
		req.DeviceName,
		req.Platform,
		req.AppVersion,
	)
	if err != nil {
		WriteDomainError(w, err)
		return
	}

	resp := dto.RegisterDeviceResponse{
		DeviceID:     result.Device.ID.String(),
		Token:        result.Token,
		DeviceSecret: result.DeviceSecret,
		ExpiresAt:    result.ExpiresAt,
	}

	w.Header().Set("Location", fmt.Sprintf("/api/v1/devices/%s", result.Device.ID.String()))
	WriteJSON(w, http.StatusCreated, resp)
}
