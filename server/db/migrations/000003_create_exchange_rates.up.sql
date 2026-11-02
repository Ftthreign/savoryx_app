-- ==============================================================================
-- Migration: 000003_create_exchange_rates.up.sql
-- ==============================================================================

CREATE TABLE IF NOT EXISTS currencies (
    code VARCHAR(3) PRIMARY KEY,
    name VARCHAR(64) NOT NULL,
    symbol VARCHAR(8) NOT NULL,
    decimal_places INT NOT NULL DEFAULT 2,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS exchange_rates (
    id UUID PRIMARY KEY,
    base_currency VARCHAR(3) NOT NULL REFERENCES currencies(code) ON DELETE RESTRICT,
    target_currency VARCHAR(3) NOT NULL REFERENCES currencies(code) ON DELETE RESTRICT,
    rate NUMERIC(18, 6) NOT NULL,
    effective_date DATE NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Indeks komposit unik untuk menjamin keunikan kurs per pasangan mata uang per tanggal
-- dan mempercepat pencarian kurs terbaru (ORDER BY effective_date DESC)
CREATE UNIQUE INDEX IF NOT EXISTS idx_exchange_rates_base_target_date
    ON exchange_rates(base_currency, target_currency, effective_date DESC);

CREATE INDEX IF NOT EXISTS idx_exchange_rates_effective_date
    ON exchange_rates(effective_date DESC);

-- Seeding data awal untuk 15 mata uang global utama
INSERT INTO currencies (code, name, symbol, decimal_places, is_active) VALUES
    ('IDR', 'Indonesian Rupiah', 'Rp', 0, TRUE),
    ('USD', 'United States Dollar', '$', 2, TRUE),
    ('SGD', 'Singapore Dollar', 'S$', 2, TRUE),
    ('EUR', 'Euro', '€', 2, TRUE),
    ('JPY', 'Japanese Yen', '¥', 0, TRUE),
    ('GBP', 'British Pound Sterling', '£', 2, TRUE),
    ('AUD', 'Australian Dollar', 'A$', 2, TRUE),
    ('CNY', 'Chinese Yuan', '¥', 2, TRUE),
    ('MYR', 'Malaysian Ringgit', 'RM', 2, TRUE),
    ('THB', 'Thai Baht', '฿', 2, TRUE),
    ('HKD', 'Hong Kong Dollar', 'HK$', 2, TRUE),
    ('CAD', 'Canadian Dollar', 'C$', 2, TRUE),
    ('CHF', 'Swiss Franc', 'CHF', 2, TRUE),
    ('KRW', 'South Korean Won', '₩', 0, TRUE),
    ('SAR', 'Saudi Riyal', '﷼', 2, TRUE)
ON CONFLICT (code) DO UPDATE SET
    name = EXCLUDED.name,
    symbol = EXCLUDED.symbol,
    decimal_places = EXCLUDED.decimal_places,
    is_active = EXCLUDED.is_active;
