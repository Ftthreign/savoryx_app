package domain

import (
	"strings"
	"time"

	"github.com/shopspring/decimal"
)

type Currency struct {
	Code          string    `json:"code"`
	Name          string    `json:"name"`
	Symbol        string    `json:"symbol"`
	DecimalPlaces int       `json:"decimal_places"`
	IsActive      bool      `json:"is_active"`
	CreatedAt     time.Time `json:"created_at"`
}

func NewCurrency(code, name, symbol string, decimalPlaces int) (*Currency, error) {
	trimmedCode := strings.ToUpper(strings.TrimSpace(code))
	if len(trimmedCode) != 3 {
		return nil, ErrInvalidInput
	}

	trimmedName := strings.TrimSpace(name)
	if trimmedName == "" {
		return nil, ErrInvalidInput
	}

	trimmedSymbol := strings.TrimSpace(symbol)
	if trimmedSymbol == "" {
		return nil, ErrInvalidInput
	}

	if decimalPlaces < 0 || decimalPlaces > 8 {
		return nil, ErrInvalidInput
	}

	return &Currency{
		Code:          trimmedCode,
		Name:          trimmedName,
		Symbol:        trimmedSymbol,
		DecimalPlaces: decimalPlaces,
		IsActive:      true,
		CreatedAt:     time.Now().UTC(),
	}, nil
}

type ExchangeRate struct {
	ID             UUID            `json:"id"`
	BaseCurrency   string          `json:"base_currency"`
	TargetCurrency string          `json:"target_currency"`
	Rate           decimal.Decimal `json:"rate"`
	EffectiveDate  time.Time       `json:"effective_date"`
	CreatedAt      time.Time       `json:"created_at"`
	UpdatedAt      time.Time       `json:"updated_at"`
}

func NewExchangeRate(base, target string, rate decimal.Decimal, effectiveDate time.Time) (*ExchangeRate, error) {
	base = strings.ToUpper(strings.TrimSpace(base))
	target = strings.ToUpper(strings.TrimSpace(target))

	if len(base) != 3 || len(target) != 3 {
		return nil, ErrInvalidInput
	}

	if rate.IsNegative() || rate.IsZero() {
		return nil, ErrInvalidInput
	}

	if effectiveDate.IsZero() {
		effectiveDate = time.Now().UTC().Truncate(24 * time.Hour)
	}

	now := time.Now().UTC()
	return &ExchangeRate{
		ID:             NewUUIDv7(),
		BaseCurrency:   base,
		TargetCurrency: target,
		Rate:           rate,
		EffectiveDate:  effectiveDate,
		CreatedAt:      now,
		UpdatedAt:      now,
	}, nil
}

func (e *ExchangeRate) Convert(amount decimal.Decimal) decimal.Decimal {
	return amount.Mul(e.Rate)
}

func (e *ExchangeRate) ConvertInverse(amount decimal.Decimal) (decimal.Decimal, error) {
	if e.Rate.IsZero() {
		return decimal.Zero, ErrInvalidInput
	}
	return amount.DivRound(e.Rate, 6), nil
}
