package domain_test

import (
	"testing"
	"time"

	"github.com/ftthreign/savoryx_app/server/internal/core/domain"
	"github.com/shopspring/decimal"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

func TestNewCurrency(t *testing.T) {
	t.Run("happy path - constructs valid currency with normalized code", func(t *testing.T) {
		c, err := domain.NewCurrency("idr ", " Indonesian Rupiah ", " Rp ", 0)
		require.NoError(t, err)
		assert.Equal(t, "IDR", c.Code)
		assert.Equal(t, "Indonesian Rupiah", c.Name)
		assert.Equal(t, "Rp", c.Symbol)
		assert.Equal(t, 0, c.DecimalPlaces)
		assert.True(t, c.IsActive)
		assert.False(t, c.CreatedAt.IsZero())
	})

	t.Run("validation failure - invalid code length", func(t *testing.T) {
		_, err := domain.NewCurrency("USDD", "US Dollar", "$", 2)
		assert.ErrorIs(t, err, domain.ErrInvalidInput)

		_, err = domain.NewCurrency("US", "US Dollar", "$", 2)
		assert.ErrorIs(t, err, domain.ErrInvalidInput)
	})

	t.Run("validation failure - empty name or symbol", func(t *testing.T) {
		_, err := domain.NewCurrency("USD", "  ", "$", 2)
		assert.ErrorIs(t, err, domain.ErrInvalidInput)

		_, err = domain.NewCurrency("USD", "US Dollar", "  ", 2)
		assert.ErrorIs(t, err, domain.ErrInvalidInput)
	})

	t.Run("validation failure - invalid decimal places", func(t *testing.T) {
		_, err := domain.NewCurrency("USD", "US Dollar", "$", -1)
		assert.ErrorIs(t, err, domain.ErrInvalidInput)

		_, err = domain.NewCurrency("USD", "US Dollar", "$", 9)
		assert.ErrorIs(t, err, domain.ErrInvalidInput)
	})
}

func TestNewExchangeRate(t *testing.T) {
	t.Run("happy path - constructs exchange rate with UUIDv7", func(t *testing.T) {
		rate := decimal.NewFromInt(15500)
		date := time.Date(2026, 11, 2, 0, 0, 0, 0, time.UTC)

		fx, err := domain.NewExchangeRate(" usd ", " idr ", rate, date)
		require.NoError(t, err)
		assert.False(t, fx.ID.IsZero())
		assert.Equal(t, "USD", fx.BaseCurrency)
		assert.Equal(t, "IDR", fx.TargetCurrency)
		assert.True(t, fx.Rate.Equal(rate))
		assert.Equal(t, date, fx.EffectiveDate)
		assert.False(t, fx.CreatedAt.IsZero())
		assert.False(t, fx.UpdatedAt.IsZero())
	})

	t.Run("validation failure - zero or negative rate", func(t *testing.T) {
		_, err := domain.NewExchangeRate("USD", "IDR", decimal.Zero, time.Now())
		assert.ErrorIs(t, err, domain.ErrInvalidInput)

		_, err = domain.NewExchangeRate("USD", "IDR", decimal.NewFromInt(-1), time.Now())
		assert.ErrorIs(t, err, domain.ErrInvalidInput)
	})

	t.Run("validation failure - invalid currency code", func(t *testing.T) {
		rate := decimal.NewFromInt(15500)
		_, err := domain.NewExchangeRate("US", "IDR", rate, time.Now())
		assert.ErrorIs(t, err, domain.ErrInvalidInput)

		_, err = domain.NewExchangeRate("USD", "IDRR", rate, time.Now())
		assert.ErrorIs(t, err, domain.ErrInvalidInput)
	})

	t.Run("default date truncation when zero date passed", func(t *testing.T) {
		rate := decimal.NewFromInt(15500)
		fx, err := domain.NewExchangeRate("USD", "IDR", rate, time.Time{})
		require.NoError(t, err)
		assert.False(t, fx.EffectiveDate.IsZero())
	})
}

func TestExchangeRate_Conversions(t *testing.T) {
	rate := decimal.NewFromInt(15000)
	fx, err := domain.NewExchangeRate("USD", "IDR", rate, time.Now())
	require.NoError(t, err)

	t.Run("Convert base to target currency", func(t *testing.T) {
		amountUSD := decimal.NewFromInt(10)
		amountIDR := fx.Convert(amountUSD)
		assert.True(t, amountIDR.Equal(decimal.NewFromInt(150000)))
	})

	t.Run("ConvertInverse target to base currency", func(t *testing.T) {
		amountIDR := decimal.NewFromInt(150000)
		amountUSD, err := fx.ConvertInverse(amountIDR)
		require.NoError(t, err)
		assert.True(t, amountUSD.Equal(decimal.NewFromInt(10)))
	})
}
