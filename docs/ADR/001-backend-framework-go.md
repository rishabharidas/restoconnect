# ADR 001: Backend Framework and Language Selection

## Status
Accepted

## Date
2026-11-24

## Context
The platform backend (`restolink`) previously had a legacy Rust Rocket prototype and migration documentation proposing either Node.js (Fastify + TypeScript) or Go (Chi + pgx).

## Decision
Retain and standardize exclusively on **Go 1.23 with Chi router, `pgx/v5`, and `gorilla/websocket`**.
Archive the legacy Rust Rocket prototype.

## Rationale
- The Go service is already ~85% implemented and functional in `restolink/cmd/api`.
- Go goroutines provide lightweight concurrency for thousands of live WebSocket KDS, waiter, and driver tracking connections.
- Sub-millisecond latency, minimal memory usage (~20MB RAM), and single static container binaries.

## Consequences
- Clean modular Go architecture with handlers, services, and repositories.
- Zero runtime overhead and fast CI builds.
