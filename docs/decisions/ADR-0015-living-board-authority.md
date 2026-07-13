# ADR-0015: Living Board definition, state, and presentation authority

- **Status:** Accepted
- **Date:** July 12, 2026

## Context

Continuous shared exploration needs named spaces and connectors that later rules can query without treating scene nodes, collisions, or rendered labels as authoritative. The board must change visibly while remaining deterministic, auditable, snapshot-testable, and independent of future turn, card, Director, networking, or save systems.

## Decision

`BoardDefinition` is an immutable authored `Resource` model. The Lantern House definition maps world regions, spawns, stable space IDs, tags, initial state, connector endpoints, types, direction, and initial connector state. Validation rejects malformed or duplicate IDs, missing endpoints, invalid geometry or initial state, and unreachable required topology.

`BoardState` exclusively owns mutable reveal, hazard, feature, blocker, connector, seat occupancy, revision, and history data. Consumers receive copied read-only query results and request changes through validated `BoardMutation` dictionaries. A rejected or idempotent request changes no authoritative snapshot data. Every accepted change increments revision and adds one history entry.

Requests for the same mutation target in one batch resolve to the lowest seat number; equal-seat ties use a stable mutation signature. Non-conflicting requests apply independently. This temporary policy is deterministic and does not imply turn order.

`BoardDebugOverlay`, exploration interactables, and diagnostics consume emitted state changes. They never decide board rules. Versioned in-memory snapshots are JSON-compatible debugging/test artifacts and are not player-facing saves.

## Consequences

Later turn, event, card, Director, networking, and companion systems can request or replicate explicit mutations without bypassing native-host authority. Deterministic graph and snapshot tests can run headlessly. Authored region overlap and shared boundaries resolve by smallest total region area, then stable space ID, which is predictable but requires authors to review geometry deliberately.
