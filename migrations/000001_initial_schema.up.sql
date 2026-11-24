-- ==============================================================================
-- Migration: 000001_initial_schema.up.sql
-- Description: Core Multi-Tenant Restaurant Operating System Schema
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
(1, 'superadmin', 'Platform superadmin with cross-tenant administrative access'),
(2, 'owner', 'Restaurant owner with full access to their restaurant tenant'),
(3, 'manager', 'Restaurant branch / outlet manager'),
(4, 'waiter', 'Service staff taking orders and serving tables'),
(5, 'chef', 'Kitchen staff preparing dishes and updating KDS'),
(6, 'driver', 'Delivery partner handling home deliveries with GPS'),
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
        "primary_color": "#27272a",
        "secondary_color": "#18181b",
        "accent_color": "#f59e0b",
        "font_family": "Inter",
        "logo_url": null,
        "hero_banner_url": null,
        "landing_mode": "DEFAULT"
    }'::jsonb,
    settings JSONB NOT NULL DEFAULT '{
        "currency": "INR",
        "currency_symbol": "₹",
        "tax_gst_percentage": 5.0,
        "service_charge_percentage": 0.0,
        "enable_dine_in": true,
        "enable_delivery": true,
        "enable_takeaway": true,
        "whatsapp_notifications": true
    }'::jsonb,
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_tenants_slug ON restoapp.tenants(slug);
CREATE INDEX IF NOT EXISTS idx_tenants_custom_domain ON restoapp.tenants(custom_domain);

-- 3. Outlets / Branches
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
CREATE INDEX IF NOT EXISTS idx_outlets_tenant ON restoapp.outlets(tenant_id);

-- 4. Users & Staff
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
CREATE INDEX IF NOT EXISTS idx_users_tenant_email ON restoapp.users(tenant_id, email);

-- 5. Restaurant Tables (Dine-In Seating)
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
CREATE INDEX IF NOT EXISTS idx_tables_tenant ON restoapp.restaurant_tables(tenant_id);
CREATE INDEX IF NOT EXISTS idx_tables_qr_token ON restoapp.restaurant_tables(qr_code_token);

-- 6. Table Reservations
CREATE TABLE IF NOT EXISTS restoapp.reservations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES restoapp.tenants(id) ON DELETE CASCADE,
    outlet_id UUID NOT NULL REFERENCES restoapp.outlets(id) ON DELETE CASCADE,
    customer_name VARCHAR(128) NOT NULL,
    customer_phone VARCHAR(32) NOT NULL,
    customer_email VARCHAR(255),
    guest_count INT NOT NULL DEFAULT 2,
    reservation_date DATE NOT NULL,
    reservation_time TIME NOT NULL,
    status VARCHAR(32) NOT NULL DEFAULT 'PENDING',
    table_id UUID REFERENCES restoapp.restaurant_tables(id),
    special_requests TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_reservations_tenant_date ON restoapp.reservations(tenant_id, reservation_date);

-- 7. Menu Categories & Items
CREATE TABLE IF NOT EXISTS restoapp.menu_categories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES restoapp.tenants(id) ON DELETE CASCADE,
    name VARCHAR(128) NOT NULL,
    description TEXT,
    display_order INT NOT NULL DEFAULT 0,
    is_active BOOLEAN NOT NULL DEFAULT true
);
CREATE INDEX IF NOT EXISTS idx_categories_tenant ON restoapp.menu_categories(tenant_id);

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
    modifiers JSONB NOT NULL DEFAULT '[]'::jsonb,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_menu_items_tenant ON restoapp.menu_items(tenant_id);
CREATE INDEX IF NOT EXISTS idx_menu_items_category ON restoapp.menu_items(category_id);

-- 8. Orders & Granular Pipeline
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
    customer_name VARCHAR(128),
    customer_phone VARCHAR(32),
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
CREATE INDEX IF NOT EXISTS idx_orders_tenant_status ON restoapp.orders(tenant_id, status);

CREATE TABLE IF NOT EXISTS restoapp.order_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id UUID NOT NULL REFERENCES restoapp.orders(id) ON DELETE CASCADE,
    item_id UUID NOT NULL REFERENCES restoapp.menu_items(id),
    quantity INT NOT NULL DEFAULT 1,
    unit_price NUMERIC(10, 2) NOT NULL,
    item_total NUMERIC(10, 2) NOT NULL,
    item_status restoapp.order_status NOT NULL DEFAULT 'PLACED',
    special_instructions TEXT,
    selected_modifiers JSONB DEFAULT '[]'::jsonb,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_order_items_order ON restoapp.order_items(order_id);

CREATE TABLE IF NOT EXISTS restoapp.order_status_history (
    id BIGSERIAL PRIMARY KEY,
    order_id UUID NOT NULL REFERENCES restoapp.orders(id) ON DELETE CASCADE,
    previous_status restoapp.order_status,
    new_status restoapp.order_status NOT NULL,
    changed_by_user_id UUID REFERENCES restoapp.users(id),
    note TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_order_history_order ON restoapp.order_status_history(order_id);

-- 9. Delivery & Live Location Logs
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
CREATE INDEX IF NOT EXISTS idx_deliveries_tenant ON restoapp.deliveries(tenant_id);

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
CREATE INDEX IF NOT EXISTS idx_driver_logs_order ON restoapp.driver_location_logs(order_id);

-- 10. Website CMS & Section Engine
CREATE TABLE IF NOT EXISTS restoapp.website_pages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES restoapp.tenants(id) ON DELETE CASCADE,
    slug VARCHAR(64) NOT NULL,
    title VARCHAR(255) NOT NULL,
    is_published BOOLEAN NOT NULL DEFAULT true,
    meta_description TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (tenant_id, slug)
);

CREATE TABLE IF NOT EXISTS restoapp.website_sections (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    page_id UUID NOT NULL REFERENCES restoapp.website_pages(id) ON DELETE CASCADE,
    tenant_id UUID NOT NULL REFERENCES restoapp.tenants(id) ON DELETE CASCADE,
    section_type VARCHAR(64) NOT NULL,
    display_order INT NOT NULL DEFAULT 0,
    is_enabled BOOLEAN NOT NULL DEFAULT true,
    content JSONB NOT NULL DEFAULT '{}'::jsonb,
    settings JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_sections_page ON restoapp.website_sections(page_id, display_order);

-- ==============================================================================
-- Demo Seed Data: Test Restaurant
-- ==============================================================================
INSERT INTO restoapp.tenants (id, slug, name, phone, email, address, branding, settings) VALUES
(
    'a0000000-0000-0000-0000-000000000001',
    'test-resto',
    'The Royal Heritage Charcoal Hearth',
    '+919876543210',
    'contact@testrestaurant.com',
    '123 Main Food Street, City Center',
    '{
        "primary_color": "#27272a",
        "secondary_color": "#18181b",
        "accent_color": "#f59e0b",
        "font_family": "Inter",
        "logo_url": "https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?w=200&auto=format&fit=crop&q=80",
        "hero_banner_url": "https://images.unsplash.com/photo-1544025162-d76694265947?w=1600&auto=format&fit=crop&q=85",
        "landing_mode": "DEFAULT"
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
) ON CONFLICT (id) DO UPDATE SET slug = EXCLUDED.slug, name = EXCLUDED.name, branding = EXCLUDED.branding;

INSERT INTO restoapp.outlets (id, tenant_id, name, phone, address, latitude, longitude) VALUES
(
    'b0000000-0000-0000-0000-000000000001',
    'a0000000-0000-0000-0000-000000000001',
    'Main Flagship Outlet',
    '+919876543210',
    '123 Main Food Street, City Center',
    12.9716,
    77.5946
) ON CONFLICT (id) DO NOTHING;

-- Demo Staff Users (bcrypt password: resto123)
-- Hash generated via bcrypt: $2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi
INSERT INTO restoapp.users (id, tenant_id, role_id, first_name, last_name, email, phone, password_hash) VALUES
('e0000000-0000-0000-0000-000000000001', 'a0000000-0000-0000-0000-000000000001', 2, 'Vikram', 'Aditya', 'owner@resto.local', '+919876500001', '$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi'),
('e0000000-0000-0000-0000-000000000002', 'a0000000-0000-0000-0000-000000000001', 4, 'Rajesh', 'Kumar', 'waiter@resto.local', '+919876500002', '$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi'),
('e0000000-0000-0000-0000-000000000003', 'a0000000-0000-0000-0000-000000000001', 5, 'Sanjeev', 'Kapoor', 'chef@resto.local', '+919876500003', '$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi'),
('e0000000-0000-0000-0000-000000000004', 'a0000000-0000-0000-0000-000000000001', 6, 'Ramesh', 'Singh', 'driver@resto.local', '+919876500004', '$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi')
ON CONFLICT (id) DO NOTHING;

-- Demo Tables for Main Outlet
INSERT INTO restoapp.restaurant_tables (tenant_id, outlet_id, table_number, qr_code_token, capacity) VALUES
('a0000000-0000-0000-0000-000000000001', 'b0000000-0000-0000-0000-000000000001', 'T-01', 'qr_token_table_1_test_resto', 4),
('a0000000-0000-0000-0000-000000000001', 'b0000000-0000-0000-0000-000000000001', 'T-02', 'qr_token_table_2_test_resto', 2),
('a0000000-0000-0000-0000-000000000001', 'b0000000-0000-0000-0000-000000000001', 'T-03', 'qr_token_table_3_test_resto', 6),
('a0000000-0000-0000-0000-000000000001', 'b0000000-0000-0000-0000-000000000001', 'T-04', 'qr_token_table_4_test_resto', 4),
('a0000000-0000-0000-0000-000000000001', 'b0000000-0000-0000-0000-000000000001', 'T-05', 'qr_token_table_5_test_resto', 4),
('a0000000-0000-0000-0000-000000000001', 'b0000000-0000-0000-0000-000000000001', 'T-06', 'qr_token_table_6_test_resto', 8)
ON CONFLICT (qr_code_token) DO NOTHING;

-- Demo Menu Categories
INSERT INTO restoapp.menu_categories (id, tenant_id, name, description, display_order) VALUES
('c0000000-0000-0000-0000-000000000001', 'a0000000-0000-0000-0000-000000000001', 'Starters & Tandoor', 'Clay oven smoked kebabs and crisp appetizers', 1),
('c0000000-0000-0000-0000-000000000002', 'a0000000-0000-0000-0000-000000000001', 'Royal Curries & Mains', 'Slow dum simmered curries and gravies', 2),
('c0000000-0000-0000-0000-000000000003', 'a0000000-0000-0000-0000-000000000001', 'Artisanal Breads & Rice', 'Blistered sourdough naans and aged basmati biryani', 3),
('c0000000-0000-0000-0000-000000000004', 'a0000000-0000-0000-0000-000000000001', 'Desserts & Botanical Drinks', 'Handcrafted saffron sweets and cold-pressed mocktails', 4)
ON CONFLICT (id) DO NOTHING;

-- Demo Menu Items
INSERT INTO restoapp.menu_items (id, tenant_id, category_id, name, description, price, food_type, preparation_time_mins, kitchen_station, image_url) VALUES
('d0000000-0000-0000-0000-000000000001', 'a0000000-0000-0000-0000-000000000001', 'c0000000-0000-0000-0000-000000000001', 'Paneer Tikka Angara', 'Clay oven grilled cottage cheese cubes marinated in smoked degi mirch and mustard oil', 280.00, 'VEG', 15, 'GRILL', 'https://images.unsplash.com/photo-1567188040759-fb8a883dc6d8?w=600&auto=format&fit=crop&q=80'),
('d0000000-0000-0000-0000-000000000002', 'a0000000-0000-0000-0000-000000000001', 'c0000000-0000-0000-0000-000000000001', 'Murgh Malai Kebab', 'Silky boneless chicken skewers steeped in cream, green cardamom, and roasted garlic', 340.00, 'NON_VEG', 18, 'GRILL', 'https://images.unsplash.com/photo-1599488615731-7e5c2823ff28?w=600&auto=format&fit=crop&q=80'),
('d0000000-0000-0000-0000-000000000003', 'a0000000-0000-0000-0000-000000000001', 'c0000000-0000-0000-0000-000000000002', 'Butter Chicken Masala', 'Tandoor roasted shredded chicken folded into a velvety, honey-kissed tomato butter gravy', 420.00, 'NON_VEG', 20, 'CURRY', 'https://images.unsplash.com/photo-1603894584373-5ac82b2ae398?w=600&auto=format&fit=crop&q=80'),
('d0000000-0000-0000-0000-000000000004', 'a0000000-0000-0000-0000-000000000001', 'c0000000-0000-0000-0000-000000000002', 'Dal Makhani Heritage', 'Whole black lentils simmered for 18 hours over charcoal embers with white butter and cream', 260.00, 'VEG', 15, 'CURRY', 'https://images.unsplash.com/photo-1546833999-b9f581a1996d?w=600&auto=format&fit=crop&q=80'),
('d0000000-0000-0000-0000-000000000005', 'a0000000-0000-0000-0000-000000000001', 'c0000000-0000-0000-0000-000000000003', 'Garlic Butter Naan', 'Crisp tandoori sourdough flatbread glazed with crushed roasted garlic and butter', 70.00, 'VEG', 8, 'GRILL', 'https://images.unsplash.com/photo-1626074353765-517a681e40be?w=600&auto=format&fit=crop&q=80'),
('d0000000-0000-0000-0000-000000000006', 'a0000000-0000-0000-0000-000000000001', 'c0000000-0000-0000-0000-000000000004', 'Gulab Jamun with Saffron Rabdi', 'Warm melt-in-mouth milk dumplings served over thick saffron cardamom rabdi', 140.00, 'VEG', 5, 'DESSERT', 'https://images.unsplash.com/photo-1667295786438-fb1c8018e690?w=600&auto=format&fit=crop&q=80')
ON CONFLICT (id) DO NOTHING;

-- Demo CMS Storefront Page & Sections
INSERT INTO restoapp.website_pages (id, tenant_id, slug, title, is_published, meta_description) VALUES
('f0000000-0000-0000-0000-000000000001', 'a0000000-0000-0000-0000-000000000001', 'home', 'The Royal Heritage Charcoal Hearth', true, 'An exceptional Michelin-grade dining experience featuring clay oven tandoor kebabs and slow dum simmered curries.')
ON CONFLICT (id) DO NOTHING;

INSERT INTO restoapp.website_sections (page_id, tenant_id, section_type, display_order, is_enabled, content, settings) VALUES
(
    'f0000000-0000-0000-0000-000000000001',
    'a0000000-0000-0000-0000-000000000001',
    'hero',
    1,
    true,
    '{
        "badge": "⭐ Michelin Guide Selected 2025/2026",
        "title": "A Symphony of Fire, Smoke & Heritage Spices",
        "subtitle": "Discover artisanal clay oven tandoori specialties and 18-hour slow dum simmered royal curries crafted with farm-fresh organic ingredients.",
        "primary_cta_label": "Reserve a Table",
        "primary_cta_action": "open_reservation_modal",
        "secondary_cta_label": "View Culinary Menu",
        "secondary_cta_action": "scroll_to_menu",
        "hero_image": "https://images.unsplash.com/photo-1544025162-d76694265947?w=1600&auto=format&fit=crop&q=85"
    }'::jsonb,
    '{"theme": "dark", "layout": "centered"}'::jsonb
),
(
    'f0000000-0000-0000-0000-000000000001',
    'a0000000-0000-0000-0000-000000000001',
    'story',
    2,
    true,
    '{
        "heading": "Our Culinary Heritage",
        "subheading": "HONORING CENTURIES OF CHARCOAL EMBER TRADITIONS",
        "story_paragraphs": [
            "At The Royal Heritage, every recipe is an homage to timeless Awadhi and Northwest Frontier culinary mastery. We eschew artificial coloring and commercial pastes, grinding whole spices daily in stone pestles.",
            "Our master chefs supervise live 800°F clay tandoors and gentle copper handi vessels, ensuring that each tender kebab and rich gravy reaches your table at the zenith of its aromatic flavor."
        ],
        "chef_name": "Executive Chef Sanjeev Kapoor",
        "chef_title": "Master of Charcoal & Royal Dum Traditions",
        "image_url": "https://images.unsplash.com/photo-1577219491135-ce391730fb2c?w=800&auto=format&fit=crop&q=80"
    }'::jsonb,
    '{"layout": "split_left_image"}'::jsonb
),
(
    'f0000000-0000-0000-0000-000000000001',
    'a0000000-0000-0000-0000-000000000001',
    'signature_dishes',
    3,
    true,
    '{
        "title": "Signature Creations",
        "subtitle": "Curated specialties that define our culinary philosophy"
    }'::jsonb,
    '{"columns": 3}'::jsonb
),
(
    'f0000000-0000-0000-0000-000000000001',
    'a0000000-0000-0000-0000-000000000001',
    'action_widget',
    4,
    true,
    '{
        "title": "Begin Your Dining Journey",
        "subtitle": "Choose your preferred experience below",
        "enable_booking": true,
        "enable_ordering": true,
        "enable_qr_scan": true
    }'::jsonb,
    '{"style": "card_dock"}'::jsonb
),
(
    'f0000000-0000-0000-0000-000000000001',
    'a0000000-0000-0000-0000-000000000001',
    'hours_location',
    5,
    true,
    '{
        "lunch_hours": "12:00 PM – 03:30 PM",
        "dinner_hours": "07:00 PM – 11:30 PM",
        "address": "123 Main Food Street, City Center, Bangalore",
        "phone": "+91 98765 43210",
        "email": "concierge@testrestaurant.com",
        "valet_available": true,
        "wheelchair_accessible": true
    }'::jsonb,
    '{"show_map": true}'::jsonb
)
ON CONFLICT DO NOTHING;
