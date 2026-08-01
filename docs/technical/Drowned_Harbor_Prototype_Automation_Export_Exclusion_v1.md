# Drowned Harbor Prototype Automation and Export Exclusion v1

## Authority and scope

This document is the P0.19 technical authority for issue #86. It closes the currently authorized isolated-prototype automation boundary after merge. It authorizes no successor implementation issue, no new gameplay interaction, and no production runtime component.

The automated profile is `DH-AUTO-P019-V1`. It is synthetic, deterministic, headless, machine-only evidence launched explicitly through `res://tests/drowned_harbor_prototype_automation_test.gd`. The profile, matrix, manifest, adapters, shells, fixture package, and scenes remain under `res://tests/` and ordinary Windows and Linux exports continue to exclude `tests/*`.

## Implemented and projection-only inventory

The aggregate matrix reuses the existing adapters and shells for:

- Low Tide `DH-FIX-001` (`DH-IS-003` / `DH-UI-003`);
- Bellhouse decision `DH-FIX-002` and recovery `DH-FIX-006`;
- controlled-private handoffs `DH-FIX-003` and `DH-FIX-007`;
- High Water `DH-FIX-004`, including the `DH-IS-009` / `DH-UI-009` transformed-board obligations.

`DH-FIX-005` remains projection-only through the existing fixture engine. P0.19 creates no Tidebound shell, scene, reducer, or interaction. The fixture inventory remains exactly `DH-FIX-001` through `DH-FIX-007` and the thirteen existing prototype components remain unchanged.

## Deterministic matrix

The profile declares twelve closed sequence identities. Every sequence runs twice with fresh shell instances where independence matters. Canonical sorted-key JSON evidence is compared between repetitions. The cases cover forward and reverse family order, full and skipped High Water presentation, controlled-private surface unavailability, disconnect and interruption, Bellhouse recovery-first, stale revision, wrong authority, wrong stable seat, duplicate and replay idempotence, fresh-shell equivalence, and post-commit reprojection.

Every governed case uses a finite step bound of 32 and no wall-clock timing. A pass means the bounded matrix reached a completed, rejected-without-mutation, or blocked-but-restorable state. It does not prove the absence of defects outside that matrix.

Private fixture values are never placed in the bounded summary. Public evidence reports only counts, digests, profile identity, deterministic equivalence, privacy-leak findings, deadlock findings, and authority/evidence denials. Controlled-private interruption and disconnect must clear application-level private content before public restoration. High Water full and semantic-skip paths must retain byte-equivalent governed evidence.

## Export-exclusion proof

Static validation verifies the unchanged two-preset `tests/*` exclusion, catalog/provider/default-Tale boundary, project startup, profile, manifest, workflows, UID, and closed marker sources. Dynamic native-export validation scans exact-head Windows and Linux export logs and binaries. Bundle validation separately scans assembled file inventories, every bundle file, and the bundle manifest.

The marker set includes test paths, all fixture IDs, exact public prototype markers, profile and manifest names, entry-point and component filenames, and exact private sentinels derived from the fixture package. Emitted evidence reports safe identifiers and hit counts, never sentinel contents. Each platform record includes the exact source SHA, preset, native size and SHA-256, export-log SHA-256, bundle inventory and manifest digests, production catalog and Lantern House identities, hit counts, classification, and `human_evidence_claimed: false`.

Generated evidence is kept outside governed portable inner bundles and removed after validation. The Windows and Linux portable contents, names, launchers, release identity, smoke behavior, and manifests remain governed by the existing portable contract.

## Production invariance

Lantern House remains the sole production/default Tale. Its catalog SHA-256 remains `2b478fd0d11fa075c2050409193aa06e6b9ca4dcf6efd4e4c550a9f3a5ff9db6`; its package SHA-256 remains `abb39d6bfbdf8d7de108379f08180c13efb99bbffa3e53f30eaaa8de7f459dee`. No Drowned Harbor provider, production Tale package, save/report authority, input action, Companion path, network dependency, telemetry, credential, cloud dependency, or production asset is created.

## Machine evidence boundary

This automation is not a human playtest and does not establish physical-controller behavior, television readability, accessibility compliance, privacy or security certification, human comprehension, fun, tension, pacing, fairness, balance, household playtesting, remote-device behavior, public-release readiness, or production readiness. Issue #39 remains the human-evidence authority. P0.19 does not claim evidence governed by that issue.

The mutation suite reports its actual executed count at runtime; this document does not predeclare a passing mutation count.
