package service

import (
	"context"
	"strings"
	"time"

	"github.com/ftthreign/savoryx_app/server/internal/core/domain"
	"github.com/ftthreign/savoryx_app/server/internal/port"
	"github.com/samber/oops"
	"github.com/shopspring/decimal"
)

type ExchangeRateService struct {
	repo     port.ExchangeRateRepository
	cache    port.FXCache
	provider port.FXProvider
}

func NewExchangeRateService(
	repo port.ExchangeRateRepository,
	cache port.FXCache,
	provider port.FXProvider,
) *ExchangeRateService {
	return &ExchangeRateService{
		repo:     repo,
		cache:    cache,
		provider: provider,
	}
}

func normalizeCurrencyCode(code string) string {
	return strings.ToUpper(strings.TrimSpace(code))
}

func isValidCurrencyCode(code string) bool {
	return len(code) == 3
}

func (s *ExchangeRateService) GetLatestRate(ctx context.Context, base, target string) (*domain.ExchangeRate, error) {
	base = normalizeCurrencyCode(base)
	target = normalizeCurrencyCode(target)

	if !isValidCurrencyCode(base) || !isValidCurrencyCode(target) {
		return nil, oops.
			In("fx_service").
			Code("ERR_INVALID_CURRENCY_CODE").
			With("base", base).
			With("target", target).
			Wrapf(domain.ErrInvalidInput, "currency codes must be valid 3-letter ISO-4217 format")
	}

	// 1:1 Identity Rate for same currency
	if base == target {
		now := time.Now().UTC()
		return &domain.ExchangeRate{
			ID:             domain.NewUUIDv7(),
			BaseCurrency:   base,
			TargetCurrency: target,
			Rate:           decimal.NewFromInt(1),
			EffectiveDate:  now.Truncate(24 * time.Hour),
			CreatedAt:      now,
			UpdatedAt:      now,
		}, nil
	}

	// 1. Try In-Memory Cache first
	if s.cache != nil {
		if cachedRate, found := s.cache.GetRate(ctx, base, target); found && cachedRate != nil {
			return cachedRate, nil
		}
	}

	// 2. Query Database Repository
	rate, err := s.repo.GetLatestRate(ctx, base, target)
	if err == nil && rate != nil {
		if s.cache != nil {
			s.cache.SetRate(ctx, rate, 0)
		}
		return rate, nil
	}

	// 3. Fallback: Query Upstream Provider on-demand if missing in DB
	if s.provider != nil {
		fetchedRates, fetchErr := s.provider.FetchLatestRates(ctx, base)
		if fetchErr == nil && len(fetchedRates) > 0 {
			for _, r := range fetchedRates {
				_ = s.repo.UpsertRate(ctx, r)
			}
			if s.cache != nil {
				s.cache.SetLatestRates(ctx, base, fetchedRates, 0)
			}

			for _, r := range fetchedRates {
				if strings.EqualFold(r.TargetCurrency, target) {
					return r, nil
				}
			}
		}
	}

	return nil, oops.
		In("fx_service").
		Code("ERR_RATE_NOT_FOUND").
		With("base", base).
		With("target", target).
		Wrapf(domain.ErrNotFound, "exchange rate not found for %s/%s", base, target)
}

func (s *ExchangeRateService) GetHistoricalRate(ctx context.Context, base, target string, date time.Time) (*domain.ExchangeRate, error) {
	base = normalizeCurrencyCode(base)
	target = normalizeCurrencyCode(target)

	if !isValidCurrencyCode(base) || !isValidCurrencyCode(target) {
		return nil, oops.
			In("fx_service").
			Code("ERR_INVALID_CURRENCY_CODE").
			With("base", base).
			With("target", target).
			Wrapf(domain.ErrInvalidInput, "currency codes must be valid 3-letter ISO-4217 format")
	}

	if date.IsZero() {
		return nil, oops.
			In("fx_service").
			Code("ERR_INVALID_DATE").
			Wrapf(domain.ErrInvalidInput, "historical rate date cannot be zero")
	}

	now := time.Now().UTC()
	if date.After(now) {
		return nil, oops.
			In("fx_service").
			Code("ERR_FUTURE_DATE").
			With("date", date.Format("2006-01-02")).
			Wrapf(domain.ErrInvalidInput, "historical rate date cannot be in the future")
	}

	dateOnly := date.Truncate(24 * time.Hour)

	// 1:1 Identity Rate for same currency
	if base == target {
		return &domain.ExchangeRate{
			ID:             domain.NewUUIDv7(),
			BaseCurrency:   base,
			TargetCurrency: target,
			Rate:           decimal.NewFromInt(1),
			EffectiveDate:  dateOnly,
			CreatedAt:      now,
			UpdatedAt:      now,
		}, nil
	}

	// 1. Query Database Repository
	rate, err := s.repo.GetHistoricalRate(ctx, base, target, dateOnly)
	if err == nil && rate != nil {
		return rate, nil
	}

	// 2. Fallback: Query Upstream Provider on-demand if historical rate not in DB
	if s.provider != nil {
		fetchedRates, fetchErr := s.provider.FetchHistoricalRates(ctx, base, dateOnly)
		if fetchErr == nil && len(fetchedRates) > 0 {
			for _, r := range fetchedRates {
				_ = s.repo.UpsertRate(ctx, r)
			}
			for _, r := range fetchedRates {
				if strings.EqualFold(r.TargetCurrency, target) {
					return r, nil
				}
			}
		}
	}

	return nil, oops.
		In("fx_service").
		Code("ERR_HISTORICAL_RATE_NOT_FOUND").
		With("base", base).
		With("target", target).
		With("date", dateOnly.Format("2006-01-02")).
		Wrapf(domain.ErrNotFound, "historical exchange rate not found for %s/%s on %s", base, target, dateOnly.Format("2006-01-02"))
}

func (s *ExchangeRateService) ListLatestRates(ctx context.Context, base string) ([]*domain.ExchangeRate, error) {
	base = normalizeCurrencyCode(base)
	if base == "" {
		base = "USD"
	}

	if !isValidCurrencyCode(base) {
		return nil, oops.
			In("fx_service").
			Code("ERR_INVALID_CURRENCY_CODE").
			With("base", base).
			Wrapf(domain.ErrInvalidInput, "base currency must be a valid 3-letter ISO-4217 format")
	}

	// 1. Try In-Memory Cache first
	if s.cache != nil {
		if cachedRates, found := s.cache.GetLatestRates(ctx, base); found && len(cachedRates) > 0 {
			return cachedRates, nil
		}
	}

	// 2. Query Database Repository
	rates, err := s.repo.ListLatestRates(ctx, base)
	if err == nil && len(rates) > 0 {
		if s.cache != nil {
			s.cache.SetLatestRates(ctx, base, rates, 0)
		}
		return rates, nil
	}

	// 3. Fallback: Query Upstream Provider if database empty
	if s.provider != nil {
		fetchedRates, fetchErr := s.provider.FetchLatestRates(ctx, base)
		if fetchErr == nil && len(fetchedRates) > 0 {
			for _, r := range fetchedRates {
				_ = s.repo.UpsertRate(ctx, r)
			}
			if s.cache != nil {
				s.cache.SetLatestRates(ctx, base, fetchedRates, 0)
			}
			return fetchedRates, nil
		}
	}

	if err != nil {
		return nil, oops.
			In("fx_service").
			Code("ERR_LIST_LATEST_RATES").
			With("base", base).
			Wrapf(err, "failed to list latest rates for %s", base)
	}

	return []*domain.ExchangeRate{}, nil
}

func (s *ExchangeRateService) ListSupportedCurrencies(ctx context.Context) ([]*domain.Currency, error) {
	currencies, err := s.repo.ListSupportedCurrencies(ctx)
	if err != nil {
		return nil, oops.
			In("fx_service").
			Code("ERR_LIST_CURRENCIES").
			Wrapf(err, "failed to list supported currencies")
	}

	return currencies, nil
}

var _ port.ExchangeRateService = (*ExchangeRateService)(nil)
