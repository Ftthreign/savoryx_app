package dto

import (
	"time"

	"github.com/ftthreign/savoryx_app/server/internal/core/domain"
	"github.com/shopspring/decimal"
)

type ExchangeRateResponse struct {
	ID             string          `json:"id"`
	BaseCurrency   string          `json:"base_currency"`
	TargetCurrency string          `json:"target_currency"`
	Rate           decimal.Decimal `json:"rate"`
	EffectiveDate  string          `json:"effective_date"` // YYYY-MM-DD
	UpdatedAt      time.Time       `json:"updated_at"`
}

type CurrencyResponse struct {
	Code          string `json:"code"`
	Name          string `json:"name"`
	Symbol        string `json:"symbol"`
	DecimalPlaces int    `json:"decimal_places"`
	IsActive      bool   `json:"is_active"`
}

type RateListMeta struct {
	Base  string `json:"base"`
	Total int    `json:"total"`
}

type CurrencyListMeta struct {
	Total int `json:"total"`
}

func ToExchangeRateResponse(rate *domain.ExchangeRate) *ExchangeRateResponse {
	if rate == nil {
		return nil
	}

	return &ExchangeRateResponse{
		ID:             rate.ID.String(),
		BaseCurrency:   rate.BaseCurrency,
		TargetCurrency: rate.TargetCurrency,
		Rate:           rate.Rate,
		EffectiveDate:  rate.EffectiveDate.Format("2006-01-02"),
		UpdatedAt:      rate.UpdatedAt,
	}
}

func ToExchangeRateResponses(rates []*domain.ExchangeRate) []*ExchangeRateResponse {
	if rates == nil {
		return []*ExchangeRateResponse{}
	}

	result := make([]*ExchangeRateResponse, len(rates))
	for i, r := range rates {
		result[i] = ToExchangeRateResponse(r)
	}
	return result
}

func ToCurrencyResponse(cur *domain.Currency) *CurrencyResponse {
	if cur == nil {
		return nil
	}

	return &CurrencyResponse{
		Code:          cur.Code,
		Name:          cur.Name,
		Symbol:        cur.Symbol,
		DecimalPlaces: cur.DecimalPlaces,
		IsActive:      cur.IsActive,
	}
}

func ToCurrencyResponses(currencies []*domain.Currency) []*CurrencyResponse {
	if currencies == nil {
		return []*CurrencyResponse{}
	}

	result := make([]*CurrencyResponse, len(currencies))
	for i, c := range currencies {
		result[i] = ToCurrencyResponse(c)
	}
	return result
}
