# Resto Platform - System Architecture & Engineering Blueprint

**Document Version:** 1.0.0  
**Target Environment:** Cloud-Ready Multi-Tenant SaaS  
**Author:** Principal Software Architect

---

## 1. High-Level Architecture Topology

The Resto Platform follows a modular monolith architecture with shared database multi-tenancy, high-performance Go backend, reactive SvelteKit 5 frontend, and real-time event distribution:

```
                           [ Cloudflare / Traefik / ALB ]
                                         │
                 ┌───────────────────────┴───────────────────────┐
                 │ Host-based Tenant Router                     │
                 │ *.resto.com  |  custom-restaurant.com         │
                 └───────────────────────┬───────────────────────┘
                                         │
                 ┌───────────────────────┴───────────────────────┐
                 │                                               │
      ┌──────────▼──────────┐                         ┌──────────▼──────────┐
      │   restoview (SSR)   │                         │    restolink (API)  │
      │   SvelteKit 5 / PWA │                         │    Go 1.23 + Chi    │
      │   Tailwind v4 / UI  │                         │    WebSocket Hub    │
      └──────────┬──────────┘                         └──────────┬──────────┘
                 │ HTTP (Browser)                                │
                 └───────────────────────┬───────────────────────┘
                                         │
                 ┌───────────────────────┴───────────────────────┐
                 │                                               │
      ┌──────────▼──────────┐                         ┌──────────▼──────────┐
      │   PostgreSQL 17     │                         │      Redis 7        │
      │   • restoapp Schema │                         │   • Pub/Sub Events  │
      │   • Strict Tenant FK│                         │   • Shared Carts    │
      │   • Audit Logging   │                         │   • Driver GEOADD   │
      └─────────────────────┘                         └─────────────────────┘
```

---

## 2. Monorepo Organization

```
resto/
├── restoconnect/                  # Orchestration root / Monorepo
│   ├── docker-compose.yaml        # Local PostgreSQL 17, Redis 7, PgAdmin
│   ├── migrations/                # Versioned SQL migrations (000001_...)
│   ├── docs/                      # Architecture, API specs, ADRs, Guides
│   │   ├── ADR/                   # Architecture Decision Records
│   │   ├── PROJECT_OVERVIEW.md
│   │   ├── REPOSITORY_AUDIT.md
│   │   ├── SYSTEM_ARCHITECTURE.md
│   │   ├── IMPLEMENTATION_ROADMAP.md
│   │   ├── DATABASE_DESIGN.md
│   │   ├── API_ARCHITECTURE.md
│   │   └── ...
│   ├── restolink/                 # Go 1.23 High-Performance Core API
│   │   ├── cmd/api/main.go        # Server bootstrap & DI container
│   │   ├── internal/
│   │   │   ├── config/            # Env configuration & secrets
│   │   │   ├── database/          # pgxpool connection & migration runner
│   │   │   ├── middleware/        # Tenant resolver, Auth, RBAC, CORS
│   │   │   ├── models/            # Domain entities & DTOs
│   │   │   ├── repository/        # PostgreSQL data access layer
│   │   │   ├── service/           # Business logic & state machine
│   │   │   ├── handlers/          # HTTP & WebSocket controllers
│   │   │   └── realtime/          # WebSocket Hub & Redis subscriber
│   │   └── tests/                 # Unit & integration test suites
│   └── restoview/                 # SvelteKit 5 Universal PWA
│       ├── src/
│       │   ├── routes/            # Role-tailored portals & routes
│       │   │   ├── +page.svelte   # Editorial Michelin-style Storefront
│       │   │   ├── table/         # QR Table Ordering & Multiplayer Cart
│       │   │   ├── waiter/        # Waiter Handheld POS & Floor Map
│       │   │   ├── kds/           # Kitchen Display System
│       │   │   ├── driver/        # Driver PWA with live GPS
│       │   │   ├── track/         # Customer Live Order Tracking
│       │   │   ├── admin/         # Restaurant Admin Portal
│       │   │   └── platform/      # Platform Owner Superadmin Portal
│       │   └── lib/
│       │       ├── components/    # Reusable UI component library
│       │       ├── cms/           # Section registry & secure HTML renderer
│       │       ├── stores/        # Svelte runes reactive stores
│       │       └── api.ts         # Type-safe API client
```

---

## 3. Core System Subsystems

### 3.1 Tenant Resolution & Context Middleware
Every incoming request must resolve a tenant through:
1. **Host Header:** `restaurant-slug.resto.com` or `order.restaurantbrand.com`.
2. **Explicit Header:** `X-Tenant-Slug` or `X-Tenant-ID` (used by native apps and internal micro-frontends).
3. **Query Parameter:** `?tenant=slug` (used during development and QR stand redirection).

The middleware queries the tenant registry in PostgreSQL (cached in Redis with 10-minute TTL) and injects `TenantContext` into the Go `context.Context`. If no tenant is matched, public multi-tenant root or `404 Not Found` is returned.

### 3.2 Real-time WebSocket & Redis Hub
WebSocket connections subscribe to isolated channel rooms:
- `tenant:<tenant_id>`: Broadcasts new orders, menu availability changes (86'ing), and urgent kitchen alerts.
- `table:<table_id>`: Coordinates multiplayer cart additions and server bell alerts among diners at the table.
- `order:<order_id>`: Streams granular preparation state changes and driver GPS coordinates to the customer tracking page.

### 3.3 Safe Section-Based Storefront CMS
To prevent the homepage from looking like a POS dashboard, the CMS uses a versioned section registry:
1. **Hero Section:** High-resolution dish hero with typography and CTA.
2. **Heritage & Culinary Philosophy:** Chef story and sourcing practices.
3. **Cuisine Classification:** Showcase of culinary categories.
4. **Signature Dishes:** Highlighting award-winning menu items.
5. **Atmosphere Gallery:** Interior, outdoor patio, and kitchen photography.
6. **Operating Hours & Location:** Google Map embed and opening timings.
7. **Action Widgets:** Embeddable, floating or inline widgets for Online Ordering, Table Booking, and QR Scanner.
8. **Sandboxed Custom HTML:** Validated and isolated inside a sandboxed iframe with strict Content Security Policy (`sandbox="allow-scripts"` without `allow-same-origin`), preventing script execution within the platform's origin.
