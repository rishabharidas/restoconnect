# Resto Platform - Implementation Roadmap & Phased Execution Plan

**Version:** 1.0.0  
**Methodology:** Iterative, Test-Driven, Verifiable Milestones

---

## Phase Breakdown Overview

```
Phase 0: Architecture & Repository Audit [COMPLETED]
   ↓
Phase 1: Platform Foundation & Core Multi-Tenancy [IN PROGRESS]
   ↓
Phase 2: Michelin Storefront & Section-Based CMS Engine
   ↓
Phase 3: Menu Catalog, Modifiers & Advanced Ordering
   ↓
Phase 4: Kitchen Operations, KDS Stations & Real-Time Sync
   ↓
Phase 5: Direct Delivery Suite, Driver PWA & GPS Tracking
   ↓
Phase 6: Table Floor Plan, Reservations & Handheld POS
   ↓
Phase 7: Inventory, Recipe Costing, Invoicing & GST Tax Engine
   ↓
Phase 8: Platform Owner Portal & Production Hardening
```

---

## Detailed Phase Execution Deliverables

### Phase 0 — Repository & Architecture Audit (COMPLETED)
- [x] Clone and inspect all three repositories (`restoconnect`, `restolink`, `restoview`).
- [x] Audit package manifests, Go dependencies, SvelteKit configuration, and database schemas.
- [x] Evaluate Go vs. Node.js; finalize decision to retain Go 1.23.
- [x] Identify architectural flaws: missing tenant query scoping, unvalidated order state transitions, lack of RBAC, missing database migration runner.
- [x] Publish comprehensive documentation suite:
  - `docs/PROJECT_OVERVIEW.md`
  - `docs/REPOSITORY_AUDIT.md`
  - `docs/SYSTEM_ARCHITECTURE.md`
  - `docs/ARCHITECTURE_DECISIONS.md`
  - `docs/IMPLEMENTATION_ROADMAP.md`

---

### Phase 1 — Platform Foundation & Core Multi-Tenancy (IN PROGRESS)
- [ ] **Database Migrations Engine:**
  - Create `migrations/` directory with versioned `.sql` migrations.
  - Implement automated migration runner in Go backend (`internal/database/migrations.go`).
  - Add tables for CMS (`website_pages`, `website_sections`, `themes`), reservations, and detailed invoicing.
- [ ] **Clean Layered Backend Architecture:**
  - Introduce `repository/` layer with explicit tenant-scoped queries.
  - Introduce `service/` layer encapsulating business logic.
  - Refactor HTTP handlers in `handlers/` to use structured request/response DTOs and typed JSON errors.
- [ ] **Role-Based Access Control (RBAC):**
  - Implement `RequireRole` and `RequirePermission` middleware.
  - Define permissions: `orders.read`, `orders.create`, `orders.update_status`, `menu.manage`, `table.manage`, `kitchen.update`, `cms.manage`.
- [ ] **Tenant Isolation Hardening:**
  - Fix `GetOrder` and `UpdateStatus` to mandate tenant validation.
  - Add unit tests verifying cross-tenant access rejection (`403 Forbidden` / `404 Not Found`).
- [ ] **Archive Legacy Rust Artifacts:**
  - Cleanly archive `legacy_rust` out of active compilation.

---

### Phase 2 — Michelin Storefront & Section-Based CMS Engine
- [ ] **Editorial Restaurant Storefront:**
  - Re-architect `/` into a stunning, image-rich editorial layout inspired by Michelin-guide standards:
    - Hero section with large food photography & brand typography.
    - "About Our Kitchen" culinary philosophy & sourcing ethics.
    - Signature Dishes showcase with high-res photography.
    - Atmosphere and interior gallery.
    - Operating hours, dining guidelines, and interactive map.
- [ ] **Section-Based CMS Builder:**
  - Dynamic section renderer loading structured section data.
  - Section reordering, editing, toggling, and background customization in Admin portal (`/admin`).
  - Sandboxed HTML section renderer with strict Content Security Policy.
- [ ] **Configurable Action Widgets:**
  - Embeddable and floating action widgets for:
    - Online Food Delivery & Takeaway.
    - QR Table Ordering.
    - Table Reservation.

---

### Phase 3 — Menu Catalog, Modifiers & Advanced Ordering
- [ ] **Comprehensive Menu CRUD:**
  - Admin endpoints for Categories, Items, and Modifier Groups (Sizes, Spice Levels, Add-ons).
  - Bulk import/export (JSON/CSV).
  - Preparation times and kitchen station assignments.
- [ ] **Enhanced Dine-In QR Ordering:**
  - Table multiplayer cart synchronization with live diner presence.
  - Digital Server Call Bell with audible notifications on waiter tablet.
  - Table-specific printable acrylic QR stands.
- [ ] **Online Ordering & Cart Checkout:**
  - Delivery and Takeaway checkout with customer name, phone, address, and special notes.

---

### Phase 4 — Kitchen Operations, KDS Stations & Real-Time Sync
- [ ] **Strict Order State Machine:**
  - Implement Go service validating allowable state transitions.
  - Append immutable audit trail to `restoapp.order_status_history`.
- [ ] **Kitchen Display System (KDS):**
  - Station-specific ticket routing (Grill, Curry, Pantry, Bar, Expo).
  - Aging timers with color codes (Green <10m, Amber 10-15m, Red >20m).
  - Instant 1-tap 86'ing out-of-stock toggle broadcasting to all client menus.
- [ ] **Customer Real-Time Tracking:**
  - Dedicated `/track/[orderId]` page with visual preparation timeline and estimated time.

---

### Phase 5 — Direct Delivery Suite & Live Map Driver GPS
- [ ] **Driver Mobile PWA:**
  - Mobile-first interface at `/driver`.
  - Task cards (Pickup from kitchen → Deliver to customer).
  - Background geolocation streaming via `navigator.geolocation.watchPosition`.
  - Delivery completion via 4-digit verification OTP.
- [ ] **Customer Live Map Tracking:**
  - Leaflet / MapLibre map with moving driver bike icon and bearing.
  - Real-time distance and ETA calculated via Redis Geospatial.

---

### Phase 6 — Table Floor Plan, Reservations & Handheld POS
- [ ] **Waiter Mobile POS:**
  - Visual floor layout with table status indicators (Available, Ordering, Served, Bill Requested).
  - Fast table ordering and bill settlement (UPI, Cash, Card).
- [ ] **Table Reservation System:**
  - Customer booking form with date, time slot, party size, and seating preference.
  - Reservation confirmation and table assignment management for floor staff.

---

### Phase 7 — Inventory, Invoicing & GST Tax Engine
- [ ] **Indian GST & Tax Breakdown:**
  - Configurable CGST (2.5%), SGST (2.5%), IGST, packaging fees, and service charges.
  - Printable itemized tax invoices.
- [ ] **Basic Inventory & Stock Depletion:**
  - Ingredient tracking and low-stock alerts triggered on order completion.

---

### Phase 8 — Platform Owner Portal & Production Hardening
- [ ] **Platform Owner Portal (`/platform`):**
  - Tenant provisioning, subscription plan management, platform-wide health monitoring.
- [ ] **Security & Production Hardening:**
  - Rate limiting with Redis token bucket.
  - Automated integration test suite.
  - Production Docker multi-stage builds.
  - CI/CD workflow configuration.
