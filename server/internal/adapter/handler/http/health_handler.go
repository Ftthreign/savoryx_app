package http

import (
	"net/http"
	"time"

	"github.com/ftthreign/savoryx_app/server/internal/port"
)

type HealthHandler struct {
	healthService port.HealthService
	appVersion    string
	appEnv        string
	startTime     time.Time
}

func NewHealthHandler(healthService port.HealthService, appVersion, appEnv string) *HealthHandler {
	return &HealthHandler{
		healthService: healthService,
		appVersion:    appVersion,
		appEnv:        appEnv,
		startTime:     time.Now().UTC(),
	}
}

func (h *HealthHandler) Readiness(w http.ResponseWriter, r *http.Request) {
	status, err := h.healthService.CheckHealth(r.Context())

	dbStatus := "connected"
	httpStatus := http.StatusOK

	if err != nil || status != "healthy" {
		dbStatus = "disconnected"
		httpStatus = http.StatusServiceUnavailable
	}

	payload := map[string]any{
		"status":   status,
		"service":  "savoryx-api",
		"version":  h.appVersion,
		"env":      h.appEnv,
		"database": dbStatus,
	}

	WriteJSON(w, httpStatus, payload)
}

func (h *HealthHandler) Liveness(w http.ResponseWriter, r *http.Request) {
	payload := map[string]any{
		"status":         "alive",
		"service":        "savoryx-api",
		"uptime_seconds": int(time.Since(h.startTime).Seconds()),
	}

	WriteJSON(w, http.StatusOK, payload)
}

// Ping provides a lightweight endpoint for latency and connectivity testing.
func (h *HealthHandler) Ping(w http.ResponseWriter, r *http.Request) {
	payload := map[string]any{
		"message":   "pong",
		"timestamp": time.Now().UTC().Format(time.RFC3339),
	}

	WriteJSON(w, http.StatusOK, payload)
}
