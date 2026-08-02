# Drowned Harbor Alpha.3 Systems & Replayability Contract v1

**Release:** P0.23
**Issue:** #106
**Baseline:** `4e28ce1d7b471c9be1113986647ccbc3147c0d9d`
**Status:** Planning authority only; no runtime implementation

## Purpose

P0.23 closes the design-to-runtime boundary for the Alpha.3 systems layer. It does not change `game/**`, create gameplay authority, register Drowned Harbor, or authorize ordinary exports. The future Alpha.3 implementation remains separately blocked.

## Inherited authority

The accepted Alpha.2 eight-stage route, package/scenario/localization identities, snapshot v2, stable-seat continuity, Council and High Water exactly-once identities, four privacy classes, public-only Director boundary, developer-only admission, and ordinary-export exclusion remain unchanged.

## Supported modes

- **Cooperative:** seats 1–8.
- **Hidden Betrayer:** seats 3–8 with exactly one Bellmarked overlay; lower seat counts fail closed to Cooperative before session start.
- **Outbreak:** seats 2–8 with no starting Tidebound seat; conversion begins only after High Water.
- **Hunted** and **Rival Crews** remain deferred.

## Roles and private objectives

`RoleSession` owns six Living role archetypes: bellhouse_archivist, fog_listener, lantern_surveyor, lifeboat_keeper, tide_chapel_warden, wreckers_heir. Stable-seat order cycles the reviewed archetype order for seats seven and eight; each assignment is an instance and persists `role_assignment_id`. No ending or route may require one named role; every role capability has a generic public alternative.

Living, Bellmarked, and Tidebound objective families are assigned from named RNG streams. The assignments persist `private_objective_assignment_id`. Shared output exposes only bounded completion status, never objective text, seat mappings, or desirability hints.

## Factions, transformation, and continuation

Bellmarked remains `faction_private` until a legal reveal or terminal attribution. Valid Cooperative routes never require a hidden faction.

A Tidebound offer is `controlled_reveal_private`, begins only after High Water, and may originate from authored exposure, bargain, or defeat. Each stable seat receives one persisted refusal before forced resolution. Alpha.3 supports no mid-session cure. Conversion preserves stable seat, position, history, inventory, and processed identities and commits one `tidebound_conversion_id`.

Defeat never silently eliminates a seat. The deterministic continuation priority is Lifeboat Survivor when a reviewed replacement route and capacity exist, Lighthouse Guardian during Last Light, Drowned Guide when a submerged rescue route exists, and Bell-Witness otherwise. Continuation commits one `continuation_transition_id` and preserves stable-seat participation history.

## Content and ownership

The contract freezes the reviewed inventories of 12 items, 12 cards, 8 resources, 12 hazards, 19 encounters, and 7 ending families from the authoring manifests. `RulesSession` owns item/card/resource/encounter/hazard/rescue state. Transfer preserves condition, charges, and hidden information. Invalid, stale, duplicate, wrong-seat, or unavailable requests consume no content, resource, state, or RNG.

## Director variation

Director selection uses only the closed public/aggregate allowlist, a named RNG stream, a three-candidate anti-repeat window, bounded filtering, and stable tie-breaking. Role IDs, private objectives, unrevealed Bellmarked seats, private item markers, and desirability scores are forbidden. Unbounded procedural generation is forbidden.

## Endings

The seven reviewed ending families are deterministic. Every reachable ending attributes every stable seat and active faction. `RulesSession` owns ending eligibility and public result; `RoleSession` owns controlled-private attribution. No ending requires a named role.

## Persistence and replay

Alpha.3 targets package/scenario/localization/provider/snapshot version 3. Alpha.2 snapshot v2 migrates explicitly to snapshot v3 or fails closed without replacing the active session. New assignment, conversion, continuation, Director, and ending identities persist alongside Council and High Water identities.

The required deterministic matrix covers three seeds across all supported seat counts and modes, repeats every case twice, and totals at least 126 runs. Coverage must reach every reviewed role, objective family, continuation form, item, card, hazard, encounter, and ending without unbounded generation. Eight consecutive rejections without progress require an actionable public diagnostic.

## Privacy and evidence

The exact classes remain `public`, `controlled_reveal_private`, `seat_private`, and `faction_private`. Surrogates receive no private projection. Reconnect returns the same authorized projection to the same stable seat. Automation is machine evidence only and does not establish physical-controller behavior, television readability, accessibility, privacy/security certification, fun, pacing, fairness, balance, production readiness, or public-release authorization.

## Routing

P0.23 is owned by Release Management and requires no Codex work. The inactive Alpha.3 implementation issue recommends Codex at **Very High** effort only after P0.23 merges and the owner separately authorizes runtime implementation.
