package service_test

import (
	"bytes"
	"context"
	"errors"
	"log/slog"
	"sync"
	"testing"
	"time"

	"github.com/ftthreign/savoryx_app/server/internal/adapter/cache"
	"github.com/ftthreign/savoryx_app/server/internal/core/domain"
	"github.com/ftthreign/savoryx_app/server/internal/core/service"
	"github.com/shopspring/decimal"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

type mockFXRepo struct {
	mu            sync.Mutex
	rates         map[string]*domain.ExchangeRate
	currencies    []*domain.Currency
	upsertedRates []*domain.ExchangeRate
	getErr        error
	upsertErr     error
}

func newMockFXRepo() *mockFXRepo {
	return &mockFXRepo{
		rates: make(map[string]*domain.ExchangeRate),
	}
}

func (m *mockFXRepo) UpsertRate(ctx context.Context, rate *domain.ExchangeRate) error {
	m.mu.Lock()
	defer m.mu.Unlock()
	if m.upsertErr != nil {
		return m.upsertErr
	}
	key := rate.BaseCurrency + ":" + rate.TargetCurrency
	m.rates[key] = rate
	m.upsertedRates = append(m.upsertedRates, rate)
	return nil
}

func (m *mockFXRepo) GetLatestRate(ctx context.Context, base, target string) (*domain.ExchangeRate, error) {
	m.mu.Lock()
	defer m.mu.Unlock()
	if m.getErr != nil {
		return nil, m.getErr
	}
	key := base + ":" + target
	if r, found := m.rates[key]; found {
		return r, nil
	}
	return nil, domain.ErrNotFound
}

func (m *mockFXRepo) GetHistoricalRate(ctx context.Context, base, target string, date time.Time) (*domain.ExchangeRate, error) {
	m.mu.Lock()
	defer m.mu.Unlock()
	if m.getErr != nil {
		return nil, m.getErr
	}
	key := base + ":" + target + ":" + date.Format("2006-01-02")
	if r, found := m.rates[key]; found {
		return r, nil
	}
	return nil, domain.ErrNotFound
}

func (m *mockFXRepo) ListLatestRates(ctx context.Context, base string) ([]*domain.ExchangeRate, error) {
	m.mu.Lock()
	defer m.mu.Unlock()
	if m.getErr != nil {
		return nil, m.getErr
	}
	var result []*domain.ExchangeRate
	for _, r := range m.rates {
		if r.BaseCurrency == base {
			result = append(result, r)
		}
	}
	return result, nil
}

func (m *mockFXRepo) ListSupportedCurrencies(ctx context.Context) ([]*domain.Currency, error) {
	m.mu.Lock()
	defer m.mu.Unlock()
	if m.getErr != nil {
		return nil, m.getErr
	}
	return m.currencies, nil
}

func (m *mockFXRepo) GetCurrency(ctx context.Context, code string) (*domain.Currency, error) {
	m.mu.Lock()
	defer m.mu.Unlock()
	for _, c := range m.currencies {
		if c.Code == code {
			return c, nil
		}
	}
	return nil, domain.ErrNotFound
}

type mockFXProvider struct {
	mu              sync.Mutex
	latestRates     map[string][]*domain.ExchangeRate
	historicalRates map[string][]*domain.ExchangeRate
	err             error
}

func newMockFXProvider() *mockFXProvider {
	return &mockFXProvider{
		latestRates:     make(map[string][]*domain.ExchangeRate),
		historicalRates: make(map[string][]*domain.ExchangeRate),
	}
}

func (m *mockFXProvider) FetchLatestRates(ctx context.Context, base string) ([]*domain.ExchangeRate, error) {
	m.mu.Lock()
	defer m.mu.Unlock()
	if m.err != nil {
		return nil, m.err
	}
	return m.latestRates[base], nil
}

func (m *mockFXProvider) FetchHistoricalRates(ctx context.Context, base string, date time.Time) ([]*domain.ExchangeRate, error) {
	m.mu.Lock()
	defer m.mu.Unlock()
	if m.err != nil {
		return nil, m.err
	}
	key := base + ":" + date.Format("2006-01-02")
	return m.historicalRates[key], nil
}

func TestExchangeRateService_GetLatestRate_SameCurrency(t *testing.T) {
	repo := newMockFXRepo()
	svc := service.NewExchangeRateService(repo, nil, nil)

	rate, err := svc.GetLatestRate(context.Background(), "USD", "USD")
	require.NoError(t, err)
	require.NotNil(t, rate)
	assert.Equal(t, "USD", rate.BaseCurrency)
	assert.Equal(t, "USD", rate.TargetCurrency)
	assert.True(t, rate.Rate.Equal(decimal.NewFromInt(1)))
}

func TestExchangeRateService_GetLatestRate_CacheHit(t *testing.T) {
	repo := newMockFXRepo()
	fxCache := cache.NewMemoryFXCache(1 * time.Hour)
	svc := service.NewExchangeRateService(repo, fxCache, nil)

	cachedRate := &domain.ExchangeRate{
		ID:             domain.NewUUIDv7(),
		BaseCurrency:   "USD",
		TargetCurrency: "EUR",
		Rate:           decimal.RequireFromString("0.920000"),
		EffectiveDate:  time.Now().UTC().Truncate(24 * time.Hour),
	}
	fxCache.SetRate(context.Background(), cachedRate, 1*time.Hour)

	rate, err := svc.GetLatestRate(context.Background(), "USD", "EUR")
	require.NoError(t, err)
	require.NotNil(t, rate)
	assert.True(t, rate.Rate.Equal(decimal.RequireFromString("0.920000")))
}

func TestExchangeRateService_GetLatestRate_DBHit(t *testing.T) {
	repo := newMockFXRepo()
	fxCache := cache.NewMemoryFXCache(1 * time.Hour)
	svc := service.NewExchangeRateService(repo, fxCache, nil)

	dbRate := &domain.ExchangeRate{
		ID:             domain.NewUUIDv7(),
		BaseCurrency:   "USD",
		TargetCurrency: "IDR",
		Rate:           decimal.RequireFromString("16200.000000"),
		EffectiveDate:  time.Now().UTC().Truncate(24 * time.Hour),
	}
	_ = repo.UpsertRate(context.Background(), dbRate)

	rate, err := svc.GetLatestRate(context.Background(), "USD", "IDR")
	require.NoError(t, err)
	require.NotNil(t, rate)
	assert.True(t, rate.Rate.Equal(decimal.RequireFromString("16200.000000")))

	cached, found := fxCache.GetRate(context.Background(), "USD", "IDR")
	assert.True(t, found)
	assert.True(t, cached.Rate.Equal(decimal.RequireFromString("16200.000000")))
}

func TestExchangeRateService_GetLatestRate_ProviderFallback(t *testing.T) {
	repo := newMockFXRepo()
	fxCache := cache.NewMemoryFXCache(1 * time.Hour)
	provider := newMockFXProvider()
	svc := service.NewExchangeRateService(repo, fxCache, provider)

	provider.latestRates["USD"] = []*domain.ExchangeRate{
		{
			ID:             domain.NewUUIDv7(),
			BaseCurrency:   "USD",
			TargetCurrency: "SGD",
			Rate:           decimal.RequireFromString("1.340000"),
			EffectiveDate:  time.Now().UTC().Truncate(24 * time.Hour),
		},
	}

	rate, err := svc.GetLatestRate(context.Background(), "USD", "SGD")
	require.NoError(t, err)
	require.NotNil(t, rate)
	assert.True(t, rate.Rate.Equal(decimal.RequireFromString("1.340000")))

	dbRate, err := repo.GetLatestRate(context.Background(), "USD", "SGD")
	require.NoError(t, err)
	assert.True(t, dbRate.Rate.Equal(decimal.RequireFromString("1.340000")))
}

func TestExchangeRateService_GetLatestRate_InfrastructureError(t *testing.T) {
	repo := newMockFXRepo()
	repo.getErr = errors.New("db connection failure")
	svc := service.NewExchangeRateService(repo, nil, nil)

	_, err := svc.GetLatestRate(context.Background(), "USD", "EUR")
	require.Error(t, err)
	assert.False(t, errors.Is(err, domain.ErrNotFound), "infra error must not be masked as not found")
	assert.Contains(t, err.Error(), "db connection failure")
}

func TestExchangeRateService_GetLatestRate_ValidationAndNotFound(t *testing.T) {
	repo := newMockFXRepo()
	svc := service.NewExchangeRateService(repo, nil, nil)

	_, err := svc.GetLatestRate(context.Background(), "US", "EUR")
	require.Error(t, err)
	assert.True(t, errors.Is(err, domain.ErrInvalidInput))

	_, err = svc.GetLatestRate(context.Background(), "USD", "XYZ")
	require.Error(t, err)
	assert.True(t, errors.Is(err, domain.ErrNotFound))
}

func TestExchangeRateService_GetHistoricalRate(t *testing.T) {
	repo := newMockFXRepo()
	provider := newMockFXProvider()
	svc := service.NewExchangeRateService(repo, nil, provider)

	targetDate := time.Date(2026, 10, 15, 0, 0, 0, 0, time.UTC)

	_, err := svc.GetHistoricalRate(context.Background(), "USD", "EUR", time.Now().Add(48*time.Hour))
	require.Error(t, err)
	assert.True(t, errors.Is(err, domain.ErrInvalidInput))

	provider.historicalRates["USD:2026-10-15"] = []*domain.ExchangeRate{
		{
			ID:             domain.NewUUIDv7(),
			BaseCurrency:   "USD",
			TargetCurrency: "EUR",
			Rate:           decimal.RequireFromString("0.915000"),
			EffectiveDate:  targetDate,
		},
	}

	rate, err := svc.GetHistoricalRate(context.Background(), "USD", "EUR", targetDate)
	require.NoError(t, err)
	require.NotNil(t, rate)
	assert.True(t, rate.Rate.Equal(decimal.RequireFromString("0.915000")))
}

func TestExchangeRateService_ListLatestRates(t *testing.T) {
	repo := newMockFXRepo()
	fxCache := cache.NewMemoryFXCache(1 * time.Hour)
	provider := newMockFXProvider()
	svc := service.NewExchangeRateService(repo, fxCache, provider)

	provider.latestRates["USD"] = []*domain.ExchangeRate{
		{
			ID:             domain.NewUUIDv7(),
			BaseCurrency:   "USD",
			TargetCurrency: "EUR",
			Rate:           decimal.RequireFromString("0.920000"),
		},
		{
			ID:             domain.NewUUIDv7(),
			BaseCurrency:   "USD",
			TargetCurrency: "IDR",
			Rate:           decimal.RequireFromString("16200.000000"),
		},
	}

	rates, err := svc.ListLatestRates(context.Background(), "USD")
	require.NoError(t, err)
	assert.Len(t, rates, 2)

	cachedRates, err := svc.ListLatestRates(context.Background(), "USD")
	require.NoError(t, err)
	assert.Len(t, cachedRates, 2)
}

func TestExchangeRateService_ListSupportedCurrencies(t *testing.T) {
	repo := newMockFXRepo()
	repo.currencies = []*domain.Currency{
		{Code: "IDR", Name: "Indonesian Rupiah", Symbol: "Rp", DecimalPlaces: 0, IsActive: true},
		{Code: "USD", Name: "United States Dollar", Symbol: "$", DecimalPlaces: 2, IsActive: true},
	}
	svc := service.NewExchangeRateService(repo, nil, nil)

	currencies, err := svc.ListSupportedCurrencies(context.Background())
	require.NoError(t, err)
	assert.Len(t, currencies, 2)
	assert.Equal(t, "IDR", currencies[0].Code)
}

func TestExchangeRateService_PersistFetched_LogsWithoutFailing(t *testing.T) {
	var logBuf bytes.Buffer
	logger := slog.New(slog.NewJSONHandler(&logBuf, nil))

	repo := newMockFXRepo()
	repo.upsertErr = errors.New("db disk write failure")
	provider := newMockFXProvider()

	svc := service.NewExchangeRateService(
		repo,
		nil,
		provider,
		service.WithExchangeRateLogger(logger),
	)

	provider.latestRates["USD"] = []*domain.ExchangeRate{
		{
			ID:             domain.NewUUIDv7(),
			BaseCurrency:   "USD",
			TargetCurrency: "EUR",
			Rate:           decimal.RequireFromString("0.920000"),
			EffectiveDate:  time.Now().UTC().Truncate(24 * time.Hour),
		},
	}

	rate, err := svc.GetLatestRate(context.Background(), "USD", "EUR")
	require.NoError(t, err, "persistence error must not fail read operation")
	assert.True(t, rate.Rate.Equal(decimal.RequireFromString("0.920000")))

	logs := logBuf.String()
	assert.Contains(t, logs, "failed to persist fallback fx rate")
	assert.Contains(t, logs, "USD")
	assert.Contains(t, logs, "EUR")
	assert.NotContains(t, logs, "0.920000", "monetary rate value must not be leaked to logs")
}
