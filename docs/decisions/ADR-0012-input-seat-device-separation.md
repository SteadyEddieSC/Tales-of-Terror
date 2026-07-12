# ADR-0012: Separate devices, seats, and input-lab presentation

- Status: Accepted
- Date: July 12, 2026

## Context

Local players need stable seat ownership even when Godot controller device IDs change after a disconnect. Future browser participants must also be able to occupy seats without making the seat model depend on Godot joypad APIs. The diagnostics screen is a laboratory, not the final game UI.

## Decision

Use three cooperating layers:

1. `DeviceRegistry` owns Godot controller discovery and exposes stable identity metadata where available.
2. `SeatManager` owns eight reusable seat records and their lifecycle independently of presentation or Godot nodes.
3. `InputDisplayLab` renders snapshots and exposes display-test controls without assigning devices itself.

The main scene translates semantic input actions and coordinates these layers. A disconnected controller leaves a reservation keyed by its reported GUID, with controller name as a fallback when no GUID is available. Reconnection prefers the previous device ID and only falls back to identity when that identity has exactly one reservation, so identical controllers are never silently swapped. Keyboard is represented as a distinct development-only device identity.

## Consequences

- A reconnected controller can reclaim its prior seat even if Godot assigns a different device ID.
- Phone and browser identities can later enter the seat model without changing its state rules.
- Final UI can replace the lab presentation without rewriting discovery or seat ownership.
- Identical controllers that return with new device IDs cannot be automatically distinguished; the lab preserves both reservations instead of guessing, pending a stronger platform-specific identity strategy.
