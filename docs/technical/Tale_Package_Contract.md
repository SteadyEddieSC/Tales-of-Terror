# Tale Package Contract

## Supported contract

v0.1.4 supports one repository-authored package kind, `tale`, at schema version `1`. The reviewed package is `game/data/tales/lantern_house/tale_package_v1.json`; its stable Tale ID remains `lantern_house_vertical_slice`, its authored package version is `1`, and its canonical SHA-256 is `abb39d6bfbdf8d7de108379f08180c13efb99bbffa3e53f30eaaa8de7f459dee`.

Schema v1 is closed: every object governed by the validator uses an exact field set and unknown fields reject. A future schema or package identity requires review, tests, and an updated runtime allowlist. There is no best-effort forward compatibility, arbitrary script field, remote package, dynamic code generation, or untrusted-package execution.

## Envelope

The package declares kind/schema/identity, display and content profiles, engine/seat/mode compatibility, existing authority references, an explicit stage graph, required fallbacks, privacy classifications, governed text keys, complete existing-content inventories, social/afterlife compatibility, a source ledger, and the identity policy.

The package references the accepted authority data instead of duplicating it. The existing manifest continues to describe the five bounded operation stages. `BoardState`, `RulesSession`, Director runtime, and `RoleSession` remain authoritative exactly as before.

## Canonical identity

Canonical input is UTF-8 compact JSON with object keys sorted lexicographically and arrays preserved in authored order. SHA-256 is computed over those bytes; no package fields are excluded. The scenario manifest and governed-key catalog carry reviewed file SHA-256 values inside the package.

The package digest is provenance/presentation metadata. It is deliberately absent from gameplay snapshots, authority digests, public history, save restoration decisions, and schema-v2 reports. Build manifests and automated smoke output may carry it. Build timestamps and evidence presentation are separately non-authoritative and excluded from replay comparison.

## Runtime boundary

`TalePackage.load_validated` accepts only the allowlisted Lantern House identity, verifies referenced JSON hashes, re-runs the existing manifest/authority validation, and compares the declared inventory with instantiated reviewed content. The coordinator constructs no authority until this succeeds. A legacy direct-manifest path, missing or mutated package, mismatched source hash, unsupported identity, or inventory mismatch fails closed with a developer-facing code, source path, and message without partial session mutation.

The package does not affect stable IDs, RNG streams, event/card behavior, roles/factions/afterlife, endings, reports, companions, reset, rematch, or the no-phone path.
