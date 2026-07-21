# Tale Catalog Contract

## Supported catalog

v0.1.5 supports one closed repository catalog kind, `tale_catalog`, at schema/content version `1`/`1`. The production catalog is `game/data/tales/tale_catalog_v1.json`; its canonical SHA-256 is `2b478fd0d11fa075c2050409193aa06e6b9ca4dcf6efd4e4c550a9f3a5ff9db6`. It contains exactly one sorted entry and defaults to `lantern_house_vertical_slice`.

The entry binds the stable Tale ID to the repository-relative package path, exact `tale` kind/schema/version, accepted package SHA-256, governed display catalog and keys, and the reviewed `lantern_house_authorities_v1` provider set. Its source ledger has exactly one governed-display, provider-registry, and Tale-package role for the entry.

## Identity and validation

Canonical input is compact UTF-8 JSON with lexicographically sorted object keys and authored array order preserved. Every field participates in SHA-256. Entries and source-ledger records have separately enforced stable order. Unknown fields, malformed kind/schema/version, duplicate IDs or roles, invalid defaults, unsafe/unresolved paths, package or display hash drift, Tale mismatch, unknown providers, provider-reference drift, secrets, URLs, scripts/classes/executables, generated paths, and unstable identity reject with a stable code, JSON path, and actionable message.

`python tools/tale_catalog.py validate` is the production offline gate. It creates no files and imports no network, subprocess, telemetry, upload, cloud, or AI client. `TaleCatalog.load_validated` independently checks the reviewed digest and provider/package/display coherence at runtime.

Catalog and package digests are provenance only. They may appear in internal build manifests and automated smoke evidence, but remain absent from gameplay snapshots, public history, saves, schema-v2 reports, companion authority, RNG, and outcomes.

## Production and test separation

The production inventory contains only Lantern House. Multi-entry, non-default-selection, provider-failure, and changed-identity fixtures live below `game/tests/`, carry unmistakable synthetic markers, and are excluded by both export presets. They are not playable production Tales, player-visible inventory, marketing entries, locked content, or future-content promises.
