# Resto Platform - Implementation Milestones & Roadmap

This roadmap tracks the development of the multi-tenant Resto platform across all layers (Frontend, Backend API, Realtime Engine, Infrastructure).

---

## 📌 Milestone Overview

```
[M1: Core Architecture] ✅ COMPLETED
   ↓
[M2: Dine-In QR & Table Ordering] 🔄 NEXT UP
   ↓
[M3: Kitchen Display System (KDS) & State Machine]
   ↓
[M4: Zero-App WhatsApp & Web Push Notifications]
   ↓
[M5: Home Delivery & Live Driver GPS Map Tracking]
   ↓
[M6: Waiter POS Handheld & Table Billing]
   ↓
[M7: Restaurant Admin & White-Label Theming Portal]
   ↓
[M8: Multi-Platform Deployment & Production Hardening]
```

---

## ✅ Milestone 1: Core Architecture & Setup (COMPLETED)
- [x] Cloned and unified `restoview`, `restolink`, and `restoconnect` into a monorepo structure.
- [x] Evaluated and selected production stack: **Go (Chi)** + **PostgreSQL 17** + **Redis 7** + **SvelteKit 5**.
- [x] Resolved all 28 SvelteKit security advisories down to 0 vulnerabilities.
- [x] Initialized multi-tenant database schema with PostGIS, RLS, enums, and demo seed data in `init-db/01-init.sql`.
- [x] Implemented Go API server in `restolink` with Chi router, pgx pool, Redis geospatial, JWT auth, and WebSocket hub.
- [x] Created `AGENTS.md`, `API_SPEC.md`, and developer onboarding documentation.

---

## 🔄 Milestone 2: Dine-In QR Ordering & Table Session Engine (CURRENT FOCUS)
**Goal:** Perfect the zero-friction customer experience when sitting at a restaurant table.
- [ ] **Table QR Code Generator:** Script / API to generate signed, encrypted QR codes with cryptographic tokens preventing spoofing.
- [ ] **Interactive Table Landing:** Auto-detect table number, load active cart/bill if items already ordered by others at the same table.
- [ ] **Item Modifiers & Add-ons:** Sizes (Small/Medium/Large), Spice Levels, Add-ons (Extra Cheese, Toppings).
- [ ] **Guest Checkout:** Fast phone number verification for WhatsApp notification routing.
- [ ] **Table Session Lock:** Prevent conflicting orders or abandoned carts.
- [ ] **Verification:** End-to-end test of scanning table QR → selecting items → order placement → database persistence.

---

## 🍳 Milestone 3: Kitchen Display System (KDS) & Granular State Machine
**Goal:** Real-time kitchen workflow for chefs and kitchen captains.
- [ ] **Granular State Machine:** Strict enforcement of state transitions:
  `PLACED` → `WAITER_CONFIRMED` → `CHEF_ACCEPTED` → `IN_COOKING` → `BEING_PREPARED` → `PLATING` → `READY_TO_SERVE` → `SERVED`.
- [ ] **Station Routing:** Auto-route items to specific kitchen stations (`Tandoor`, `Curry`, `Grill`, `Bar`).
- [ ] **Touch-Friendly KDS UI:** Big cards with timer alerts (amber at 10m, red at 15m), audio chimes on new orders.
- [ ] **Item-Level Status:** Mark individual items as cooked rather than only the entire order.
- [ ] **Verification:** Advance orders from KDS and verify instant status reflection in Customer Tracker via WebSockets.

---

## 📲 Milestone 4: Zero-App WhatsApp & Web Push Notifications
**Goal:** Inform customers of their meal's progress without requiring an app store download.
- [ ] **WhatsApp Business Cloud API:** Webhook worker triggered on key pipeline transitions (`CHEF_ACCEPTED`, `PLATING`, `READY_TO_SERVE`, `OUT_FOR_DELIVERY`).
- [ ] **Interactive WhatsApp Templates:** Messages containing live tracking URL buttons.
- [ ] **Web Push API (Service Worker):** Browser notification prompt on customer PWA for desktop/mobile browsers.
- [ ] **SMS Fallback:** Twilio / Fast2SMS fallback when WhatsApp is unavailable.

---

## 🛵 Milestone 5: Home Delivery & Live Driver GPS Map Tracking
**Goal:** Direct-to-consumer delivery rivaling Swiggy and Zomato.
- [ ] **Driver PWA (`/driver`):** Background location polling with `navigator.geolocation.watchPosition`.
- [ ] **Redis Geospatial Stream:** High-frequency GPS ingestion without writing every ping to disk.
- [ ] **Interactive Customer Map:** Leaflet / MapLibre GL map showing animated driver icon, restaurant marker, delivery destination, and polyline route.
- [ ] **ETA Calculation:** Dynamic distance and arrival time estimation based on driver speed.
- [ ] **Delivery Verification:** Customer OTP verification on food handover.

---

## 📱 Milestone 6: Waiter POS Handheld & Table Management
**Goal:** Mobile web tool for restaurant floor staff.
- [ ] **Table Grid Overview:** Visual floor plan showing table statuses (`Available`, `Occupied`, `Billed`, `Dirty`).
- [ ] **Order Taking Mode:** Waiter can take orders on behalf of guests, add special chef notes, and apply discounts.
- [ ] **Bill Splitting & Settlement:** Split bill by seat or item, accept Cash/UPI/Card.
- [ ] **Kitchen Order Ticket (KOT):** Auto-print or route tickets to thermal receipt printers.

---

## 🏢 Milestone 7: Restaurant Admin & White-Label Theming Portal
**Goal:** Multi-tenant control panel for restaurant owners and platform managers.
- [ ] **Branding Editor:** Live color picker, logo upload, font selector, and banner customizer that dynamically changes frontend CSS.
- [ ] **Menu Management:** CRUD categories, items, prices, out-of-stock toggles.
- [ ] **Operating Hours & Ordering Modes:** Toggle Dine-In, Delivery, or Takeaway per branch.
- [ ] **Sales & Tax Analytics:** Daily revenue, GST breakdown, top-selling dishes, peak dining hours.

---

## 🚀 Milestone 8: Multi-Platform Deployment & Production Hardening
**Goal:** Production launch across separate independent cloud platforms.
- [ ] **Frontend Deployment:** Vercel / Cloudflare Pages CI/CD configuration.
- [ ] **Backend Deployment:** Railway / Render / VPS Docker deployment with Caddy reverse proxy and wildcard SSL (`*.resto.com`).
- [ ] **Automated Tests:** Full Playwright E2E test suite covering Customer → Waiter → Kitchen → Driver.
- [ ] **Database Backups:** Automated daily PostgreSQL pg_dump to S3/Cloud Storage.
