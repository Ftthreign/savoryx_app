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
	DefaultRateLimitPerMinute = 60
	defaultBucketIdleTTL = 10 * time.Minute
	defaultSweepInterval = 1 * time.Minute
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

func (l *RateLimiter) sweepLocked(now time.Time) {
	if now.Sub(l.lastSweep) < l.sweepEvery {
		return
	}
	l.lastSweep = now
	for id, b := range l.buckets {
		if now.Sub(b.lastSeen) > l.idleTTL {
			delete(l.buckets, id)
		}
	}
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
				retryAfter := int(math.Ceil(wait.Seconds()))
				if retryAfter < 1 {
					retryAfter = 1
				}
				w.Header().Set("Retry-After", strconv.Itoa(retryAfter))
				WriteError(w, http.StatusTooManyRequests, "rate_limit_exceeded", "Too many requests, please retry later")
				return
			}

			next.ServeHTTP(w, r)
		})
	}
}
