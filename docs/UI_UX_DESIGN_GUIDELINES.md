# Resto Platform - UI/UX Design System & Experience Guidelines

---

## 1. Visual Purpose by Experience

The Resto Platform consists of 5 distinct user interfaces, each tailored to its specific operational environment:

```
┌─────────────────────────┬───────────────────────────────┬─────────────────────────────┐
│ Interface               │ Visual Purpose                │ Key Design Rules            │
├─────────────────────────┼───────────────────────────────┼─────────────────────────────┤
│ 1. Public Storefront    │ Michelin-grade Editorial      │ High-res photography,       │
│                         │ Brand Showcase                │ generous whitespace,        │
│                         │                               │ subtle animations, no POS   │
│                         │                               │ card clutter.               │
├─────────────────────────┼───────────────────────────────┼─────────────────────────────┤
│ 2. Customer QR Order    │ Mobile-first Conversion       │ Large touch targets, fast   │
│                         │ Frictionless Ordering         │ dietary filters, realtime   │
│                         │                               │ multiplayer cart drawer.    │
├─────────────────────────┼───────────────────────────────┼─────────────────────────────┤
│ 3. Waiter POS           │ High-Speed Floor Operations   │ Visual table map, rapid     │
│                         │ Tablet/Handheld Optimization  │ bill settlement, call bell  │
│                         │                               │ audio alerts.               │
├─────────────────────────┼───────────────────────────────┼─────────────────────────────┤
│ 4. Kitchen KDS          │ Glanceable Line Production    │ High contrast, large text   │
│                         │ High-Heat Legibility          │ aging timer color-coding,   │
│                         │                               │ 1-tap 86'ing toggle.        │
├─────────────────────────┼───────────────────────────────┼─────────────────────────────┤
│ 5. Driver PWA           │ Sunlight Mobile Navigation    │ Bold task cards, turn-by-   │
│                         │ Battery-Optimized GPS         │ turn directions, 4-digit    │
│                         │                               │ OTP input keypad.           │
└─────────────────────────┴───────────────────────────────┴─────────────────────────────┘
```

---

## 2. Color Palette & Typography Guidelines

### Typography
- **Headings & Editorial Display:** Clean, modern Sans-serif (`Inter`, `system-ui`) with optional serif accentuation for fine dining themes.
- **Numbers & Metrics:** Tabular figures (`tnum`) for currency amounts, prep timers, and order numbers.

### Core Palettes (Dark Grey Zinc Aesthetic)
- **Base Background:** Zinc-100 (Light) / Zinc-950 (Dark)
- **Cards & Surfaces:** White (Light) / Zinc-900 (Dark)
- **Borders & Dividers:** Zinc-200 (Light) / Zinc-800 (Dark)
- **Brand Accents:** Injected via CSS variables `--color-primary`, `--color-secondary`, and `--color-accent` (default: Amber-400 `#f59e0b` / Amber-500).
- **Status Indicators:**
  - 🟢 Pure Veg / Cooking Ready: Emerald-500
  - 🔴 Non-Veg / Overdue Aging: Rose-500
  - 🟡 Amber Aging / Warning: Amber-400
  - 🔵 In Route / Waiter Alert: Sky-500
