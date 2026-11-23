# AGENTS.md - Developer & Agent Onboarding Guide

Welcome to the **Resto Platform** monorepo (`restoconnect`). This repository orchestrates a multi-tenant, cloud-ready Restaurant Operating System covering Dine-In QR Ordering, Waiter POS, Kitchen Display Systems (KDS), Direct-to-Consumer Home Delivery with live GPS map tracking, and zero-app WhatsApp/Web notifications.

---

## 1. Monorepo Topology & Services

```
restoconnect/
├── restoview/                  # Universal Frontend (SvelteKit 5, Tailwind v4, PWA)
├── restolink/                  # Core Backend API & Realtime Hub (Fastify/Go)
├── init-db/                    # Automated database schema & seed scripts
│   └── 01-init.sql
├── docker-compose.yaml         # Local services: PostgreSQL 17, Redis 7, PgAdmin
├── .env.example                # Unified environment variables
└── AGENTS.md                   # System rules and agent guide
```

| Service | Path | Role | Primary Tech Stack |
| :--- | :--- | :--- | :--- |
| **Frontend** | [`./restoview`](./restoview) | Customer QR PWA, Waiter POS, Chef KDS, Driver Tracker, Admin Portal | SvelteKit 5, Tailwind v4, Flowbite, TypeScript |
| **Backend API**| [`./restolink`](./restolink) | REST API, WebSocket/SSE Realtime hub, Order State Machine, Location Ingestion | Node.js (Fastify + TypeScript) or Go |
| **Infrastructure**| Root | Docker compose services, Postgres & Redis configuration | Docker Compose, PostgreSQL 17, Redis 7 |

---

## 2. Architecture & Design Principles

### 2.1 Multi-Tenancy (White-Label SaaS)
- **Tenant Context:** Every request identifies a tenant via:
  1. Subdomain: `https://<tenant-slug>.resto.com`
  2. Custom Domain: `https://order.restaurantname.com`
  3. Header/Param: `X-Tenant-ID` or `X-Tenant-Slug`
- **Data Isolation:** All database tables under the `restoapp` schema contain `tenant_id UUID`. All queries MUST filter by `tenant_id` (or enforce Row Level Security).
- **Dynamic Theming:** The tenant configuration carries custom colors, logo, font, currency, tax rates, and operating hours. The frontend injects CSS custom properties (`--color-primary`, `--color-secondary`) during SSR.

### 2.2 Order State Machine (Granular Pipeline)
The order state machine is strictly forward-progressing with audit history:
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

Every state change:
1. Emits a WebSocket/Redis PubSub event to active clients (Customer Web, Waiter, KDS).
2. Appends an entry into `restoapp.order_status_history`.
3. Triggers automated WhatsApp / Web Push notifications to the customer.

### 2.3 Live Map Tracking (Delivery Service)
- The delivery partner runs a lightweight mobile web PWA (`/driver`).
- `navigator.geolocation.watchPosition` streams coordinates over WebSocket: `(latitude, longitude, heading, speed)`.
- The backend caches the latest location in Redis (`GEOADD`) and publishes to `order_tracking:<order_id>`.
- The customer view renders an animated Leaflet/MapLibre map showing the driver's progress toward the delivery address.

---

## 3. Local Development & Setup

### 3.1 Prerequisites
- Docker & Docker Compose
- Node.js (>= 20 LTS) or Go (>= 1.22)
- pnpm or npm

### 3.2 Quick Start
1. Copy the environment file:
   ```bash
   cp .env.example .env
   ```
2. Start the core database and cache services:
   ```bash
   docker compose up -d postgres redis
   ```
3. Run the frontend (`restoview`):
   ```bash
   cd restoview
   npm install
   npm run dev
   ```
4. Run the API service (`restolink`):
   ```bash
   cd restolink
   # Follow instructions in restolink/MIGRATION_GUIDE.md and restolink/API_SPEC.md
   ```

---

## 4. Coding Conventions & Best Practices

- **Never Hardcode Secrets:** All secrets, keys, and credentials must come from environment variables.
- **Fail Fast & Explicitly:** Return typed HTTP error responses (`400 Bad Request`, `401 Unauthorized`, `403 Forbidden`, `404 Not Found`, `422 Unprocessable Entity`).
- **Idempotency:** Payment webhooks and order status transitions must be idempotent.
- **Strict Typing:** All API requests and responses must have validated schemas (Zod or TypeBox for TypeScript; struct tags for Go).
- **Audit Logs:** Never delete orders or financial records. Use soft deletes (`is_active = false`) and status history tracking.
