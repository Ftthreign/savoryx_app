-- ==============================================================================
-- Migration: 000004_create_transactions_table.down.sql
-- Description: Rollback transactions table and transaction_type enum
-- ==============================================================================

DROP INDEX IF EXISTS idx_transactions_active;
DROP INDEX IF EXISTS idx_transactions_updated_at;
DROP INDEX IF EXISTS idx_transactions_account_date;
DROP TABLE IF EXISTS transactions;
DROP TYPE IF EXISTS transaction_type;
