package cache

import (
	"context"
	"strings"
	"sync"
	"time"

	"github.com/ftthreign/savoryx_app/server/internal/core/domain"
	"github.com/ftthreign/savoryx_app/server/internal/port"
)

const (
	DefaultCacheTTL = 1 * time.Hour
)

type singleRateItem struct {
	rate      *domain.ExchangeRate
	expiresAt time.Time
}

type listRatesItem struct {
	rates     []*domain.ExchangeRate
	expiresAt time.Time
}

type MemoryFXCache struct {
	mu          sync.RWMutex
	defaultTTL  time.Duration
	rates       map[string]singleRateItem
	latestRates map[string]listRatesItem
}

func NewMemoryFXCache(defaultTTL time.Duration) *MemoryFXCache {
	if defaultTTL <= 0 {
		defaultTTL = DefaultCacheTTL
	}

	return &MemoryFXCache{
		defaultTTL:  defaultTTL,
		rates:       make(map[string]singleRateItem),
		latestRates: make(map[string]listRatesItem),
	}
}

func rateKey(base, target string) string {
	return strings.ToUpper(strings.TrimSpace(base)) + ":" + strings.ToUpper(strings.TrimSpace(target))
}

func normalizeCode(code string) string {
	return strings.ToUpper(strings.TrimSpace(code))
}

func (c *MemoryFXCache) GetRate(ctx context.Context, base, target string) (*domain.ExchangeRate, bool) {
	key := rateKey(base, target)

	c.mu.RLock()
	item, exists := c.rates[key]
	c.mu.RUnlock()

	if !exists {
		return nil, false
	}

	if time.Now().After(item.expiresAt) {
		// Lazily remove expired entry
		c.mu.Lock()
		delete(c.rates, key)
		c.mu.Unlock()
		return nil, false
	}

	return copyRate(item.rate), true
}

func (c *MemoryFXCache) SetRate(ctx context.Context, rate *domain.ExchangeRate, ttl time.Duration) {
	if rate == nil {
		return
	}

	if ttl <= 0 {
		ttl = c.defaultTTL
	}

	key := rateKey(rate.BaseCurrency, rate.TargetCurrency)
	item := singleRateItem{
		rate:      copyRate(rate),
		expiresAt: time.Now().Add(ttl),
	}

	c.mu.Lock()
	c.rates[key] = item
	c.mu.Unlock()
}

func (c *MemoryFXCache) GetLatestRates(ctx context.Context, base string) ([]*domain.ExchangeRate, bool) {
	baseKey := normalizeCode(base)

	c.mu.RLock()
	item, exists := c.latestRates[baseKey]
	c.mu.RUnlock()

	if !exists {
		return nil, false
	}

	if time.Now().After(item.expiresAt) {
		c.mu.Lock()
		delete(c.latestRates, baseKey)
		c.mu.Unlock()
		return nil, false
	}

	return copyRates(item.rates), true
}

func (c *MemoryFXCache) SetLatestRates(ctx context.Context, base string, rates []*domain.ExchangeRate, ttl time.Duration) {
	if ttl <= 0 {
		ttl = c.defaultTTL
	}

	baseKey := normalizeCode(base)
	expiresAt := time.Now().Add(ttl)

	c.mu.Lock()
	defer c.mu.Unlock()

	c.latestRates[baseKey] = listRatesItem{
		rates:     copyRates(rates),
		expiresAt: expiresAt,
	}

	for _, r := range rates {
		if r != nil {
			key := rateKey(r.BaseCurrency, r.TargetCurrency)
			c.rates[key] = singleRateItem{
				rate:      copyRate(r),
				expiresAt: expiresAt,
			}
		}
	}
}

func (c *MemoryFXCache) Invalidate(ctx context.Context, base string) {
	baseKey := normalizeCode(base)
	prefix := baseKey + ":"

	c.mu.Lock()
	defer c.mu.Unlock()

	delete(c.latestRates, baseKey)

	for k := range c.rates {
		if strings.HasPrefix(k, prefix) {
			delete(c.rates, k)
		}
	}
}

func (c *MemoryFXCache) InvalidateAll(ctx context.Context) {
	c.mu.Lock()
	defer c.mu.Unlock()

	c.rates = make(map[string]singleRateItem)
	c.latestRates = make(map[string]listRatesItem)
}

func (c *MemoryFXCache) CleanExpired() int {
	now := time.Now()
	cleaned := 0

	c.mu.Lock()
	defer c.mu.Unlock()

	for k, item := range c.rates {
		if now.After(item.expiresAt) {
			delete(c.rates, k)
			cleaned++
		}
	}

	for k, item := range c.latestRates {
		if now.After(item.expiresAt) {
			delete(c.latestRates, k)
			cleaned++
		}
	}

	return cleaned
}

func (c *MemoryFXCache) Size() (singleCount int, listCount int) {
	c.mu.RLock()
	defer c.mu.RUnlock()
	return len(c.rates), len(c.latestRates)
}

func copyRate(r *domain.ExchangeRate) *domain.ExchangeRate {
	if r == nil {
		return nil
	}
	cpy := *r
	return &cpy
}

func copyRates(list []*domain.ExchangeRate) []*domain.ExchangeRate {
	if list == nil {
		return nil
	}
	result := make([]*domain.ExchangeRate, len(list))
	for i, r := range list {
		result[i] = copyRate(r)
	}
	return result
}

var _ port.FXCache = (*MemoryFXCache)(nil)
