package http

import (
	"log/slog"
	"net/http"
	"time"

	"github.com/ftthreign/savoryx_app/server/docs"
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

	// OpenAPI 3.0 Specification & Swagger UI (Spec-First)
	r.Get("/docs/openapi.yaml", func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/yaml; charset=utf-8")
		_, _ = w.Write(docs.OpenAPISpec)
	})

	serveSwaggerUI := func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "text/html; charset=utf-8")
		_, _ = w.Write([]byte(swaggerUIHTML))
	}

	r.Get("/swagger", serveSwaggerUI)
	r.Get("/swagger/", serveSwaggerUI)
	r.Get("/swagger/*", serveSwaggerUI)
	r.Get("/docs", serveSwaggerUI)
	r.Get("/docs/", serveSwaggerUI)

	return r
}

const swaggerUIHTML = `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <title>Savoryx Financial OS — API Documentation</title>
  <link rel="stylesheet" href="https://unpkg.com/swagger-ui-dist@5.11.0/swagger-ui.css" />
  <style>
    body { margin: 0; background: #fafafa; font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif; }
    .topbar { display: none; }
  </style>
</head>
<body>
<div id="swagger-ui"></div>
<script src="https://unpkg.com/swagger-ui-dist@5.11.0/swagger-ui-bundle.js" crossorigin></script>
<script>
  window.onload = () => {
    window.ui = SwaggerUIBundle({
      url: '/docs/openapi.yaml',
      dom_id: '#swagger-ui',
      deepLinking: true,
      presets: [
        SwaggerUIBundle.presets.apis,
        SwaggerUIBundle.SwaggerUIStandalonePreset
      ],
      layout: "BaseLayout"
    });
  };
</script>
</body>
</html>`
