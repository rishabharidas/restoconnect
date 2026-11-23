# Resto Platform - Comprehensive Roadmap & Product Milestones

This document details the multi-tenant architecture, role-based user experiences, and operational deliverables for the **Resto Platform**. It unites all restaurant stakeholders—Diners, Waiters, Chefs, Delivery Drivers, and Restaurant Owners—into a synchronized, real-time operating system.

---

## 🧭 Milestone Overview & Execution Phases

```
[M1: Core Architecture & Foundation] ✅ COMPLETED
   ↓
[M2: Collaborative Dine-In QR & Smart Table Experience] ✅ COMPLETED
   ↓
[M3: Kitchen Display System (KDS) & Role-Based Portals] ✅ COMPLETED
   ↓
[M3.5: Essential Restaurant Operations & Menu Management Suite] 🔄 IMMEDIATE FOCUS
   ↓
[M4: Zero-App WhatsApp Business Engine & Digital Invoicing]
   ↓
[M5: Direct Delivery Suite & Live Map Driver GPS Tracking]
   ↓
[M6: Waiter Handheld POS, Floor Plan & Thermal KOT Printing]
   ↓
[M7: Restaurant Owner Command Center & Multi-Branch Scaling]
   ↓
[M8: Multi-Platform Cloud Deployment & Production Hardening]
```

---

## 👥 Role-Based Portals & Specialized Views

The Resto Platform provides dedicated, role-tailored user interfaces optimized for each user persona:

| Persona | Primary URL | Core Responsibilities & Features |
| :--- | :--- | :--- |
| **Guest / Diner** | `/`, `/table/[token]`, `/track/[id]` | Brand story showcase & achievements, Dine-in QR scan, Multiplayer cart, Digital service bell, Home delivery with live GPS map |
| **Floor Waiter** | [`/waiter`](file:///Users/iocod/iocod/learn/personal/resto/restoconnect/restoview/src/routes/waiter/+page.svelte) | Visual table floor plan (T-01 to T-06), seating guests, live service bell notifications, table ordering, bill settlement (UPI, Cash, Card) |
| **Kitchen Chef** | [`/kds`](file:///Users/iocod/iocod/learn/personal/resto/restoconnect/restoview/src/routes/kds/+page.svelte) | High-contrast glanceable queue, station routing (Grill, Curry, Bar, Expo), elapsed aging timers (Green/Amber/Red), 1-tap 86'ing out-of-stock toggle |
| **Delivery Driver** | [`/driver`](file:///Users/iocod/iocod/learn/personal/resto/restoconnect/restoview/src/routes/driver/+page.svelte) | Delivery task cards, restaurant pickup & customer drop, 1-tap turn-by-turn navigation, battery-optimized live GPS broadcasting, customer handover OTP |
| **Manager / Admin** | [`/admin`](file:///Users/iocod/iocod/learn/personal/resto/restoconnect/restoview/src/routes/admin/+page.svelte) | Real-time income & sales metrics (Gross revenue, UPI/Cash/Card split), Top selling dishes, Staff management (Chefs, Waiters, Drivers), Live theme customizer |

---

## 🎨 System-Aware Dark & Light Theme Engine

The platform includes a native, persistent theme engine:
- **3-Way Mode:** `Light ☀️`, `Dark 🌙`, and `System Auto 💻` (detects OS `prefers-color-scheme`).
- **Low-Light Optimization:** Dark theme provides high-contrast legibility for ambient dining environments, dimly lit restaurant bars, and high-heat kitchen lines.
- **Dynamic Brand Customization:** Injects tenant CSS variables (`--color-primary`, `--color-secondary`, `--color-accent`) on top of base light/dark palettes.
- **Persistence:** Stored in `localStorage` with reactive updates across all components.

---

## ✅ Milestone 1: Core Architecture & Foundation (COMPLETED)
- [x] **Monorepo Topology:** Unified `restoview` (SvelteKit 5), `restolink` (Go Chi), and `restoconnect` (PostgreSQL 17 + Redis 7).
- [x] **Zero Vulnerabilities:** Upgraded SvelteKit, Svelte 5, and Vite with all 28 security advisories resolved down to 0 CVEs.
- [x] **Multi-Tenant Schema:** RLS-isolated PostgreSQL 17 schema with PostGIS, custom branding JSON, and seed demo restaurant.
- [x] **Go Backend API:** High-throughput Go server with pgx connection pooling, Redis in-memory pub/sub, JWT auth, and WebSocket hub.
- [x] **Generic Demo Seed Data:** Converted all demo references to `test-resto` / `Test Restaurant`.
- [x] **Cross-Origin Readiness:** CORS and headers configured for deploying frontend and backend to separate cloud platforms.

---

## ✅ Milestone 2: Collaborative Dine-In QR & Smart Table Experience (COMPLETED)
- [x] **Multiplayer Shared Table Cart:** Real-time synchronized cart across multiple diners at the same table via WebSocket room `table:<id>`.
- [x] **Digital Server Call Bell:** `POST /api/v1/table/:id/bell` with 1-tap alerts for "Call Server", "Request Water", and "Request Bill".
- [x] **Item Customizations & Modifiers:** Portion sizing (Regular/Full), spice level preferences (Mild, Medium, Extra Spicy), add-ons, and chef instructions.
- [x] **Print-Ready QR Stand Generator:** [`/table/qr-print`](file:///Users/iocod/iocod/learn/personal/resto/restoconnect/restoview/src/routes/table/qr-print/+page.svelte) generating A5/A6 acrylic table stands with QR code, Wi-Fi credentials, and restaurant branding.
- [x] **Cryptographic Table QR Engine:** Secure token generator creating unique QR keys (`qr_token_table_1_test_resto`).

---

## ✅ Milestone 3: Kitchen Display System (KDS) & Multi-Role Portals (COMPLETED)
- [x] **Granular Pipeline State Machine:**
   $$\text{PLACED} \to \text{WAITER\_CONFIRMED} \to \text{CHEF\_ACCEPTED} \to \text{IN\_COOKING} \to \text{BEING\_PREPARED} \to \text{PLATING} \to \text{READY\_TO\_SERVE} \to \text{SERVED}$$
- [x] **Station-Based Kitchen Routing:**
   - Filter tickets by station: `All`, `🔥 Tandoor / Grill`, `🍲 Curry & Wok`, `🍸 Drinks & Bar`, `🛎️ Expeditor Pass`.
- [x] **Visual & Auditory Rush Hour Alerts:**
   - Color-coded ticket aging timers: Green (< 10m), Amber (10-15m), Blinking Red (> 20m overdue).
- [x] **Instant 1-Tap 86'ing (Out-of-Stock):**
   - Chef can immediately toggle ingredient availability from the KDS drawer; updates all digital menus instantly.
- [x] **Dedicated Role Portals & Layout Switching:**
   - Default public view is strictly guest-facing.
   - Staff login modal (`<StaffLoginModal />`) with 1-tap testing logins for Waiter, Chef, Driver, and Admin.
   - Role route guards (`<AuthGuard />`) protecting staff URLs.
   - Waiter Floor POS (`/waiter`), Driver GPS Hub (`/driver`), and Executive Admin (`/admin`).

---

## 🔄 Milestone 3.5: Essential Restaurant Operations & Menu Engineering (IMMEDIATE FOCUS)
*Goal: Bridge critical foundational features required for real-world restaurant owners, kitchen managers, and diners.*

### 1. Complete Menu Item & Catalog Management Suite (CRUD)
Restaurant owners must be able to manage their live culinary offerings without writing database queries or touching code.
- **Add Menu Item Interface:**
  - Item Title, Subtitle, Long Description.
  - Category selector with 1-click "Create New Category" option.
  - Base Price & Dynamic Currency.
  - Food Type flag: `🟢 PURE_VEG`, `🔴 NON_VEG`, `🌱 VEGAN`, `🥚 CONTAINS_EGG`.
  - Preparation Time (in minutes) for KDS routing.
  - Nutritional & Dietary Information (Estimated calories, protein, carbs, allergens: Peanuts, Dairy, Gluten, Soy).
  - High-resolution dish photography upload or CDN URL.
- **Modifier & Portion Groups Builder:**
  - Create reusable modifier groups:
    - *Portion Sizes:* Half, Full, Quarter, Family Pack with relative price differentials ($+\$120$).
    - *Spice Customization:* Mild, Medium, Hot, Extra Hot (Ghost Pepper).
    - *Add-ons & Extras:* Extra cheese, garlic butter glaze, raita, mint chutney cups, side salads.
  - Multi-select constraints: Min Select and Max Select rules.
- **Category Hierarchy & Drag-and-Drop Reordering:**
  - Manage categories: Starters, Soups, Charcoal Tandoor, Main Course Curries, Artisanal Breads, Rice & Biryanis, Desserts, Signature Beverages.
  - Priority sort index (allows owners to push high-margin specials to the top of the menu).
- **Bulk CSV / JSON Menu Import & Export:**
  - Import 100+ dishes from a spreadsheet with automatic column mapping.
  - 1-click export of entire menu catalog for offline backup or printer formatting.

### 2. Guest View: Restaurant Heritage, Cuisine Showcase & Ambience Story
A restaurant ordering portal is also its digital storefront. Diners want to know the story, culinary style, atmosphere, and dining guidelines before ordering.
- **"About Our Kitchen" Culinary Story:**
  - Storytelling card explaining the restaurant's culinary philosophy, sourcing ethics (farm-to-table, organic, zero artificial food coloring).
  - Founding story, head chef's heritage, and cooking techniques (charcoal tandoor smoking, 18-hour slow dum simmering).
- **Cuisine Classification & Specialties Showcase:**
  - Visual cards spotlighting the specific types of food served:
    - 🥘 *Royal Awadhi & Mughlai Specialties* (Saffron infused, velvety kormas, hand-pounded aromatic spices).
    - 🍢 *Artisanal Charcoal Tandoor* (Clay oven roasted kebabs, paneer skewers, blistered sourdough naans).
    - 🍲 *Slow Dum Simmered Curries* (18-hour slow-cooked black lentils, rich cashew-tomato gravies).
    - 🍹 *Cold-Pressed Botanical Mocktails & Lassis* (Alphonso mango lassi, mint shikanji, smoked chaas).
- **Interactive Ambience & Dining Spaces Gallery:**
  - Photo gallery showcasing the restaurant interior: Main Dining Hall, Open Charcoal Grill, Rooftop Terrace, Private Dining Lounge, and Cocktail Bar.
- **Dining Guidelines & Facility Tags:**
  - Operating Timings: Lunch (12:00 PM – 3:30 PM), Dinner (7:00 PM – 11:30 PM).
  - Facility Badges: Valet Parking Available, High Chairs for Kids, Wheelchair Accessible, Wi-Fi Enabled, Pet-Friendly Outdoor Patio, Air Conditioned.
  - Dietary Certifications: 100% Halal Meat Sourced, Dedicated Pure-Jain Kitchen Utensils, Celiac-Safe Gluten-Free Cooking Protocols.

### 3. Digital Table Reservation & Seating Booking Engine
Allow customers to reserve a table in advance before visiting.
- **Reservation Booking Flow:**
  - Date selector & Dining Slot picker (Lunch slots vs Dinner slots).
  - Party size selector (2, 4, 6, 8, or Large Party 10+).
  - Seating preference: Indoor AC, Outdoor Rooftop, Romantic Corner, Window Seat.
  - Special Occasion tag: Birthday, Anniversary, Business Meeting, Casual Dining.
- **Floor Staff Booking Management:**
  - Waiters and Managers can view today's upcoming reservations on the `/waiter` and `/admin` dashboards.
  - Auto-assign reserved tables (e.g. Table T-03 held for Rahul at 8:00 PM).
  - WhatsApp confirmation message sent to the guest upon booking.

### 4. Promotional Discount Engine & Happy Hours
Increase conversion with smart promotional rules:
- **Promo Coupon Codes:**
  - Enter promo code (e.g. `WELCOME50`, `WEEKENDTREAT`, `FLAT100`).
  - Validation rules: Minimum cart subtotal, maximum discount cap, one-time per user phone number.
- **Automated Happy Hour Pricing Rules:**
  - Dynamic discounts applied automatically based on time of day (e.g., 20% off all beverages between 4:00 PM and 7:00 PM on weekdays).
- **Bill Surcharges & Tax Precision:**
  - Configurable split between Central GST (2.5%) and State GST (2.5%) or VAT.
  - Optional service charge toggle (with guest ability to request waiver).
  - Takeaway eco-packaging fee (₹15/container).

### 5. Customer Profile & 1-Tap Repeat Ordering
- Mobile OTP login for customers to save delivery addresses and favorite orders.
- Order History timeline showing previous orders with one-click "Order Again" button that populates the tray.

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
   - High ratings (4–5★) prompt a Google Review link; low ratings alert the manager privately.

---

## 🛵 Milestone 5: Direct Delivery Suite & Live Map Driver GPS Tracking
*Goal: Turn every restaurant into its own delivery service, saving 20–30% in third-party aggregator commissions.*

### Key Innovations & Features:
1. **Driver PWA (`/driver`):**
   - Works on any Android/iOS browser with zero app installation.
   - Background location streaming using `navigator.geolocation.watchPosition`.
   - Adaptive battery optimization: streams every 10s when stationary, every 3s when moving.
2. **Real-time Animated Customer Tracking Map:**
   - Interactive Leaflet / MapLibre GL map showing pickup point, animated bike icon with bearing rotation, and customer delivery destination.
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
     - 🔴 **Bill Requested:** Diners pressed "Request Bill" on phone.
2. **Table Merging & Bill Splitting:**
   - Merge Table 3 and Table 4 for large group reservations.
   - Split bill evenly across $N$ diners, or split by individual dishes.
3. **Thermal Printer Integration (ESC-POS / Network KOT):**
   - Support for direct network printing to standard thermal printers (Epson, Star Micronics) for physical kitchen order chits.

---

## 🏢 Milestone 7: Restaurant Owner Command Center & Multi-Branch Scaling
*Goal: Give restaurant owners complete control over branding, pricing, staff, multi-location outlets, and financial health.*

### Key Innovations & Features:
1. **5-Minute Tenant Self-Onboarding Wizard:**
   - Enter Restaurant Name → choose primary brand colors → upload logo → pick currency & tax rates.
   - 1-click bulk table generator (creates Tables 1 through 30 with printable QR codes).
2. **Multi-Outlet Branch Selector:**
   - Seamlessly switch between branches (e.g. *Indiranagar Flagship*, *Koramangala Bistro*, *Whitefield Cloud Kitchen*).
   - Independent inventory stock and station routing per branch.
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
