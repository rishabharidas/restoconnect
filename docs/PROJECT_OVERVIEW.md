# Resto Platform - Project Overview

**Document Version:** 1.0.0  
**Status:** Approved Architecture Baseline  
**Classification:** Confidential / Platform Engineering

---

## 1. Vision & Strategic Mission

The **Resto Platform** is a modern, cloud-native, multi-tenant Restaurant Operating System (ROS). It empowers restaurant brands—from single-location fine dining establishments and artisanal cafes to large multi-branch chains, food courts, and high-velocity cloud kitchens—to operate their entire physical and digital dining lifecycle from a single, unified software stack.

Unlike fragmented setups combining separate point-of-sale systems, third-party delivery aggregators, static marketing websites, and stand-alone kitchen displays, Resto provides an end-to-end synchronized platform:

```
┌──────────────────────────────────────────────────────────────────────────────┐
│                              RESTO PLATFORM                                  │
├──────────────────────┬──────────────────────┬────────────────────────────────┤
│   Dine-In Diners     │    Floor Staff       │      Kitchen Operations        │
│   • QR Table Scan    │    • Waiter POS      │      • Station KDS             │
│   • Multiplayer Cart │    • Table Layout    │      • Aging Alert Timers      │
│   • Server Call Bell │    • Bill Settlement │      • Instant 86'ing          │
├──────────────────────┼──────────────────────┼────────────────────────────────┤
│   Direct Delivery    │    Storefront CMS    │      Enterprise Admin          │
│   • Zero-Fee Orders  │    • Michelin Visuals│      • Platform SaaS Portal    │
│   • Driver PWA (GPS) │    • Section Builder │      • Tenant Dashboards       │
│   • Live Map Stream  │    • Action Widgets  │      • Real-Time Analytics     │
└──────────────────────┴──────────────────────┴────────────────────────────────┘
```

---

## 2. Core Stakeholders & Personas

1. **Platform Owner / Superadmin:**
   - Manages SaaS subscriptions, provisions new restaurant tenants, monitors multi-tenant API health, configures feature tiers, and reviews platform-wide billing and audit logs.
2. **Restaurant Owner & General Manager:**
   - Owns brand identity, custom domains, branch locations, menu catalog, pricing, tax compliance (e.g. Indian GST), staff assignments, and marketing CMS.
3. **Floor Waiter & Captain:**
   - Operates a touch-optimized tablet/mobile POS to seat guests, take orders, accommodate customizations, handle server call bell alerts, and accept split/combined bill payments.
4. **Kitchen Chef & Expeditor:**
   - Monitors live high-contrast KDS screens segregated by station (Grill, Curry, Pantry, Bar, Expo), tracks ticket preparation timers, and toggles real-time 86'ing of unavailable items.
5. **Delivery Driver:**
   - Uses a zero-install mobile PWA to view assigned home deliveries, trigger turn-by-turn navigation, stream GPS coordinates, and complete deliveries via customer verification OTP.
6. **Guest / Customer:**
   - Experiences an editorial, brand-customized restaurant website, scans table QR codes for zero-app multiplayer ordering, or places delivery orders with live tracking.

---

## 3. Product Principles & Architecture Tenets

1. **Tenancy Isolation Without Compromise:**
   - Every piece of data—from menu items to audit logs—is strictly partitioned by `tenant_id`. No cross-tenant data leakage is permitted at the API, database, cache, or WebSocket layer.
2. **Editorial Storefront Separation:**
   - The public restaurant website is a brand's digital showcase (rich photography, heritage storytelling, culinary philosophy, atmosphere), not an online POS. Ordering and booking are integrated as non-intrusive, customizable action widgets.
3. **Granular Order State Machine:**
   - Status transitions strictly adhere to a deterministic, forward-progressing lifecycle with immutable audit history. Arbitrary status skipping is rejected.
4. **Real-time Synchronized Operations:**
   - Changes made in the kitchen immediately reflect on waiter tablets, customer tracking screens, and admin dashboards via low-latency WebSocket rooms and Redis Pub/Sub.
5. **Performance & Lightweight Footprint:**
   - The backend is powered by compiled Go binaries delivering sub-millisecond response times, low RAM utilization, and high concurrency for WebSocket connections.
