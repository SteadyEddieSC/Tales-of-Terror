# Quality follow-up: Actionlint and dependency review

## Summary

Adds two free, low-maintenance checks to the repository-controlled automated assurance baseline:

- checksum-pinned Actionlint `1.7.12` with embedded ShellCheck analysis for GitHub Actions workflows;
- immutable-pinned GitHub Dependency Review Action `5.0.0` for pull-request dependency changes.

## Scope

- `.github/workflows/actionlint.yml`
- `.github/workflows/dependency-review.yml`
- `quality/run_quality.py`
- `docs/technical/Workflow_and_Dependency_Review.md`
- this release record

## Policy

Actionlint is blocking and scans all repository workflows whenever workflow definitions change. Dependency review blocks newly introduced high or critical vulnerabilities across runtime, development, and unknown scopes. License information remains visible but no broad license allowlist or denylist is introduced in this release.

The existing Gitleaks, Zizmor, deterministic workflow policy, CodeQL, npm audit, pip audit, Dependabot, SBOM, Godot, companion, asset, snapshot, and export controls remain in place.

## Boundaries

This release changes no gameplay, Godot scenes, scripts, resources, input mappings, save/state behavior, art, audio, Drowned Harbor runtime authority, catalog/provider admission, export contents, public-release status, signing, telemetry, paid-service use, or automatic-merge behavior.
