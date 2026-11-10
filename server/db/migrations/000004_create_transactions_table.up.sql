-- ==============================================================================
-- Migration: 000004_create_transactions_table.up.sql
-- Description: Create transactions table with deterministic numeric precision and sync indexes
-- Guidelines: AGENTS.md & PRD Savoryx (Deterministic Math & UUIDv7 support)
-- ==============================================================================

CREATE TYPE transaction_type AS ENUM ('INCOME', 'EXPENSE', 'TRANSFER');

CREATE TABLE IF NOT EXISTS transactions (
    id UUID PRIMARY KEY,
    account_id UUID NOT NULL REFERENCES accounts(id) ON DELETE RESTRICT,
    category_id UUID NULL REFERENCES categories(id) ON DELETE SET NULL,
    destination_account_id UUID NULL REFERENCES accounts(id) ON DELETE RESTRICT,
    type transaction_type NOT NULL,
    amount NUMERIC(19, 4) NOT NULL CHECK (amount > 0),
    currency VARCHAR(3) NOT NULL DEFAULT 'IDR',
    exchange_rate_to_base NUMERIC(18, 6) NOT NULL DEFAULT 1.000000 CHECK (exchange_rate_to_base > 0),
    base_amount NUMERIC(19, 4) NOT NULL CHECK (base_amount > 0),
    note TEXT NOT NULL DEFAULT '',
    is_talangan BOOLEAN NOT NULL DEFAULT FALSE,
    transaction_date TIMESTAMPTZ NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMPTZ NULL
);

CREATE INDEX IF NOT EXISTS idx_transactions_account_date ON transactions(account_id, transaction_date DESC) WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_transactions_updated_at ON transactions(updated_at);
CREATE INDEX IF NOT EXISTS idx_transactions_active ON transactions(deleted_at) WHERE deleted_at IS NULL;
