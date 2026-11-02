-- name: CreateExchangeRate :one
INSERT INTO exchange_rates (
    id, base_currency, target_currency, rate, effective_date, created_at, updated_at
) VALUES (
    $1, $2, $3, $4, $5, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
)
RETURNING id, base_currency, target_currency, rate, effective_date, created_at, updated_at;

-- name: UpsertExchangeRate :one
INSERT INTO exchange_rates (
    id, base_currency, target_currency, rate, effective_date, created_at, updated_at
) VALUES (
    $1, $2, $3, $4, $5, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
)
ON CONFLICT (base_currency, target_currency, effective_date)
DO UPDATE SET
    rate = EXCLUDED.rate,
    updated_at = CURRENT_TIMESTAMP
RETURNING id, base_currency, target_currency, rate, effective_date, created_at, updated_at;

-- name: GetLatestRate :one
SELECT id, base_currency, target_currency, rate, effective_date, created_at, updated_at
FROM exchange_rates
WHERE base_currency = $1 AND target_currency = $2
ORDER BY effective_date DESC
LIMIT 1;

-- name: GetHistoricalRateByDate :one
SELECT id, base_currency, target_currency, rate, effective_date, created_at, updated_at
FROM exchange_rates
WHERE base_currency = $1 AND target_currency = $2 AND effective_date = $3
LIMIT 1;

-- name: ListLatestRates :many
SELECT DISTINCT ON (target_currency)
    id, base_currency, target_currency, rate, effective_date, created_at, updated_at
FROM exchange_rates
WHERE base_currency = $1
ORDER BY target_currency, effective_date DESC;

-- name: ListSupportedCurrencies :many
SELECT code, name, symbol, decimal_places, is_active, created_at
FROM currencies
WHERE is_active = TRUE
ORDER BY code ASC;

-- name: GetCurrencyByCode :one
SELECT code, name, symbol, decimal_places, is_active, created_at
FROM currencies
WHERE code = $1
LIMIT 1;
