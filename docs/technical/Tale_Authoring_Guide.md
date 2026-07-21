# Tale Authoring Guide

This guide covers the reviewed repository-authored Tale schema v1. It is not a public modding SDK and does not authorize downloaded packages, arbitrary scripts, callbacks, remote content, or untrusted execution.

## Layout and versioning

Place reviewed runtime JSON below `game/data/tales/<tale_id>/`. Keep the Tale envelope separate from the existing authority definitions it references. Use package kind `tale`, schema `1`, a lowercase snake_case stable Tale ID, and a positive authored package version. Schema changes require a new ADR; content revisions require review and a new package identity.

Stable IDs are persistence and replay contracts. Never rename or reuse an event, card, item, board, location, role, faction, form, objective, transition, mode, stage, narration key, or Tale ID merely for presentation. Propose semantic changes separately from package migration.

## Vocabulary, sources, and fallbacks

Schema v1 composes the existing Lantern House board, rules, Director, social content, and vertical-slice stage operations. It declares graph/compatibility/fallback/privacy/inventory/source contracts. It cannot name executable scripts, expressions, URLs, generated files, private evidence, secrets, or new runtime behavior.

References must resolve to reviewed repository sources. Source-ledger paths are repository-relative, sorted, unique, and consumed by one supported role. `res://` is allowed only for runtime resources. Absolute user paths, `.evidence`, build/output/cache paths, tests as shipped content, and network URLs reject.

Lantern House declares exactly 1–8 stable seats. Hidden Betrayer remains the default where supported; cooperative remains the accepted fallback. The package must declare an actionable no-phone route, native-authority behavior when optional companions are unavailable, and fail-closed behavior for unsupported optional features. Required afterlife roles must be a non-empty subset of the declared roles.

## Privacy, text, and ordering

Classify governed values as `public`, `controlled_reveal_private`, `seat_private`, or `faction_private`. Every governed localization or narration key must resolve; extra catalog records are rejected as orphans. The catalog mirrors accepted player-visible text while the existing manifest remains runtime presentation input in v0.1.4.

Sort inventory IDs, source-ledger paths, privacy keys, compatibility lists, and graph edges. Preserve explicit authored order only where order is semantic, such as `stage_order`. The validator canonicalizes object keys and preserves arrays.

Run:

```text
python tools/tale_package.py validate
python tools/tale_package.py identity
python tools/test_tale_package.py
Godot_v4.7.1-stable --headless --path game --script res://tests/tale_package_test.gd
Godot_v4.7.1-stable --headless --path game --script res://tests/tale_replay_equivalence_test.gd
```

Diagnostics contain `code`, JSON/source `path`, and a correction-oriented message. Codes cover unsupported schema, missing fields, duplicates, unresolved references/text, invalid or unreachable transitions, player counts, social compatibility, fallbacks, orphans, privacy, unsafe paths/URLs/secrets/generated references, ordering, and identity.

The synthetic fixture at `game/tests/fixtures/tale_package_invalid_cases_v1.json` is test input only and is explicitly not shipped Tale content.

## Future Tales

Open a bounded design issue describing vocabulary reuse, new authority needs, stable IDs, source provenance, privacy, seat/mode/fallback policy, replay evidence, and semantic changes. Do not copy Lantern House or add literal content-ID branches to generic runtime code.
