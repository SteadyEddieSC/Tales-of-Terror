# Living Board Engine

## Layer boundaries

The v0.0.5 engine has three deliberately separate layers:

- `BoardDefinition` and `LanternHouseBoardDefinition` are authored `Resource` data. They describe stable IDs, named spaces, types, tags, world regions, spawn locations, initial state, required topology, and connectors.
- `BoardState` is authoritative mutable state. It owns reveal state, hazards, features, blockers, connector state, seat occupancy, revision, rejection reason, and bounded mutation history.
- `BoardDebugOverlay`, exploration interactables, and `ExplorationDiagnostics` are presentation. They consume queries and `state_changed`; they do not edit dictionaries or decide outcomes.

Future turns, cards, events, the Director, networking, companions, and player-facing saves are outside this layer. They may later submit requests or replicate accepted changes, but the native host remains the mutation authority.

## Authored Lantern House board

`LanternHouseBoardDefinition` maps the v0.0.4 room into five stable spaces:

- `lantern_hall`: safe spawn room.
- `gate_passage`: the Iron Threshold corridor.
- `narrow_gallery`: dangerous surrounding gallery.
- `sealed_archive`: initially hidden objective space.
- `flooded_vault`: dangerous space with an initial `black_water` hazard and `flooded_floor` blocker.

Five connectors demonstrate doors, passages, locks, scenario-controlled collapse, and one-way direction. Definition validation rejects malformed/duplicate IDs, missing or self-linked endpoints, unsupported connector types or states, invalid region geometry, malformed initial collections, and unreachable required topology.

Authored regions use one or more positive `Rect2` areas. Mapping tests all inclusive areas. If a point belongs to multiple spaces—including a shared boundary—the smallest total authored region wins, followed by lexical stable ID. A point in no region maps to `outside_board`.

## Occupancy and exploration

Occupancy keys are stable seat numbers, never transient device IDs. `sync_occupancy()` sorts pawns by seat, maps positions, removes departed seats, prevents duplicates, and records one atomic entry/exit batch only when occupancy changes. A disconnected or reserved pawn remains in its named space because its pawn and position remain seat-owned; reconnecting a replacement device does not rewrite occupancy.

Existing `CharacterBody2D` collision and the shared camera remain responsible for continuous movement and framing. Board graph queries reason about named regions and connector rules. `crossing_is_blocked()` reports a direct connection whose current state is closed, locked, or collapsed; the existing iron-gate collision consumes the authoritative `hall_gate` state.

## Deterministic graph queries

The engine exposes direct connectivity, directional connector traversability, sorted reachable spaces, deterministic unweighted shortest paths, blocked-crossing detection, and required-area disconnection checks. Breadth-first searches process lexical neighbor IDs so equal-length paths remain stable across runs.

This is rule-aware board connectivity, not a navigation mesh or AI pathfinder.

## Mutation contract

Stable mutation types are:

- `reveal_space`
- `set_connector_state`
- `set_hazard`
- `set_feature`
- `set_blocker`

Each request is completely validated before application. Missing targets, unsupported states, malformed payloads, and idempotent reapplications return `accepted=false`; they do not increment revision or alter the snapshot/history. Accepted requests change one authoritative target, increment revision once, append a concise history entry, and emit `state_changed`.

For simultaneous batches, requests sort by seat number and stable mutation signature. The lowest seat claims a conflicting target. Other requests for that target fail atomically with `conflict_won_by_seat_N`; requests for different targets still apply.

The showcase visibly demonstrates archive reveal, gate opening, route collapse, hazard activation, and feature activation. Text, symbols, outlines, diagonal hatch, chevrons, cross marks, and occupancy Roman numerals supplement color.

## Snapshots

`to_snapshot()` produces a version-1 JSON-compatible `Dictionary` containing board identity/version, revision, all mutable maps, occupancy rows, and history. `restore_snapshot()` parses and validates an entire temporary state before swapping it into authority. Unsupported snapshot versions, board mismatches, malformed collections, invalid connector states, duplicate/invalid seats, unknown spaces, and malformed history are rejected without partial restoration.

Snapshots are in-memory test/debug support only. They do not write files and are not campaign saves.

## Diagnostics and safe frame

The existing diagnostics toggle also controls board-debug visibility. Diagnostics report board ID/version, revision, each pawn's named space, occupancy, connector states, hazards/features, recent history, and the last rejection. The overlay labels spaces and connector states and uses non-color patterns and symbols. Essential status/reset panels continue to recalculate against the active 0–48 px safe margin within the 960×540 logical viewport.
