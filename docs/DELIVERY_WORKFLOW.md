# Resto Platform - Direct Delivery Operations & Live GPS Tracking Workflow

---

## 1. Direct Delivery Lifecycle

```
[ Customer Places Order ] ──► Status: PLACED
                                  │
                                  ▼
[ Kitchen Prepares Food ] ──► Status: IN_COOKING → READY_TO_SERVE
                                  │
                                  ▼
[ Driver Assignment ]     ──► Status: DRIVER_ASSIGNED
                                  │
                                  ▼
[ Pickup from Kitchen ]   ──► Status: OUT_FOR_DELIVERY
                              (Driver location streaming activated)
                                  │
                                  ▼
[ Customer Handover ]     ──► Status: DELIVERED (Verified by 4-digit OTP)
```

---

## 2. Driver PWA (`/driver`) & Geolocation Streaming

- The driver uses any standard mobile browser (Chrome/Safari) with zero app download.
- Location coordinates are streamed via `navigator.geolocation.watchPosition`:
  - Stationary: updates every 10 seconds.
  - In motion (> 5 km/h): updates every 3 seconds.
- Ingestion endpoint: `POST /api/v1/delivery/location`:
  - Stores coordinate in Redis Geo index (`GEOADD tenant:{id}:drivers`).
  - Broadcasts payload over WebSocket room `order:{order_id}`.

---

## 3. Customer Live Tracking Page (`/track/:order_id`)

The customer order tracking screen renders:
1. Preparation timeline (Placed → Confirmed → Cooking → Plated → En Route → Delivered).
2. Live interactive map showing restaurant origin, animated driver bike marker with heading angle, and customer delivery destination.
3. Live ETA in minutes computed dynamically.
4. Customer handover OTP for contact verification.
