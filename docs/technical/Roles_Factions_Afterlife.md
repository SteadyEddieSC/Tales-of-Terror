# Roles, Factions & Afterlife

## Authority boundary

`LanternHouseSocialContent` is reviewed authored data. `SocialContent` validates it. `RoleSession` alone owns assignment, current role/form and faction, reveal/lifecycle state, seat-private objectives/actions, bounded uses, transition history, outcome references, dedicated RNG, revision, and snapshots.

It does not own pawn position, controller identity, rules counters/cards/events, board geometry/mutations, Director pacing, networking, or saves. Stable seats are passed in from the seat layer. General effects call `RulesSession.apply_effect_bundle`; board effects remain `board_mutation` effects validated and applied by `BoardState`. The Director consumes only `RoleSession.director_safe_signals()` through `DirectorTelemetry.build`.

## Determinism and assignment

The Park–Miller role stream is salted with `social_roles_v1` plus the selected mode ID. Random pools select from sorted stable seats with bounded draws. Fixed modes consume zero draws. A plan is built against a probe stream and committed only after it is complete, so invalid content, unsupported layouts, and impossible plans consume no role RNG.

One-seat hidden betrayal selects the cooperative fallback declared by the mode. The public view states that the fallback is active. Late joins are explicitly deferred; they are never silently assigned another seat's private state.

## Lifecycle and transaction flow

Transitions validate the current form, authored trigger, target form, objective/action availability, mode afterlife policy, and per-transition chain count. Actions additionally validate stable-seat authority, lifecycle, target scope, phase, total uses, per-round use, and cooldown.

Proposal flow is:

1. Validate the complete social transition/action plan.
2. Preflight the accumulated rules and board effects against cloned authoritative snapshots.
3. Submit the same bundle through public `RulesSession`/`BoardState` APIs.
4. Commit form/faction/use state and one social revision.
5. Generate private audit and separately authored public history/presentation records.

A rejected step emits no player-visible success and changes no role, rules, board, or Director state.

## Lantern House demonstrations

Authored fixture recipes drive cooperative, hidden-private, Betrayer reveal, Horror transformation, Changed spread, Restless omen, guardian, reconnect, mixed result, diagnostics, and unsupported-count fallback stages. The fixture interpreter branches only on the bounded operation vocabulary, never on canonical role/faction/form/objective/fixture IDs.

Evidence stages use `ExplorationShowcase.tscn` with `--evidence-stage=social_cooperative`, `social_hidden_private`, `social_betrayer_reveal`, `social_horror`, `social_changed`, `social_restless`, `social_guardian`, `social_reconnect`, `social_mixed`, `social_diagnostics`, or `social_fallback`.

## Known limits

This is local deterministic engineering content, not final balance or production narrative volume. The shared-screen private reveal is controlled pass-and-play evidence, not simultaneous privacy. Full combat, enemy/minion control, companions, networking, campaign persistence, cloud AI, accounts, analytics, and moderation are not implemented.
