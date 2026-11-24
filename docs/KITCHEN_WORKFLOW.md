# Resto Platform - Kitchen Display System (KDS) & Operational Workflow

---

## 1. Kitchen Stations & Routing Topology

The Resto KDS coordinates incoming orders across distinct kitchen preparation lines:

| Station ID | Display Name | Assigned Food Categories | Primary Equipment |
| :--- | :--- | :--- | :--- |
| `GRILL` | 🔥 Tandoor & Charcoal Grill | Starters, Kebabs, Tikkas, Sourdough Naans | 800°F Clay Tandoors, Charcoal Embers |
| `CURRY` | 🍲 Royal Curries & Dum Mains | Gravies, Dal Makhani, Dum Biryani | Copper Degchis, Copper Handis |
| `PANTRY` | 🥗 Cold Pantry & Salads | Raitas, Chutneys, Fresh Salad Bowls | Cold Prep Tables, Chillers |
| `BAR` | 🍹 Drinks & Beverages | Lassis, Mocktails, Botanical Shikanjis | Beverage Dispensers, Blenders |
| `EXPO` | 🛎️ Expeditor Pass | All Stations (Final Plating & Assembly) | Heated Pass, Ticket Printer |

---

## 2. Ticket Aging Alert Algorithm

Tickets in the KDS queue calculate elapsed time relative to `created_at`:

$$\Delta t = t_{\text{current}} - t_{\text{order}}$$

- **Green (< 10 minutes):** Normal preparation window.
- **Amber (10 – 15 minutes):** Priority attention; expeditors monitor line progress.
- **Blinking Red (> 20 minutes):** Overdue rush alert; audible bell ping to kitchen manager.

---

## 3. Realtime 86'ing (Instant Out-of-Stock)

When a chef marks an ingredient or menu item as unavailable (`PATCH /api/v1/menu/items/:id/availability` with `{ "is_available": false }`):
1. The database flag `is_available` is updated in `restoapp.menu_items`.
2. A WebSocket event `ITEM_AVAILABILITY_CHANGED` broadcasts to room `tenant:<tenant_id>`.
3. All customer ordering views, waiter POS terminals, and online storefronts immediately disable the dish without requiring a page refresh.
