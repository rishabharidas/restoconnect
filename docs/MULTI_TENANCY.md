# Resto Platform - Multi-Tenancy Architecture & Data Isolation

---

## 1. Multi-Tenant Tenets

The Resto Platform is built from the ground up as a shared-resource, strict-isolation SaaS:
1. **Zero Tenant Bleed:** No tenant may ever read, query, update, or delete data belonging to another tenant.
2. **Dynamic Theming & Assets:** Each tenant has independent styling, fonts, color palettes, and hero media.
3. **Branch Awareness:** A tenant can operate multiple geographic outlets (`restoapp.outlets`) sharing menu and catalog configurations while maintaining branch-specific table layouts and inventory.

---

## 2. Multi-Level Isolation Defense

```
[ Request Ingestion ] ──► Layer 1: Domain & Host Resolution
                             │
                             ▼
[ Context Injection ] ──► Layer 2: Go TenantContext Middleware
                             │
                             ▼
[ Authorization ]     ──► Layer 3: RBAC & Tenant Match Verification
                             │
                             ▼
[ Database Query ]    ──► Layer 4: Mandatory `tenant_id` WHERE predicates
                             │
                             ▼
[ Redis / PubSub ]    ──► Layer 5: Namespaced Redis keys: `tenant:{id}:*`
```

### 2.1 Layer 1 & 2: Middleware Tenant Resolution
The Go middleware resolves `tenantSlug` from `Host`, `X-Tenant-Slug`, or `?tenant=`. It loads the tenant metadata from PostgreSQL, verifies `is_active = true`, and stores `*models.Tenant` in `r.Context()`.

### 2.2 Layer 3: Authorization Verification
When an authenticated staff member makes a request, their JWT contains `tenant_id`. If the JWT `tenant_id` does not match the resolved request `tenant_id` (unless the user holds the `superadmin` role), the request is rejected immediately with `403 Forbidden`.

### 2.3 Layer 4: Mandatory Tenant Query Predicates
Every repository method MUST take `tenantID uuid.UUID` as an explicit parameter.

**Vulnerable:**
```sql
SELECT * FROM restoapp.orders WHERE id = $1;
```

**Secured:**
```sql
SELECT * FROM restoapp.orders WHERE id = $1 AND tenant_id = $2;
```

### 2.4 Layer 5: Redis Namespacing
All Redis cache keys, multiplayer carts, and WebSocket rooms are namespaced:
- Multiplayer cart: `tenant:{tenant_id}:table:{table_id}:cart`
- Driver location: `tenant:{tenant_id}:driver:{driver_id}:location`
- Channel: `tenant:{tenant_id}:events`
