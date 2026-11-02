package test

import (
	"context"
	"encoding/json"
	"errors"
	"net/http"
	"sync"
	"testing"
	"time"

	"github.com/ftthreign/savoryx_app/server/internal/adapter/cache"
	httpAdapter "github.com/ftthreign/savoryx_app/server/internal/adapter/handler/http"
	"github.com/ftthreign/savoryx_app/server/internal/adapter/worker"
	"github.com/ftthreign/savoryx_app/server/internal/core/domain"
	"github.com/ftthreign/savoryx_app/server/internal/core/service"
	"github.com/ftthreign/savoryx_app/server/internal/testutil/fakes"
	"github.com/shopspring/decimal"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

// stubFXProvider is a controllable upstream FX provider. Rates are kept as
// decimal strings end to end so the tests prove no float64 conversion occurs.
type stubFXProvider struct {
	mu    sync.Mutex
	date  time.Time
	rates map[string]map[string]string // base -> target -> decimal string
	err   error
}

func newStubFXProvider(date time.Time) *stubFXProvider {
	return &stubFXProvider{date: date, rates: make(map[string]map[string]string)}
}

func (p *stubFXProvider) SetRates(base string, rates map[string]string) {
	p.mu.Lock()
	defer p.mu.Unlock()
	p.rates[base] = rates
}

func (p *stubFXProvider) SetError(err error) {
	p.mu.Lock()
	defer p.mu.Unlock()
	p.err = err
}

func (p *stubFXProvider) FetchLatestRates(_ context.Context, base string) ([]*domain.ExchangeRate, error) {
	p.mu.Lock()
	defer p.mu.Unlock()

	if p.err != nil {
		return nil, p.err
	}

	out := make([]*domain.ExchangeRate, 0, len(p.rates[base]))
	for target, raw := range p.rates[base] {
		out = append(out, &domain.ExchangeRate{
			ID:             domain.NewUUIDv7(),
			BaseCurrency:   base,
			TargetCurrency: target,
			Rate:           decimal.RequireFromString(raw),
			EffectiveDate:  p.date,
		})
	}
	return out, nil
}

func (p *stubFXProvider) FetchHistoricalRates(_ context.Context, _ string, _ time.Time) ([]*domain.ExchangeRate, error) {
	return nil, nil
}

type fxEnv struct {
	*TestEnv
	Repo     *fakes.InMemoryExchangeRateRepository
	Cache    *cache.MemoryFXCache
	Provider *stubFXProvider
	Worker   *worker.FXCronWorker
	Token    string
	Today    string
}

func setupFXEnvironment(t *testing.T) *fxEnv {
	t.Helper()

	today := time.Now().UTC().Truncate(24 * time.Hour)

	repo := fakes.NewInMemoryExchangeRateRepository(
		&domain.Currency{Code: "EUR", Name: "Euro", Symbol: "EUR", DecimalPlaces: 2, IsActive: true},
		&domain.Currency{Code: "IDR", Name: "Indonesian Rupiah", Symbol: "Rp", DecimalPlaces: 0, IsActive: true},
		&domain.Currency{Code: "USD", Name: "United States Dollar", Symbol: "$", DecimalPlaces: 2, IsActive: true},
	)
	fxCache := cache.NewMemoryFXCache(time.Hour)
	provider := newStubFXProvider(today)

	fxService := service.NewExchangeRateService(repo, fxCache, provider)
	env := setupTestEnvironment(t, httpAdapter.WithExchangeRateService(fxService))

	w := worker.NewFXCronWorker(
		repo,
		provider,
		env.Logger,
		worker.WithCache(fxCache),
		worker.WithBaseCurrencies("USD"),
	)

	token, _ := env.RegisterDevice(t, "FX Flow Phone", "android", "1.0.0")

	return &fxEnv{
		TestEnv:  env,
		Repo:     repo,
		Cache:    fxCache,
		Provider: provider,
		Worker:   w,
		Token:    token,
		Today:    today.Format("2006-01-02"),
	}
}

type fxRatePayload struct {
	BaseCurrency   string `json:"base_currency"`
	TargetCurrency string `json:"target_currency"`
	Rate           string `json:"rate"`
	EffectiveDate  string `json:"effective_date"`
}

func (e *fxEnv) getJSON(t *testing.T, path string, dst any) int {
	t.Helper()

	res, err := e.DoAuthRequest(e.Token, http.MethodGet, path, nil)
	require.NoError(t, err)
	defer res.Body.Close()

	if dst != nil && res.StatusCode == http.StatusOK {
		require.NoError(t, json.NewDecoder(res.Body).Decode(dst))
	}
	return res.StatusCode
}

func (e *fxEnv) latestRate(t *testing.T, base, target string) string {
	t.Helper()

	var body struct {
		Data fxRatePayload `json:"data"`
	}
	status := e.getJSON(t, "/api/v1/rates/latest?base="+base+"&target="+target, &body)
	require.Equal(t, http.StatusOK, status)
	return body.Data.Rate
}

func dec(s string) string {
	return decimal.RequireFromString(s).String()
}

func TestE2E_FX_WorkerSyncToAPIPrecisionFlow(t *testing.T) {
	env := setupFXEnvironment(t)
	ctx := context.Background()

	env.Provider.SetRates("USD", map[string]string{
		"IDR": "16234.567891",
		"EUR": "0.920000",
		"JPY": "154.1",
		"TST": "0.000123",
	})

	// Stage 1: worker sync persists upstream snapshots.
	require.NoError(t, env.Worker.SyncRates(ctx))
	assert.Equal(t, 4, env.Repo.RowCount())

	// Stage 2: list endpoint serves exact decimals with envelope metadata.
	var list struct {
		Data []fxRatePayload `json:"data"`
		Meta struct {
			Base  string `json:"base"`
			Total int    `json:"total"`
		} `json:"meta"`
	}
	require.Equal(t, http.StatusOK, env.getJSON(t, "/api/v1/rates/latest?base=USD", &list))
	assert.Equal(t, "USD", list.Meta.Base)
	assert.Equal(t, 4, list.Meta.Total)

	got := make(map[string]string, len(list.Data))
	for _, r := range list.Data {
		assert.Equal(t, env.Today, r.EffectiveDate)
		got[r.TargetCurrency] = r.Rate
	}
	assert.Equal(t, map[string]string{
		"IDR": dec("16234.567891"),
		"EUR": dec("0.92"),
		"JPY": dec("154.1"),
		"TST": dec("0.000123"),
	}, got)

	// Stage 3: single-pair lookup warms the cache from the database.
	assert.Equal(t, "16234.567891", env.latestRate(t, "USD", "IDR"))
	cached, found := env.Cache.GetRate(ctx, "USD", "IDR")
	require.True(t, found, "single-pair lookup must populate the cache")
	assert.True(t, cached.Rate.Equal(decimal.RequireFromString("16234.567891")))

	// Stage 4: upstream moves; second sync must upsert in place (idempotent)
	// and invalidate the cache so the API never serves the stale snapshot.
	env.Provider.SetRates("USD", map[string]string{
		"IDR": "16300.000001",
		"EUR": "0.920000",
		"JPY": "154.1",
		"TST": "0.000123",
	})
	require.NoError(t, env.Worker.SyncRates(ctx))
	assert.Equal(t, 4, env.Repo.RowCount(), "same-day resync must not create duplicate snapshots")

	_, stillCached := env.Cache.GetRate(ctx, "USD", "IDR")
	assert.False(t, stillCached, "successful sync must invalidate cached rates for the base")
	assert.Equal(t, "16300.000001", env.latestRate(t, "USD", "IDR"))

	// Stage 5: historical endpoint resolves the same-day snapshot.
	var hist struct {
		Data fxRatePayload `json:"data"`
	}
	require.Equal(t, http.StatusOK,
		env.getJSON(t, "/api/v1/rates/historical?base=USD&target=IDR&date="+env.Today, &hist))
	assert.Equal(t, "16300.000001", hist.Data.Rate)

	assert.Equal(t, http.StatusNotFound,
		env.getJSON(t, "/api/v1/rates/historical?base=USD&target=IDR&date=2001-01-01", nil))

	// Stage 6: same-currency identity rate is exactly 1.
	assert.Equal(t, "1", env.latestRate(t, "USD", "USD"))
}

func TestE2E_FX_SupportedCurrenciesEndpoint(t *testing.T) {
	env := setupFXEnvironment(t)

	var body struct {
		Data []struct {
			Code string `json:"code"`
		} `json:"data"`
		Meta struct {
			Total int `json:"total"`
		} `json:"meta"`
	}
	require.Equal(t, http.StatusOK, env.getJSON(t, "/api/v1/currencies", &body))
	assert.Equal(t, 3, body.Meta.Total)

	codes := make([]string, 0, len(body.Data))
	for _, c := range body.Data {
		codes = append(codes, c.Code)
	}
	assert.Equal(t, []string{"EUR", "IDR", "USD"}, codes)
}

func TestE2E_FX_ProviderOutageServesLastKnownRates(t *testing.T) {
	env := setupFXEnvironment(t)
	ctx := context.Background()

	env.Provider.SetRates("USD", map[string]string{"IDR": "16234.567891"})
	require.NoError(t, env.Worker.SyncRates(ctx))

	env.Provider.SetError(errors.New("upstream unavailable"))
	require.Error(t, env.Worker.SyncRates(ctx))

	// A failed sync must not poison stored data or take the API down.
	assert.Equal(t, "16234.567891", env.latestRate(t, "USD", "IDR"))
	assert.Equal(t, 1, env.Repo.RowCount())
}

func TestE2E_FX_EndpointsRequireAuthentication(t *testing.T) {
	env := setupFXEnvironment(t)

	paths := []string{
		"/api/v1/currencies",
		"/api/v1/rates/latest?base=USD",
		"/api/v1/rates/historical?base=USD&target=IDR&date=" + env.Today,
	}

	for _, p := range paths {
		res, err := env.DoAuthRequest("", http.MethodGet, p, nil)
		require.NoError(t, err)
		res.Body.Close()
		assert.Equal(t, http.StatusUnauthorized, res.StatusCode, p)
	}
}

func TestE2E_FX_InputValidation(t *testing.T) {
	env := setupFXEnvironment(t)

	cases := map[string]int{
		"/api/v1/rates/latest?base=TOOLONG":                          http.StatusBadRequest,
		"/api/v1/rates/latest?base=USD&target=XX":                    http.StatusBadRequest,
		"/api/v1/rates/historical?base=USD&target=IDR":               http.StatusBadRequest,
		"/api/v1/rates/historical?base=USD&target=IDR&date=15-10-26": http.StatusBadRequest,
		"/api/v1/rates/historical?base=USD&date=2026-10-15":          http.StatusBadRequest,
	}

	for path, want := range cases {
		assert.Equal(t, want, env.getJSON(t, path, nil), path)
	}
}
