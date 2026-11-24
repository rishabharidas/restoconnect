-- ==============================================================================
-- Migration: 000001_initial_schema.down.sql
-- Description: Revert Core Schema
-- ==============================================================================

DROP TABLE IF EXISTS restoapp.website_sections CASCADE;
DROP TABLE IF EXISTS restoapp.website_pages CASCADE;
DROP TABLE IF EXISTS restoapp.driver_location_logs CASCADE;
DROP TABLE IF EXISTS restoapp.deliveries CASCADE;
DROP TABLE IF EXISTS restoapp.order_status_history CASCADE;
DROP TABLE IF EXISTS restoapp.order_items CASCADE;
DROP TABLE IF EXISTS restoapp.orders CASCADE;
DROP TABLE IF EXISTS restoapp.menu_items CASCADE;
DROP TABLE IF EXISTS restoapp.menu_categories CASCADE;
DROP TABLE IF EXISTS restoapp.reservations CASCADE;
DROP TABLE IF EXISTS restoapp.restaurant_tables CASCADE;
DROP TABLE IF EXISTS restoapp.users CASCADE;
DROP TABLE IF EXISTS restoapp.outlets CASCADE;
DROP TABLE IF EXISTS restoapp.tenants CASCADE;
DROP TABLE IF EXISTS restoapp.roles CASCADE;

DROP TYPE IF EXISTS restoapp.order_status CASCADE;
DROP TYPE IF EXISTS restoapp.order_type CASCADE;

DROP SCHEMA IF EXISTS restoapp CASCADE;
