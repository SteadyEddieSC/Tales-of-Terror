# ADR-0024: Automated Quality, Security, and Export Baseline

- **Status:** Proposed for review
- **Date:** 2026-08-05
- **Decision scope:** repository-wide development assurance; no gameplay, art, audio, Tale-admission, publication, or release-authority change

## Context

Terror Turn already has a strong Godot 4.7.1 foundation: checksum-pinned engine downloads, vendored GUT 9.7.1, deterministic direct `SceneTree` suites, GDScript Toolkit gates, locked Node/Python dependencies, internal Windows/Linux export presets, and exact-head portable-build smoke validation. The missing layer is one maintained baseline that treats scene/resource integrity, input/configuration policy, synthetic snapshot compatibility, asset budgets, evidence capture, workflow security, secret detection, supported-language static analysis, and export metadata as one explicit assurance system.

The repository does not currently expose a disk-backed player save-slot service. Its authoritative persistence boundary is the versioned `to_snapshot` / `restore_snapshot` contract implemented by the coordinator and gameplay authorities. Creating a new save architecture only to satisfy a testing checklist would be premature and could alter approved runtime behavior.

The active Drowned Harbor governance release is metadata-only and prohibits runtime, visual, source-art, UX, and implementation changes. This decision therefore excludes all Drowned Harbor governed content paths and does not change Tale admission, authority, assets, or release status.

## Decision

1. Retain **Godot 4.7.1** and the existing **GUT 9.7.1** installation. No engine or test-framework upgrade is introduced.
2. Add a dependency-free Python validator for project configuration, production-scene discovery, resource paths, UID duplication, structured data, asset budgets, input mappings, export policy, workflow pinning, and synthetic snapshot fixtures.
3. Add a standalone Godot `SceneTree` baseline test that:
   - loads and instantiates every first-party production scene discovered beneath `res://`;
   - validates required keyboard/controller input actions;
   - exercises deterministic coordinator initialization using seed `4706`;
   - verifies current snapshot round-trip determinism;
   - proves future-version, missing-field, and unknown-field rejection is atomic;
   - records broad startup/load/snapshot timing and orphan-node smoke metrics.
4. Add one branch-capable quality workflow that runs the inherited repository validators, complete direct Godot test surface, GUT JUnit suite, companion tests and native-authority E2E, clean Windows/Linux exports, Linux exported-artifact smoke, checksums, dependency inventories, add-on inventory, and CycloneDX npm SBOM.
5. Add Gitleaks as a blocking full-history secret scan using a checksum-pinned binary.
6. Add Zizmor for full workflow analysis. Existing high-risk structural requirements—immutable action pins, least-privilege permission blocks, and prohibition of `pull_request_target`—are blocking through the deterministic validator. Full Zizmor findings are advisory until individually reviewed, because broad automatic suppression or retroactive failure on untriaged informational findings would be unsafe.
7. Add CodeQL for the repository's supported **JavaScript/TypeScript** and **Python** sources. CodeQL is not represented as GDScript coverage.
8. Expand Dependabot to GitHub Actions, npm, and pip with grouped minor/patch updates and no automatic merge.
9. Preserve all existing internal-only export classifications, denylisted test/development resources, unsigned packaging, and non-publication behavior.

## Blocking checks

- Python validator self-tests;
- project/configuration, production scene/resource, UID, data, input-map, export-policy, and workflow-policy validation;
- asset size/header/case-collision budgets;
- all inherited repository policy validators;
- GDScript lint and formatting;
- complete headless Godot direct tests and GUT;
- companion typecheck/tests/build/native-authority E2E;
- high-severity npm audit;
- Gitleaks repository/history scan;
- exact-head Windows and Linux export;
- Linux exported-artifact smoke;
- checksum and metadata generation;
- fail-closed log classification for parser/load/crash indicators;
- CodeQL workflow execution for supported languages.

## Advisory checks

- duplicate assets by content hash;
- potential unused/orphan assets where static confidence is insufficient;
- dense but potentially intentional input-binding overlap;
- lowercase asset naming drift inherited from approved/vendor content;
- full Zizmor finding set pending finding-by-finding disposition;
- Python tooling vulnerability audit pending ecosystem severity mapping;
- broad CI performance measurements, which are regression smoke signals rather than player-hardware benchmarks.

## Save compatibility policy

- Current authoritative coordinator snapshot version: **2**.
- Current-version snapshots must round-trip deterministically and preserve gameplay-critical state.
- Invalid transitions and failed restores must not mutate existing state.
- Future versions, missing required fields, and unknown fields must be rejected rather than silently discarded.
- Synthetic fixtures are test-only and contain no user data.
- Disk corruption, truncation, multi-slot behavior, filesystem recovery, and prior retail-save migration become blocking requirements when a disk-backed save service is introduced. They are not falsely claimed as implemented today.

## Consequences

The development agent receives a single local command surface and pre-PR branch workflows that provide reproducible evidence with little or no manual setup. CI runtime increases because the branch workflow intentionally exercises the full inherited Godot and companion surface plus clean exports. Thresholds are deliberately broad to catch major regressions without pretending GitHub-hosted hardware represents player hardware.

Automation does not replace gameplay-feel review, art-direction review, audio review, balancing, accessibility review, physical-device/controller testing, player usability testing, store certification, code signing, or final release approval.
