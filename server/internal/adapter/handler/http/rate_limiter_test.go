package http_test

import (
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"strconv"
	"sync"
	"sync/atomic"
	"testing"
	"time"

	httpAdapter "github.com/ftthreign/savoryx_app/server/internal/adapter/handler/http"
	"github.com/ftthreign/savoryx_app/server/internal/core/domain"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

type fakeRateLimiterClock struct {
	mu  sync.Mutex
	now time.Time
}

func newFakeRateLimiterClock(initial time.Time) *fakeRateLimiterClock {
	return &fakeRateLimiterClock{now: initial.UTC()}
}

func (c *fakeRateLimiterClock) Now() time.Time {
	c.mu.Lock()
	defer c.mu.Unlock()
	return c.now
}

func (c *fakeRateLimiterClock) Advance(d time.Duration) {
	c.mu.Lock()
	defer c.mu.Unlock()
	c.now = c.now.Add(d)
}

func TestSyncRateLimiter_Enforces120PerMinuteAndHeaders(t *testing.T) {
	t.Parallel()

	clock := newFakeRateLimiterClock(time.Date(2026, 11, 10, 12, 0, 0, 0, time.UTC))
	deviceID := domain.NewUUIDv7()

	limiter := httpAdapter.NewSlidingWindowLimiter(0, httpAdapter.WithSlidingWindowClock(clock.Now))
	handler := httpAdapter.SyncRateLimiter(limiter)(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusOK)
	}))

	for i := 0; i < httpAdapter.DefaultSyncRateLimitPerMinute; i++ {
		req := httptest.NewRequest(http.MethodPost, "/api/v1/sync/push", nil)
		req = req.WithContext(httpAdapter.WithDeviceID(req.Context(), deviceID))
		rec := httptest.NewRecorder()
		handler.ServeHTTP(rec, req)

		require.Equal(t, http.StatusOK, rec.Code, "request %d should succeed", i+1)
		assert.Equal(t, "120", rec.Header().Get("X-RateLimit-Limit"))
		assert.Equal(t, strconv.Itoa(119-i), rec.Header().Get("X-RateLimit-Remaining"))
		assert.NotEmpty(t, rec.Header().Get("X-RateLimit-Reset"))
	}

	// 121st request inside the same 60-second window must be rejected with 429.
	reqOver := httptest.NewRequest(http.MethodPost, "/api/v1/sync/push", nil)
	reqOver = reqOver.WithContext(httpAdapter.WithDeviceID(reqOver.Context(), deviceID))
	recOver := httptest.NewRecorder()
	handler.ServeHTTP(recOver, reqOver)

	assert.Equal(t, http.StatusTooManyRequests, recOver.Code)
	assert.Equal(t, "120", recOver.Header().Get("X-RateLimit-Limit"))
	assert.Equal(t, "0", recOver.Header().Get("X-RateLimit-Remaining"))
	assert.Equal(t, "60", recOver.Header().Get("Retry-After"))

	var env httpAdapter.ErrorEnvelope
	require.NoError(t, json.Unmarshal(recOver.Body.Bytes(), &env))
	assert.Equal(t, "rate_limit_exceeded", env.Error.Code)
}

func TestSyncRateLimiter_SlidingWindowRecoveryAndDeviceIsolation(t *testing.T) {
	t.Parallel()

	clock := newFakeRateLimiterClock(time.Date(2026, 11, 10, 12, 0, 0, 0, time.UTC))
	deviceA := domain.NewUUIDv7()
	deviceB := domain.NewUUIDv7()

	middleware := httpAdapter.NewSyncRateLimiter(3, httpAdapter.WithSlidingWindowClock(clock.Now))
	handler := middleware(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusOK)
	}))

	sendAs := func(id domain.UUID) *httptest.ResponseRecorder {
		req := httptest.NewRequest(http.MethodPost, "/api/v1/sync/pull", nil)
		req = req.WithContext(httpAdapter.WithDeviceID(req.Context(), id))
		rec := httptest.NewRecorder()
		handler.ServeHTTP(rec, req)
		return rec
	}

	// Consume 2 requests at t=0s and 1 request at t=30s for deviceA.
	assert.Equal(t, http.StatusOK, sendAs(deviceA).Code)
	assert.Equal(t, http.StatusOK, sendAs(deviceA).Code)
	clock.Advance(30 * time.Second)
	assert.Equal(t, http.StatusOK, sendAs(deviceA).Code)

	// 4th request at t=30s must be rejected with Retry-After ~30s.
	recBlocked := sendAs(deviceA)
	assert.Equal(t, http.StatusTooManyRequests, recBlocked.Code)
	assert.Equal(t, "30", recBlocked.Header().Get("Retry-After"))

	// Device B retains an isolated quota while Device A is blocked.
	assert.Equal(t, http.StatusOK, sendAs(deviceB).Code)
	assert.Equal(t, http.StatusOK, sendAs(deviceB).Code)

	// Advance to t=60s: the 2 timestamps from t=0s slide out of the 60s window!
	clock.Advance(30 * time.Second)
	recRecovered := sendAs(deviceA)
	assert.Equal(t, http.StatusOK, recRecovered.Code)
	assert.Equal(t, "1", recRecovered.Header().Get("X-RateLimit-Remaining"))
}

func TestSyncRateLimiter_IdleEvictionAndConcurrentRaceSafety(t *testing.T) {
	t.Parallel()

	t.Run("evicts idle device windows after idle TTL", func(t *testing.T) {
		t.Parallel()

		clock := newFakeRateLimiterClock(time.Date(2026, 11, 10, 12, 0, 0, 0, time.UTC))
		limiter := httpAdapter.NewSlidingWindowLimiter(
			10,
			httpAdapter.WithSlidingWindowClock(clock.Now),
			httpAdapter.WithSlidingWindowIdleTTL(2*time.Minute),
		)

		dev1 := domain.NewUUIDv7()
		dev2 := domain.NewUUIDv7()
		assert.True(t, limiter.Allow(dev1).Allowed)
		assert.True(t, limiter.Allow(dev2).Allowed)
		assert.Equal(t, 2, limiter.Size())

		// Advance past idle TTL and trigger sweep on dev3 request.
		clock.Advance(3 * time.Minute)
		dev3 := domain.NewUUIDv7()
		assert.True(t, limiter.Allow(dev3).Allowed)
		assert.Equal(t, 1, limiter.Size())
	})

	t.Run("concurrent bursts stay strictly within 120 req/min limit without races", func(t *testing.T) {
		t.Parallel()

		clock := newFakeRateLimiterClock(time.Date(2026, 11, 10, 12, 0, 0, 0, time.UTC))
		limiter := httpAdapter.NewSlidingWindowLimiter(120, httpAdapter.WithSlidingWindowClock(clock.Now))
		deviceID := domain.NewUUIDv7()

		const totalAttempts = 180
		var allowedCount atomic.Int32
		var rejectedCount atomic.Int32
		var wg sync.WaitGroup

		for i := 0; i < totalAttempts; i++ {
			wg.Add(1)
			go func() {
				defer wg.Done()
				res := limiter.Allow(deviceID)
				if res.Allowed {
					allowedCount.Add(1)
				} else {
					rejectedCount.Add(1)
				}
			}()
		}
		wg.Wait()

		assert.Equal(t, int32(120), allowedCount.Load())
		assert.Equal(t, int32(60), rejectedCount.Load())
	})

	t.Run("nil limiter passes through and missing device ID returns 401", func(t *testing.T) {
		t.Parallel()

		passThrough := httpAdapter.SyncRateLimiter(nil)(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			w.WriteHeader(http.StatusAccepted)
		}))
		req1 := httptest.NewRequest(http.MethodPost, "/api/v1/sync/push", nil)
		rec1 := httptest.NewRecorder()
		passThrough.ServeHTTP(rec1, req1)
		assert.Equal(t, http.StatusAccepted, rec1.Code)

		guarded := httpAdapter.NewSyncRateLimiter(120)(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			t.Fatal("handler must not run without device identity")
		}))
		req2 := httptest.NewRequest(http.MethodPost, "/api/v1/sync/push", nil)
		rec2 := httptest.NewRecorder()
		guarded.ServeHTTP(rec2, req2)
		assert.Equal(t, http.StatusUnauthorized, rec2.Code)
	})
}
