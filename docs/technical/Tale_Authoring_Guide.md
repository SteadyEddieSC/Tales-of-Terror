# Tale Authoring Guide

This guide covers the reviewed repository-authored Tale package and catalog schema v1 contracts. It is not a public modding SDK and does not authorize downloaded packages, arbitrary scripts, callbacks, remote content, or untrusted execution.

## Layout and versioning

Place reviewed runtime JSON below `game/data/tales/<tale_id>/`. Keep the Tale envelope separate from the existing authority definitions it references. Use package kind `tale`, schema `1`, a lowercase snake_case stable Tale ID, and a positive authored package version. Schema changes require a new ADR; content revisions require review and a new package identity.

Stable IDs are persistence and replay contracts. Never rename or reuse an event, card, item, board, location, role, faction, form, objective, transition, mode, stage, narration key, or Tale ID merely for presentation. Propose semantic changes separately from package migration.

## Vocabulary, sources, and fallbacks

Schema v1 composes the existing Lantern House board, rules, Director, social content, and vertical-slice stage operations. It declares graph/compatibility/fallback/privacy/inventory/source contracts. It cannot name executable scripts, expressions, URLs, generated files, private evidence, secrets, or new runtime behavior.

References must resolve to reviewed repository sources. Source-ledger paths are repository-relative, sorted, unique, and consumed by one supported role. `res://` is allowed only for runtime resources. Absolute user paths, `.evidence`, build/output/cache paths, tests as shipped content, and network URLs reject.

Lantern House declares exactly 1–8 stable seats. Hidden Betrayer remains the default where supported; cooperative remains the accepted fallback. The package must declare an actionable no-phone route, native-authority behavior when optional companions are unavailable, and fail-closed behavior for unsupported optional features. Required afterlife roles must be a non-empty subset of the declared roles.

## Privacy, text, and ordering

Classify governed values as `public`, `controlled_reveal_private`, `seat_private`, or `faction_private`. Every governed localization or narration key must resolve; extra localization records are rejected as orphans. The v0.1.5 repository Tale catalog repeats the exact governed display, briefing, and objective references needed for pre-session presentation and must match the package.

Sort inventory IDs, source-ledger paths, privacy keys, compatibility lists, and graph edges. Preserve explicit authored order only where order is semantic, such as `stage_order`. The validator canonicalizes object keys and preserves arrays.

Run:

```text
python tools/tale_package.py validate
python tools/tale_package.py identity
python tools/test_tale_package.py
python tools/tale_catalog.py validate
python tools/tale_catalog.py identity
python tools/test_tale_catalog.py
Godot_v4.7.1-stable --headless --path game --script res://tests/tale_package_test.gd
Godot_v4.7.1-stable --headless --path game --script res://tests/tale_catalog_test.gd
Godot_v4.7.1-stable --headless --path game --script res://tests/tale_replay_equivalence_test.gd
```

Diagnostics contain `code`, JSON/source `path`, and a correction-oriented message. Codes cover unsupported schema, missing fields, duplicates, unresolved references/text, invalid or unreachable transitions, player counts, social compatibility, fallbacks, orphans, privacy, unsafe paths/URLs/secrets/generated references, ordering, and identity.

Synthetic package/catalog/provider fixtures below `game/tests/` are test input only, explicitly not shipped Tale content, and excluded by both portable export presets.

## Future Tales

Open a separately reviewed design/content issue describing vocabulary reuse, new authority needs, stable IDs, source provenance, privacy, seat/mode/fallback policy, replay evidence, and semantic changes. After that review, add a validated package, a static provider registration, governed display references, sorted catalog/source records, a new catalog digest, and full compatibility evidence. Editing the catalog alone never authorizes a future Tale. Do not copy Lantern House or add literal content-ID branches to generic runtime code.
