# Drowned Harbor development-only fixtures and shells

Everything in this directory is synthetic, test-only, and excluded from ordinary Windows and Linux exports by the existing `tests/*` export rule.

## Current package

- `state_projection_fixture_schema_v1.json` — closed P0.14 fixture schema.
- `state_projection_fixtures_v1.json` — six deterministic fixtures bound to P0.11 interaction traces.
- `low_tide_fixture_adapter.gd` — fail-closed public reader for `DH-FIX-001`.
- `low_tide_shared_screen_shell.gd` — controller-first Low Tide presentation and intent shell.
- `low_tide_shared_screen_shell.tscn` — explicit test-only Low Tide scene using placeholder geometry.
- `bellhouse_fixture_adapter.gd` — fail-closed public readers for `DH-FIX-002` and `DH-FIX-006`.
- `bellhouse_decision_shell.gd` — controller-first Bellhouse decision and recovery shell.
- `bellhouse_decision_shell.tscn` — explicit test-only Bellhouse scene using placeholder geometry.

## P0.15 Low Tide boundary

The Low Tide shell presents synthetic public fixture data for `DH-UI-003`, `DH-IS-003`, and `DH-FIX-001`:

- public stage objective and returning-tide state;
- Underteller host-authority area;
- placeholder board geography for the damaged causeway, Bellhouse, Salt Market, lifeboat shed, and distant lighthouse;
- stable-seat rail and active focus text;
- persistent captions, legal actions, prompts, status, and recovery messaging;
- inspect, preview, cancel, explicit revision-bound confirmation, transcript-open, and replay intent seams.

The Low Tide shell does not implement movement, encounters, items, action points, balance, a reducer, production saves, networking, Companion behavior, Tale completion, High Water, Bellhouse commitment, private bargains, transformations, or ending logic.

## P0.16 Bellhouse and recovery boundary

The Bellhouse shell presents synthetic public fixture data for:

- `DH-UI-004`, `DH-IS-004`, and `DH-FIX-002` — public Bellhouse Ledger decision;
- `DH-UI-019`, `DH-IS-019`, and `DH-FIX-006` — public-safe invalid-action recovery.

The Bellhouse decision shows public Ledger and ring counts, one governed synthetic priority, its public consequence, the current stable-seat authority, captions, prompts, legal actions, focus, preview, cancel, transcript, replay, and explicit confirmation.

A valid revision-, authority-, and option-bound confirmation records one synthetic prototype result and emits `bellhouse_decision_committed` once. Repeating the same confirmation reprojects the existing result and emits no second event. The shell explicitly records `production_authority: false` and does not create a production reducer, save, final Ledger mechanic, or balance rule.

Bellhouse request rejection preserves the Bellhouse source revision, fixture fingerprint, RNG cursor, stable seat, option, and deterministic focus. `DH-FIX-006` remains an independent seat-6 recovery fixture and is never merged into the seat-2 Bellhouse state.

Recovery uses public-safe neutral language and includes no ridicule, blame, penalty, timer loss, hidden consequence, stable-seat reset, input lock, or deadlock.

## Privacy and evidence boundary

Only public and approved seat-public fields are projected. Private fixture markers are deliberately present in the source fixtures so tests can prove they do not enter the public screen, captions, transcript, replay, diagnostics, recovery, or events.

Automated input coverage proves semantic controller mappings and keyboard fallback paths only. It is not physical-controller evidence, television-readability evidence, accessibility certification, privacy certification, fun evidence, fairness evidence, balance evidence, or household playtest evidence.

## Validation

From the repository root:

```bash
python tools/validate_drowned_harbor_bellhouse_recovery.py
python tools/test_validate_drowned_harbor_bellhouse_recovery.py
python tools/validate_drowned_harbor_low_tide_shell_p016.py
python tools/test_validate_drowned_harbor_low_tide_shell_p016.py
python tools/validate_drowned_harbor_projection_fixtures_p016.py
python tools/test_validate_drowned_harbor_projection_fixtures_p016.py
python tools/validate_drowned_harbor_prototype_isolation.py
python tools/test_validate_drowned_harbor_prototype_isolation.py
```

Godot 4.7.1-stable:

```bash
godot --headless --path game --script res://tests/drowned_harbor_bellhouse_recovery_test.gd
godot --headless --path game --script res://tests/drowned_harbor_low_tide_shell_test.gd
godot --headless --path game --script res://tests/drowned_harbor_prototype_isolation_test.gd
```

Drowned Harbor remains development-only and absent from the production Tale catalog and provider. Lantern House remains the sole production/default Tale. Issue #39 remains the human-evidence authority, and issue #44 remains the separate Companion dependency-remediation authority.
