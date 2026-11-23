# Resto Platform - Comprehensive Roadmap & Product Milestones

This document details the feature roadmap, operational workflows, and technical deliverables for the **Resto Platform**. It incorporates modern restaurant industry innovations (inspired by Toast POS, DoorDash Drive, and Olo) to ensure the platform is intuitive for restaurant owners, floor staff, kitchen crews, and diners.

---

## 🧭 Milestone Overview & Execution Phases

```
[M1: Core Architecture & Setup] ✅ COMPLETED
   ↓
[M2: Collaborative Dine-In QR & Smart Table Experience] ✅ COMPLETED
   ↓
[M3: Kitchen Display System (KDS) & Realtime State Machine] 🔄 NEXT UP
   ↓
[M4: Zero-App WhatsApp Business Engine & Digital Invoicing]
   ↓
[M5: Direct Delivery Suite & Live Map Driver GPS Tracking]
   ↓
[M6: Waiter Handheld POS, Floor Plan & Thermal KOT Printing]
   ↓
[M7: Restaurant Owner Command Center & 5-Min Onboarding]
   ↓
[M8: Multi-Platform Cloud Deployment & Production Verification]
```

---

## ✅ Milestone 1: Core Architecture & Foundation (COMPLETED)
- [x] **Monorepo Topology:** Unified `restoview` (SvelteKit 5), `restolink` (Go Chi), and `restoconnect` (PostgreSQL 17 + Redis 7).
- [x] **Zero Vulnerabilities:** Upgraded SvelteKit, Svelte 5, and Vite with all security advisories resolved (0 CVEs).
- [x] **Multi-Tenant Schema:** RLS-isolated PostgreSQL 17 schema with PostGIS, custom branding JSON, and seed demo restaurant.
- [x] **Go Backend API:** High-throughput Go server with pgx connection pooling, Redis in-memory pub/sub, JWT auth, and WebSocket hub.
- [x] **Independent Deployment Readiness:** Cross-Origin Resource Sharing (CORS) configured for deploying frontend and backend to separate cloud hosts.
- [x] **Documentation & Agents:** Created `AGENTS.md`, `API_SPEC.md`, and `MIGRATION_GUIDE.md`.

---

## ✅ Milestone 2: Collaborative Dine-In QR & Smart Table Experience (COMPLETED)
- [x] **Multiplayer Shared Table Cart:** Real-time synchronized cart across multiple diners at the same table via WebSocket room `table:<id>`.
- [x] **Digital Server Call Bell:** `POST /api/v1/table/:id/bell` with 1-tap alerts for "Call Server", "Request Water", and "Request Bill".
- [x] **Item Customizations & Modifiers:** Portion sizing (Regular/Full), spice level preferences, add-ons, and chef instructions.
- [x] **Print-Ready QR Stand Generator:** [`/table/qr-print`](file:///Users/iocod/iocod/learn/personal/resto/restoconnect/restoview/src/routes/table/qr-print/+page.svelte) generating A5/A6 acrylic table stands with QR code, Wi-Fi credentials, and restaurant branding.
- [x] **Cryptographic Table QR Engine:** Secure token generator creating unique QR keys.

---

## 🔄 Milestone 3: Kitchen Display System (KDS) & Realtime State Machine (CURRENT FOCUS)
*Goal: High-speed, error-free kitchen coordination designed for high-volume rush hours.*

### Key Innovations & Features:
1. **Granular Pipeline State Machine:**
   $$\text{PLACED} \to \text{WAITER\_CONFIRMED} \to \text{CHEF\_ACCEPTED} \to \text{IN\_COOKING} \to \text{BEING\_PREPARED} \to \text{PLATING} \to \text{READY\_TO\_SERVE} \to \text{SERVED}$$
2. **Station-Based Kitchen Routing:**
   - Auto-routes items to dedicated station displays:
     - 🔥 **Grill / Tandoor Display:** Only shows kebabs, tikkas, and breads.
     - 🍲 **Curry / Wok Display:** Only shows main course gravies and stir-fries.
     - 🍸 **Bar / Beverage Display:** Only shows mocktails, cocktails, and drinks.
     - 🛎️ **Expeditor (Pass) Master Display:** Shows the entire table tray to assemble before calling the waiter.
3. **Visual & Auditory Rush Hour Alerts:**
   - Ticket aging timers: Green (< 10 mins), Amber (10–15 mins), Blinking Red (> 20 mins overdue).
   - Audio chimes when new tickets land on the screen.
4. **Instant 1-Tap 86'ing (Out-of-Stock):**
   - If the chef runs out of *Paneer Tikka*, long-pressing the item on the KDS marks it "Sold Out Today".
   - It is immediately greyed out across all table QR menus and online ordering in real time.

---

## 📲 Milestone 4: Zero-App WhatsApp Business Engine & Digital Invoicing
*Goal: Engage diners and delivery customers directly on WhatsApp without forcing an app store download.*

### Key Innovations & Features:
1. **Automated WhatsApp Progress Updates (Meta Cloud API):**
   - **On Order Placement:** Interactive WhatsApp message with Order ID and dynamic Web Tracking link button.
   - **On Chef Cooking:** *"Chef Rajesh has started preparing your order! 🍳 Track live: [link]"*
   - **On Plating / Ready:** *"Your food is freshly plated and on its way to your table! 🍽️"*
2. **Paperless Digital Tax Invoice:**
   - Eliminates thermal paper waste and printer jams.
   - Customers receive an official PDF receipt directly on WhatsApp with GST/tax breakdown, business registration details, and itemized bill.
3. **Instant Post-Meal Feedback:**
   - 10 minutes after `SERVED` / `DELIVERED`, WhatsApp sends a friendly 1-tap star rating (⭐ 1 to 5).
   - High ratings (4–5★) prompt a Google Review link; low ratings alert the manager privately to fix customer dissatisfaction before they leave.

---

## 🛵 Milestone 5: Direct Delivery Suite & Live Map Driver GPS Tracking
*Goal: Turn every restaurant into its own delivery service, saving 20–30% in third-party aggregator commissions.*

### Key Innovations & Features:
1. **Driver PWA (`/driver`):**
   - Works on any Android/iOS browser with zero app installation.
   - Background location streaming using `navigator.geolocation.watchPosition`.
   - Adaptive battery optimization: streams every 10s when stationary, every 3s when moving.
2. **Real-time Animated Customer Tracking Map:**
   - Interactive Leaflet / MapLibre GL map showing:
     - Restaurant pickup point marker.
     - Animated delivery bike icon with real-time heading/bearing rotation.
     - Customer delivery destination marker with route polyline.
3. **Live ETA & Distance Engine:**
   - Uses Redis Geospatial (`GEODIST`) to compute live distance and estimated minutes to arrival.
4. **Proof of Delivery & Handover OTP:**
   - Customer provides a secure 4-digit OTP generated by the system before the driver can mark `DELIVERED`.

---

## 📱 Milestone 6: Waiter Handheld POS & Fast Floor Operations
*Goal: Empower waitstaff to serve tables faster, increase table turn rates, and boost average order value.*

### Key Innovations & Features:
1. **Visual Floor Plan & Table Grid:**
   - Real-time color-coded restaurant layout:
     - 🟢 **Available:** Table ready for seating.
     - 🟡 **Ordering:** Guests seated and browsing menu.
     - 🔵 **Served / Eating:** Food served, running bill active.
     - 🟠 **Bill Requested:** Diners pressed "Request Bill" on phone.
     - 🔴 **Dirty / Needs Busser:** Table vacated, needs clearing.
2. **Table Merging & Bill Splitting:**
   - Merge Table 3 and Table 4 for large group reservations.
   - Split bill evenly across $N$ diners, or split by individual dishes.
3. **Thermal Printer Integration (ESC-POS / Network KOT):**
   - Support for direct network printing to standard thermal printers (Epson, Star Micronics) for physical kitchen order chits.

---

## 🏢 Milestone 7: Restaurant Owner Command Center & 5-Min Onboarding
*Goal: Give restaurant owners complete control over branding, pricing, staff, and financial health.*

### Key Innovations & Features:
1. **5-Minute Tenant Self-Onboarding Wizard:**
   - Enter Restaurant Name → choose primary brand colors → upload logo → pick currency & tax rates.
   - 1-click bulk table generator (creates Tables 1 through 30 with printable QR codes).
2. **Live White-Label Brand Styler:**
   - Owners can change primary color, accent color, banner image, and font family in the admin panel.
   - All customer-facing QR and web views instantly update their CSS custom properties.
3. **Daily Z-Report & Financial Analytics:**
   - End-of-Day settlement: Total cash collected, UPI/card payments, total GST tax collected, net payout.
   - Peak hour heat map (busiest hours of the week).
   - Top 5 revenue-generating dishes vs dead inventory items.
4. **Role-Based Access Control (RBAC):**
   - Strict roles: `Owner` (full access), `Manager` (voids & discounts), `Cashier` (billing), `Waiter` (ordering), `Chef` (KDS only), `Driver` (deliveries only).

---

## 🚀 Milestone 8: Multi-Platform Cloud Deployment & Production Hardening
*Goal: Cloud-ready deployment and rigorous quality assurance.*

- [ ] **Cross-Platform Deployments:**
  - `restoview` deployed to **Vercel** or **Cloudflare Pages**.
  - `restolink` containerized on **Railway**, **Render**, or a standalone **VPS**.
  - Managed PostgreSQL 17 + Redis.
- [ ] **Automated E2E Testing:** Playwright tests simulating the entire diner lifecycle (Scan QR → Order → KDS Advance → Waiter Serve → Settle Bill).
- [ ] **Disaster Recovery:** Daily automated pg_dump database snapshots.
