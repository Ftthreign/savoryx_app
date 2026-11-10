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
	AuthService         port.AuthService
	AccountService      port.AccountService
	CategoryService     port.CategoryService
	TransactionService  port.TransactionService
	SyncService         port.SyncService
	ExchangeRateService port.ExchangeRateService
	TokenManager        port.TokenManager
	FXRateLimiter       *RateLimiter
	HMACSecretKey       string
}

type RouterOption func(*RouterOptions)

func WithAuthService(authService port.AuthService) RouterOption {
	return func(o *RouterOptions) {
		o.AuthService = authService
	}
}

func WithAccountService(accountService port.AccountService) RouterOption {
	return func(o *RouterOptions) {
		o.AccountService = accountService
	}
}

func WithCategoryService(categoryService port.CategoryService) RouterOption {
	return func(o *RouterOptions) {
		o.CategoryService = categoryService
	}
}

func WithTransactionService(transactionService port.TransactionService) RouterOption {
	return func(o *RouterOptions) {
		o.TransactionService = transactionService
	}
}

func WithSyncService(syncService port.SyncService) RouterOption {
	return func(o *RouterOptions) {
		o.SyncService = syncService
	}
}

func WithTokenManager(tokenManager port.TokenManager) RouterOption {
	return func(o *RouterOptions) {
		o.TokenManager = tokenManager
	}
}

func WithExchangeRateService(exchangeRateService port.ExchangeRateService) RouterOption {
	return func(o *RouterOptions) {
		o.ExchangeRateService = exchangeRateService
	}
}

// WithFXRateLimiter overrides the default per-device limiter guarding FX endpoints.
func WithFXRateLimiter(limiter *RateLimiter) RouterOption {
	return func(o *RouterOptions) {
		o.FXRateLimiter = limiter
	}
}

// WithHMACSecretKey enables HMAC-SHA256 payload signature verification on mutation routes.
func WithHMACSecretKey(secretKey string) RouterOption {
	return func(o *RouterOptions) {
		o.HMACSecretKey = secretKey
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
	r.Use(RequireJSONContentType)
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

		if options.TokenManager != nil {
			api.Group(func(protected chi.Router) {
				protected.Use(AuthMiddleware(options.TokenManager))
				if options.HMACSecretKey != "" {
					protected.Use(VerifyHMACSignature(options.HMACSecretKey))
				}

				if options.AccountService != nil {
					accountHandler := NewAccountHandler(options.AccountService)
					protected.Route("/accounts", func(acc chi.Router) {
						acc.Get("/", accountHandler.ListAccounts)
						acc.Post("/", accountHandler.CreateAccount)
						acc.Get("/{id}", accountHandler.GetAccount)
						acc.Put("/{id}", accountHandler.UpdateAccount)
						acc.Put("/{id}/balance", accountHandler.UpdateBalance)
						acc.Patch("/{id}/balance", accountHandler.UpdateBalance)
						acc.Delete("/{id}", accountHandler.DeleteAccount)
					})
				}

				if options.CategoryService != nil {
					categoryHandler := NewCategoryHandler(options.CategoryService)
					protected.Route("/categories", func(cat chi.Router) {
						cat.Get("/", categoryHandler.ListCategories)
						cat.Post("/", categoryHandler.CreateCategory)
						cat.Get("/{id}", categoryHandler.GetCategory)
						cat.Put("/{id}", categoryHandler.UpdateCategory)
						cat.Delete("/{id}", categoryHandler.DeleteCategory)
					})
				}

				if options.TransactionService != nil {
					txHandler := NewTransactionHandler(options.TransactionService)
					protected.Route("/transactions", func(tx chi.Router) {
						tx.Get("/", txHandler.ListTransactions)
						tx.Post("/", txHandler.CreateTransaction)
						tx.Get("/{id}", txHandler.GetTransaction)
						tx.Delete("/{id}", txHandler.DeleteTransaction)
					})
				}

				if options.SyncService != nil {
					syncHandler := NewSyncHandler(options.SyncService)
					protected.Route("/sync", func(sync chi.Router) {
						sync.Post("/pull", syncHandler.PullChanges)
						sync.Post("/push", syncHandler.PushChanges)
					})
				}

				if options.ExchangeRateService != nil {
					fxLimiter := options.FXRateLimiter
					if fxLimiter == nil {
						fxLimiter = NewRateLimiter(DefaultRateLimitPerMinute)
					}

					fxHandler := NewFXHandler(options.ExchangeRateService)
					protected.Group(func(fx chi.Router) {
						fx.Use(RateLimitMiddleware(fxLimiter))
						fx.Get("/currencies", fxHandler.ListCurrencies)
						fx.Route("/rates", func(rates chi.Router) {
							rates.Get("/latest", fxHandler.GetLatestRates)
							rates.Get("/historical", fxHandler.GetHistoricalRate)
						})
					})
				}
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
