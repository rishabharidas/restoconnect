# ADR 004: Granular Order State Machine and Audit Logging

## Status
Accepted

## Date
2026-11-24

## Context
A restaurant operating system requires strict, predictable progression of orders across Waiters, Kitchen, Delivery, and Billing without skipped states or unrecorded changes.

## Decision
Enforce a **Deterministic Finite State Machine (FSM)** in the Go service layer and append every transition to `restoapp.order_status_history`.

## Transition Matrix
$$\text{PLACED} \to \text{WAITER\_CONFIRMED} \to \text{CHEF\_ACCEPTED} \to \text{IN\_COOKING} \to \text{BEING\_PREPARED} \to \text{PLATING} \to \text{READY\_TO\_SERVE} \to \text{SERVED} / \text{DELIVERED} \to \text{COMPLETED}$$

## Rationale
- Prevents invalid or fraudulent transitions (e.g., claiming food was delivered before cooking).
- Provides immutable operational audit logs for dispute resolution, kitchen prep time metrics, and staff accountability.
