# Drowned Harbor development-only fixtures and shell

Everything in this directory is synthetic, test-only, and excluded from ordinary Windows and Linux exports by the existing `tests/*` export rule.

## Current package

- `state_projection_fixture_schema_v1.json` — closed P0.14 fixture schema.
- `state_projection_fixtures_v1.json` — six deterministic fixtures bound to P0.11 interaction traces.
- `low_tide_fixture_adapter.gd` — fail-closed public reader for `DH-FIX-001`.
- `low_tide_shared_screen_shell.gd` — controller-first Low Tide presentation and intent shell.
- `low_tide_shared_screen_shell.tscn` — explicit test-only scene using placeholder geometry.

## P0.15 shell boundary

The Low Tide shell presents synthetic public fixture data for `DH-UI-003`, `DH-IS-003`, and `DH-FIX-001`:

- public stage objective and returning-tide state;
- Underteller host-authority area;
- placeholder board geography for the damaged causeway, Bellhouse, Salt Market, lifeboat shed, and distant lighthouse;
- stable-seat rail and active focus text;
- persistent captions, legal actions, prompts, status, and recovery messaging;
- inspect, preview, cancel, explicit revision-bound confirmation, transcript-open, and replay intent seams.

The shell does not implement movement, encounters, items, action points, balance, a reducer, production saves, networking, Companion behavior, Tale completion, High Water, Bellhouse commitment, private bargains, transformations, or ending logic.

## Privacy and evidence boundary

Only public and approved seat-public fields are projected. Private fixture markers are deliberately present in the source fixture so tests can prove they do not enter the public screen, captions, transcript, replay, diagnostics, or public events.

Automated input coverage proves semantic controller mappings and keyboard fallback paths only. It is not physical-controller evidence, television-readability evidence, accessibility certification, privacy certification, fun evidence, fairness evidence, balance evidence, or household playtest evidence.

## Validation

From the repository root:

```bash
python tools/validate_drowned_harbor_low_tide_shell.py
python tools/test_validate_drowned_harbor_low_tide_shell.py
python tools/validate_drowned_harbor_projection_fixtures.py
python tools/test_validate_drowned_harbor_projection_fixtures.py
python tools/validate_drowned_harbor_prototype_isolation.py
python tools/test_validate_drowned_harbor_prototype_isolation.py
```

Godot 4.7.1-stable:

```bash
godot --headless --path game --script res://tests/drowned_harbor_low_tide_shell_test.gd
godot --headless --path game --script res://tests/drowned_harbor_prototype_isolation_test.gd
```

Drowned Harbor remains development-only and absent from the production Tale catalog and provider. Lantern House remains the sole production/default Tale. Issue #39 remains the human-evidence authority, and issue #44 remains the separate Companion dependency-remediation authority.
