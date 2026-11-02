package postgres

import (
	"context"
	"errors"
	"time"

	"github.com/ftthreign/savoryx_app/server/internal/adapter/repository/postgres/db"
	"github.com/ftthreign/savoryx_app/server/internal/core/domain"
	"github.com/ftthreign/savoryx_app/server/internal/port"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgtype"
	"github.com/samber/oops"
)

type ExchangeRateRepository struct {
	q *db.Queries
}

func NewExchangeRateRepository(d *DB) *ExchangeRateRepository {
	return &ExchangeRateRepository{
		q: db.New(d.Pool),
	}
}

func (r *ExchangeRateRepository) queries(ctx context.Context) *db.Queries {
	if tx := ExtractTx(ctx); tx != nil {
		return r.q.WithTx(tx)
	}
	return r.q
}

func (r *ExchangeRateRepository) UpsertRate(ctx context.Context, rate *domain.ExchangeRate) error {
	if rate == nil {
		return oops.
			In("exchange_rate_repo").
			Code("ERR_NIL_EXCHANGE_RATE").
			Wrap(domain.ErrInvalidInput)
	}

	dateOnly := rate.EffectiveDate.Truncate(24 * time.Hour)
	params := db.UpsertExchangeRateParams{
		ID:             pgtype.UUID{Bytes: rate.ID.Bytes(), Valid: true},
		BaseCurrency:   rate.BaseCurrency,
		TargetCurrency: rate.TargetCurrency,
		Rate:           rate.Rate,
		EffectiveDate:  pgtype.Date{Time: dateOnly, Valid: true},
	}

	row, err := r.queries(ctx).UpsertExchangeRate(ctx, params)
	if err != nil {
		return oops.
			In("exchange_rate_repo").
			Code("ERR_UPSERT_RATE").
			With("base", rate.BaseCurrency).
			With("target", rate.TargetCurrency).
			Wrapf(err, "failed to upsert exchange rate record")
	}

	*rate = *toDomainExchangeRate(row)
	return nil
}

func (r *ExchangeRateRepository) GetLatestRate(ctx context.Context, base, target string) (*domain.ExchangeRate, error) {
	params := db.GetLatestRateParams{
		BaseCurrency:   base,
		TargetCurrency: target,
	}

	row, err := r.queries(ctx).GetLatestRate(ctx, params)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, oops.
				In("exchange_rate_repo").
				Code("ERR_RATE_NOT_FOUND").
				With("base", base).
				With("target", target).
				Wrap(domain.ErrNotFound)
		}
		return nil, oops.
			In("exchange_rate_repo").
			Code("ERR_GET_LATEST_RATE").
			With("base", base).
			With("target", target).
			Wrapf(err, "failed to query latest exchange rate")
	}

	return toDomainExchangeRate(row), nil
}

func (r *ExchangeRateRepository) GetHistoricalRate(ctx context.Context, base, target string, date time.Time) (*domain.ExchangeRate, error) {
	dateOnly := date.Truncate(24 * time.Hour)
	params := db.GetHistoricalRateByDateParams{
		BaseCurrency:   base,
		TargetCurrency: target,
		EffectiveDate:  pgtype.Date{Time: dateOnly, Valid: true},
	}

	row, err := r.queries(ctx).GetHistoricalRateByDate(ctx, params)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, oops.
				In("exchange_rate_repo").
				Code("ERR_HISTORICAL_RATE_NOT_FOUND").
				With("base", base).
				With("target", target).
				With("date", dateOnly.Format("2006-01-02")).
				Wrap(domain.ErrNotFound)
		}
		return nil, oops.
			In("exchange_rate_repo").
			Code("ERR_GET_HISTORICAL_RATE").
			Wrapf(err, "failed to query historical exchange rate")
	}

	return toDomainExchangeRate(row), nil
}

func (r *ExchangeRateRepository) ListLatestRates(ctx context.Context, base string) ([]*domain.ExchangeRate, error) {
	rows, err := r.queries(ctx).ListLatestRates(ctx, base)
	if err != nil {
		return nil, oops.
			In("exchange_rate_repo").
			Code("ERR_LIST_LATEST_RATES").
			With("base", base).
			Wrapf(err, "failed to list latest exchange rates")
	}

	result := make([]*domain.ExchangeRate, len(rows))
	for i, row := range rows {
		result[i] = toDomainExchangeRate(row)
	}
	return result, nil
}

func (r *ExchangeRateRepository) ListSupportedCurrencies(ctx context.Context) ([]*domain.Currency, error) {
	rows, err := r.queries(ctx).ListSupportedCurrencies(ctx)
	if err != nil {
		return nil, oops.
			In("exchange_rate_repo").
			Code("ERR_LIST_CURRENCIES").
			Wrapf(err, "failed to list supported currencies")
	}

	result := make([]*domain.Currency, len(rows))
	for i, row := range rows {
		result[i] = toDomainCurrency(row)
	}
	return result, nil
}

func (r *ExchangeRateRepository) GetCurrency(ctx context.Context, code string) (*domain.Currency, error) {
	row, err := r.queries(ctx).GetCurrencyByCode(ctx, code)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, oops.
				In("exchange_rate_repo").
				Code("ERR_CURRENCY_NOT_FOUND").
				With("code", code).
				Wrap(domain.ErrNotFound)
		}
		return nil, oops.
			In("exchange_rate_repo").
			Code("ERR_GET_CURRENCY").
			With("code", code).
			Wrapf(err, "failed to get currency by code")
	}

	return toDomainCurrency(row), nil
}

func toDomainExchangeRate(row db.ExchangeRate) *domain.ExchangeRate {
	return &domain.ExchangeRate{
		ID:             domain.FromBytes(row.ID.Bytes),
		BaseCurrency:   row.BaseCurrency,
		TargetCurrency: row.TargetCurrency,
		Rate:           row.Rate,
		EffectiveDate:  row.EffectiveDate.Time,
		CreatedAt:      row.CreatedAt.Time,
		UpdatedAt:      row.UpdatedAt.Time,
	}
}

func toDomainCurrency(row db.Currency) *domain.Currency {
	return &domain.Currency{
		Code:          row.Code,
		Name:          row.Name,
		Symbol:        row.Symbol,
		DecimalPlaces: int(row.DecimalPlaces),
		IsActive:      row.IsActive,
		CreatedAt:     row.CreatedAt.Time,
	}
}

var _ port.ExchangeRateRepository = (*ExchangeRateRepository)(nil)
