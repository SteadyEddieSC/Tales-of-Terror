# Drowned Harbor Low-Tide Shared-Screen Prototype Shell

**Version:** 1.0  
**Release:** P0.15  
**Issue:** #82  
**Status:** Development-only, test-only, export-excluded prototype contract  
**Tale status:** Drowned Harbor remains outside the production Tale catalog and provider

## 1. Purpose

P0.15 creates the first visual and interactive Drowned Harbor prototype state for:

- storyboard `DH-UI-003`;
- interaction trace `DH-IS-003`;
- deterministic fixture `DH-FIX-001`;
- stage `low_tide_arrival`.

The shell answers a narrow engineering question:

> Can the accepted synthetic Low Tide fixture be presented on one controller-first shared screen with deterministic focus, public-only information, persistent voice-off text, explicit revision-bound confirmation, and fail-closed recovery without creating production gameplay authority?

It does not answer whether the final game is fun, balanced, accessible, readable on a television, safe for private information in every future environment, or validated with physical controllers.

## 2. Governed components

All runtime-like components remain under the existing export-excluded test tree:

- `game/tests/drowned_harbor_dev_only/low_tide_fixture_adapter.gd`;
- `game/tests/drowned_harbor_dev_only/low_tide_shared_screen_shell.gd`;
- `game/tests/drowned_harbor_dev_only/low_tide_shared_screen_shell.tscn`;
- `game/tests/drowned_harbor_low_tide_shell_test.gd`.

Godot UID records are tracked for all three new GDScript files.

## 3. Fixture adapter

The adapter loads only `DH-FIX-001` from the P0.14 package and validates:

- fixture, trace, and storyboard identity;
- test-only package and fixture status;
- public-shared privacy surface;
- source revision 11 and result revision 12;
- unchanged RNG cursor 4;
- stable-seat identity `seat_01`;
- active actor and request intent;
- Low Tide Arrival stage;
- an empty private projection map.

The adapter accepts one closed request shape:

- `fixture_id`;
- `source_revision`;
- `actor_kind`;
- `stable_seat_id`;
- `intent`.

Unknown fields, missing fields, unknown fixtures, stale revisions, unauthorized actors, wrong seats, and unknown intents fail closed before public output is produced.

## 4. Public projection

The shell receives only these approved fields:

- stage;
- tide state;
- objective;
- routes;
- resources;
- caption;
- history label;
- legal actions;
- active seat-public record.

The fixture's private role, objective, inventory item, and hidden route remain in the source fixture as leak sentinels. They may not enter the screen snapshot, caption, transcript, replay, diagnostics, recovery message, or public intent.

## 5. Shared-screen presentation

The shell presents:

- `LOW TIDE ARRIVAL`;
- the public objective;
- returning-tide state;
- Underteller host-authority area;
- active stable-seat identity and public location;
- deterministic focus position and selected legal action;
- persistent caption and legal-action inventory;
- controller and keyboard prompts;
- explicit status and recovery text;
- placeholder board geography.

The placeholder board labels:

- damaged causeway;
- Bellhouse;
- Salt Market;
- lifeboat shed;
- distant lighthouse.

The geometry is explicitly marked `placeholder_geometry_not_final`. No final camera, board geometry, art, animation, audio, music, voice, or localization is authorized.

## 6. Visual direction

The shell uses project-authored styling and simple geometry only:

- cool-dark backdrop;
- readable value separation;
- restrained amber emphasis inherited from the project theme;
- explicit text for active seat, focus, route/action meaning, and recovery state;
- no color-only communication;
- persistent public text when voice is disabled.

Automated snapshots and headless tests do not establish television-readability.

## 7. Semantic input model

Presentation code consumes semantic actions rather than device IDs:

- `ui_navigate_up`;
- `ui_navigate_down`;
- `ui_navigate_left`;
- `ui_navigate_right`;
- `ui_confirm`;
- `ui_cancel_action`;
- `interact`;
- `help_accessibility`;
- `diagnostic_test`.

Repository input mappings retain controller events and keyboard fallback. Automated checks establish mapping presence and deterministic behavior only; they are not physical-controller evidence.

## 8. Focus, inspect, preview, and cancel

Focus wraps deterministically through the three fixture legal actions. Focus movement changes a visible text ordinal and action label, so focus does not rely on color alone.

Inspect, preview, replay, transcript, and cancel preserve:

- source revision;
- source-state fingerprint;
- RNG cursor;
- stable-seat identity.

Cancel always returns to the board mode and clears a pending confirmation without committing anything.

## 9. Confirmation seam

The first confirm creates a pending record containing:

- focused action;
- source revision;
- stable-seat authority.

A second explicit confirm must present the same current revision and stable seat. A valid request emits `prototype_confirmation_requested` with:

- `classification: public`;
- `revision_bound: true`;
- `authoritative_commit: false`.

This is an implementation seam only. It does not implement final movement, encounter resolution, action points, item economy, balance, a production reducer, or a production save.

Stale revision, wrong authority, or absent confirmation fails closed and enters a public-safe recovery mode.

## 10. Transcript and replay

Transcript and replay requests use the already-sanitized public projection and event payload. They do not read the fixture's private domain.

Transcript and replay are intents only. They do not establish a production transcript service, replay engine, persistence format, or final UX.

## 11. Recovery

Unknown or unauthorized work produces a public-safe recovery result that states:

- the request was rejected;
- no state changed;
- no stable seat changed;
- no RNG was consumed.

Recovery contains no ridicule, hidden information, penalty, deadlock, stable-seat reset, or automatic acceptance.

## 12. Production invariance

P0.15 must leave unchanged:

- `game/data/tales/tale_catalog_v1.json`;
- `game/src/session/tale_provider_registry.gd`;
- the Lantern House default Tale;
- ordinary export presets;
- production saves and runtime authority.

The production catalog remains Lantern House-only. Drowned Harbor remains absent from the normal Tale Library and ordinary Windows/Linux exports.

## 13. Validation

The bounded workflow enforces the exact P0.15 path set and runs:

- P0.15 static contract validation;
- P0.15 fail-closed mutations;
- P0.14 projection validation and regressions;
- updated prototype-isolation validation and regressions;
- Godot 4.7.1-stable import validation;
- the standalone Low Tide shell test;
- the standalone isolation test.

Repository-wide workflows separately exercise repository, Godot, traceability, and portable-build gates.

## 14. Evidence limits

P0.15 automation is not:

- physical-controller evidence;
- television-readability evidence;
- accessibility certification;
- privacy certification;
- fun evidence;
- fairness evidence;
- balance evidence;
- household playtest evidence.

Issue #39 remains the human-playtest authority. Issue #44 remains the separate Companion dependency-remediation authority; its known audit failure is not suppressed, downgraded, ignored, or reinterpreted.

## 15. Approval boundary

P0.15 does not authorize:

- production Tale registration;
- production provider changes;
- Tale Library visibility;
- ordinary playable exports;
- Bellhouse gameplay;
- private bargain UX;
- High Water;
- Tidebound transformation;
- full Tale progression;
- final endings;
- final art or marketing claims.

Issues #83–#86 remain blocked. The next potential bounded release after merge is P0.16 under issue #83, and it requires separate user authorization.
