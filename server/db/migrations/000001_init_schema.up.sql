-- ==============================================================================
-- Migration: 000001_init_schema.up.sql
-- Description: Inisialisasi skema inti PostgreSQL (user_preferences, accounts, categories)
-- Guidelines: AGENTS.md & PRD Savoryx (Deterministic Math & UUIDv7 support)
-- ==============================================================================

CREATE EXTENSION IF NOT EXISTS "pgcrypto";

CREATE TYPE theme_preference AS ENUM ('CLAY_LIGHT', 'CLAY_DARK', 'OLED_BLACK');
CREATE TYPE font_family_type AS ENUM ('NUNITO_SANS', 'INTER', 'POPPINS', 'UBUNTU', 'CHANGA_ONE', 'TINY5');
CREATE TYPE account_type AS ENUM ('CASH', 'BANK', 'E_WALLET', 'CREDIT_CARD', 'INVESTMENT', 'ASSET');

CREATE TABLE IF NOT EXISTS user_preferences (
    id UUID PRIMARY KEY,
    theme theme_preference NOT NULL DEFAULT 'CLAY_LIGHT',
    font_family font_family_type NOT NULL DEFAULT 'NUNITO_SANS',
    base_currency CHAR(3) NOT NULL DEFAULT 'IDR',
    monthly_work_hours INT NOT NULL DEFAULT 160,
    monthly_income_net NUMERIC(15, 2) NOT NULL DEFAULT 0.00,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS accounts (
    id UUID PRIMARY KEY,
    name VARCHAR(64) NOT NULL,
    type account_type NOT NULL,
    currency CHAR(3) NOT NULL DEFAULT 'IDR',
    balance NUMERIC(15, 2) NOT NULL DEFAULT 0.00,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMPTZ NULL
);

CREATE TABLE IF NOT EXISTS categories (
    id UUID PRIMARY KEY,
    name VARCHAR(64) NOT NULL,
    icon VARCHAR(32) NOT NULL,
    color VARCHAR(7) NOT NULL,
    is_wants BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMPTZ NULL
);

-- INDEKS PERFORMA & FILTER SOFT DELETE
CREATE INDEX IF NOT EXISTS idx_accounts_active ON accounts(deleted_at) WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_accounts_updated ON accounts(updated_at);
CREATE INDEX IF NOT EXISTS idx_categories_active ON categories(deleted_at) WHERE deleted_at IS NULL;
