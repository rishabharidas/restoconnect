# ADR 005: Incremental Database Migrations

## Status
Accepted

## Date
2026-11-24

## Context
Previously, database changes were only reflected in a single `init-db/01-init.sql` file. Evolving schema in production requires safe, versioned up/down migration files.

## Decision
Adopt **Numbered SQL Migration Scripts (`migrations/00000X_*.sql`)** with automated startup checks.

## Rationale
- Repeatable, auditable schema evolution across local dev, CI/CD, and production instances.
- Clear `.up.sql` and `.down.sql` parity for rollback testing.
