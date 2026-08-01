# Drowned Harbor Production Architecture and Tale-Compilation Contract v1

**Release:** P0.21
**Issue:** #98
**Baseline:** `58f6f4e4ece9bbdd5932216c87aacc064e48e05a`
**Status:** Active planning contract; no runtime authority

## 1. Purpose

This contract defines the boundary between the existing design-only Drowned Harbor authoring package and any future production Tale implementation.

It is implementation-ready architecture, not an implementation. It does not create a production package, provider, catalog entry, save schema, reducer, event, RNG stream, scene, asset, or ordinary export.

The machine-readable authority is `docs/preproduction/drowned_harbor_production_compilation_contract_v1.json`. Its schema is closed and fail-closed.

## 2. Existing authorities

The following inputs remain immutable during P0.21:

- `docs/technical/Tale_Authoring_Reference_Contract_v1.md`;
- `docs/preproduction/tale_authoring_reference_schema_v1.json`;
- `docs/tales/drowned_harbor/authoring/drowned_harbor_authoring_reference_v1.json`;
- `docs/technical/Tale_Package_Contract.md`;
- `docs/technical/Tale_Catalog_Contract.md`;
- `docs/technical/Tale_Runtime_Providers.md`.

The authoring reference and its content manifests are compilation inputs only. They are not runtime inputs and may not be copied into `game/data/tales/` or loaded by production code as substitutes for reviewed native authorities.

## 3. Compilation model

A future implementation release must compile reviewed authoring identities into separately reviewed production outputs:

1. scenario and stage-graph authority;
2. board authority;
3. rules and reducer authority;
4. Director content and bounded inputs;
5. social, role, faction, form, and private-projection authority;
6. governed localization catalog;
7. production Tale package;
8. static provider registration;
9. production catalog entry;
10. save and migration envelope;
11. exact validation and release evidence.

Compilation means an accountable implementation process, not executable data generation. Every output must map to repository source authorities and stable authoring IDs. Every output remains subject to independent review, tests, canonical identity, and exact-head release governance.

Compilation data may not contain or select arbitrary classes, script paths, callbacks, expressions, executable fragments, remote packages, URLs, credentials, telemetry, dynamic provider registration, or untrusted code. No future tool may infer missing authority through best-effort identity guessing.

## 4. Authority ownership

### Stage progression and mutations

`RulesSession` and its reviewed reducer own stage progression and authoritative mutations. Presentation layers, animations, dialogue timing, controllers, browsers, assets, and the Companion may request or display actions but may not commit state.

Every accepted action must identify its stable seat, authoritative revision, legal intent, and exactly-once request or event identity. Invalid, stale, duplicate, wrong-seat, unavailable, or malformed actions must leave state and RNG unchanged.

### Board state

`BoardState` owns spaces, connectors, tide-state board mutations, hazards, routes, pawns, and board-facing authoritative values. Read-only board projections may be consumed by UI and accessibility presentation.

### Social and private state

`RoleSession` and the reviewed private-projection layer own roles, factions, objectives, transformed forms, private bargains, controlled reveals, and ending attribution inputs.

The only supported privacy classes remain:

- `public`;
- `controlled_reveal_private`;
- `seat_private`;
- `faction_private`.

Shared output may never expose private terms, hidden targets, desirability hints, unrevealed allegiances, or pending private transformations.

### Director

The Director receives public state and explicitly authorized aggregate signals only. It may not inspect private objectives, hidden targets, private terms, or unrevealed faction membership. Director outputs remain bounded candidates resolved by native authority.

### RNG

Randomness must use named native-authority streams with deterministic ownership. Wall-clock time, animation duration, audio duration, network arrival, controller polling order, asset availability, and presentation timing may not influence outcomes.

### Presentation and history

Shared-screen UI, captions, transcripts, voice, music, SFX, browser surfaces, and reports consume read-only projections. Public history contains public consequences only. Private projections remain scoped to the authorized stable seat or faction.

## 5. Stable-seat continuity

The stable seat owns gameplay state across disconnect, surrogate control, replacement control source, human return, transformation, defeat, Restless continuation, and ending attribution.

No control-source transition may reset location, condition, inventory, role, faction, objective, form, cooldown, participation history, or ending ownership. A defeated active seat must receive an authored continuation, transformation, replacement route, or explicit terminal result.

## 6. Package, provider, and catalog admission

Lantern House remains the sole normal production/default Tale and the normal production catalog count remains one.

The reserved future identities are:

- Tale ID: `drowned_harbor`;
- provider ID: `drowned_harbor_authorities_v1`;
- package kind/schema: `tale` / `1`.

These identities are planning reservations only. P0.21 does not register them.

A future provider must be statically reviewed and must construct a complete candidate bundle. The coordinator may commit no session authority until the package, provider, catalog identity, source hashes, inventories, compatibility, mode plan, localization, migrations, and native candidates all validate.

An incomplete Drowned Harbor build may use only a separately authorized `developer_only_explicit_launch` gate. That gate must be unavailable to the normal Tale Library, absent from normal catalog presentation, and excluded from ordinary Windows and Linux exports. It may not silently change the default Tale.

## 7. Persistence, migration, replay, and exactly-once behavior

Stable authoring IDs become persistence contracts after runtime adoption. They may not be renamed or reused without an explicit migration record.

Restore must first select and validate the Tale identity and package version. A save from an unsupported identity or version must use an explicit versioned migration or fail closed with an actionable diagnostic. There is no best-effort field matching or fallback to a different Tale.

Equal authoritative inputs and seeds must produce replay-equivalent outcomes. Exactly-once event and request identities must be persisted or otherwise represented in authoritative restoration state so duplicates remain no-ops after save, reload, reconnect, or retry.

Reset clears all Drowned Harbor session authorities and returns to the normal Lantern House default. Rematch reconstructs the selected Tale through the validated package/provider path rather than reusing mutable session objects.

Package and catalog digests are provenance and admission metadata only. They must not influence gameplay snapshots, RNG, outcomes, public history, or ending attribution.

## 8. Localization, assets, and provenance

Future production text must use a closed governed localization catalog with reviewed keys. Public understanding must remain complete through shared-screen text, captions, transcript-capable presentation, and persistent-text support.

Every production asset must have a repository-relative identity and provenance record containing source, license or permission, production status, and attribution requirements. Temporary media must be explicitly labeled replaceable and internal-only.

Missing optional voice, music, SFX, animation, or noncritical art must use a declared safe text or original-placeholder fallback without changing authority, legal actions, private state, RNG, or outcomes.

P0.21 does not approve final localization, assets, voice, music, accessibility presentation, licensing, or human validation.

## 9. Rollback and removal

Any identity, validation, migration, privacy, or export-boundary failure must fail closed before partial authority is committed.

Rollback removes or disables hidden admission atomically, retains the normal Lantern House-only catalog, and removes any hidden provider registration as one bounded change. Existing saves are preserved unmodified or rejected with an actionable diagnostic; they are never silently rewritten into a different identity.

A later release must include a tested removal path before exposing Drowned Harbor beyond the developer-only gate.

## 10. Planned implementation sequence

The implementation definitions are recorded in `docs/preproduction/P0.21_Implementation_Issue_Set.md`:

1. `v0.2.0-alpha.1` — Production Tale Scaffold;
2. `v0.2.0-alpha.2` — End-to-End Graybox;
3. `v0.2.0-alpha.3` — Systems & Replayability;
4. `v0.2.0-beta` — Presentation & Content Integration;
5. `v0.2.0-rc` — Hardening & Distribution Readiness.

All five remain `planned_blocked`, have no GitHub issue, and are not activated by this contract.

## 11. Evidence boundary

Automation is not human evidence.

P0.21 makes no claim of physical-controller validation, television readability, accessibility certification, privacy certification, security certification, fun, pacing, fairness, balance, production readiness, or public-release authorization. Issue #39 remains the human-evidence authority and issue #7 remains the public-branding gate.

## 12. Exit condition

P0.21 exits when the human and machine-readable contracts, implementation issue definitions, status succession, validators, mutation suites, and applicable workflows all pass on one exact candidate head.

The next stage may be activated only by a separate owner authorization after P0.21 merges. That later runtime stage is expected to require Codex for substantial local Godot implementation and repeated local testing.
