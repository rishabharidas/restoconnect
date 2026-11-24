# Resto Platform - Database Architecture & Schema Specification

**Document Version:** 1.0.0  
**Database Engine:** PostgreSQL 17  
**Schema:** `restoapp`

---

## 1. Schema Design Philosophy

The database design adheres to:
1. **Multi-Tenancy Isolation:** Every tenant-owned table features `tenant_id UUID NOT NULL REFERENCES restoapp.tenants(id) ON DELETE CASCADE` with a dedicated index on `(tenant_id)`.
2. **PostgreSQL Native Features:** Enums (`order_type`, `order_status`, `food_type`), JSONB for tenant branding and flexible section content, and PostGIS/Spatial geometry or coordinates (`latitude`, `longitude`).
3. **Immutable Audit History:** State-critical transitions (order pipeline, driver locations, payment logs) append to append-only audit tables.
4. **Soft Deletion & Flags:** Catalog entities use `is_active` or `is_available` to protect historical reporting.

---

## 2. Complete Domain Entities & DDL Specification

### 2.1 Core Identity & Multi-Tenancy

```sql
-- Schema & Extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";
CREATE SCHEMA IF NOT EXISTS restoapp;

-- 1. Roles
CREATE TABLE restoapp.roles (
    id SERIAL PRIMARY KEY,
    name VARCHAR(64) UNIQUE NOT NULL,
    description TEXT
);

-- 2. Tenants (Master Registry)
CREATE TABLE restoapp.tenants (
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

-- 3. Outlets / Branches
CREATE TABLE restoapp.outlets (
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
CREATE INDEX idx_outlets_tenant ON restoapp.outlets(tenant_id);

-- 4. Users & Staff
CREATE TABLE restoapp.users (
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
CREATE INDEX idx_users_tenant_phone ON restoapp.users(tenant_id, phone);
```

### 2.2 Tables & Seating Management

```sql
-- 5. Restaurant Tables
CREATE TABLE restoapp.restaurant_tables (
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
CREATE INDEX idx_tables_tenant ON restoapp.restaurant_tables(tenant_id);
CREATE INDEX idx_tables_qr_token ON restoapp.restaurant_tables(qr_code_token);

-- 6. Table Reservations
CREATE TABLE restoapp.reservations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES restoapp.tenants(id) ON DELETE CASCADE,
    outlet_id UUID NOT NULL REFERENCES restoapp.outlets(id) ON DELETE CASCADE,
    customer_name VARCHAR(128) NOT NULL,
    customer_phone VARCHAR(32) NOT NULL,
    customer_email VARCHAR(255),
    guest_count INT NOT NULL DEFAULT 2,
    reservation_date DATE NOT NULL,
    reservation_time TIME NOT NULL,
    status VARCHAR(32) NOT NULL DEFAULT 'PENDING', -- PENDING, CONFIRMED, SEATED, CANCELLED
    table_id UUID REFERENCES restoapp.restaurant_tables(id),
    special_requests TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_reservations_tenant_date ON restoapp.reservations(tenant_id, reservation_date);
```

### 2.3 Menu Catalog & Modifiers

```sql
-- 7. Menu Categories
CREATE TABLE restoapp.menu_categories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES restoapp.tenants(id) ON DELETE CASCADE,
    name VARCHAR(128) NOT NULL,
    description TEXT,
    display_order INT NOT NULL DEFAULT 0,
    is_active BOOLEAN NOT NULL DEFAULT true
);
CREATE INDEX idx_categories_tenant ON restoapp.menu_categories(tenant_id);

-- 8. Menu Items
CREATE TABLE restoapp.menu_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES restoapp.tenants(id) ON DELETE CASCADE,
    category_id UUID NOT NULL REFERENCES restoapp.menu_categories(id) ON DELETE RESTRICT,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    price NUMERIC(10, 2) NOT NULL,
    food_type VARCHAR(32) NOT NULL DEFAULT 'VEG', -- VEG, NON_VEG, VEGAN, CONTAINS_EGG
    image_url TEXT,
    is_available BOOLEAN NOT NULL DEFAULT true,
    kitchen_station VARCHAR(64) DEFAULT 'MAIN_KITCHEN',
    preparation_time_mins INT DEFAULT 15,
    modifiers JSONB NOT NULL DEFAULT '[]'::jsonb, -- modifier groups & options
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_menu_items_tenant ON restoapp.menu_items(tenant_id);
```

### 2.4 Order Lifecycle & Auditing

```sql
-- Enums
CREATE TYPE restoapp.order_type AS ENUM ('DINE_IN', 'DELIVERY', 'TAKEAWAY');
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

-- 9. Orders
CREATE TABLE restoapp.orders (
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
CREATE INDEX idx_orders_tenant_status ON restoapp.orders(tenant_id, status);

-- 10. Order Items
CREATE TABLE restoapp.order_items (
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
CREATE INDEX idx_order_items_order ON restoapp.order_items(order_id);

-- 11. Order Status History (Audit Trail)
CREATE TABLE restoapp.order_status_history (
    id BIGSERIAL PRIMARY KEY,
    order_id UUID NOT NULL REFERENCES restoapp.orders(id) ON DELETE CASCADE,
    previous_status restoapp.order_status,
    new_status restoapp.order_status NOT NULL,
    changed_by_user_id UUID REFERENCES restoapp.users(id),
    note TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_order_history_order ON restoapp.order_status_history(order_id);
```

### 2.5 Delivery & Live Location Tracking

```sql
-- 12. Deliveries
CREATE TABLE restoapp.deliveries (
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
CREATE INDEX idx_deliveries_tenant ON restoapp.deliveries(tenant_id);

-- 13. Driver Location Logs
CREATE TABLE restoapp.driver_location_logs (
    id BIGSERIAL PRIMARY KEY,
    driver_id UUID NOT NULL REFERENCES restoapp.users(id),
    order_id UUID REFERENCES restoapp.orders(id),
    latitude DOUBLE PRECISION NOT NULL,
    longitude DOUBLE PRECISION NOT NULL,
    heading REAL,
    speed REAL,
    recorded_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_driver_logs_order ON restoapp.driver_location_logs(order_id);
```

### 2.6 Website CMS & Section Builder

```sql
-- 14. Website Pages
CREATE TABLE restoapp.website_pages (
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

-- 15. Website Sections
CREATE TABLE restoapp.website_sections (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    page_id UUID NOT NULL REFERENCES restoapp.website_pages(id) ON DELETE CASCADE,
    tenant_id UUID NOT NULL REFERENCES restoapp.tenants(id) ON DELETE CASCADE,
    section_type VARCHAR(64) NOT NULL, -- 'hero', 'story', 'cuisine_highlights', 'signature_dishes', 'gallery', 'hours_map', 'action_widget', 'custom_html'
    display_order INT NOT NULL DEFAULT 0,
    is_enabled BOOLEAN NOT NULL DEFAULT true,
    content JSONB NOT NULL DEFAULT '{}'::jsonb,
    settings JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_sections_page ON restoapp.website_sections(page_id, display_order);
```
