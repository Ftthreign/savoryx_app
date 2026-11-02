package worker_test

import (
	"context"
	"errors"
	"io"
	"log/slog"
	"sync"
	"testing"
	"time"

	"github.com/ftthreign/savoryx_app/server/internal/adapter/worker"
	"github.com/ftthreign/savoryx_app/server/internal/core/domain"
	"github.com/shopspring/decimal"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

type mockExchangeRateRepo struct {
	mu            sync.Mutex
	upsertedRates []*domain.ExchangeRate
	upsertErr     error
}

func (m *mockExchangeRateRepo) UpsertRate(ctx context.Context, rate *domain.ExchangeRate) error {
	m.mu.Lock()
	defer m.mu.Unlock()
	if m.upsertErr != nil {
		return m.upsertErr
	}
	m.upsertedRates = append(m.upsertedRates, rate)
	return nil
}

func (m *mockExchangeRateRepo) GetLatestRate(ctx context.Context, base, target string) (*domain.ExchangeRate, error) {
	return nil, nil
}

func (m *mockExchangeRateRepo) GetHistoricalRate(ctx context.Context, base, target string, date time.Time) (*domain.ExchangeRate, error) {
	return nil, nil
}

func (m *mockExchangeRateRepo) ListLatestRates(ctx context.Context, base string) ([]*domain.ExchangeRate, error) {
	return nil, nil
}

func (m *mockExchangeRateRepo) ListSupportedCurrencies(ctx context.Context) ([]*domain.Currency, error) {
	return nil, nil
}

func (m *mockExchangeRateRepo) GetCurrency(ctx context.Context, code string) (*domain.Currency, error) {
	return nil, nil
}

type mockFXProvider struct {
	mu           sync.Mutex
	ratesByBase  map[string][]*domain.ExchangeRate
	fetchErr     error
	fetchedBases []string
}

func (m *mockFXProvider) FetchLatestRates(ctx context.Context, base string) ([]*domain.ExchangeRate, error) {
	m.mu.Lock()
	defer m.mu.Unlock()
	m.fetchedBases = append(m.fetchedBases, base)
	if m.fetchErr != nil {
		return nil, m.fetchErr
	}
	return m.ratesByBase[base], nil
}

func (m *mockFXProvider) FetchHistoricalRates(ctx context.Context, base string, date time.Time) ([]*domain.ExchangeRate, error) {
	return nil, nil
}

func TestSyncRates_Success(t *testing.T) {
	discardLogger := slog.New(slog.NewTextHandler(io.Discard, nil))
	repo := &mockExchangeRateRepo{}

	provider := &mockFXProvider{
		ratesByBase: map[string][]*domain.ExchangeRate{
			"USD": {
				{
					ID:             domain.NewUUIDv7(),
					BaseCurrency:   "USD",
					TargetCurrency: "EUR",
					Rate:           decimal.NewFromFloat(0.92),
					EffectiveDate:  time.Now().UTC().Truncate(24 * time.Hour),
				},
				{
					ID:             domain.NewUUIDv7(),
					BaseCurrency:   "USD",
					TargetCurrency: "IDR",
					Rate:           decimal.NewFromInt(16200),
					EffectiveDate:  time.Now().UTC().Truncate(24 * time.Hour),
				},
			},
			"EUR": {
				{
					ID:             domain.NewUUIDv7(),
					BaseCurrency:   "EUR",
					TargetCurrency: "USD",
					Rate:           decimal.NewFromFloat(1.08),
					EffectiveDate:  time.Now().UTC().Truncate(24 * time.Hour),
				},
			},
		},
	}

	w := worker.NewFXCronWorker(
		repo,
		provider,
		discardLogger,
		worker.WithBaseCurrencies("USD", "EUR"),
	)

	err := w.SyncRates(context.Background())
	require.NoError(t, err)

	repo.mu.Lock()
	defer repo.mu.Unlock()
	assert.Len(t, repo.upsertedRates, 3)
}

func TestSyncRates_ProviderError(t *testing.T) {
	discardLogger := slog.New(slog.NewTextHandler(io.Discard, nil))
	repo := &mockExchangeRateRepo{}
	provider := &mockFXProvider{
		fetchErr: errors.New("upstream service unavailable"),
	}

	w := worker.NewFXCronWorker(
		repo,
		provider,
		discardLogger,
		worker.WithBaseCurrencies("USD"),
	)

	err := w.SyncRates(context.Background())
	require.Error(t, err)
	assert.Contains(t, err.Error(), "upstream service unavailable")
}

func TestSyncRates_ContextCancelled(t *testing.T) {
	discardLogger := slog.New(slog.NewTextHandler(io.Discard, nil))
	repo := &mockExchangeRateRepo{}
	provider := &mockFXProvider{}

	w := worker.NewFXCronWorker(
		repo,
		provider,
		discardLogger,
		worker.WithBaseCurrencies("USD"),
	)

	ctx, cancel := context.WithCancel(context.Background())
	cancel() // Cancel immediately

	err := w.SyncRates(ctx)
	require.Error(t, err)
	assert.Contains(t, err.Error(), "context canceled")
}

func TestSyncRates_RepoUpsertError(t *testing.T) {
	discardLogger := slog.New(slog.NewTextHandler(io.Discard, nil))
	repo := &mockExchangeRateRepo{
		upsertErr: errors.New("db disk full"),
	}
	provider := &mockFXProvider{
		ratesByBase: map[string][]*domain.ExchangeRate{
			"USD": {
				{
					ID:             domain.NewUUIDv7(),
					BaseCurrency:   "USD",
					TargetCurrency: "EUR",
					Rate:           decimal.NewFromFloat(0.92),
				},
			},
		},
	}

	w := worker.NewFXCronWorker(
		repo,
		provider,
		discardLogger,
		worker.WithBaseCurrencies("USD"),
	)

	err := w.SyncRates(context.Background())
	require.Error(t, err)
	assert.Contains(t, err.Error(), "db disk full")
}

func TestFXCronWorker_Lifecycle(t *testing.T) {
	discardLogger := slog.New(slog.NewTextHandler(io.Discard, nil))
	repo := &mockExchangeRateRepo{}
	provider := &mockFXProvider{}

	w := worker.NewFXCronWorker(
		repo,
		provider,
		discardLogger,
		worker.WithSchedule("5 0 * * *"),
		worker.WithSyncTimeout(10*time.Second),
	)

	assert.False(t, w.IsRunning())

	err := w.Start(context.Background())
	require.NoError(t, err)
	assert.True(t, w.IsRunning())

	// Calling Start again should be idempotent
	err = w.Start(context.Background())
	require.NoError(t, err)
	assert.True(t, w.IsRunning())

	stopCtx := w.Stop()
	select {
	case <-stopCtx.Done():
		// Successfully stopped
	case <-time.After(2 * time.Second):
		t.Fatal("worker stop timed out")
	}

	assert.False(t, w.IsRunning())
}

func TestFXCronWorker_InvalidSchedule(t *testing.T) {
	discardLogger := slog.New(slog.NewTextHandler(io.Discard, nil))
	repo := &mockExchangeRateRepo{}
	provider := &mockFXProvider{}

	w := worker.NewFXCronWorker(
		repo,
		provider,
		discardLogger,
		worker.WithSchedule("invalid-schedule-expression"),
	)

	err := w.Start(context.Background())
	require.Error(t, err)
	assert.False(t, w.IsRunning())
}
