# Dread Director

## Authority and data flow

`LanternHouseDirectorContent` supplies reviewed profiles and candidates to the generic `DirectorContent` validator. `DirectorTelemetry` builds a read-only JSON-compatible copy from authoritative local rules and board state. `DirectorRuntime` evaluates that copy, records complete score/rejection detail, and returns a proposal. It cannot call rules or board mutation APIs.

When a `RoleSession` is supplied, telemetry may additionally copy only the social mode's allowlisted public/revealed counts and aggregates. It never receives hidden role/form/faction identities, private objectives, secret targets/messages, or future transitions. Different unrevealed assignments therefore produce identical social telemetry and Director decisions.

`DirectorProposalApplier` is the only integration boundary:

- `queue_event` and `rules_effects` call public `RulesSession` validation/transaction methods.
- `board_mutation` calls `BoardState.apply_mutation`.
- `presentation` returns a replaceable host/ambient payload.
- `no_op` deliberately changes no gameplay state.

Invalid downstream work leaves both authorities unchanged. An accepted result is passed back to `DirectorRuntime.record_application`, which advances Director revision, budgets, cooldowns, targeting, momentum, and audit state.

## Determinism

The Director derives a Park–Miller stream from the session seed plus the stable `dread_director_v1` salt and profile ID. It never shares the `RulesSession` RNG. Valid highest-score ties use one Director draw; unique winners use none. Invalid telemetry and invalid authored content consume no Director RNG.

The full decision input is the validated content identity, selected profile, telemetry snapshot, and Director snapshot. Reusing those values reproduces the candidate, target, score, and tie break.

## Pacing and scoring

Progress selects an authored act and target-tension band. Estimated tension is the bounded weighted sum of failure, resource, hazard, separation, stall, and pressure/relief momentum signals. This is a pacing estimate, not a player skill score.

For every legal candidate:

`final = max(0, base + pacing_fit + tension_gap + telemetry_affinities + profile_tag_affinity + repetition + fairness + mercy/recovery + volatility + scenario_constraints)`

Diagnostics preserve every integer component. Ineligible candidates remain visible with explicit reasons. The selector chooses the highest positive score; exact ties use the dedicated stream. A legal authored no-op handles off mode, all-zero sets, exhausted budgets, cooldowns, unfair targeting, and invalid pressure.

## Guardrails

- Negative targets must be connected active seats.
- Rolling per-seat targeting never exceeds the profile cap.
- Failure or critical resource pressure suppresses pressure and boosts relief/hints.
- Severe accepted pressure starts a recovery window.
- Rolling pressure impact cannot exceed the profile cap.
- Candidate and equivalent-tag cooldowns prevent immediate repetition.
- Budgets never go below zero.
- Authored board requests cannot bypass Living Board validation or remove required recovery paths.
- No resolved check, deck order, seat ownership, or accepted prompt response is altered.

These are transparent pacing and anti-frustration constraints, not hidden victory guarantees.

## Modes

The authored Lantern House set includes Off/Authored Only, Story/Gentle, Standard, Relentless/Dread, and Fixed Test profiles. Gentle and Fixed support reduced volatility. Spooky, Grim, and Gore & Dread remain presentation profiles and do not alter Director gameplay decisions.

## Director Lab

`ExplorationShowcase.tscn` accepts `--evidence-stage=director_struggling`, `director_cruising`, `director_stalled`, or `director_diagnostics`. Fixtures use public authoritative APIs, then build telemetry. The player card uses friendly names, a symbol, a named pattern, rationale, target, and outcome. Raw IDs, telemetry, RNG counters, component scores, cooldowns, and audit history remain in the intentionally paged diagnostics view.

No ambient hook flashes. Authored presentation payloads declare `reduced_motion_safe` for future sensory settings.
