# Resto Platform - Security Architecture & Hardening

---

## 1. Threat Model & Mitigation Matrix

| Threat Vector | Potential Impact | Resto Platform Defense Mechanism |
| :--- | :--- | :--- |
| **Cross-Tenant Data Leakage** | Critical: Tenant A views Tenant B orders or revenues | Mandatory `tenant_id` WHERE clause in all repository queries; middleware context matching against authenticated JWT claims. |
| **Insecure HTML Execution** | High: Malicious tenant script steals cookies or admin session | Sandboxed iframe rendering (`sandbox="allow-scripts"` without `allow-same-origin`); HTML sanitization. |
| **SQL Injection** | Critical: Unauthorized DB extraction | Parameterized queries exclusively using `jackc/pgx/v5` with positional `$1, $2` parameters; zero string concatenation in SQL. |
| **Arbitrary Order Transition** | Medium: Customer marks order delivered without cooking | Strict Finite State Machine (FSM) enforcing valid status transitions and actor role permissions. |
| **Brute Force & Flooding** | High: API denial of service, credential guessing | Redis token bucket rate limiter on `/api/v1/auth/login` and `/api/v1/orders`. |
| **Token Hijacking & Revocation** | High: Stolen staff JWT used indefinitely | Redis token blacklist checked on every request; short token TTLs. |

---

## 2. OWASP Compliance Checklist

1. **A01: Broken Access Control:** Addressed via role-based middleware (`RequirePermission`) and tenant boundary enforcement.
2. **A02: Cryptographic Failures:** Passwords hashed with `bcrypt` (cost 12); HTTPS enforced in production; tokens signed with HMAC-SHA256 with 256-bit entropy.
3. **A03: Injection:** 100% parameterized SQL queries via `pgx`.
4. **A07: Identification & Auth Failures:** Account lockout and rate limiting on login routes.
