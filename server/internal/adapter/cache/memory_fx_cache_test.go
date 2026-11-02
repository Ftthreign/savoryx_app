package cache_test

import (
	"context"
	"fmt"
	"sync"
	"testing"
	"time"

	"github.com/ftthreign/savoryx_app/server/internal/adapter/cache"
	"github.com/ftthreign/savoryx_app/server/internal/core/domain"
	"github.com/shopspring/decimal"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

func sampleRate(base, target string, rateVal string) *domain.ExchangeRate {
	d, _ := decimal.NewFromString(rateVal)
	return &domain.ExchangeRate{
		ID:             domain.NewUUIDv7(),
		BaseCurrency:   base,
		TargetCurrency: target,
		Rate:           d,
		EffectiveDate:  time.Now().UTC().Truncate(24 * time.Hour),
		CreatedAt:      time.Now().UTC(),
		UpdatedAt:      time.Now().UTC(),
	}
}

func TestMemoryFXCache_SetAndGetRate(t *testing.T) {
	ctx := context.Background()
	c := cache.NewMemoryFXCache(10 * time.Minute)

	// Cache miss initially
	rate, found := c.GetRate(ctx, "USD", "IDR")
	assert.False(t, found)
	assert.Nil(t, rate)

	// Set rate
	orig := sampleRate("USD", "IDR", "16250.500000")
	c.SetRate(ctx, orig, 10*time.Minute)

	// Cache hit (standard casing)
	cached, found := c.GetRate(ctx, "USD", "IDR")
	require.True(t, found)
	require.NotNil(t, cached)
	assert.Equal(t, orig.ID, cached.ID)
	assert.True(t, orig.Rate.Equal(cached.Rate))

	// Case insensitive lookup
	cachedLower, found := c.GetRate(ctx, "usd", "idr")
	require.True(t, found)
	require.NotNil(t, cachedLower)
	assert.True(t, orig.Rate.Equal(cachedLower.Rate))

	// Defensive copy check: mutating returned pointer must not modify cache
	cached.Rate = decimal.NewFromInt(999999)
	cachedFresh, _ := c.GetRate(ctx, "USD", "IDR")
	assert.True(t, orig.Rate.Equal(cachedFresh.Rate))
}

func TestMemoryFXCache_LatestRates(t *testing.T) {
	ctx := context.Background()
	c := cache.NewMemoryFXCache(10 * time.Minute)

	rates := []*domain.ExchangeRate{
		sampleRate("USD", "EUR", "0.920000"),
		sampleRate("USD", "IDR", "16200.000000"),
		sampleRate("USD", "JPY", "154.500000"),
	}

	c.SetLatestRates(ctx, "USD", rates, 10*time.Minute)

	// Query latest rates list
	got, found := c.GetLatestRates(ctx, "USD")
	require.True(t, found)
	assert.Len(t, got, 3)

	// Verify individual pairs are also cached and queryable
	singleEUR, foundEUR := c.GetRate(ctx, "USD", "EUR")
	require.True(t, foundEUR)
	assert.True(t, singleEUR.Rate.Equal(decimal.RequireFromString("0.920000")))

	singleIDR, foundIDR := c.GetRate(ctx, "USD", "IDR")
	require.True(t, foundIDR)
	assert.True(t, singleIDR.Rate.Equal(decimal.RequireFromString("16200.000000")))
}

func TestMemoryFXCache_TTL_Expiration(t *testing.T) {
	ctx := context.Background()
	c := cache.NewMemoryFXCache(1 * time.Hour)

	r := sampleRate("USD", "SGD", "1.340000")
	// Set with 20ms TTL
	c.SetRate(ctx, r, 20*time.Millisecond)

	// Should be present immediately
	_, found := c.GetRate(ctx, "USD", "SGD")
	assert.True(t, found)

	// Wait for TTL expiration
	time.Sleep(35 * time.Millisecond)

	// Lazy eviction should return false
	_, foundAfter := c.GetRate(ctx, "USD", "SGD")
	assert.False(t, foundAfter)
}

func TestMemoryFXCache_Invalidate(t *testing.T) {
	ctx := context.Background()
	c := cache.NewMemoryFXCache(1 * time.Hour)

	c.SetRate(ctx, sampleRate("USD", "EUR", "0.92"), 1*time.Hour)
	c.SetRate(ctx, sampleRate("USD", "IDR", "16200"), 1*time.Hour)
	c.SetRate(ctx, sampleRate("EUR", "USD", "1.08"), 1*time.Hour)

	// Invalidate only USD
	c.Invalidate(ctx, "USD")

	// USD rates gone
	_, foundUSDEUR := c.GetRate(ctx, "USD", "EUR")
	assert.False(t, foundUSDEUR)
	_, foundUSDIDR := c.GetRate(ctx, "USD", "IDR")
	assert.False(t, foundUSDIDR)

	// EUR rate remains intact
	eurUSD, foundEUR := c.GetRate(ctx, "EUR", "USD")
	assert.True(t, foundEUR)
	require.NotNil(t, eurUSD)
}

func TestMemoryFXCache_InvalidateAll(t *testing.T) {
	ctx := context.Background()
	c := cache.NewMemoryFXCache(1 * time.Hour)

	c.SetRate(ctx, sampleRate("USD", "EUR", "0.92"), 1*time.Hour)
	c.SetRate(ctx, sampleRate("EUR", "USD", "1.08"), 1*time.Hour)

	c.InvalidateAll(ctx)

	sCount, lCount := c.Size()
	assert.Equal(t, 0, sCount)
	assert.Equal(t, 0, lCount)
}

func TestMemoryFXCache_CleanExpired(t *testing.T) {
	ctx := context.Background()
	c := cache.NewMemoryFXCache(1 * time.Hour)

	c.SetRate(ctx, sampleRate("USD", "EUR", "0.92"), 15*time.Millisecond)
	c.SetRate(ctx, sampleRate("USD", "IDR", "16200"), 1*time.Hour)

	time.Sleep(25 * time.Millisecond)

	cleaned := c.CleanExpired()
	assert.Equal(t, 1, cleaned)

	sCount, _ := c.Size()
	assert.Equal(t, 1, sCount)
}

func TestMemoryFXCache_Concurrency_RaceFree(t *testing.T) {
	ctx := context.Background()
	c := cache.NewMemoryFXCache(500 * time.Millisecond)

	const goroutines = 30
	const iterations = 100
	var wg sync.WaitGroup

	for i := 0; i < goroutines; i++ {
		wg.Add(1)
		go func(workerID int) {
			defer wg.Done()
			base := fmt.Sprintf("C%d", workerID%5)
			target := "USD"

			for j := 0; j < iterations; j++ {
				switch j % 5 {
				case 0:
					c.SetRate(ctx, sampleRate(base, target, "1.234"), 500*time.Millisecond)
				case 1:
					c.GetRate(ctx, base, target)
				case 2:
					c.SetLatestRates(ctx, base, []*domain.ExchangeRate{
						sampleRate(base, "USD", "1.234"),
						sampleRate(base, "EUR", "0.987"),
					}, 500*time.Millisecond)
				case 3:
					c.GetLatestRates(ctx, base)
				case 4:
					c.Invalidate(ctx, base)
				}
			}
		}(i)
	}

	wg.Wait()
}

func BenchmarkMemoryFXCache_GetRate(b *testing.B) {
	ctx := context.Background()
	c := cache.NewMemoryFXCache(1 * time.Hour)
	c.SetRate(ctx, sampleRate("USD", "IDR", "16200.00"), 1*time.Hour)

	b.ResetTimer()
	b.RunParallel(func(pb *testing.PB) {
		for pb.Next() {
			_, _ = c.GetRate(ctx, "USD", "IDR")
		}
	})
}
