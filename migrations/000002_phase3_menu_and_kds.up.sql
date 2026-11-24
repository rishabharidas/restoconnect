-- ==============================================================================
-- Migration: 000002_phase3_menu_and_kds.up.sql
-- Description: Phase 3 Menu Engineering & Phase 4 Kitchen Station Pipeline
-- ==============================================================================

-- 1. Extend menu_items with allergens, multi-station routing, and variants
ALTER TABLE restoapp.menu_items
    ADD COLUMN IF NOT EXISTS allergens TEXT[] NOT NULL DEFAULT '{}',
    ADD COLUMN IF NOT EXISTS variants JSONB NOT NULL DEFAULT '[]'::jsonb,
    ADD COLUMN IF NOT EXISTS assigned_stations TEXT[] NOT NULL DEFAULT '{"MAIN_KITCHEN"}';

-- Populate assigned_stations from kitchen_station if already present
UPDATE restoapp.menu_items 
SET assigned_stations = ARRAY[kitchen_station] 
WHERE kitchen_station IS NOT NULL AND assigned_stations = '{"MAIN_KITCHEN"}';

-- 2. Outlet-specific Pricing & Availability (Multi-branch customization)
CREATE TABLE IF NOT EXISTS restoapp.outlet_menu_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES restoapp.tenants(id) ON DELETE CASCADE,
    outlet_id UUID NOT NULL REFERENCES restoapp.outlets(id) ON DELETE CASCADE,
    item_id UUID NOT NULL REFERENCES restoapp.menu_items(id) ON DELETE CASCADE,
    price NUMERIC(10, 2) NOT NULL,
    is_available BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_outlet_menu_item UNIQUE (tenant_id, outlet_id, item_id)
);
CREATE INDEX IF NOT EXISTS idx_outlet_menu_items_outlet ON restoapp.outlet_menu_items(outlet_id);
CREATE INDEX IF NOT EXISTS idx_outlet_menu_items_item ON restoapp.outlet_menu_items(item_id);

-- 3. Idempotency Support for Orders
ALTER TABLE restoapp.orders
    ADD COLUMN IF NOT EXISTS idempotency_key VARCHAR(128);

CREATE UNIQUE INDEX IF NOT EXISTS idx_orders_tenant_idempotency 
ON restoapp.orders(tenant_id, idempotency_key) 
WHERE idempotency_key IS NOT NULL;

-- 4. Granular Item-level Kitchen Display Status and Notes
ALTER TABLE restoapp.order_items
    ADD COLUMN IF NOT EXISTS kitchen_notes TEXT,
    ADD COLUMN IF NOT EXISTS assigned_station VARCHAR(50) DEFAULT 'MAIN_KITCHEN',
    ADD COLUMN IF NOT EXISTS completed_at TIMESTAMPTZ;
