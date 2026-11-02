package http

import (
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"strconv"
	"sync"
	"testing"
	"time"

	"github.com/ftthreign/savoryx_app/server/internal/adapter/security"
	"github.com/ftthreign/savoryx_app/server/internal/core/domain"
	"github.com/ftthreign/savoryx_app/server/internal/port"
	"github.com/ftthreign/savoryx_app/server/internal/testutil"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

type fxFakeClock struct {
	mu  sync.Mutex
	now time.Time
}

func newFXFakeClock() *fxFakeClock {
	return &fxFakeClock{now: time.Date(2026, 11, 2, 0, 0, 0, 0, time.UTC)}
}

func (c *fxFakeClock) Now() time.Time {
	c.mu.Lock()
	defer c.mu.Unlock()
	return c.now
}

func (c *fxFakeClock) Advance(d time.Duration) {
	c.mu.Lock()
	defer c.mu.Unlock()
	c.now = c.now.Add(d)
}

type fxSecurityEnv struct {
	router http.Handler
	tm     port.TokenManager
	clock  *fxFakeClock
}

func newFXSecurityEnv(t *testing.T, perMinute int) *fxSecurityEnv {
	t.Helper()

	tm, err := security.NewPasetoTokenManager("")
	require.NoError(t, err)

	clock := newFXFakeClock()
	limiter := NewRateLimiter(perMinute, WithClock(clock.Now))

	router := SetupRouter(
		testutil.DiscardLogger(),
		nil,
		"1.0.0",
		"test",
		WithTokenManager(tm),
		WithExchangeRateService(newMockFXService()),
		WithFXRateLimiter(limiter),
	)

	return &fxSecurityEnv{router: router, tm: tm, clock: clock}
}

func (e *fxSecurityEnv) token(t *testing.T, deviceID domain.UUID) string {
	t.Helper()
	tok, err := e.tm.GenerateDeviceToken(deviceID, time.Hour)
	require.NoError(t, err)
	return tok
}

func (e *fxSecurityEnv) get(path, token string) *httptest.ResponseRecorder {
	req := httptest.NewRequest(http.MethodGet, path, nil)
	if token != "" {
		req.Header.Set("Authorization", "Bearer "+token)
	}
	rec := httptest.NewRecorder()
	e.router.ServeHTTP(rec, req)
	return rec
}

func TestFXSecurity_UnauthenticatedRequestsRejected(t *testing.T) {
	env := newFXSecurityEnv(t, 60)

	paths := []string{
		"/api/v1/currencies",
		"/api/v1/rates/latest?base=USD",
		"/api/v1/rates/historical?base=USD&target=EUR&date=2026-10-15",
	}

	for _, p := range paths {
		t.Run(p, func(t *testing.T) {
			rec := env.get(p, "")
			assert.Equal(t, http.StatusUnauthorized, rec.Code)
		})
	}
}

func TestFXSecurity_InvalidTokenRejected(t *testing.T) {
	env := newFXSecurityEnv(t, 60)

	rec := env.get("/api/v1/currencies", "v4.local.not-a-real-token")
	assert.Equal(t, http.StatusUnauthorized, rec.Code)
}

func TestFXSecurity_ValidTokenAccepted(t *testing.T) {
	env := newFXSecurityEnv(t, 60)
	tok := env.token(t, domain.NewUUIDv7())

	rec := env.get("/api/v1/currencies", tok)
	assert.Equal(t, http.StatusOK, rec.Code)
}

func TestFXSecurity_RateLimitExceededReturns429(t *testing.T) {
	env := newFXSecurityEnv(t, 3)
	tok := env.token(t, domain.NewUUIDv7())

	for i := 0; i < 3; i++ {
		rec := env.get("/api/v1/currencies", tok)
		require.Equal(t, http.StatusOK, rec.Code, "request %d should pass", i+1)
	}

	rec := env.get("/api/v1/currencies", tok)
	require.Equal(t, http.StatusTooManyRequests, rec.Code)

	retryAfter, err := strconv.Atoi(rec.Header().Get("Retry-After"))
	require.NoError(t, err)
	// 3 req/min refills one token every 20 seconds.
	assert.Equal(t, 20, retryAfter)

	var body ErrorEnvelope
	require.NoError(t, json.Unmarshal(rec.Body.Bytes(), &body))
	assert.Equal(t, "rate_limit_exceeded", body.Error.Code)
	assert.NotEmpty(t, body.Error.Message)
}

func TestFXSecurity_DefaultLimitIs60PerMinute(t *testing.T) {
	env := newFXSecurityEnv(t, DefaultRateLimitPerMinute)
	tok := env.token(t, domain.NewUUIDv7())

	for i := 0; i < 60; i++ {
		rec := env.get("/api/v1/currencies", tok)
		require.Equal(t, http.StatusOK, rec.Code, "request %d should pass", i+1)
	}

	rec := env.get("/api/v1/currencies", tok)
	assert.Equal(t, http.StatusTooManyRequests, rec.Code)
	assert.Equal(t, "1", rec.Header().Get("Retry-After"))
}

func TestFXSecurity_RateLimitIsolatedPerDevice(t *testing.T) {
	env := newFXSecurityEnv(t, 2)
	tokA := env.token(t, domain.NewUUIDv7())
	tokB := env.token(t, domain.NewUUIDv7())

	require.Equal(t, http.StatusOK, env.get("/api/v1/currencies", tokA).Code)
	require.Equal(t, http.StatusOK, env.get("/api/v1/currencies", tokA).Code)
	require.Equal(t, http.StatusTooManyRequests, env.get("/api/v1/currencies", tokA).Code)

	// Device B has its own bucket and must be unaffected.
	assert.Equal(t, http.StatusOK, env.get("/api/v1/currencies", tokB).Code)
}

func TestFXSecurity_RateLimitRecoversAfterRefill(t *testing.T) {
	env := newFXSecurityEnv(t, 3)
	tok := env.token(t, domain.NewUUIDv7())

	for i := 0; i < 3; i++ {
		require.Equal(t, http.StatusOK, env.get("/api/v1/currencies", tok).Code)
	}
	require.Equal(t, http.StatusTooManyRequests, env.get("/api/v1/currencies", tok).Code)

	env.clock.Advance(21 * time.Second)

	assert.Equal(t, http.StatusOK, env.get("/api/v1/currencies", tok).Code)
	assert.Equal(t, http.StatusTooManyRequests, env.get("/api/v1/currencies", tok).Code)
}

func TestFXSecurity_RateLimitSharedAcrossFXEndpoints(t *testing.T) {
	env := newFXSecurityEnv(t, 2)
	tok := env.token(t, domain.NewUUIDv7())

	require.Equal(t, http.StatusOK, env.get("/api/v1/currencies", tok).Code)
	require.Equal(t, http.StatusNotFound, env.get("/api/v1/rates/latest?base=USD&target=EUR", tok).Code)

	rec := env.get("/api/v1/rates/latest?base=USD", tok)
	assert.Equal(t, http.StatusTooManyRequests, rec.Code)
}

func TestRateLimiter_EvictsIdleBuckets(t *testing.T) {
	clock := newFXFakeClock()
	limiter := NewRateLimiter(60, WithClock(clock.Now), WithIdleTTL(5*time.Minute))

	for i := 0; i < 10; i++ {
		allowed, _ := limiter.Allow(domain.NewUUIDv7())
		require.True(t, allowed)
	}
	assert.Equal(t, 10, limiter.Size())

	clock.Advance(6 * time.Minute)

	// Any Allow call past the sweep interval evicts stale buckets.
	allowed, _ := limiter.Allow(domain.NewUUIDv7())
	require.True(t, allowed)
	assert.Equal(t, 1, limiter.Size())
}

func TestRateLimiter_ConcurrentAccessRaceFree(t *testing.T) {
	limiter := NewRateLimiter(1000)
	devices := []domain.UUID{domain.NewUUIDv7(), domain.NewUUIDv7(), domain.NewUUIDv7()}

	var wg sync.WaitGroup
	for i := 0; i < 30; i++ {
		wg.Add(1)
		go func(n int) {
			defer wg.Done()
			for j := 0; j < 100; j++ {
				limiter.Allow(devices[n%len(devices)])
			}
		}(i)
	}
	wg.Wait()

	assert.Equal(t, len(devices), limiter.Size())
}

func TestRateLimitMiddleware_NilLimiterPassesThrough(t *testing.T) {
	called := false
	h := RateLimitMiddleware(nil)(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		called = true
		w.WriteHeader(http.StatusOK)
	}))

	rec := httptest.NewRecorder()
	h.ServeHTTP(rec, httptest.NewRequest(http.MethodGet, "/", nil))

	assert.True(t, called)
	assert.Equal(t, http.StatusOK, rec.Code)
}

func TestRateLimitMiddleware_MissingDeviceIdentityRejected(t *testing.T) {
	h := RateLimitMiddleware(NewRateLimiter(60))(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		t.Fatal("handler must not run without device identity")
	}))

	rec := httptest.NewRecorder()
	h.ServeHTTP(rec, httptest.NewRequest(http.MethodGet, "/", nil))

	assert.Equal(t, http.StatusUnauthorized, rec.Code)
}
