# AGENTS.md - Database Guidelines (`init-db` & `migrations`)

## 1. Role & Stack
- **Role:** PostgreSQL 17 multi-tenant schema definition, versioned migrations, and seed demo records.
- **Engine:** PostgreSQL 17 with `uuid-ossp` and `pgcrypto`. Schema: `restoapp`.

## 2. Key Architectural Directives
1. **Strict Foreign Keys:**
   - Every tenant-owned table has `tenant_id UUID NOT NULL REFERENCES restoapp.tenants(id) ON DELETE CASCADE`.
   - Dedicated indexes on `(tenant_id)` are mandatory for high-speed tenant partitioning.
2. **Versioned Migrations:**
   - All schema changes must be created as numbered migrations in `migrations/00000X_name.up.sql` and `migrations/00000X_name.down.sql`.
   - Maintain synchronization with `init-db/01-init.sql`.
3. **Audit History Preservation:**
   - Critical events (order lifecycle, driver location logs, payment receipts) are append-only.
   - Never hard delete orders or menus; use `is_active` or status tracking.
