# Drowned Harbor development-only fixtures and shells

Everything in this directory is synthetic, test-only, and excluded from ordinary Windows and Linux exports by the existing `tests/*` export rule.

## Current package

- `state_projection_fixture_schema_v1.json` — closed P0.17 fixture schema.
- `state_projection_fixtures_v1.json` — seven deterministic fixtures bound to governed interaction traces.
- `low_tide_fixture_adapter.gd` — fail-closed public reader for `DH-FIX-001`.
- `low_tide_shared_screen_shell.gd` — controller-first Low Tide presentation and intent shell.
- `low_tide_shared_screen_shell.tscn` — explicit test-only Low Tide scene using placeholder geometry.
- `bellhouse_fixture_adapter.gd` — fail-closed public readers for `DH-FIX-002` and `DH-FIX-006`.
- `bellhouse_decision_shell.gd` — controller-first Bellhouse decision and recovery shell.
- `bellhouse_decision_shell.tscn` — explicit test-only Bellhouse scene using placeholder geometry.
- `controlled_private_fixture_adapter.gd` — exact request and revision binding for `DH-FIX-003` and `DH-FIX-007`.
- `controlled_private_surface.gd` — local deterministic private-surface abstraction and clearing lifecycle.
- `controlled_private_shield_shell.gd` — information-neutral shared-screen shield and sanitized restoration shell.
- `controlled_private_shield_shell.tscn` — explicit test-only controlled-private scene.

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

## P0.17 controlled-private shield boundary

The P0.17 proof binds `DH-FIX-003` to `DH-UI-007` / `DH-IS-007` and the new `DH-FIX-007` to `DH-UI-016` / `DH-IS-016`. An information-neutral neutral shield replaces the public presentation before a private payload is requested. Only the authorized test-only surface receives synthetic private content; confirm is not the default focus, and acceptance requires an explicit current-revision acknowledgement.

The local abstraction binds stable seat, controller authority, source revision, handoff identity and revision, expected trace, and a deterministic fixture counter. It has no network, account, Companion, device, cloud, or telemetry behavior. Semantic Confirm on the governed Refuse focus runs an explicit no-commit refusal path, separate from B/Escape cancellation/deferral. Before sanitized public restoration or after refusal it clears its private payload, event, presentation, focus, acknowledgement, binding, caption/audio requests, adapter, and shell projection state. After commitment, semantic Cancel rejects non-destructively and interruption moves or remains in recovery; both preserve the pending sanitized result and deterministic restoration route without admitting another handoff or emitting a duplicate.

Exactly-once tracking is scoped to deterministic fixture/handoff/source/result/event identities. Aggregate counts are evidence only. A single shell can complete DH-FIX-003 and DH-FIX-007 sequentially, retain both authorized sanitized public histories, and reject only true retries without clearing one layer before duplicate validation.

The no-phone fallback stays neutral, permits governed cancellation, deferral, and Help, and commits nothing. `DH-FIX-007` retains the same stable seat and existing state; it does not heal, reroll, restore inventory, reset objectives or conditions, erase history, or change ending identity.

## Privacy and evidence boundary

Only public and approved seat-public fields are projected. Private fixture markers are deliberately present in the source fixtures so tests can prove they do not enter the public screen, captions, transcript, replay, diagnostics, recovery, or events.

Automated input coverage proves semantic controller mappings and keyboard fallback paths only. It is not physical-controller evidence, television-readability evidence, accessibility certification, privacy certification, fun evidence, fairness evidence, balance evidence, or household playtest evidence.

## Validation

From the repository root:

```bash
python tools/validate_drowned_harbor_bellhouse_recovery.py
python tools/test_validate_drowned_harbor_bellhouse_recovery.py
python tools/validate_drowned_harbor_controlled_private_shield.py
python tools/test_validate_drowned_harbor_controlled_private_shield.py
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
godot --headless --path game --script res://tests/drowned_harbor_controlled_private_shield_test.gd
godot --headless --path game --script res://tests/drowned_harbor_low_tide_shell_test.gd
godot --headless --path game --script res://tests/drowned_harbor_prototype_isolation_test.gd
```

Drowned Harbor remains development-only and absent from the production Tale catalog and provider. Lantern House remains the sole production/default Tale. Issue #44 is completed. Issue #39 remains the deferred human-evidence authority. Issues #85 and #86 remain blocked.
