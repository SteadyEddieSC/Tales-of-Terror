# Drowned Harbor Deterministic State & Projection Fixtures

**Version:** 1.0  
**Release:** P0.14  
**Issue:** #81  
**Status:** Development-only synthetic fixture contract  
**Tale status:** Drowned Harbor remains design-only  
**Runtime implementation:** Not authorized

## 1. Purpose

P0.14 converts six accepted P0.11 interaction states into deterministic, synthetic test fixtures without creating Drowned Harbor gameplay, a reducer, a production save format, a Tale package, a provider, a scene, or normal Tale Library visibility.

The fixtures answer a narrow engineering question:

> Given the same synthetic source state, source revision, seed, authorized actor, and projection request, does the projection layer produce the same public/private result bytes and event sequence without mutating source state, consuming RNG, replacing a stable seat, or leaking private content?

They do not answer whether the final mechanics are balanced, fun, complete, readable, controller-validated, or production-ready.

## 2. Governed files

- `game/tests/drowned_harbor_dev_only/state_projection_fixture_schema_v1.json`
- `game/tests/drowned_harbor_dev_only/state_projection_fixtures_v1.json`
- `tools/validate_drowned_harbor_projection_fixtures.py`
- `tools/test_validate_drowned_harbor_projection_fixtures.py`

The fixture package remains under `game/tests/`, which is excluded by both ordinary Windows and Linux export presets.

## 3. Covered interaction traces

| Fixture | Interaction trace | State |
|---|---|---|
| `DH-FIX-001` | `DH-IS-003` | Low-Tide public action |
| `DH-FIX-002` | `DH-IS-004` | Bellhouse decision |
| `DH-FIX-003` | `DH-IS-007` | Controlled-private Harbor bargain handoff |
| `DH-FIX-004` | `DH-IS-008` | Once-only High Water transformation |
| `DH-FIX-005` | `DH-IS-010` | Tidebound public transformation |
| `DH-FIX-006` | `DH-IS-019` | Invalid-action recovery |

Each fixture binds the exact P0.11 storyboard ID, privacy surface, authoritative-commit behavior, and event-key inventory.

## 4. Fixture anatomy

Every fixture declares:

- globally stable fixture, trace, and storyboard IDs;
- a synthetic seed;
- source and result revisions;
- RNG cursor before and after projection;
- authoritative-commit behavior;
- the same stable-seat identity before and after;
- authorized actor kinds;
- one projection-only request;
- public, seat-public, private, and nonplayer diagnostic source domains;
- explicit public and private projection maps;
- expected event keys, classifications, exactly-once behavior, and payload maps;
- embedded fail-closed request mutations;
- an evidence and approval boundary.

The source state deliberately contains private marker values so privacy regression tests can prove that public projections, public events, captions, and history never serialize those values.

## 5. Pure projection model

The standard-library projector:

1. validates the fixture ID, source revision, actor kind, stable seat, request intent, and once-only state;
2. resolves declared source paths;
3. builds projection keys in sorted order;
4. emits the trace-authorized event sequence;
5. serializes canonical UTF-8 JSON using sorted keys and compact separators;
6. verifies source state is unchanged;
7. verifies the RNG cursor is unchanged.

Running the same fixture twice must produce byte-equivalent canonical output.

The projector is not a gameplay reducer. It does not choose legal actions, calculate balance, resolve movement, perform encounter logic, or advance a real session.

## 6. Revision and RNG rules

For committed synthetic fixtures:

- `result_revision` equals `source_revision + 1`;
- the event carries both revisions;
- reprojection returns the existing result;
- no additional RNG is consumed.

For invalid-action recovery:

- `result_revision` equals `source_revision`;
- authoritative state does not change;
- the RNG cursor does not change;
- the event remains diagnostic and not exactly-once.

## 7. Privacy rules

Public projection maps may read only:

- `public.*`;
- `seat_public.*`;
- approved revision/RNG metadata.

Controlled-private maps may additionally read:

- `private.*`.

A public or diagnostic event payload may not read private state. Private events may read private state only for the controlled-private fixture.

The controlled-private fixture produces:

- a private event and private projection for the authorized stable seat;
- a separate public resolution event;
- no private terms, costs, objectives, factions, or markers in the public projection or public history.

Raw player, account, network, credential, or voice-derived identities are absent. Stable seats use synthetic IDs such as `seat_03`.

## 8. Fail-closed behavior

Embedded request cases cover:

- stale source revision;
- unauthorized actor;
- wrong stable seat;
- unknown projection intent;
- missing private surface;
- repeated once-only transformation.

The regression suite additionally mutates:

- fixture inventory and identity;
- trace and storyboard bindings;
- public/private path boundaries;
- event keys and trace privacy;
- revisions and RNG cursors;
- stable-seat continuity;
- human-evidence flags;
- shipping status;
- trace-source availability;
- export exclusion;
- prototype-manifest work and fixture registration;
- approval language.

Unknown, stale, malformed, or unauthorized projection requests fail before output is produced.

## 9. Prototype-manifest update

The isolated prototype manifest now records:

- completed bounded packages: issues #80 and #81;
- remaining future packages: issues #82–#86;
- the P0.14 fixture package under `res://tests/drowned_harbor_dev_only/`.

Launch policy remains `explicit_test_script_only`. The fixture JSON is data, not a launch entry point.

## 10. Human evidence boundary

Automated fixture evidence does not establish:

- final mechanics;
- balance;
- fun or social tension;
- controller behavior;
- television readability;
- caption usability;
- accessibility compliance;
- privacy certification;
- household or remote networking;
- production readiness.

Issue #39 remains the authority for later human evidence. Issue #44 remains open and its Companion audit may not be suppressed.

## 11. Approval boundary

P0.14 does not approve:

- a Drowned Harbor production Tale package;
- a provider or Tale catalog entry;
- a runtime reducer, scene, save, or event bus;
- final Low Tide, Bellhouse, High Water, Tidebound, bargain, or recovery mechanics;
- balance values;
- production assets;
- normal Tale Library visibility;
- playable Windows or Linux exports;
- network or Companion behavior;
- human validation claims.

Issues #82–#86 remain blocked until separately authorized.
