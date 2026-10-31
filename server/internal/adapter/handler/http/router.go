package http

import (
	"log/slog"
	"time"

	"github.com/ftthreign/savoryx_app/server/internal/port"
	"github.com/go-chi/chi/v5"
	"github.com/go-chi/chi/v5/middleware"
)

type RouterOptions struct {
	AuthService port.AuthService
}

type RouterOption func(*RouterOptions)

func WithAuthService(authService port.AuthService) RouterOption {
	return func(o *RouterOptions) {
		o.AuthService = authService
	}
}

func SetupRouter(
	logger *slog.Logger,
	healthService port.HealthService,
	appVersion, appEnv string,
	opts ...RouterOption,
) *chi.Mux {
	options := &RouterOptions{}
	for _, opt := range opts {
		opt(options)
	}

	r := chi.NewRouter()

	r.Use(middleware.RequestID)
	r.Use(StructuredLogger(logger))
	r.Use(OopsRecoverer(logger))
	r.Use(SecurityHeaders)
	r.Use(CORS)
	r.Use(middleware.Timeout(30 * time.Second))

	healthHandler := NewHealthHandler(healthService, appVersion, appEnv)

	r.Get("/healthz", healthHandler.Readiness)
	r.Get("/livez", healthHandler.Liveness)

	r.Route("/api/v1", func(api chi.Router) {
		api.Get("/ping", healthHandler.Ping)

		if options.AuthService != nil {
			authHandler := NewAuthHandler(options.AuthService)
			api.Route("/auth", func(auth chi.Router) {
				auth.Post("/register-device", authHandler.RegisterDevice)
			})
		}
	})

	return r
}
