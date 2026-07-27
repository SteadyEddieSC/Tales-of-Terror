# Drowned Harbor Bellhouse Decision & Invalid-Action Recovery

**Version:** 1.0
**Release:** P0.16
**Issue:** #83
**Status:** Development-only, test-only, export-excluded prototype contract
**Tale status:** Drowned Harbor remains outside the production Tale catalog and provider

## 1. Purpose

P0.16 extends the isolated Drowned Harbor prototype with two governed public-shared states:

- `DH-UI-004` / `DH-IS-004` / `DH-FIX-002` — Bellhouse Ledger decision;
- `DH-UI-019` / `DH-IS-019` / `DH-FIX-006` — invalid-action recovery.

The release asks whether a synthetic Bellhouse decision can be projected, previewed, explicitly confirmed once, replayed safely, and recovered after rejected input without exposing private fixture data or creating production gameplay authority.

It does not establish final Ledger mechanics, balance, physical-controller behavior, television-readability, accessibility compliance, privacy certification, fun, fairness, or human playability.

## 2. Governed components

All runtime-like components remain under the existing export-excluded test tree:

- `game/tests/drowned_harbor_dev_only/bellhouse_fixture_adapter.gd`;
- `game/tests/drowned_harbor_dev_only/bellhouse_decision_shell.gd`;
- `game/tests/drowned_harbor_dev_only/bellhouse_decision_shell.tscn`;
- `game/tests/drowned_harbor_bellhouse_recovery_test.gd`.

Godot UID records are tracked for the three new GDScript files.

## 3. Bellhouse fixture adapter

The adapter loads the existing closed P0.14 fixture package and resolves exactly:

- `DH-FIX-002` for the Bellhouse decision;
- `DH-FIX-006` for invalid-action recovery.

The Bellhouse projection validates:

- trace `DH-IS-004` and storyboard `DH-UI-004`;
- public-shared privacy surface;
- source revision 21 and result revision 22;
- unchanged RNG cursor 7;
- stable-seat identity `seat_02`;
- active-stable-seat authority;
- stage `bellhouse_ledger`;
- public Ledger, ring, selected-option, consequence, caption, history, and legal-action data;
- an empty private projection map.

The recovery projection validates:

- trace `DH-IS-019` and storyboard `DH-UI-019`;
- public-shared privacy surface;
- source and result revision 61;
- unchanged RNG cursor 18;
- stable-seat identity `seat_06`;
- no authoritative commit;
- `state_changed: false` and `rng_changed: false`;
- a focus destination contained in the current legal-alternative set;
- an empty private projection map.

## 4. Independent fixture boundary

`DH-FIX-002` and `DH-FIX-006` intentionally represent different governed situations, stable seats, and source revisions. The shell does not merge their source states.

- Bellhouse request rejection is generated from the preserved Bellhouse decision and retains seat 2.
- The explicit `DH-FIX-006` proof is projected as an independent recovery surface retaining seat 6.
- Returning from `DH-FIX-006` restores the unchanged Bellhouse decision projection.

This separation prevents a reusable recovery fixture from silently replacing the Bellhouse authority, stage, or source revision.

## 5. Public Bellhouse projection

The Bellhouse shell presents only approved public and seat-public fields:

- public objective;
- visible, erased, and unresolved Ledger counts;
- visible and audible ring counts;
- unresolved extra-ring state;
- the governed synthetic priority `record_missing_position`;
- its public consequence;
- active stable-seat authority and control source;
- public caption, history, and legal actions.

The source fixture contains private role, faction, objective, inventory, and hidden-route sentinels. No `PRIVATE_` value may enter the screen snapshot, caption, transcript, replay, diagnostics, recovery, or public event.

## 6. Presentation

The test-only `Control` shell includes:

- `BELLHOUSE LEDGER` stage text;
- public objective and consequence;
- public Ledger and ring summaries;
- Underteller host-authority area;
- active stable-seat and control-source text;
- explicit focus ordinal and selected option text;
- separate preview and confirmation states;
- persistent caption, legal-action, status, and recovery text;
- controller prompts with keyboard fallback;
- placeholder geometry for one large bell, long ropes, squared Bellhouse space, and public Ledger.

The geometry is explicitly marked `placeholder_geometry_not_final`. No final art, camera, animation, sound, music, voice, timing, or localization is authorized.

## 7. Preview, inspect, focus, and cancel

Inspect, preview, focus movement, cancel, transcript, and replay preserve:

- source revision;
- source-state fingerprint;
- RNG cursor;
- stable-seat identity;
- prototype commit count.

With the current fixture, the deterministic decision-option set contains one governed synthetic option. Focus movement therefore wraps to the same option rather than inventing additional Ledger mechanics or priorities.

## 8. Revision-bound confirmation

The first confirm creates a pending record containing:

- selected option;
- source revision;
- stable-seat authority;
- actor kind.

A second explicit confirm validates:

- current source revision;
- current stable seat;
- authorized active-stable-seat actor;
- unchanged selected option;
- current legal-option availability.

A valid confirmation records one synthetic prototype result and emits the governed public event key `bellhouse_decision_committed` once. The emitted payload states:

- `prototype_commit: true`;
- `production_authority: false`.

The fixture source state and RNG remain unchanged. Repeating the same valid confirmation reprojects the existing result and emits no second governed event.

This is not a production reducer, production save, final Ledger mechanic, or balance commitment.

## 9. Bellhouse request recovery

Stale revision, wrong stable seat, unauthorized actor, changed option, unavailable option, absent confirmation, malformed input, unknown input, and private-output detection fail before prototype commit.

The recovery overlay contains only:

- public-safe rejection code and message;
- preserved current legal options;
- deterministic focus destination;
- `state_changed: false`;
- `rng_changed: false`;
- `stable_seat_reset: false`.

Recovery uses neutral system language and includes no ridicule, blame, buzzer, jump scare, score penalty, timer loss, hidden causation, future-answer hint, input lock, or deadlock.

## 10. Governed DH-FIX-006 recovery proof

The independent recovery projection presents:

- rejected public action;
- public-safe unavailability reason;
- current legal alternatives;
- deterministic focus on `move_to_bellhouse_roof`;
- active seat 6 and its public control source;
- persistent caption and history;
- explicit no-state-change and no-RNG-change values.

Its diagnostic event key is `invalid_action_recovery_projected`. Reprojection is deterministic and does not execute a game action.

## 11. Transcript and replay

Transcript and replay are built only from the sanitized public projection. They do not read the private fixture domain and do not:

- repeat the Bellhouse commit;
- consume RNG;
- change stable-seat authority;
- execute final gameplay;
- create persistence.

## 12. Production and export invariance

P0.16 leaves unchanged:

- `game/data/tales/tale_catalog_v1.json`;
- `game/src/session/tale_provider_registry.gd`;
- the Lantern House default Tale;
- ordinary export presets;
- production saves, reducers, and runtime authority;
- Companion code and protocol.

Lantern House remains the sole production/default Tale. Drowned Harbor remains absent from the normal Tale Library, production provider, production catalog, and ordinary Windows/Linux exports.

## 13. Validation

The release-specific read-only workflow must enforce the exact P0.16 path set and run:

- P0.16 static contract validation;
- P0.16 fail-closed regression mutations;
- inherited P0.15 Low Tide validation and regressions through a P0.16 manifest-compatibility layer;
- inherited six-fixture validation and regressions through a P0.16 manifest-compatibility layer;
- updated prototype-isolation validation and regressions;
- pinned `gdformat --check` and `gdlint`;
- Godot 4.7.1-stable import validation;
- the standalone Bellhouse/recovery Godot test;
- the standalone Low Tide Godot test;
- the standalone prototype-isolation Godot test;
- repository and Windows/Linux portable-build gates.

## 14. Evidence limits

P0.16 automation is not:

- physical-controller evidence;
- television-readability evidence;
- accessibility certification;
- privacy certification;
- fun evidence;
- fairness evidence;
- balance evidence;
- household or remote human-playtest evidence.

Issue #39 remains the human-playtest authority. Issue #44 remains the separate Companion dependency-remediation authority, and its audit is not suppressed, downgraded, ignored, or reinterpreted.

## 15. Approval boundary

P0.16 does not authorize:

- final Ledger rules or priorities;
- final Bellhouse consequences;
- final movement, encounter, item, or action-point mechanics;
- private bargain UX;
- High Water or Tidebound transformation;
- full Tale progression or endings;
- production Tale registration;
- Tale Library visibility;
- ordinary playable exports;
- final assets or public marketing claims.

Issues #84–#86 remain blocked. The next potential bounded release after merge is P0.17 under issue #84 and requires separate user authorization.
