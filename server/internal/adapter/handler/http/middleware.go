package http

import (
	"bytes"
	"context"
	"crypto/hmac"
	"crypto/sha256"
	"crypto/subtle"
	"encoding/hex"
	"errors"
	"io"
	"log/slog"
	"net/http"
	"strconv"
	"strings"
	"time"

	"github.com/ftthreign/savoryx_app/server/internal/core/domain"
	"github.com/ftthreign/savoryx_app/server/internal/port"
	"github.com/go-chi/chi/v5/middleware"
	"github.com/samber/oops"
)

const MaxClockSkew = 60 * time.Second

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

func RequireJSONContentType(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if r.Method == http.MethodPost || r.Method == http.MethodPut || r.Method == http.MethodPatch {
			contentType := r.Header.Get("Content-Type")
			if contentType == "" {
				WriteError(w, http.StatusUnsupportedMediaType, "unsupported_media_type", "Content-Type must be application/json")
				return
			}

			mediaType := strings.ToLower(strings.TrimSpace(strings.Split(contentType, ";")[0]))
			if mediaType != "application/json" {
				WriteError(w, http.StatusUnsupportedMediaType, "unsupported_media_type", "Content-Type must be application/json")
				return
			}
		}

		next.ServeHTTP(w, r)
	})
}

type deviceCtxKey struct{}

func WithDeviceID(ctx context.Context, id domain.UUID) context.Context {
	return context.WithValue(ctx, deviceCtxKey{}, id)
}

func DeviceIDFromContext(ctx context.Context) (domain.UUID, error) {
	if ctx == nil {
		return domain.NilUUID, domain.ErrUnauthorized
	}
	val := ctx.Value(deviceCtxKey{})
	if val == nil {
		return domain.NilUUID, domain.ErrUnauthorized
	}
	id, ok := val.(domain.UUID)
	if !ok || id.IsZero() {
		return domain.NilUUID, domain.ErrUnauthorized
	}
	return id, nil
}

func GetDeviceIDFromContext(ctx context.Context) (domain.UUID, error) {
	return DeviceIDFromContext(ctx)
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
				if errors.Is(err, domain.ErrDeviceRevoked) {
					WriteError(w, http.StatusUnauthorized, "device_revoked", "Device authorization has been revoked")
					return
				}
				WriteError(w, http.StatusUnauthorized, "unauthorized", "Invalid or expired authorization token")
				return
			}

			if claims == nil || claims.DeviceID.IsZero() {
				WriteError(w, http.StatusUnauthorized, "unauthorized", "Invalid token claims")
				return
			}

			ctx := WithDeviceID(r.Context(), claims.DeviceID)
			next.ServeHTTP(w, r.WithContext(ctx))
		})
	}
}

// ComputeHMACSignature computes the canonical hex-encoded HMAC-SHA256 digest over
// timestamp + "\n" + method + "\n" + path + "\n" + body.
func ComputeHMACSignature(secret, timestamp, method, path string, body []byte) string {
	mac := hmac.New(sha256.New, []byte(secret))
	_, _ = mac.Write([]byte(timestamp))
	_, _ = mac.Write([]byte("\n"))
	_, _ = mac.Write([]byte(strings.ToUpper(method)))
	_, _ = mac.Write([]byte("\n"))
	_, _ = mac.Write([]byte(path))
	_, _ = mac.Write([]byte("\n"))
	_, _ = mac.Write(body)
	return hex.EncodeToString(mac.Sum(nil))
}

func computeLegacyHMACSignature(secret, timestamp string, body []byte) string {
	mac := hmac.New(sha256.New, []byte(secret))
	_, _ = mac.Write([]byte(timestamp))
	_, _ = mac.Write(body)
	return hex.EncodeToString(mac.Sum(nil))
}

func parseSignatureTimestamp(raw string) (time.Time, error) {
	if t, err := time.Parse(time.RFC3339Nano, raw); err == nil {
		return t.UTC(), nil
	}
	if t, err := time.Parse(time.RFC3339, raw); err == nil {
		return t.UTC(), nil
	}
	if sec, err := strconv.ParseInt(raw, 10, 64); err == nil {
		return time.Unix(sec, 0).UTC(), nil
	}
	return time.Time{}, errors.New("unsupported timestamp format")
}

// VerifyHMACSignature validates X-Signature and X-Timestamp headers on mutation requests
// (POST, PUT, PATCH, DELETE) using constant-time HMAC-SHA256 comparison and a 60s clock skew guard.
func VerifyHMACSignature(secretKey string) func(next http.Handler) http.Handler {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			switch r.Method {
			case http.MethodPost, http.MethodPut, http.MethodPatch, http.MethodDelete:
			default:
				next.ServeHTTP(w, r)
				return
			}

			if strings.TrimSpace(secretKey) == "" {
				WriteError(w, http.StatusInternalServerError, "internal_error", "HMAC signing secret is not configured")
				return
			}

			sigHeader := strings.TrimSpace(r.Header.Get("X-Signature"))
			tsHeader := strings.TrimSpace(r.Header.Get("X-Timestamp"))
			if sigHeader == "" || tsHeader == "" {
				WriteError(w, http.StatusUnauthorized, "missing_signature", "Missing X-Signature or X-Timestamp header")
				return
			}

			reqTime, err := parseSignatureTimestamp(tsHeader)
			if err != nil {
				WriteError(w, http.StatusUnauthorized, "invalid_timestamp", "Invalid X-Timestamp header format")
				return
			}

			skew := time.Since(reqTime)
			if skew < 0 {
				skew = -skew
			}
			if skew > MaxClockSkew {
				WriteError(w, http.StatusUnauthorized, "clock_skew_exceeded", "Request timestamp exceeds 60-second clock skew tolerance")
				return
			}

			var bodyBytes []byte
			if r.Body != nil {
				const maxBody = 1 << 20 // 1 MB
				var readErr error
				bodyBytes, readErr = io.ReadAll(io.LimitReader(r.Body, maxBody))
				_ = r.Body.Close()
				if readErr != nil {
					WriteError(w, http.StatusBadRequest, "invalid_body", "Failed to read request body")
					return
				}
				r.Body = io.NopCloser(bytes.NewBuffer(bodyBytes))
			}

			providedSig := strings.ToLower(strings.TrimSpace(strings.TrimPrefix(sigHeader, "sha256=")))
			expectedCanonical := ComputeHMACSignature(secretKey, tsHeader, r.Method, r.URL.Path, bodyBytes)
			expectedLegacy := computeLegacyHMACSignature(secretKey, tsHeader, bodyBytes)

			canonicalMatch := subtle.ConstantTimeCompare([]byte(providedSig), []byte(expectedCanonical)) == 1
			legacyMatch := subtle.ConstantTimeCompare([]byte(providedSig), []byte(expectedLegacy)) == 1
			if !canonicalMatch && !legacyMatch {
				WriteError(w, http.StatusUnauthorized, "invalid_signature", "Invalid HMAC-SHA256 digital signature")
				return
			}

			next.ServeHTTP(w, r)
		})
	}
}
