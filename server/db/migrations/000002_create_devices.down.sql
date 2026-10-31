-- ==============================================================================
-- Migration: 000002_create_devices.down.sql
-- Description: Rollback tabel devices
-- ==============================================================================

DROP INDEX IF EXISTS idx_devices_active;
DROP TABLE IF EXISTS devices;
