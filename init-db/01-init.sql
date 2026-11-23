-- ==============================================================================
-- Resto Platform Database Initialization
-- Multi-Tenant Schema, Enum Types, Tables, RLS, and Demo Data
-- ==============================================================================

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

CREATE SCHEMA IF NOT EXISTS restoapp;

-- 1. Roles
CREATE TABLE IF NOT EXISTS restoapp.roles (
    id SERIAL PRIMARY KEY,
    name VARCHAR(64) UNIQUE NOT NULL,
    description TEXT
);

INSERT INTO restoapp.roles (id, name, description) VALUES
(1, 'superadmin', 'Platform superadmin with access to all tenants'),
(2, 'owner', 'Restaurant owner with full access to their restaurant tenant'),
(3, 'manager', 'Restaurant branch manager'),
(4, 'waiter', 'Service staff taking orders and serving food'),
(5, 'chef', 'Kitchen staff preparing dishes'),
(6, 'driver', 'Delivery partner handling home deliveries'),
(7, 'customer', 'End customer ordering food')
ON CONFLICT (id) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description;

-- 2. Tenants (Multi-Tenant Registry)
CREATE TABLE IF NOT EXISTS restoapp.tenants (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    slug VARCHAR(64) UNIQUE NOT NULL,
    name VARCHAR(255) NOT NULL,
    custom_domain VARCHAR(255) UNIQUE,
    phone VARCHAR(32) NOT NULL,
    email VARCHAR(255) NOT NULL,
    address TEXT NOT NULL,
    branding JSONB NOT NULL DEFAULT '{
        "primary_color": "#2563eb",
        "secondary_color": "#1e293b",
        "font_family": "Inter",
        "logo_url": null,
        "hero_banner_url": null
    }'::jsonb,
    settings JSONB NOT NULL DEFAULT '{
        "currency": "INR",
        "currency_symbol": "₹",
        "tax_gst_percentage": 5.0,
        "service_charge_percentage": 0.0,
        "enable_dine_in": true,
        "enable_delivery": true,
        "enable_takeaway": true
    }'::jsonb,
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 3. Outlets (Branches)
CREATE TABLE IF NOT EXISTS restoapp.outlets (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES restoapp.tenants(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    phone VARCHAR(32) NOT NULL,
    address TEXT NOT NULL,
    latitude DOUBLE PRECISION,
    longitude DOUBLE PRECISION,
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 4. Users
CREATE TABLE IF NOT EXISTS restoapp.users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID REFERENCES restoapp.tenants(id) ON DELETE CASCADE,
    role_id INT NOT NULL REFERENCES restoapp.roles(id),
    first_name VARCHAR(128) NOT NULL,
    last_name VARCHAR(128) NOT NULL,
    email VARCHAR(255),
    phone VARCHAR(32) NOT NULL,
    password_hash VARCHAR(255),
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_users_tenant_phone ON restoapp.users(tenant_id, phone);

-- 5. Restaurant Tables (For Dine-In)
CREATE TABLE IF NOT EXISTS restoapp.restaurant_tables (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES restoapp.tenants(id) ON DELETE CASCADE,
    outlet_id UUID NOT NULL REFERENCES restoapp.outlets(id) ON DELETE CASCADE,
    table_number VARCHAR(32) NOT NULL,
    qr_code_token VARCHAR(255) NOT NULL UNIQUE,
    capacity INT NOT NULL DEFAULT 4,
    status VARCHAR(32) NOT NULL DEFAULT 'AVAILABLE',
    active_order_id UUID,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 6. Menu Categories & Items
CREATE TABLE IF NOT EXISTS restoapp.menu_categories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES restoapp.tenants(id) ON DELETE CASCADE,
    name VARCHAR(128) NOT NULL,
    description TEXT,
    display_order INT NOT NULL DEFAULT 0,
    is_active BOOLEAN NOT NULL DEFAULT true
);

CREATE TABLE IF NOT EXISTS restoapp.menu_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES restoapp.tenants(id) ON DELETE CASCADE,
    category_id UUID NOT NULL REFERENCES restoapp.menu_categories(id) ON DELETE RESTRICT,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    price NUMERIC(10, 2) NOT NULL,
    food_type VARCHAR(32) NOT NULL DEFAULT 'VEG',
    image_url TEXT,
    is_available BOOLEAN NOT NULL DEFAULT true,
    kitchen_station VARCHAR(64) DEFAULT 'MAIN_KITCHEN',
    preparation_time_mins INT DEFAULT 15,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 7. Orders & States
DO $$ BEGIN
    CREATE TYPE restoapp.order_type AS ENUM ('DINE_IN', 'DELIVERY', 'TAKEAWAY');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE restoapp.order_status AS ENUM (
        'PLACED',
        'WAITER_CONFIRMED',
        'CHEF_ACCEPTED',
        'IN_COOKING',
        'BEING_PREPARED',
        'PLATING',
        'READY_TO_SERVE',
        'SERVED',
        'DRIVER_ASSIGNED',
        'OUT_FOR_DELIVERY',
        'DELIVERED',
        'COMPLETED',
        'CANCELLED'
    );
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

CREATE TABLE IF NOT EXISTS restoapp.orders (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES restoapp.tenants(id) ON DELETE CASCADE,
    outlet_id UUID NOT NULL REFERENCES restoapp.outlets(id) ON DELETE CASCADE,
    order_number VARCHAR(32) NOT NULL,
    order_type restoapp.order_type NOT NULL,
    status restoapp.order_status NOT NULL DEFAULT 'PLACED',
    table_id UUID REFERENCES restoapp.restaurant_tables(id),
    customer_id UUID REFERENCES restoapp.users(id),
    waiter_id UUID REFERENCES restoapp.users(id),
    special_instructions TEXT,
    subtotal NUMERIC(10, 2) NOT NULL DEFAULT 0.00,
    tax_amount NUMERIC(10, 2) NOT NULL DEFAULT 0.00,
    delivery_fee NUMERIC(10, 2) NOT NULL DEFAULT 0.00,
    total_amount NUMERIC(10, 2) NOT NULL DEFAULT 0.00,
    payment_status VARCHAR(32) NOT NULL DEFAULT 'PENDING',
    payment_method VARCHAR(32),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS restoapp.order_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id UUID NOT NULL REFERENCES restoapp.orders(id) ON DELETE CASCADE,
    item_id UUID NOT NULL REFERENCES restoapp.menu_items(id),
    quantity INT NOT NULL DEFAULT 1,
    unit_price NUMERIC(10, 2) NOT NULL,
    item_total NUMERIC(10, 2) NOT NULL,
    item_status restoapp.order_status NOT NULL DEFAULT 'PLACED',
    special_instructions TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 8. Order Status History (Audit trail for tracking pipeline)
CREATE TABLE IF NOT EXISTS restoapp.order_status_history (
    id BIGSERIAL PRIMARY KEY,
    order_id UUID NOT NULL REFERENCES restoapp.orders(id) ON DELETE CASCADE,
    previous_status restoapp.order_status,
    new_status restoapp.order_status NOT NULL,
    changed_by_user_id UUID REFERENCES restoapp.users(id),
    note TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 9. Delivery Details & Live Location Logs
CREATE TABLE IF NOT EXISTS restoapp.deliveries (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES restoapp.tenants(id) ON DELETE CASCADE,
    order_id UUID NOT NULL REFERENCES restoapp.orders(id) ON DELETE CASCADE,
    driver_id UUID REFERENCES restoapp.users(id),
    delivery_address TEXT NOT NULL,
    delivery_lat DOUBLE PRECISION,
    delivery_lng DOUBLE PRECISION,
    customer_phone VARCHAR(32) NOT NULL,
    delivery_otp VARCHAR(6),
    estimated_arrival_time TIMESTAMPTZ,
    started_at TIMESTAMPTZ,
    delivered_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS restoapp.driver_location_logs (
    id BIGSERIAL PRIMARY KEY,
    driver_id UUID NOT NULL REFERENCES restoapp.users(id),
    order_id UUID REFERENCES restoapp.orders(id),
    latitude DOUBLE PRECISION NOT NULL,
    longitude DOUBLE PRECISION NOT NULL,
    heading REAL,
    speed REAL,
    recorded_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ==============================================================================
-- Demo Seed Data (for immediate testing out of the box)
-- ==============================================================================

INSERT INTO restoapp.tenants (id, slug, name, phone, email, address, branding, settings) VALUES
(
    'a0000000-0000-0000-0000-000000000001',
    'royal-spice',
    'The Royal Spice Restaurant',
    '+919876543210',
    'contact@royalspice.com',
    '123 MG Road, Bangalore, India',
    '{
        "primary_color": "#e11d48",
        "secondary_color": "#1e293b",
        "accent_color": "#fbbf24",
        "font_family": "Inter",
        "logo_url": "https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?w=200&auto=format&fit=crop&q=80"
    }'::jsonb,
    '{
        "currency": "INR",
        "currency_symbol": "₹",
        "tax_gst_percentage": 5.0,
        "service_charge_percentage": 0.0,
        "enable_dine_in": true,
        "enable_delivery": true,
        "enable_takeaway": true,
        "whatsapp_notifications": true
    }'::jsonb
) ON CONFLICT (slug) DO NOTHING;

INSERT INTO restoapp.outlets (id, tenant_id, name, phone, address, latitude, longitude) VALUES
(
    'b0000000-0000-0000-0000-000000000001',
    'a0000000-0000-0000-0000-000000000001',
    'Indiranagar Outlet',
    '+919876543210',
    '100 Feet Road, Indiranagar, Bangalore',
    12.9716,
    77.5946
) ON CONFLICT DO NOTHING;

-- Demo Tables for Indiranagar Outlet
INSERT INTO restoapp.restaurant_tables (tenant_id, outlet_id, table_number, qr_code_token, capacity) VALUES
('a0000000-0000-0000-0000-000000000001', 'b0000000-0000-0000-0000-000000000001', 'T-01', 'qr_token_table_1_royal_spice', 4),
('a0000000-0000-0000-0000-000000000001', 'b0000000-0000-0000-0000-000000000001', 'T-02', 'qr_token_table_2_royal_spice', 2),
('a0000000-0000-0000-0000-000000000001', 'b0000000-0000-0000-0000-000000000001', 'T-03', 'qr_token_table_3_royal_spice', 6)
ON CONFLICT (qr_code_token) DO NOTHING;

-- Demo Menu Category & Items
INSERT INTO restoapp.menu_categories (id, tenant_id, name, display_order) VALUES
('c0000000-0000-0000-0000-000000000001', 'a0000000-0000-0000-0000-000000000001', 'Starters', 1),
('c0000000-0000-0000-0000-000000000002', 'a0000000-0000-0000-0000-000000000001', 'Main Course', 2),
('c0000000-0000-0000-0000-000000000003', 'a0000000-0000-0000-0000-000000000001', 'Desserts & Beverages', 3)
ON CONFLICT DO NOTHING;

INSERT INTO restoapp.menu_items (tenant_id, category_id, name, description, price, food_type, preparation_time_mins) VALUES
('a0000000-0000-0000-0000-000000000001', 'c0000000-0000-0000-0000-000000000001', 'Paneer Tikka', 'Clay oven grilled cottage cheese marinated in spices', 280.00, 'VEG', 15),
('a0000000-0000-0000-0000-000000000001', 'c0000000-0000-0000-0000-000000000001', 'Murgh Malai Kebab', 'Creamy boneless chicken kebab flavored with cardamom', 340.00, 'NON_VEG', 18),
('a0000000-0000-0000-0000-000000000001', 'c0000000-0000-0000-0000-000000000002', 'Butter Chicken Masala', 'Classic roasted chicken in silky rich tomato-butter gravy', 420.00, 'NON_VEG', 20),
('a0000000-0000-0000-0000-000000000001', 'c0000000-0000-0000-0000-000000000002', 'Dal Makhani', 'Slow simmered black lentils with cream and butter', 260.00, 'VEG', 15),
('a0000000-0000-0000-0000-000000000003', 'c0000000-0000-0000-0000-000000000003', 'Gulab Jamun with Rabdi', 'Warm milk dumplings served with reduced saffron milk', 140.00, 'VEG', 5)
ON CONFLICT DO NOTHING;
