-- ==============================================================================
-- Migration: 000005_create_sync_logs_table.down.sql
-- Description: Rollback sync_logs audit table creation
-- ==============================================================================

DROP INDEX IF EXISTS idx_sync_logs_device_created;
DROP TABLE IF EXISTS sync_logs;
