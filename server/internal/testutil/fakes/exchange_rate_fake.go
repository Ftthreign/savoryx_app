package fakes

import (
	"context"
	"sort"
	"sync"
	"time"

	"github.com/ftthreign/savoryx_app/server/internal/core/domain"
	"github.com/ftthreign/savoryx_app/server/internal/port"
	"github.com/samber/oops"
)

type InMemoryExchangeRateRepository struct {
	mu         sync.RWMutex
	rates      map[string]*domain.ExchangeRate
	currencies map[string]*domain.Currency
}

func NewInMemoryExchangeRateRepository(currencies ...*domain.Currency) *InMemoryExchangeRateRepository {
	r := &InMemoryExchangeRateRepository{
		rates:      make(map[string]*domain.ExchangeRate),
		currencies: make(map[string]*domain.Currency),
	}
	for _, c := range currencies {
		cp := *c
		r.currencies[c.Code] = &cp
	}
	return r
}

func rateKey(base, target string, date time.Time) string {
	return base + "|" + target + "|" + date.UTC().Format("2006-01-02")
}

func (r *InMemoryExchangeRateRepository) UpsertRate(_ context.Context, rate *domain.ExchangeRate) error {
	if rate == nil {
		return oops.In("fake_exchange_rate_repo").Wrap(domain.ErrInvalidInput)
	}

	r.mu.Lock()
	defer r.mu.Unlock()

	now := time.Now().UTC()
	key := rateKey(rate.BaseCurrency, rate.TargetCurrency, rate.EffectiveDate)

	if existing, ok := r.rates[key]; ok {
		existing.Rate = rate.Rate
		existing.UpdatedAt = now
		*rate = *existing
		return nil
	}

	stored := *rate
	stored.EffectiveDate = rate.EffectiveDate.UTC().Truncate(24 * time.Hour)
	stored.CreatedAt = now
	stored.UpdatedAt = now
	r.rates[key] = &stored
	*rate = stored
	return nil
}

func (r *InMemoryExchangeRateRepository) GetLatestRate(_ context.Context, base, target string) (*domain.ExchangeRate, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()

	var latest *domain.ExchangeRate
	for _, v := range r.rates {
		if v.BaseCurrency != base || v.TargetCurrency != target {
			continue
		}
		if latest == nil || v.EffectiveDate.After(latest.EffectiveDate) {
			latest = v
		}
	}
	if latest == nil {
		return nil, domain.ErrNotFound
	}
	cp := *latest
	return &cp, nil
}

func (r *InMemoryExchangeRateRepository) GetHistoricalRate(_ context.Context, base, target string, date time.Time) (*domain.ExchangeRate, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()

	v, ok := r.rates[rateKey(base, target, date)]
	if !ok {
		return nil, domain.ErrNotFound
	}
	cp := *v
	return &cp, nil
}

func (r *InMemoryExchangeRateRepository) ListLatestRates(_ context.Context, base string) ([]*domain.ExchangeRate, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()

	latestByTarget := make(map[string]*domain.ExchangeRate)
	for _, v := range r.rates {
		if v.BaseCurrency != base {
			continue
		}
		cur, ok := latestByTarget[v.TargetCurrency]
		if !ok || v.EffectiveDate.After(cur.EffectiveDate) {
			latestByTarget[v.TargetCurrency] = v
		}
	}

	result := make([]*domain.ExchangeRate, 0, len(latestByTarget))
	for _, v := range latestByTarget {
		cp := *v
		result = append(result, &cp)
	}
	sort.Slice(result, func(i, j int) bool { return result[i].TargetCurrency < result[j].TargetCurrency })
	return result, nil
}

func (r *InMemoryExchangeRateRepository) ListSupportedCurrencies(_ context.Context) ([]*domain.Currency, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()

	result := make([]*domain.Currency, 0, len(r.currencies))
	for _, c := range r.currencies {
		cp := *c
		result = append(result, &cp)
	}
	sort.Slice(result, func(i, j int) bool { return result[i].Code < result[j].Code })
	return result, nil
}

func (r *InMemoryExchangeRateRepository) GetCurrency(_ context.Context, code string) (*domain.Currency, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()

	c, ok := r.currencies[code]
	if !ok {
		return nil, domain.ErrNotFound
	}
	cp := *c
	return &cp, nil
}

// RowCount returns the number of stored rate snapshots (test inspection helper).
func (r *InMemoryExchangeRateRepository) RowCount() int {
	r.mu.RLock()
	defer r.mu.RUnlock()
	return len(r.rates)
}

var _ port.ExchangeRateRepository = (*InMemoryExchangeRateRepository)(nil)
