-- ==============================================================================
-- Migration: 000003_create_exchange_rates.down.sql
-- Description: Rollback tabel exchange_rates dan currencies
-- ==============================================================================

DROP TABLE IF EXISTS exchange_rates CASCADE;
DROP TABLE IF EXISTS currencies CASCADE;
