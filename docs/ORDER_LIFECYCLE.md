# Resto Platform - Order Lifecycle & State Machine Specification

---

## 1. Granular Order State Graph

The order state machine enforces deterministic, forward-progressing transitions with full audit logging:

```mermaid
stateDiagram-v2
    [*] --> PLACED: Order Submitted
    PLACED --> WAITER_CONFIRMED: Waiter Acknowledges
    PLACED --> CANCELLED: Out of Stock / Rejected

    WAITER_CONFIRMED --> CHEF_ACCEPTED: KDS Ticket Accepted
    WAITER_CONFIRMED --> CANCELLED: Cancelled with Reason

    CHEF_ACCEPTED --> IN_COOKING: Cooking Starts
    IN_COOKING --> BEING_PREPARED: Assembly / Sides
    BEING_PREPARED --> PLATING: Finishing / Box Packaging
    PLATING --> READY_TO_SERVE: Expeditor Ready

    state DineIn {
        READY_TO_SERVE --> SERVED: Delivered to Table
        SERVED --> COMPLETED: Bill Settled
    }

    state Delivery {
        READY_TO_SERVE --> DRIVER_ASSIGNED: Driver Assigned
        DRIVER_ASSIGNED --> OUT_FOR_DELIVERY: Driver Picked Up
        OUT_FOR_DELIVERY --> DELIVERED: Handover Verified (OTP)
        DELIVERED --> COMPLETED: Reconciled
    }
```

---

## 2. Transition Validation Rules

| Current Status | Allowed Next Statuses | Actor Roles Allowed |
| :--- | :--- | :--- |
| `PLACED` | `WAITER_CONFIRMED`, `CHEF_ACCEPTED`, `CANCELLED` | `waiter`, `chef`, `manager`, `owner` |
| `WAITER_CONFIRMED` | `CHEF_ACCEPTED`, `IN_COOKING`, `CANCELLED` | `chef`, `manager`, `owner` |
| `CHEF_ACCEPTED` | `IN_COOKING`, `CANCELLED` | `chef`, `manager` |
| `IN_COOKING` | `BEING_PREPARED`, `PLATING`, `READY_TO_SERVE` | `chef` |
| `BEING_PREPARED` | `PLATING`, `READY_TO_SERVE` | `chef` |
| `PLATING` | `READY_TO_SERVE` | `chef`, `waiter` |
| `READY_TO_SERVE` | `SERVED` (Dine-in), `DRIVER_ASSIGNED` (Delivery) | `waiter`, `chef`, `manager` |
| `DRIVER_ASSIGNED` | `OUT_FOR_DELIVERY`, `CANCELLED` | `driver`, `manager` |
| `OUT_FOR_DELIVERY` | `DELIVERED` | `driver` (requires OTP verification) |
| `SERVED` / `DELIVERED` | `COMPLETED` | `waiter`, `manager`, `owner` |

Attempting any transition outside this matrix returns `422 Unprocessable Entity` with an explicit reason.
Every valid transition appends to `restoapp.order_status_history` and emits WebSocket updates.
