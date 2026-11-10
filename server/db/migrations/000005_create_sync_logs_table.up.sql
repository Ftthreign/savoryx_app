-- ==============================================================================
-- Migration: 000005_create_sync_logs_table.up.sql
-- Description: Create sync_logs audit table and enforce microsecond TIMESTAMPTZ(6) precision
-- Guidelines: AGENTS.md & Sprint 4 Task #53 (Two-Way Delta Sync Engine & Audit Trail)
-- ==============================================================================

CREATE TABLE IF NOT EXISTS sync_logs (
    id UUID PRIMARY KEY,
    device_id UUID NOT NULL REFERENCES devices(id) ON DELETE CASCADE,
    direction VARCHAR(10) NOT NULL CHECK (direction IN ('PUSH', 'PULL')),
    batch_size INT NOT NULL DEFAULT 0 CHECK (batch_size >= 0),
    status VARCHAR(20) NOT NULL CHECK (status IN ('SUCCESS', 'PARTIAL', 'FAILED')),
    client_timestamp TIMESTAMPTZ(6) NOT NULL,
    server_timestamp TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_sync_logs_device_created
    ON sync_logs (device_id, created_at DESC);

ALTER TABLE accounts
    ALTER COLUMN created_at TYPE TIMESTAMPTZ(6),
    ALTER COLUMN updated_at TYPE TIMESTAMPTZ(6),
    ALTER COLUMN deleted_at TYPE TIMESTAMPTZ(6);

ALTER TABLE categories
    ALTER COLUMN created_at TYPE TIMESTAMPTZ(6),
    ALTER COLUMN updated_at TYPE TIMESTAMPTZ(6),
    ALTER COLUMN deleted_at TYPE TIMESTAMPTZ(6);

ALTER TABLE transactions
    ALTER COLUMN transaction_date TYPE TIMESTAMPTZ(6),
    ALTER COLUMN created_at TYPE TIMESTAMPTZ(6),
    ALTER COLUMN updated_at TYPE TIMESTAMPTZ(6),
    ALTER COLUMN deleted_at TYPE TIMESTAMPTZ(6);
