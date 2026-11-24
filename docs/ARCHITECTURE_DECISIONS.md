# Resto Platform - Architecture Decision Records (ADR Summary)

This document aggregates the foundational Architecture Decision Records (ADRs) governing the engineering and lifecycle of the Resto Platform.

---

## ADR 001: Backend Framework & Language Selection

### Context
The backend repository (`restolink`) contained a prototype in Rust (Rocket framework) and a migration guide presenting two options: Node.js (Fastify + TypeScript) or Go (Chi + pgx).

### Decision
**Adopt Go 1.23 with Chi router, `pgx/v5`, and `gorilla/websocket`.**
Cleanly archive and deprecate the legacy Rust code.

### Rationale
1. **Existing Progress:** The Go service in `restolink/cmd/api` is already ~85% implemented and functional. Migrating to Node.js would require throwing away working code.
2. **Concurrency & Realtime:** Goroutines provide lightweight, high-density concurrency for managing thousands of persistent WebSocket connections for KDS screens, waiter tablets, and live driver GPS streams.
3. **Resource Efficiency:** Go microservices run in ~20MB RAM, allowing multi-tenant background workers and APIs to run on low-cost cloud instances.
4. **Static Single Binary:** Zero dependency deployments, sub-second container build times, and zero `node_modules` security bloat.

### Consequences
- Single language (Go) for backend engineering; all future backend modules (reservations, inventory, billing) must follow Go idioms.
- Automated tests will be written using Go's standard `testing` package and `testify`.

---

## ADR 002: Multi-Tenant Isolation Strategy

### Context
The platform must support hundreds of independent restaurants, cloud kitchens, and restaurant chains on a shared infrastructure without data leakage.

### Decision
**Implement Shared Application Infrastructure with Shared PostgreSQL Database and Mandatory Tenant Scoping.**

### Rationale
1. **Cost & Operational Simplicity:** Separate databases per tenant incur excessive operational overhead, complex connection pool exhaustion, and expensive infrastructure costs for small restaurants.
2. **Strict Foreign Key Constraints:** Every tenant-owned table in the `restoapp` schema has `tenant_id UUID NOT NULL REFERENCES restoapp.tenants(id) ON DELETE CASCADE`.
3. **Layered Isolation Defense:**
   - **Layer 1 (Middleware):** Resolves verified `tenant_id` from Host/Headers and injects it into request context.
   - **Layer 2 (Repository):** Repository methods explicitly mandate `tenant_id` in all SQL queries (`WHERE id = $1 AND tenant_id = $2`).
   - **Layer 3 (Database Constraints & RLS):** Database schema enforces foreign keys and supports PostgreSQL Row-Level Security (`ALTER TABLE ... ENABLE ROW LEVEL SECURITY`).
   - **Layer 4 (Redis Key Namespacing):** Redis cache and pub/sub channels are strictly prefixed with `tenant:{tenant_id}:*`.

### Consequences
- No handler or repository query may ever select or mutate records without verifying `tenant_id` matches the authenticated context.
- Automated multi-tenant penetration tests are required in CI.

---

## ADR 003: Section-Based CMS Engine & Secure HTML Sandboxing

### Context
Restaurant owners need to customize their public homepage (branding, story, signature dishes, galleries) and occasionally upload promotional HTML templates. However, rendering arbitrary user HTML directly in the frontend exposes the application to Cross-Site Scripting (XSS) and token theft.

### Decision
**Implement a Structured Section-Based CMS Engine with Sandboxed Iframe Execution for Custom HTML.**

### Rationale
1. **Storefront vs Ordering Distinction:** The homepage must look like a high-end restaurant publication (Michelin aesthetic) rather than an online POS cart.
2. **Section Registry:** Standard sections (Hero, Story, Cuisine Highlights, Signature Dishes, Atmosphere Gallery, Hours & Map, Reusable Action Widgets) are structured JSON schemas rendered by native SvelteKit components.
3. **HTML Sandboxing:** When a tenant supplies custom promotional HTML, it is rendered in an isolated iframe with `sandbox="allow-scripts"` (without `allow-same-origin`). This prevents custom scripts from accessing local storage, session cookies, or the parent application's DOM.

### Consequences
- Public websites are completely dynamic and managed without code changes.
- Custom HTML cannot breach tenant data or steal credentials.

---

## ADR 004: Granular Order State Machine & Event Auditing

### Context
Restaurant operations require an auditable, deterministic order lifecycle to prevent kitchen chaos, missed delivery handoffs, or premature billing.

### Decision
**Enforce a Forward-Progressing Finite State Machine (FSM) with Immutable Audit History.**

### Transition Graph:
```
PLACED 
  ↓ (Waiter or POS acknowledge)
WAITER_CONFIRMED 
  ↓ (Routed to KDS)
CHEF_ACCEPTED 
  ↓ (Prep begins)
IN_COOKING 
  ↓ (Assembly / sides)
BEING_PREPARED 
  ↓ (Plated / Boxed)
PLATING 
  ↓
READY_TO_SERVE 
  ↓
[Dine-In: SERVED → BILLED → COMPLETED]
[Delivery: DRIVER_ASSIGNED → OUT_FOR_DELIVERY (Live Map) → DELIVERED]
```

### Rationale
- Status changes can only transition to valid adjacent states.
- Every state transition appends a record into `restoapp.order_status_history` recording `order_id`, `previous_status`, `new_status`, `changed_by_user_id`, `note`, and `created_at`.
- State transitions emit real-time events over Redis Pub/Sub to active WebSocket connections.

---

## ADR 005: Database Schema Evolution & Migration Strategy

### Context
Database schema was previously defined solely in `init-db/01-init.sql`. Schema changes in production require versioned, repeatable migrations.

### Decision
**Introduce an Incremental, Numbered SQL Migration Suite (`migrations/000001_...sql`).**

### Rationale
- Each schema change has an explicit `.up.sql` and `.down.sql`.
- Backend includes an automated migration runner during server startup (`migrate.RunMigrations()`), ensuring zero-drift between code and database schema across development, staging, and production.
