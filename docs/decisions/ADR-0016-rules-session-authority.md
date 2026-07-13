# ADR-0016: Rules-session authority and declarative consequences

- **Status:** Accepted
- **Date:** July 12, 2026

## Context

Turns, choices, checks, events, cards, inventory, and votes must be reproducible without allowing authored content or scenes to mutate authoritative state. Future Director, faction, companion, network, and campaign layers need a stable request/snapshot boundary.

## Decision

`RulesSession` is the scene-independent native-host authority for scenario identity, participating seats, round/phase progression, prompt responses, a session-owned seeded RNG stream, event queue, card zones, inventory, votes, terminal state, and bounded ordered history. Disconnected seats retain ownership and submissions. Late joins become participants only at the next round boundary.

`RulesContent` is validated declarative data. It uses a bounded condition/effect vocabulary and cannot execute scripts. Generic runtime and presentation code must not branch on event or card IDs. Event chains stop after 16 resolved steps.

Checks record raw draws, modifiers, outcome, and RNG counters. Malformed definitions consume no RNG. Deck shuffles use the same auditable stream.

Consequence bundles are preflighted in authored order against temporary rule and `BoardState` state. Any invalid effect rejects the entire bundle. Accepted board effects call `BoardState.apply_mutation`; rules code never edits board dictionaries. Within one bundle, later effects observe earlier preflight effects. Idempotent or conflicting board changes reject the bundle rather than silently succeeding.

Version-1 JSON-compatible snapshots fully validate content identity and referenced cards/events before state replacement. They are test/debug artifacts, not campaign saves.

## Consequences

The provisional host is a presentation key and metadata payload, not a rules dependency. The future Dread Director may request queued content but cannot select by mutating session state directly. Roles/factions/afterlife, private companion choices, networking replication, and campaign persistence remain separate future authorities.
