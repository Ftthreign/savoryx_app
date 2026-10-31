-- ==============================================================================
-- Migration: 000002_create_devices.up.sql
-- Description: Tabel devices untuk device handshake & PASETO authentication
-- Guidelines: AGENTS.md & Task #21
-- ==============================================================================

CREATE TABLE IF NOT EXISTS devices (
    id UUID PRIMARY KEY,
    device_name VARCHAR(128) NOT NULL,
    platform VARCHAR(20) NOT NULL,
    app_version VARCHAR(20) NOT NULL,
    device_secret_hash VARCHAR(255) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    last_active_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    revoked_at TIMESTAMPTZ NULL
);

CREATE INDEX IF NOT EXISTS idx_devices_active ON devices(last_active_at) WHERE revoked_at IS NULL;
