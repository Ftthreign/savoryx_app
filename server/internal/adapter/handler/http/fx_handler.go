package http

import (
	"net/http"
	"strings"
	"time"

	"github.com/ftthreign/savoryx_app/server/internal/adapter/handler/http/dto"
	"github.com/ftthreign/savoryx_app/server/internal/core/domain"
	"github.com/ftthreign/savoryx_app/server/internal/port"
)

type FXHandler struct {
	service port.ExchangeRateService
}

func NewFXHandler(service port.ExchangeRateService) *FXHandler {
	return &FXHandler{
		service: service,
	}
}

func (h *FXHandler) GetLatestRates(w http.ResponseWriter, r *http.Request) {
	base := strings.TrimSpace(r.URL.Query().Get("base"))
	if base == "" {
		base = "USD"
	}
	base = strings.ToUpper(base)

	if len(base) != 3 {
		WriteError(w, http.StatusBadRequest, "invalid_currency_code", "Base currency must be a valid 3-letter ISO-4217 code")
		return
	}

	target := strings.ToUpper(strings.TrimSpace(r.URL.Query().Get("target")))
	if target != "" {
		if len(target) != 3 {
			WriteError(w, http.StatusBadRequest, "invalid_currency_code", "Target currency must be a valid 3-letter ISO-4217 code")
			return
		}

		rate, err := h.service.GetLatestRate(r.Context(), base, target)
		if err != nil {
			WriteDomainError(w, err)
			return
		}

		WriteJSON(w, http.StatusOK, dto.ToExchangeRateResponse(rate))
		return
	}

	rates, err := h.service.ListLatestRates(r.Context(), base)
	if err != nil {
		WriteDomainError(w, err)
		return
	}

	WriteJSONWithMeta(w, http.StatusOK, dto.ToExchangeRateResponses(rates), dto.RateListMeta{
		Base:  base,
		Total: len(rates),
	})
}

func (h *FXHandler) GetHistoricalRate(w http.ResponseWriter, r *http.Request) {
	base := strings.TrimSpace(r.URL.Query().Get("base"))
	if base == "" {
		base = "USD"
	}
	base = strings.ToUpper(base)

	if len(base) != 3 {
		WriteError(w, http.StatusBadRequest, "invalid_currency_code", "Base currency must be a valid 3-letter ISO-4217 code")
		return
	}

	target := strings.ToUpper(strings.TrimSpace(r.URL.Query().Get("target")))
	if target == "" {
		WriteError(w, http.StatusBadRequest, "missing_parameter", "Query parameter 'target' is required")
		return
	}
	if len(target) != 3 {
		WriteError(w, http.StatusBadRequest, "invalid_currency_code", "Target currency must be a valid 3-letter ISO-4217 code")
		return
	}

	dateStr := strings.TrimSpace(r.URL.Query().Get("date"))
	if dateStr == "" {
		WriteError(w, http.StatusBadRequest, "missing_parameter", "Query parameter 'date' is required in YYYY-MM-DD format")
		return
	}

	parsedDate, err := time.Parse("2006-01-02", dateStr)
	if err != nil {
		WriteError(w, http.StatusBadRequest, "invalid_date_format", "Query parameter 'date' must be in YYYY-MM-DD format")
		return
	}

	rate, err := h.service.GetHistoricalRate(r.Context(), base, target, parsedDate)
	if err != nil {
		WriteDomainError(w, err)
		return
	}

	WriteJSON(w, http.StatusOK, dto.ToExchangeRateResponse(rate))
}

func (h *FXHandler) ListCurrencies(w http.ResponseWriter, r *http.Request) {
	currencies, err := h.service.ListSupportedCurrencies(r.Context())
	if err != nil {
		WriteDomainError(w, err)
		return
	}

	if currencies == nil {
		currencies = []*domain.Currency{}
	}

	WriteJSONWithMeta(w, http.StatusOK, dto.ToCurrencyResponses(currencies), dto.CurrencyListMeta{
		Total: len(currencies),
	})
}
