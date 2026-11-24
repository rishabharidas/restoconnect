# ADR 002: Multi-Tenant Data Isolation Strategy

## Status
Accepted

## Date
2026-11-24

## Context
The platform hosts multiple independent restaurants, clouds kitchens, and restaurant chains on a shared cloud environment. Absolute tenant isolation is mandatory to prevent unauthorized data access.

## Decision
Implement **Shared Application Infrastructure with Shared PostgreSQL Database and Mandatory Tenant Query Scoping**.

## Rationale
- Shared database reduces infrastructure cost and connection pool overhead compared to separate databases per tenant.
- Mandatory `tenant_id UUID NOT NULL REFERENCES restoapp.tenants(id) ON DELETE CASCADE` on all tenant-owned tables.
- Defense in depth:
  1. Middleware resolves tenant from verified host or header.
  2. Middleware asserts that authenticated user JWT claims match the request tenant ID.
  3. Every SQL query explicitly filters by `tenant_id = $x`.
  4. Redis keys are namespaced with `tenant:{tenant_id}:*`.

## Consequences
- All developers must ensure queries are scoped with `tenant_id`.
- Automated cross-tenant tests prevent data leaks.
