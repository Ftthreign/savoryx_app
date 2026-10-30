package http

import (
	"log/slog"
	"time"

	"github.com/ftthreign/savoryx_app/server/internal/port"
	"github.com/go-chi/chi/v5"
	"github.com/go-chi/chi/v5/middleware"
)

func SetupRouter(logger *slog.Logger, healthService port.HealthService, appVersion, appEnv string) *chi.Mux {
	r := chi.NewRouter()

	r.Use(middleware.RequestID)
	r.Use(middleware.RealIP)
	r.Use(StructuredLogger(logger))
	r.Use(OopsRecoverer(logger))
	r.Use(CORS)
	r.Use(middleware.Timeout(30 * time.Second))

	healthHandler := NewHealthHandler(healthService, appVersion, appEnv)

	r.Get("/healthz", healthHandler.Readiness)
	r.Get("/livez", healthHandler.Liveness)

	r.Route("/api/v1", func(api chi.Router) {
		api.Get("/ping", healthHandler.Ping)
	})

	return r
}
