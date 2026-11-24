# ADR 003: Section-Based CMS Engine & Secure HTML Sandboxing

## Status
Accepted

## Date
2026-11-24

## Context
Restaurant owners want to customize their public storefront without requiring code changes, including uploading custom promotional HTML sections. However, executing arbitrary HTML in the primary web origin poses severe XSS and cookie-theft vulnerabilities.

## Decision
Implement a **Structured Section-Based CMS Engine** with an isolated **Sandboxed Iframe** for user-supplied HTML.

## Rationale
- Reusable native Svelte components for standard sections (Hero, Story, Cuisine Specialties, Signature Dishes, Atmosphere Gallery, Hours & Map, Action Widgets).
- Custom promotional HTML is isolated into an iframe with `sandbox="allow-scripts"` (without `allow-same-origin`) and strict Content Security Policy, preventing access to the parent application's cookies, local storage, or internal APIs.

## Consequences
- Restaurant owners have creative freedom.
- Zero risk of cross-tenant credential compromise via custom HTML.
