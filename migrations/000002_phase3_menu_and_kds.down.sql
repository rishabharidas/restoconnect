-- ==============================================================================
-- Migration: 000002_phase3_menu_and_kds.down.sql
-- Description: Rollback Phase 3 & Phase 4 schema changes
-- ==============================================================================

-- 1. Revert order_items additions
ALTER TABLE restoapp.order_items
    DROP COLUMN IF EXISTS completed_at,
    DROP COLUMN IF EXISTS assigned_station,
    DROP COLUMN IF EXISTS kitchen_notes;

-- 2. Revert orders idempotency
DROP INDEX IF EXISTS restoapp.idx_orders_tenant_idempotency;
ALTER TABLE restoapp.orders
    DROP COLUMN IF EXISTS idempotency_key;

-- 3. Revert outlet_menu_items
DROP TABLE IF EXISTS restoapp.outlet_menu_items;

-- 4. Revert menu_items additions
ALTER TABLE restoapp.menu_items
    DROP COLUMN IF EXISTS assigned_stations,
    DROP COLUMN IF EXISTS variants,
    DROP COLUMN IF EXISTS allergens;
