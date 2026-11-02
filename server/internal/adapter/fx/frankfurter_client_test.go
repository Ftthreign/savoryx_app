package fx_test

import (
	"context"
	"net/http"
	"net/http/httptest"
	"sync/atomic"
	"testing"
	"time"

	"github.com/ftthreign/savoryx_app/server/internal/adapter/fx"
	"github.com/ftthreign/savoryx_app/server/internal/core/domain"
	"github.com/shopspring/decimal"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

func TestFrankfurterClient_FetchLatestRates(t *testing.T) {
	t.Run("happy path - fetches latest rates and parses decimal accurately", func(t *testing.T) {
		server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			assert.Equal(t, "/latest", r.URL.Path)
			assert.Equal(t, "USD", r.URL.Query().Get("from"))
			assert.Equal(t, "Savoryx-API/1.0", r.Header.Get("User-Agent"))

			w.Header().Set("Content-Type", "application/json")
			w.WriteHeader(http.StatusOK)
			_, _ = w.Write([]byte(`{
				"amount": 1.0,
				"base": "USD",
				"date": "2026-11-02",
				"rates": {
					"IDR": 15500.50,
					"EUR": 0.925431,
					"SGD": 1.342100
				}
			}`))
		}))
		defer server.Close()

		client := fx.NewFrankfurterClient(
			fx.WithBaseURL(server.URL),
			fx.WithHTTPClient(server.Client()),
		)

		rates, err := client.FetchLatestRates(context.Background(), "USD")
		require.NoError(t, err)
		require.NotEmpty(t, rates)

		rateMap := make(map[string]decimal.Decimal)
		for _, r := range rates {
			rateMap[r.TargetCurrency] = r.Rate
		}

		expectedIDR, _ := decimal.NewFromString("15500.50")
		expectedEUR, _ := decimal.NewFromString("0.925431")
		expectedSGD, _ := decimal.NewFromString("1.342100")

		assert.True(t, rateMap["IDR"].Equal(expectedIDR))
		assert.True(t, rateMap["EUR"].Equal(expectedEUR))
		assert.True(t, rateMap["SGD"].Equal(expectedSGD))
		assert.True(t, rateMap["USD"].Equal(decimal.NewFromInt(1)))
	})

	t.Run("validation failure - invalid currency code", func(t *testing.T) {
		client := fx.NewFrankfurterClient()
		_, err := client.FetchLatestRates(context.Background(), "US")
		assert.ErrorIs(t, err, domain.ErrInvalidInput)

		_, err = client.FetchLatestRates(context.Background(), "USDD")
		assert.ErrorIs(t, err, domain.ErrInvalidInput)
	})

	t.Run("upstream non-200 returns error", func(t *testing.T) {
		server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			w.WriteHeader(http.StatusNotFound)
		}))
		defer server.Close()

		client := fx.NewFrankfurterClient(
			fx.WithBaseURL(server.URL),
			fx.WithHTTPClient(server.Client()),
		)

		_, err := client.FetchLatestRates(context.Background(), "XYZ")
		assert.Error(t, err)
		assert.Contains(t, err.Error(), "404")
	})
}

func TestFrankfurterClient_FetchHistoricalRates(t *testing.T) {
	t.Run("happy path - fetches historical rates for specific date", func(t *testing.T) {
		targetDate := time.Date(2026, 10, 15, 0, 0, 0, 0, time.UTC)

		server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			assert.Equal(t, "/2026-10-15", r.URL.Path)
			assert.Equal(t, "IDR", r.URL.Query().Get("from"))

			w.Header().Set("Content-Type", "application/json")
			w.WriteHeader(http.StatusOK)
			_, _ = w.Write([]byte(`{
				"amount": 1.0,
				"base": "IDR",
				"date": "2026-10-15",
				"rates": {
					"USD": 0.000064,
					"SGD": 0.000085
				}
			}`))
		}))
		defer server.Close()

		client := fx.NewFrankfurterClient(
			fx.WithBaseURL(server.URL),
			fx.WithHTTPClient(server.Client()),
		)

		rates, err := client.FetchHistoricalRates(context.Background(), "IDR", targetDate)
		require.NoError(t, err)
		require.NotEmpty(t, rates)

		rateMap := make(map[string]decimal.Decimal)
		for _, r := range rates {
			rateMap[r.TargetCurrency] = r.Rate
			assert.Equal(t, targetDate, r.EffectiveDate)
		}

		expectedUSD, _ := decimal.NewFromString("0.000064")
		assert.True(t, rateMap["USD"].Equal(expectedUSD))
	})

	t.Run("validation failure - zero date", func(t *testing.T) {
		client := fx.NewFrankfurterClient()
		_, err := client.FetchHistoricalRates(context.Background(), "USD", time.Time{})
		assert.ErrorIs(t, err, domain.ErrInvalidInput)
	})
}

func TestFrankfurterClient_Retries(t *testing.T) {
	t.Run("retries on 500 internal server error and succeeds on second attempt", func(t *testing.T) {
		var attempts int32
		server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			curr := atomic.AddInt32(&attempts, 1)
			if curr == 1 {
				w.WriteHeader(http.StatusInternalServerError)
				return
			}
			w.Header().Set("Content-Type", "application/json")
			w.WriteHeader(http.StatusOK)
			_, _ = w.Write([]byte(`{"base":"USD","date":"2026-11-02","rates":{"IDR":15500.00}}`))
		}))
		defer server.Close()

		client := fx.NewFrankfurterClient(
			fx.WithBaseURL(server.URL),
			fx.WithHTTPClient(server.Client()),
		)

		rates, err := client.FetchLatestRates(context.Background(), "USD")
		require.NoError(t, err)
		assert.NotEmpty(t, rates)
		assert.Equal(t, int32(2), atomic.LoadInt32(&attempts))
	})

	t.Run("context cancellation terminates retry loop immediately", func(t *testing.T) {
		server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			w.WriteHeader(http.StatusInternalServerError)
		}))
		defer server.Close()

		client := fx.NewFrankfurterClient(
			fx.WithBaseURL(server.URL),
			fx.WithHTTPClient(server.Client()),
		)

		ctx, cancel := context.WithTimeout(context.Background(), 50*time.Millisecond)
		defer cancel()

		_, err := client.FetchLatestRates(ctx, "USD")
		assert.Error(t, err)
	})
}
