# Automated Validation, Security, Asset, and Export Baseline

## Release classification

Development-assurance infrastructure only. This change does not authorize or implement gameplay redesign, new Tale content, Drowned Harbor runtime/presentation/source-art/UX work, engine upgrade, telemetry, paid services, public distribution, store publication, code signing, or automatic release/merge.

## Source baseline

- Protected `main`: `3ad17fbbf2ae8c2bf52c8535ba8936ea8b858dcb`
- Godot: `4.7.1.stable.official.a13da4feb`
- GUT: `9.7.1`
- Normal playable version: `v0.1.9`
- Primary export validation: internal Windows x86_64
- Additional export/smoke: internal Linux x86_64

## Added

- deterministic repository validator and mutation-style unit tests;
- production scene discovery/load/instantiate/release smoke;
- project/resource/UID/input/export/structured-data checks;
- snapshot compatibility and atomic state-transition tests;
- configurable texture/audio/file budgets and asset reports;
- broad performance regression smoke metrics;
- complete branch-capable quality/test/export workflow;
- Gitleaks full-history secret detection;
- Zizmor workflow-security analysis plus blocking structural workflow policy;
- CodeQL for JavaScript/TypeScript and Python;
- Dependabot coverage for GitHub Actions, npm, and pip;
- Windows/Linux exact-head exports, Linux artifact smoke, SHA-256 checksums, build metadata, dependency inventories, add-on inventory, and npm SBOM;
- local cross-platform command surface and detailed operating documentation.

## Blocking versus advisory

Blocking checks cover correctness, parser/import/resource/scene failures, current deterministic snapshot compatibility, asset budget/header/case collisions, complete headless tests, high dependency vulnerabilities, secrets, high-risk workflow configuration, and export/smoke failures.

Advisory checks cover potential unused assets, duplicate asset hashes, inherited naming drift, full Zizmor findings pending individual triage, Python tooling vulnerabilities without severity mapping, and broad CI performance trends.

## Save compatibility boundary

No disk-backed save-slot system exists in the authoritative project. The implemented tests therefore target the real versioned snapshot contract. Future, unknown, or incomplete snapshots are rejected atomically and are never silently discarded. Disk corruption recovery and multiple slots remain explicit future requirements when a save service exists.

## Evidence expected from the draft pull request

- all workflow conclusions and exact run URLs;
- current pass/fail counts;
- GUT JUnit and complete Godot logs;
- scene/resource/asset/security reports;
- deterministic seed and performance measurements;
- export sizes, hashes, metadata, and Linux smoke output;
- accepted-warning and exception list;
- residual manual validation list.

## Explicit non-actions

No gameplay behavior, engine version, approved artwork/audio, default Tale, provider/catalog route, release classification, signing configuration, telemetry, external account, paid SaaS, store listing, public release, or merge is changed by this baseline.
