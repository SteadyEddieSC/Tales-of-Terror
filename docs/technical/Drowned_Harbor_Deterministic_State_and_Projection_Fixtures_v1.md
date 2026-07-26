# Drowned Harbor Deterministic State and Projection Fixtures

**Version:** 1.0  
**Release:** P0.14  
**Issue:** #81  
**Status:** Development-only, synthetic, export-excluded  
**Production Tale:** Lantern House remains the sole production Tale

## Purpose

This package defines six deterministic synthetic state-and-projection fixtures for selected Drowned Harbor interaction traces. The fixtures are review and test data only. They do not create a Drowned Harbor runtime, reducer, provider, Tale package, catalog entry, scene, save format, or playable export.

The package proves that a bounded projection layer can:

- read an authoritative synthetic source/result state;
- validate actor, stable-seat, action, revision, and private-surface authority;
- produce byte-equivalent public projections and event sequences;
- project controlled-private content only to the authorized stable seat;
- keep private values out of public projections, history, events, captions, and player-facing diagnostics;
- preserve stable-seat identity through accepted, transformed, private, and rejected examples;
- reproject without mutating fixture inputs or consuming deterministic randomness;
- fail closed for unknown, stale, malformed, wrong-seat, unauthorized, or illegal fixture actions.

## Fixture inventory

| Fixture | Trace | Purpose | Event authority |
|---|---|---|---|
| `DH-FX-001` | `DH-IS-003` | Low Tide public action | `low_tide_public_action_committed` |
| `DH-FX-002` | `DH-IS-004` | Bellhouse decision | `bellhouse_decision_committed` |
| `DH-FX-003` | `DH-IS-007` | Controlled-private Harbor bargain | private commit plus public resolution |
| `DH-FX-004` | `DH-IS-008` | High Water once-only transformation | `high_water_transformation_committed` |
| `DH-FX-005` | `DH-IS-010` | Tidebound public transformation | `tidebound_transformation_committed` |
| `DH-FX-006` | `DH-IS-019` | Invalid-action fail-closed recovery | `invalid_action_recovery_projected` |

The trace IDs, storyboard IDs, privacy surfaces, event keys, classifications, and exactly-once settings are validated directly against the merged P0.11 interaction-trace manifests.

## Authoritative revisions

Every fixture declares:

- a positive `source_revision`;
- one stable-seat ID;
- a request revision;
- an action and current legal-action inventory;
- source and result public/private state;
- whether the example represents an authoritative commit;
- a deterministic expected result revision.

For accepted authoritative fixtures, the result revision is exactly `source_revision + 1`. The invalid-action fixture remains at the source revision because no authoritative mutation occurred.

Projection never invents a later revision, partially commits, or changes an already committed fixture result.

## Stable-seat contract

The same stable-seat ID appears before and after every fixture projection.

A changed controller source, public form, route, stage, or private handoff does not create a replacement character, reset the seat, restore state, or discard prior history. The Tidebound fixture changes public form while preserving the same stable seat. The controlled-private fixture routes private terms to the same authorized seat and clears them from shared output.

## Public and private projection contract

Public projection is constructed only from explicitly listed public result-state keys. Controlled-private projection is constructed only from explicitly listed private keys for the authorized recipient seat.

The validator collects private string values from source and result state and rejects a fixture if any private value appears in:

- public projection;
- public event payloads;
- public history;
- public-safe recovery text.

Private events remain in the private event sequence. The public Harbor-bargain resolution event contains no private term, cost, consequence, response, hidden identity, raw controller identifier, credential, or account information.

## Determinism and randomness

`tools/drowned_harbor_fixture_projection.py` is a pure standard-library projector. It:

- deep-copies selected values;
- does not modify source or result state;
- performs no file writes;
- performs no network calls;
- consumes no random numbers;
- produces canonical sorted UTF-8 JSON bytes;
- records one SHA-256 digest per expected projection.

The validator projects every fixture twice and requires identical object output and canonical SHA-256 identity.

The fixture seed is provenance for future deterministic reducer work. The projection layer does not draw from it.

## Invalid-action example

`DH-FX-006` requests a route that is not in the current legal-action inventory. The projector must:

- reject before mutation;
- retain the source revision;
- retain the same stable seat and location;
- leave projection RNG at zero draws;
- emit only the governed diagnostic event;
- expose a public-safe reason and current alternatives;
- omit hidden routes and private objectives.

## Repository and export boundary

The schema and fixture data live under `game/tests/` and are excluded by the existing `tests/*` Windows and Linux export rule.

The prototype manifest records:

- completed work issues #80 and #81;
- future work issues #82 through #86;
- the fixture package path;
- no production registration, provider, Tale Library visibility, runtime authority, or playable-export authorization.

The production catalog canonical digest remains unchanged and contains only Lantern House.

## Validation

Run:

```bash
python tools/validate_drowned_harbor_prototype_isolation.py
python tools/test_validate_drowned_harbor_prototype_isolation.py
python tools/validate_drowned_harbor_projection_fixtures.py
python tools/test_validate_drowned_harbor_projection_fixtures.py
```

The regression suites reject weakened production boundaries and fixture defects including duplicate IDs, missing coverage, unknown trace or event keys, privacy drift, stale or wrong-seat requests, unauthorized private projection, RNG use, stable-seat loss, private-data leakage, human-evidence claims, and digest drift.

## Evidence boundary

P0.14 provides deterministic synthetic projection evidence only. It does not establish:

- final Drowned Harbor mechanics or balance;
- gameplay fun, tension, pacing, or comprehension;
- physical-controller behavior;
- television readability;
- private-screen usability;
- privacy certification;
- accessibility compliance;
- final dialogue, art, sound, music, voice, or localization;
- production Tale readiness.

Issues #82 through #86 remain blocked until separately authorized.
