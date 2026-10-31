package http

import (
	"context"
	"errors"
	"log/slog"
	"net/http"
	"strings"
	"time"

	"github.com/ftthreign/savoryx_app/server/internal/core/domain"
	"github.com/ftthreign/savoryx_app/server/internal/port"
	"github.com/go-chi/chi/v5/middleware"
	"github.com/samber/oops"
)

func StructuredLogger(logger *slog.Logger) func(next http.Handler) http.Handler {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			start := time.Now()
			ww := middleware.NewWrapResponseWriter(w, r.ProtoMajor)

			defer func() {
				duration := time.Since(start)
				reqID := middleware.GetReqID(r.Context())

				logger.Info("http request completed",
					slog.String("request_id", reqID),
					slog.String("method", r.Method),
					slog.String("path", r.URL.Path),
					slog.Int("status", ww.Status()),
					slog.Int64("bytes_written", int64(ww.BytesWritten())),
					slog.Duration("duration", duration),
					slog.String("remote_ip", r.RemoteAddr),
				)
			}()

			next.ServeHTTP(ww, r)
		})
	}
}

func CORS(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Access-Control-Allow-Origin", "*")
		w.Header().Set("Access-Control-Allow-Methods", "GET, POST, PUT, PATCH, DELETE, OPTIONS")
		w.Header().Set("Access-Control-Allow-Headers", "Accept, Authorization, Content-Type, X-Request-ID, X-Signature")
		w.Header().Set("Access-Control-Max-Age", "300")

		if r.Method == http.MethodOptions {
			w.WriteHeader(http.StatusNoContent)
			return
		}

		next.ServeHTTP(w, r)
	})
}

func OopsRecoverer(logger *slog.Logger) func(next http.Handler) http.Handler {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			defer func() {
				if rvr := recover(); rvr != nil {
					if rvr == http.ErrAbortHandler {
						panic(rvr)
					}

					oopsErr := oops.
						In("http_middleware").
						Code("ERR_PANIC_RECOVERED").
						With("path", r.URL.Path).
						With("method", r.Method).
						Errorf("panic recovered: %v", rvr)

					logger.Error("unhandled panic recovered in HTTP pipeline",
						slog.String("error", oopsErr.Error()),
						slog.String("path", r.URL.Path),
					)

					WriteError(w, http.StatusInternalServerError, "internal_server_error", "An unexpected server error occurred")
				}
			}()

			next.ServeHTTP(w, r)
		})
	}
}

func SecurityHeaders(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("X-Content-Type-Options", "nosniff")
		w.Header().Set("X-Frame-Options", "DENY")
		w.Header().Set("Referrer-Policy", "strict-origin-when-cross-origin")

		next.ServeHTTP(w, r)
	})
}

type contextKey string

const (
	deviceIDContextKey contextKey = "device_id"
)

func GetDeviceIDFromContext(ctx context.Context) (domain.UUID, error) {
	val := ctx.Value(deviceIDContextKey)
	if val == nil {
		return domain.NilUUID, domain.ErrUnauthorized
	}
	id, ok := val.(domain.UUID)
	if !ok || id.IsZero() {
		return domain.NilUUID, domain.ErrUnauthorized
	}
	return id, nil
}

func AuthMiddleware(tokenManager port.TokenManager) func(next http.Handler) http.Handler {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			if tokenManager == nil {
				WriteError(w, http.StatusInternalServerError, "internal_error", "Token manager not configured")
				return
			}

			authHeader := r.Header.Get("Authorization")
			if authHeader == "" {
				WriteError(w, http.StatusUnauthorized, "unauthorized", "Missing Authorization header")
				return
			}

			const prefix = "Bearer "
			if !strings.HasPrefix(authHeader, prefix) {
				WriteError(w, http.StatusUnauthorized, "unauthorized", "Authorization header must use Bearer scheme")
				return
			}

			tokenStr := strings.TrimSpace(strings.TrimPrefix(authHeader, prefix))
			if tokenStr == "" {
				WriteError(w, http.StatusUnauthorized, "unauthorized", "Authorization token must not be empty")
				return
			}

			claims, err := tokenManager.VerifyDeviceToken(tokenStr)
			if err != nil {
				if errors.Is(err, domain.ErrTokenExpired) {
					WriteError(w, http.StatusUnauthorized, "token_expired", "Authorization token has expired")
					return
				}
				WriteError(w, http.StatusUnauthorized, "unauthorized", "Invalid or expired authorization token")
				return
			}

			if claims == nil || claims.DeviceID.IsZero() {
				WriteError(w, http.StatusUnauthorized, "unauthorized", "Invalid token claims")
				return
			}

			ctx := context.WithValue(r.Context(), deviceIDContextKey, claims.DeviceID)
			next.ServeHTTP(w, r.WithContext(ctx))
		})
	}
}

