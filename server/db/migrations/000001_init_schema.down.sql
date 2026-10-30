-- ==============================================================================
-- Migration: 000001_init_schema.down.sql
-- Description: Rollback skema inti PostgreSQL
-- ==============================================================================

DROP TABLE IF EXISTS categories CASCADE;
DROP TABLE IF EXISTS accounts CASCADE;
DROP TABLE IF EXISTS user_preferences CASCADE;

DROP TYPE IF EXISTS account_type;
DROP TYPE IF EXISTS font_family_type;
DROP TYPE IF EXISTS theme_preference;
