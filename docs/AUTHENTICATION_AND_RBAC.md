# Resto Platform - Authentication & Role-Based Access Control (RBAC)

---

## 1. Role Hierarchy & Responsibilities

The system defines hierarchical roles at the Platform and Restaurant levels:

| Role Name | Scope | Permissions & Capabilities |
| :--- | :--- | :--- |
| `superadmin` | Platform Global | Full cross-tenant access, tenant creation, billing oversight, platform audit. |
| `owner` | Restaurant Tenant | Full administrative access to the restaurant tenant: branding, CMS, billing, menu, staff, branches. |
| `manager` | Outlet / Branch | Menu management, voids, discounts, staff shift oversight, table management. |
| `waiter` | Dining Room | Table ordering, guest seating, bill requests, table service bell management. |
| `chef` | Kitchen | KDS ticket status progression, 86'ing ingredient availability, prep notes. |
| `driver` | Delivery | Assigned delivery execution, GPS location broadcasting, OTP delivery confirmation. |
| `customer` | Guest / Consumer | Dine-in QR ordering, takeaway/delivery checkout, order progress tracking. |

---

## 2. Granular Permissions Model

Rather than hardcoding checks against role strings, the backend evaluates atomic permissions:

```go
type Permission string

const (
    PermTenantManage   Permission = "tenant.manage"
    PermCMSManage      Permission = "cms.manage"
    PermMenuManage     Permission = "menu.manage"
    PermMenuRead       Permission = "menu.read"
    PermTableManage    Permission = "table.manage"
    PermTableRead      Permission = "table.read"
    PermOrdersRead     Permission = "orders.read"
    PermOrdersCreate   Permission = "orders.create"
    PermOrdersStatus   Permission = "orders.status_update"
    PermKitchenUpdate  Permission = "kitchen.update"
    PermDeliveryDrive  Permission = "delivery.drive"
    PermStaffManage    Permission = "staff.manage"
    PermBillingSettle  Permission = "billing.settle"
)
```

---

## 3. Token Architecture

- **Staff JWTs:** Issued on `POST /api/v1/auth/login`. Carries `user_id`, `tenant_id`, and `role`. Signed with HMAC-SHA256 (`JWTSecret`). Token expiry: 24 hours. Blacklist revocation supported via Redis (`blacklist:<token>`).
- **Customer Guest Sessions:** Zero-app QR diners do not require password registration. On scanning a table QR or placing a guest delivery order, an ephemeral session token is issued binding them to their table or order tracking URL.
