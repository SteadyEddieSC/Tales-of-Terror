# Social Privacy and Seat-Scoped View Contract

## View types

All views are versioned and JSON-compatible. They are regenerated from `RoleSession`; filtered views are never stored as authority.

- `public_shared_screen` contains friendly public/cover identity, intentionally public faction, lifecycle/connection status, public objectives/actions, sanitized history, public host payloads, public outcome summaries, and policy notices.
- `seat_private` nests the public view plus only the authorized stable seat's role/form/faction IDs, private text, objective/action details, prompt ownership, and acknowledgement state.
- `faction_private` exists only where the authored faction permits communication and includes only that faction's members.
- `spoiler_diagnostics` requires an explicit flag and contains full IDs, RNG, assignment/audit state, private causes, outcome detail, public preview, and leak evaluation.

## Shared-screen honesty

An ordinary television panel is always public. A seat-private reveal overlays an opaque full-screen obscurer, names the authorized seat, requires seat-scoped input, and closes back to a newly generated public view after acknowledgement or cancel. It warns that future companion devices are the better simultaneous-privacy layer.

## Leak surfaces and recursion

Tests collect unrevealed role/form/faction IDs and private objective text, serialize complete nested payloads, and check public views, public histories, errors, host payloads, Director telemetry/signals, and every unauthorized seat-private view. Public audit records are created separately rather than redacting the private audit in place. Rejection codes are generic and do not echo secret targets or causes.

Director aggregates are scenario-allowlisted counts/pressure values derived only from revealed state, defeat/afterlife state, or explicitly public conversion state. Changing which unrevealed seat holds a secret cannot change Director telemetry or decisions.

## Reconnect

Ownership keys are stable seat numbers. Disconnect changes only the connection flag and public reserved label. Role, faction, objectives, uses, cooldowns, pending private prompts, and private acknowledgement remain attached to that seat. A new device binding is handled outside `RoleSession` and cannot inspect the prior seat unless it legitimately reclaims that stable seat.
