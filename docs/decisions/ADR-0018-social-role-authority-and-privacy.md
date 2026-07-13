# ADR-0018: Social-role authority, privacy, transitions, and afterlife

- **Status:** Accepted
- **Date:** July 13, 2026

## Context

Cooperative, betrayal, one-versus-many, conversion, mixed-objective, and afterlife play need one deterministic source of truth without letting shared-screen presentation expose secrets or letting social state take over rules, board, seat, or Director authority. A disconnected controller must not move a secret to another player. Defeat must not create an unbounded passive spectator when afterlife is enabled.

## Decision

`RoleSession` is the scene-independent native-host authority for stable-seat role/form assignment, current faction, reveal and lifecycle state, private objective/capability ownership, bounded uses, transitions, outcomes, role RNG, snapshots, and separate private/public audit histories. `SocialContent` validates declarative factions, roles/forms, modes, objectives, actions, transitions, and authored evidence fixtures. Generic runtime and presentation never branch on their stable IDs.

Role assignment uses a separately salted deterministic stream derived from the session seed and selected social-mode ID. Fixed plans consume no draws. Validation, impossible plans, and rejected transitions/actions do not advance it. Rules/check/deck and Dread Director streams remain separate.

`RoleSession` exposes four versioned JSON-compatible projections: public shared-screen, stable-seat private, authorized faction private, and explicitly enabled spoiler diagnostics. Public histories, errors, host payloads, and Director output are built independently from private audit state. The Director receives only scenario-allowlisted counts or public aggregates. A controlled private reveal first obscures the shared screen and accepts acknowledgement only from its stable seat; it does not claim an ordinary television panel is private.

Transitions and actions preflight complete downstream effect bundles against cloned `RulesSession` and `BoardState` snapshots. Accepted general/board effects cross existing public authority APIs before social state and uses commit. Rejection leaves every authority unchanged. Transition chains, action targets, use limits, per-round limits, and cooldowns are bounded.

An afterlife-enabled mode may transition a defeated seat only to a validated form with an objective and meaningful proposal-backed legal action within the authored delay. A mode may disable afterlife only through explicit authored policy and a player-visible warning before play.

## Consequences

Stable seat IDs—not device IDs—own secrets through disconnect and reconnect. Future companions may consume filtered views but cannot become gameplay authorities. Full online identity, campaign persistence, combat, enemy control, procedural role generation, production balance, and simultaneous private-device presentation remain separate work.
