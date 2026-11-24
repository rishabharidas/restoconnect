# Resto Platform - API Architecture & Contract Standards

**Version:** 1.0.0  
**Base URL:** `/api/v1`  
**Protocol:** REST (JSON) + WebSocket (`/ws`)

---

## 1. Global Conventions & Multi-Tenancy

Every incoming request resolves against a restaurant tenant using:
1. `Host` header: `slug.resto.com` or `custom-domain.com`.
2. Header: `X-Tenant-Slug: <slug>`.
3. Query Param: `?tenant=<slug>`.

All JSON responses follow a standardized payload envelope:

### Success Response
```json
{
  "success": true,
  "data": { ... },
  "meta": {
    "timestamp": "2026-11-24T10:30:00Z",
    "request_id": "req-98721634"
  }
}
```

### Error Response
```json
{
  "success": false,
  "error": {
    "code": "ORDER_TRANSITION_INVALID",
    "message": "Cannot transition order from PLACED directly to READY_TO_SERVE",
    "details": []
  },
  "meta": {
    "timestamp": "2026-11-24T10:30:00Z",
    "request_id": "req-98721634"
  }
}
```

---

## 2. API Route Map

```
/api/v1
├── /auth
│   ├── POST /login                   # Staff & Admin JWT login
│   └── POST /guest-session           # Customer QR dine-in guest session
├── /tenant
│   ├── GET  /config                  # Public tenant branding & settings
│   └── PUT  /config                  # Admin update branding (RequireRole: OWNER)
├── /cms
│   ├── GET  /pages/:slug             # Fetch published page & sections
│   ├── POST /pages                   # Create new page
│   ├── PUT  /pages/:id               # Update page metadata
│   ├── GET  /pages/:id/sections      # List sections for editor
│   ├── POST /sections                # Add section to page
│   ├── PUT  /sections/:id            # Update section content & settings
│   ├── PUT  /sections/reorder        # Reorder sections array
│   └── DELETE /sections/:id          # Remove section
├── /menu
│   ├── GET  /                        # Public menu category tree
│   ├── POST /categories              # Create category (RequireRole: OWNER, MANAGER)
│   ├── PUT  /categories/:id          # Update category
│   ├── POST /items                   # Create menu item
│   ├── PUT  /items/:id               # Update menu item
│   ├── PATCH /items/:id/availability # 1-tap 86'ing toggle (RequireRole: CHEF, MANAGER)
│   └── DELETE /items/:id             # Soft delete menu item
├── /tables
│   ├── GET  /                        # List tables (RequireRole: WAITER, MANAGER)
│   ├── GET  /qr/:token               # Resolve table by cryptographic token
│   ├── POST /generate-qr             # Generate printable table QR code
│   ├── POST /:id/bell                # Ring digital server call bell
│   ├── GET  /:id/cart                # Get multiplayer table cart
│   └── POST /:id/cart                # Sync multiplayer table cart
├── /reservations
│   ├── GET  /                        # List reservations for date (RequireRole: WAITER, MANAGER)
│   ├── POST /                        # Public table reservation submission
│   └── PATCH /:id/status             # Confirm / Cancel reservation
├── /orders
│   ├── POST /                        # Create new order (Dine-in or Delivery)
│   ├── GET  /:id                     # Fetch order details (Tenant-scoped)
│   ├── PATCH /:id/status             # Progress order state machine
│   └── GET  /queue                   # Active KDS / Waiter queue
└── /delivery
    ├── POST /location                # Driver GPS location ingestion
    └── GET  /track/:order_id         # Live map coordinates & ETA
```

---

## 3. Realtime WebSocket Contracts (`/ws?rooms=...`)

### Outgoing Events
- `NEW_ORDER`: Dispatched to `tenant:<id>` when an order is placed.
- `ORDER_STATUS_UPDATED`: Dispatched to `order:<id>` and `tenant:<id>`.
- `TABLE_BELL_ALERT`: Dispatched to `tenant:<id>` and `table:<id>`.
- `MULTIPLAYER_CART_UPDATED`: Dispatched to `table:<id>`.
- `ITEM_AVAILABILITY_CHANGED`: Dispatched to `tenant:<id>` (86'ing).
- `DRIVER_LOCATION_STREAM`: Dispatched to `order:<id>`.
