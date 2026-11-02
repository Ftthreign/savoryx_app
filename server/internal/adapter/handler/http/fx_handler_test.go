package http

import (
	"context"
	"encoding/json"
	"errors"
	"net/http"
	"net/http/httptest"
	"testing"
	"time"

	"github.com/ftthreign/savoryx_app/server/internal/core/domain"
	"github.com/ftthreign/savoryx_app/server/internal/testutil"
	"github.com/shopspring/decimal"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

type mockFXService struct {
	rates       map[string]*domain.ExchangeRate
	latestLists map[string][]*domain.ExchangeRate
	historical  map[string]*domain.ExchangeRate
	currencies  []*domain.Currency
	err         error
}

func newMockFXService() *mockFXService {
	return &mockFXService{
		rates:       make(map[string]*domain.ExchangeRate),
		latestLists: make(map[string][]*domain.ExchangeRate),
		historical:  make(map[string]*domain.ExchangeRate),
	}
}

func (m *mockFXService) GetLatestRate(ctx context.Context, base, target string) (*domain.ExchangeRate, error) {
	if m.err != nil {
		return nil, m.err
	}
	key := base + ":" + target
	if r, found := m.rates[key]; found {
		return r, nil
	}
	return nil, domain.ErrNotFound
}

func (m *mockFXService) GetHistoricalRate(ctx context.Context, base, target string, date time.Time) (*domain.ExchangeRate, error) {
	if m.err != nil {
		return nil, m.err
	}
	key := base + ":" + target + ":" + date.Format("2006-01-02")
	if r, found := m.historical[key]; found {
		return r, nil
	}
	return nil, domain.ErrNotFound
}

func (m *mockFXService) ListLatestRates(ctx context.Context, base string) ([]*domain.ExchangeRate, error) {
	if m.err != nil {
		return nil, m.err
	}
	if list, found := m.latestLists[base]; found {
		return list, nil
	}
	return []*domain.ExchangeRate{}, nil
}

func (m *mockFXService) ListSupportedCurrencies(ctx context.Context) ([]*domain.Currency, error) {
	if m.err != nil {
		return nil, m.err
	}
	return m.currencies, nil
}

func setupFXTestRouter(service *mockFXService) http.Handler {
	return SetupRouter(
		testutil.DiscardLogger(),
		nil,
		"1.0.0",
		"test",
		WithExchangeRateService(service),
	)
}

func TestFXHandler_GetLatestRate_Single(t *testing.T) {
	svc := newMockFXService()
	svc.rates["USD:EUR"] = &domain.ExchangeRate{
		ID:             domain.NewUUIDv7(),
		BaseCurrency:   "USD",
		TargetCurrency: "EUR",
		Rate:           decimal.RequireFromString("0.920000"),
		EffectiveDate:  time.Date(2026, 11, 2, 0, 0, 0, 0, time.UTC),
		UpdatedAt:      time.Now().UTC(),
	}

	router := setupFXTestRouter(svc)
	req := httptest.NewRequest(http.MethodGet, "/api/v1/rates/latest?base=USD&target=EUR", nil)
	rec := httptest.NewRecorder()

	router.ServeHTTP(rec, req)

	require.Equal(t, http.StatusOK, rec.Code)

	var res struct {
		Data struct {
			BaseCurrency   string `json:"base_currency"`
			TargetCurrency string `json:"target_currency"`
			Rate           string `json:"rate"`
			EffectiveDate  string `json:"effective_date"`
		} `json:"data"`
	}
	err := json.Unmarshal(rec.Body.Bytes(), &res)
	require.NoError(t, err)
	assert.Equal(t, "USD", res.Data.BaseCurrency)
	assert.Equal(t, "EUR", res.Data.TargetCurrency)
	assert.Equal(t, "0.92", res.Data.Rate)
	assert.Equal(t, "2026-11-02", res.Data.EffectiveDate)
}

func TestFXHandler_GetLatestRates_List(t *testing.T) {
	svc := newMockFXService()
	svc.latestLists["USD"] = []*domain.ExchangeRate{
		{
			ID:             domain.NewUUIDv7(),
			BaseCurrency:   "USD",
			TargetCurrency: "EUR",
			Rate:           decimal.RequireFromString("0.920000"),
			EffectiveDate:  time.Date(2026, 11, 2, 0, 0, 0, 0, time.UTC),
		},
		{
			ID:             domain.NewUUIDv7(),
			BaseCurrency:   "USD",
			TargetCurrency: "IDR",
			Rate:           decimal.RequireFromString("16200.000000"),
			EffectiveDate:  time.Date(2026, 11, 2, 0, 0, 0, 0, time.UTC),
		},
	}

	router := setupFXTestRouter(svc)
	req := httptest.NewRequest(http.MethodGet, "/api/v1/rates/latest?base=USD", nil)
	rec := httptest.NewRecorder()

	router.ServeHTTP(rec, req)

	require.Equal(t, http.StatusOK, rec.Code)

	var res struct {
		Data []map[string]any `json:"data"`
		Meta struct {
			Base  string `json:"base"`
			Total int    `json:"total"`
		} `json:"meta"`
	}
	err := json.Unmarshal(rec.Body.Bytes(), &res)
	require.NoError(t, err)
	assert.Len(t, res.Data, 2)
	assert.Equal(t, "USD", res.Meta.Base)
	assert.Equal(t, 2, res.Meta.Total)
}

func TestFXHandler_GetLatestRates_ValidationErrors(t *testing.T) {
	svc := newMockFXService()
	router := setupFXTestRouter(svc)

	// Invalid base length
	req1 := httptest.NewRequest(http.MethodGet, "/api/v1/rates/latest?base=TOOLONG", nil)
	rec1 := httptest.NewRecorder()
	router.ServeHTTP(rec1, req1)
	assert.Equal(t, http.StatusBadRequest, rec1.Code)

	// Invalid target length
	req2 := httptest.NewRequest(http.MethodGet, "/api/v1/rates/latest?base=USD&target=1", nil)
	rec2 := httptest.NewRecorder()
	router.ServeHTTP(rec2, req2)
	assert.Equal(t, http.StatusBadRequest, rec2.Code)

	// Rate not found
	req3 := httptest.NewRequest(http.MethodGet, "/api/v1/rates/latest?base=USD&target=XYZ", nil)
	rec3 := httptest.NewRecorder()
	router.ServeHTTP(rec3, req3)
	assert.Equal(t, http.StatusNotFound, rec3.Code)
}

func TestFXHandler_GetHistoricalRate(t *testing.T) {
	svc := newMockFXService()
	svc.historical["USD:EUR:2026-10-15"] = &domain.ExchangeRate{
		ID:             domain.NewUUIDv7(),
		BaseCurrency:   "USD",
		TargetCurrency: "EUR",
		Rate:           decimal.RequireFromString("0.915000"),
		EffectiveDate:  time.Date(2026, 10, 15, 0, 0, 0, 0, time.UTC),
	}

	router := setupFXTestRouter(svc)

	// Happy path
	req := httptest.NewRequest(http.MethodGet, "/api/v1/rates/historical?base=USD&target=EUR&date=2026-10-15", nil)
	rec := httptest.NewRecorder()
	router.ServeHTTP(rec, req)
	require.Equal(t, http.StatusOK, rec.Code)

	// Missing target
	reqMissingTarget := httptest.NewRequest(http.MethodGet, "/api/v1/rates/historical?base=USD&date=2026-10-15", nil)
	recMissingTarget := httptest.NewRecorder()
	router.ServeHTTP(recMissingTarget, reqMissingTarget)
	assert.Equal(t, http.StatusBadRequest, recMissingTarget.Code)

	// Missing date
	reqMissingDate := httptest.NewRequest(http.MethodGet, "/api/v1/rates/historical?base=USD&target=EUR", nil)
	recMissingDate := httptest.NewRecorder()
	router.ServeHTTP(recMissingDate, reqMissingDate)
	assert.Equal(t, http.StatusBadRequest, recMissingDate.Code)

	// Invalid date format
	reqBadDate := httptest.NewRequest(http.MethodGet, "/api/v1/rates/historical?base=USD&target=EUR&date=15-10-2026", nil)
	recBadDate := httptest.NewRecorder()
	router.ServeHTTP(recBadDate, reqBadDate)
	assert.Equal(t, http.StatusBadRequest, recBadDate.Code)
}

func TestFXHandler_ListCurrencies(t *testing.T) {
	svc := newMockFXService()
	svc.currencies = []*domain.Currency{
		{Code: "IDR", Name: "Indonesian Rupiah", Symbol: "Rp", DecimalPlaces: 0, IsActive: true},
		{Code: "USD", Name: "United States Dollar", Symbol: "$", DecimalPlaces: 2, IsActive: true},
	}

	router := setupFXTestRouter(svc)
	req := httptest.NewRequest(http.MethodGet, "/api/v1/currencies", nil)
	rec := httptest.NewRecorder()

	router.ServeHTTP(rec, req)

	require.Equal(t, http.StatusOK, rec.Code)

	var res struct {
		Data []struct {
			Code   string `json:"code"`
			Name   string `json:"name"`
			Symbol string `json:"symbol"`
		} `json:"data"`
		Meta struct {
			Total int `json:"total"`
		} `json:"meta"`
	}
	err := json.Unmarshal(rec.Body.Bytes(), &res)
	require.NoError(t, err)
	assert.Len(t, res.Data, 2)
	assert.Equal(t, "IDR", res.Data[0].Code)
	assert.Equal(t, 2, res.Meta.Total)
}

func TestFXHandler_ListCurrencies_Error(t *testing.T) {
	svc := newMockFXService()
	svc.err = errors.New("database disk read error")

	router := setupFXTestRouter(svc)
	req := httptest.NewRequest(http.MethodGet, "/api/v1/currencies", nil)
	rec := httptest.NewRecorder()

	router.ServeHTTP(rec, req)
	assert.Equal(t, http.StatusInternalServerError, rec.Code)
}
