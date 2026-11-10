package http

import (
	"math"
	"net/http"
	"strconv"
	"sync"
	"time"

	"github.com/ftthreign/savoryx_app/server/internal/core/domain"
)

const (
	DefaultRateLimitPerMinute     = 60
	DefaultSyncRateLimitPerMinute = 120
	defaultSyncWindowDuration     = 1 * time.Minute
	defaultBucketIdleTTL          = 10 * time.Minute
	defaultSweepInterval          = 1 * time.Minute
)

type tokenBucket struct {
	tokens   float64
	lastSeen time.Time
}

type RateLimiter struct {
	mu         sync.Mutex
	buckets    map[domain.UUID]*tokenBucket
	capacity   float64
	refillRate float64 // tokens per second
	idleTTL    time.Duration
	sweepEvery time.Duration
	lastSweep  time.Time
	now        func() time.Time
}

type RateLimiterOption func(*RateLimiter)

func WithClock(now func() time.Time) RateLimiterOption {
	return func(l *RateLimiter) {
		if now != nil {
			l.now = now
		}
	}
}

func WithIdleTTL(ttl time.Duration) RateLimiterOption {
	return func(l *RateLimiter) {
		if ttl > 0 {
			l.idleTTL = ttl
		}
	}
}

func NewRateLimiter(requestsPerMinute int, opts ...RateLimiterOption) *RateLimiter {
	if requestsPerMinute <= 0 {
		requestsPerMinute = DefaultRateLimitPerMinute
	}

	l := &RateLimiter{
		buckets:    make(map[domain.UUID]*tokenBucket),
		capacity:   float64(requestsPerMinute),
		refillRate: float64(requestsPerMinute) / 60.0,
		idleTTL:    defaultBucketIdleTTL,
		sweepEvery: defaultSweepInterval,
		now:        time.Now,
	}
	for _, opt := range opts {
		opt(l)
	}
	l.lastSweep = l.now()
	return l
}

func (l *RateLimiter) Allow(deviceID domain.UUID) (bool, time.Duration) {
	l.mu.Lock()
	defer l.mu.Unlock()

	now := l.now()
	l.sweepLocked(now)

	b, ok := l.buckets[deviceID]
	if !ok {
		b = &tokenBucket{tokens: l.capacity, lastSeen: now}
		l.buckets[deviceID] = b
	} else {
		elapsed := now.Sub(b.lastSeen).Seconds()
		if elapsed > 0 {
			b.tokens = math.Min(l.capacity, b.tokens+elapsed*l.refillRate)
		}
		b.lastSeen = now
	}

	if b.tokens >= 1 {
		b.tokens--
		return true, 0
	}

	missing := 1 - b.tokens
	wait := time.Duration(missing / l.refillRate * float64(time.Second))
	return false, wait
}

func (l *RateLimiter) Size() int {
	l.mu.Lock()
	defer l.mu.Unlock()
	return len(l.buckets)
}

func sweepIdleEntries[T any](entries map[domain.UUID]T, now, lastSweep time.Time, sweepEvery, idleTTL time.Duration, lastSeen func(T) time.Time) time.Time {
	if now.Sub(lastSweep) < sweepEvery {
		return lastSweep
	}
	for id, entry := range entries {
		if now.Sub(lastSeen(entry)) > idleTTL {
			delete(entries, id)
		}
	}
	return now
}

func (l *RateLimiter) sweepLocked(now time.Time) {
	l.lastSweep = sweepIdleEntries(l.buckets, now, l.lastSweep, l.sweepEvery, l.idleTTL, func(b *tokenBucket) time.Time {
		return b.lastSeen
	})
}

// SlidingWindowResult describes the rate-limit evaluation outcome for a single request.
type SlidingWindowResult struct {
	Allowed    bool
	Limit      int
	Remaining  int
	ResetAt    time.Time
	RetryAfter time.Duration
}

type deviceWindow struct {
	timestamps []time.Time
	lastSeen   time.Time
}

// SlidingWindowLimiter enforces an exact per-device sliding-window request quota.
type SlidingWindowLimiter struct {
	mu         sync.Mutex
	windows    map[domain.UUID]*deviceWindow
	limit      int
	window     time.Duration
	idleTTL    time.Duration
	sweepEvery time.Duration
	lastSweep  time.Time
	now        func() time.Time
}

// SlidingWindowOption configures a SlidingWindowLimiter instance.
type SlidingWindowOption func(*SlidingWindowLimiter)

// WithSlidingWindowClock overrides the time source used by SlidingWindowLimiter (for testing).
func WithSlidingWindowClock(now func() time.Time) SlidingWindowOption {
	return func(l *SlidingWindowLimiter) {
		if now != nil {
			l.now = now
		}
	}
}

// WithSlidingWindowDuration overrides the rolling window duration (default: 1 minute).
func WithSlidingWindowDuration(window time.Duration) SlidingWindowOption {
	return func(l *SlidingWindowLimiter) {
		if window > 0 {
			l.window = window
		}
	}
}

// WithSlidingWindowIdleTTL overrides the idle device eviction TTL (default: 10 minutes).
func WithSlidingWindowIdleTTL(ttl time.Duration) SlidingWindowOption {
	return func(l *SlidingWindowLimiter) {
		if ttl > 0 {
			l.idleTTL = ttl
		}
	}
}

// NewSlidingWindowLimiter constructs a thread-safe per-device sliding window limiter.
func NewSlidingWindowLimiter(requestsPerMinute int, opts ...SlidingWindowOption) *SlidingWindowLimiter {
	if requestsPerMinute <= 0 {
		requestsPerMinute = DefaultSyncRateLimitPerMinute
	}

	l := &SlidingWindowLimiter{
		windows:    make(map[domain.UUID]*deviceWindow),
		limit:      requestsPerMinute,
		window:     defaultSyncWindowDuration,
		idleTTL:    defaultBucketIdleTTL,
		sweepEvery: defaultSweepInterval,
		now:        time.Now,
	}
	for _, opt := range opts {
		opt(l)
	}
	l.lastSweep = l.now().UTC()
	return l
}

// Allow checks whether deviceID may perform a sync operation in the current sliding window.
func (l *SlidingWindowLimiter) Allow(deviceID domain.UUID) SlidingWindowResult {
	l.mu.Lock()
	defer l.mu.Unlock()

	now := l.now().UTC()
	l.lastSweep = sweepIdleEntries(l.windows, now, l.lastSweep, l.sweepEvery, l.idleTTL, func(w *deviceWindow) time.Time {
		return w.lastSeen
	})

	w, ok := l.windows[deviceID]
	if !ok {
		w = &deviceWindow{
			timestamps: make([]time.Time, 0, min(l.limit, 16)),
			lastSeen:   now,
		}
		l.windows[deviceID] = w
	} else {
		cutoff := now.Add(-l.window)
		pruneIdx := 0
		for pruneIdx < len(w.timestamps) && !w.timestamps[pruneIdx].After(cutoff) {
			pruneIdx++
		}
		if pruneIdx > 0 {
			remainingLen := copy(w.timestamps, w.timestamps[pruneIdx:])
			w.timestamps = w.timestamps[:remainingLen]
		}
		w.lastSeen = now
	}

	if len(w.timestamps) < l.limit {
		w.timestamps = append(w.timestamps, now)
		resetAt := w.timestamps[0].Add(l.window)
		return SlidingWindowResult{
			Allowed:   true,
			Limit:     l.limit,
			Remaining: l.limit - len(w.timestamps),
			ResetAt:   resetAt,
		}
	}

	resetAt := w.timestamps[0].Add(l.window)
	retryAfter := max(resetAt.Sub(now), 0)
	return SlidingWindowResult{
		Allowed:    false,
		Limit:      l.limit,
		Remaining:  0,
		ResetAt:    resetAt,
		RetryAfter: retryAfter,
	}
}

// Size returns the number of active device windows tracked in memory.
func (l *SlidingWindowLimiter) Size() int {
	l.mu.Lock()
	defer l.mu.Unlock()
	return len(l.windows)
}

func formatRetryAfterSeconds(wait time.Duration) string {
	retryAfter := max(int(math.Ceil(wait.Seconds())), 1)
	return strconv.Itoa(retryAfter)
}

func RateLimitMiddleware(limiter *RateLimiter) func(next http.Handler) http.Handler {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			if limiter == nil {
				next.ServeHTTP(w, r)
				return
			}

			deviceID, err := DeviceIDFromContext(r.Context())
			if err != nil {
				WriteError(w, http.StatusUnauthorized, "unauthorized", "Missing device identity")
				return
			}

			allowed, wait := limiter.Allow(deviceID)
			if !allowed {
				w.Header().Set("Retry-After", formatRetryAfterSeconds(wait))
				WriteError(w, http.StatusTooManyRequests, "rate_limit_exceeded", "Too many requests, please retry later")
				return
			}

			next.ServeHTTP(w, r)
		})
	}
}

// SyncRateLimiter enforces per-device sliding-window rate limits and emits X-RateLimit-* headers.
func SyncRateLimiter(limiter *SlidingWindowLimiter) func(next http.Handler) http.Handler {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			if limiter == nil {
				next.ServeHTTP(w, r)
				return
			}

			deviceID, err := DeviceIDFromContext(r.Context())
			if err != nil {
				WriteError(w, http.StatusUnauthorized, "unauthorized", "Missing device identity")
				return
			}

			res := limiter.Allow(deviceID)
			w.Header().Set("X-RateLimit-Limit", strconv.Itoa(res.Limit))
			w.Header().Set("X-RateLimit-Remaining", strconv.Itoa(res.Remaining))
			w.Header().Set("X-RateLimit-Reset", strconv.FormatInt(res.ResetAt.Unix(), 10))

			if !res.Allowed {
				w.Header().Set("Retry-After", formatRetryAfterSeconds(res.RetryAfter))
				WriteError(w, http.StatusTooManyRequests, "rate_limit_exceeded", "Sync rate limit exceeded, please retry later")
				return
			}

			next.ServeHTTP(w, r)
		})
	}
}

// NewSyncRateLimiter constructs a SyncRateLimiter middleware configured for requestsPerMinute.
func NewSyncRateLimiter(requestsPerMinute int, opts ...SlidingWindowOption) func(next http.Handler) http.Handler {
	return SyncRateLimiter(NewSlidingWindowLimiter(requestsPerMinute, opts...))
}
