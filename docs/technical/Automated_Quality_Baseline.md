# Automated Quality Baseline

## Purpose

This baseline provides deterministic local and GitHub-native checks for Terror Turn without paid services, new accounts, telemetry, automatic publication, or automatic merge. It extends the existing Godot 4.7.1, GUT 9.7.1, GDScript Toolkit, companion, and portable-build systems rather than replacing them.

## Tool versions

| Tool | Version / pin | Role |
| --- | --- | --- |
| Godot | `4.7.1-stable` | import, parser, headless startup, tests, scenes, exports, smoke |
| GUT | `9.7.1` vendored | focused unit/boundary tests and JUnit |
| GDScript Toolkit | repository lock | lint and format-check |
| Python | `3.11.9` | deterministic repository validators |
| Node | `24.18.0` | companion tests/build/audit/SBOM |
| Gitleaks | `8.30.1`, release archive SHA-256 pinned | secret scanning |
| Zizmor | CLI `1.26.1`, PyPI wheel SHA-256 pinned | workflow security analysis |
| CodeQL Action | `4.35.2`, immutable commit | JavaScript/TypeScript and Python static security analysis |

## Local commands

Run from the repository root. `GODOT_BIN` may be an absolute path to the Godot 4.7.1 console executable.

```powershell
$env:GODOT_BIN = 'C:\Users\Eddie\Documents\Codex\Tools\Godot\4.7.1-stable\Godot_v4.7.1-stable_win64_console.exe'
python quality/run_quality.py static
python quality/run_quality.py godot --godot $env:GODOT_BIN
python quality/run_quality.py all --godot $env:GODOT_BIN
```

Focused static commands:

```powershell
python quality/validate_repository.py config
python quality/validate_repository.py references
python quality/validate_repository.py assets
python quality/validate_repository.py data
python quality/validate_repository.py workflows
python quality/validate_repository.py save-fixtures
python -m unittest discover -s quality -p 'test_*.py' -v
```

Gitleaks and Zizmor are installed by CI with checksum-pinned versions. Local equivalents, when already installed, are:

```powershell
gitleaks git . --log-opts='--all' --redact --no-banner
zizmor --offline .github/workflows
```

## GitHub Actions

### Automated quality baseline

Runs on pull requests, pushes to `main`, `agent/**`, `release/**`, and `rc/**`, plus manual dispatch. The single job:

1. verifies checksum-pinned Godot editor and export templates;
2. runs validator tests and all static validation scopes;
3. runs inherited repository policy validators;
4. enforces GDScript lint and formatting;
5. imports the project, starts the main scene, runs every established direct Godot suite, runs the new scene/config/snapshot baseline, and runs GUT with JUnit;
6. runs companion typecheck, tests, build, native-authority E2E, and high-severity dependency audit;
7. performs clean exact-head Windows and Linux exports;
8. launches the exported Linux artifact in portable-build smoke mode;
9. generates SHA-256 checksums, project/tool/build metadata, dependency inventories, add-on inventory, and a CycloneDX npm SBOM;
10. classifies logs and uploads evidence even when a check fails.

### Security baseline

Runs on the same development branches, pull requests, weekly schedule, and manual dispatch.

- **Gitleaks:** blocking scan of repository content and complete fetched history. `.gitleaks.toml` extends the default rules. `.gitleaksignore` contains only an exact reviewed fingerprint for one historical prose false positive; no path-wide or rule-wide suppression exists.
- **Workflow policy:** blocking deterministic checks for immutable action pins, explicit permissions, and dangerous triggers.
- **Zizmor:** full-repository advisory scan while findings are triaged. A Zizmor non-success is retained in the evidence artifact; it does not override the blocking structural policy.
- **npm audit:** blocks on high/critical findings in the locked graph.
- **pip-audit:** advisory for the development-only Python lock until severity-aware disposition is available.

### CodeQL

Runs `security-extended` queries for JavaScript/TypeScript and Python. GDScript is covered by Godot parsing, GDScript Toolkit, deterministic tests, resource checks, and targeted review—not CodeQL.

## Scene and resource validation

The baseline discovers every first-party `.tscn` beneath `game/`, excluding vendored add-ons and tests. Each scene is loaded, instantiated, attached to the tree for a frame, released, and measured. The static validator independently checks text scene/resource references for missing paths, case mismatch, boundary escapes, duplicate external-resource IDs, invalid/duplicate first-party UID files, and generated-resource exceptions.

Missing references in `.tscn`, `.tres`, and project configuration are blocking. Script-string references are advisory because scripts legitimately contain negative-test and generated-path values; Godot parser/import and scene tests remain the runtime truth.

## Input-map checks

Required gameplay and UI actions must exist, contain at least one event, and retain controller support where intended. Binding overlap is advisory unless it removes a required binding. Debug actions may remain only because current export presets are explicitly classified `internal_playtest`; no public/release preset is created.

## Save and state testing

Terror Turn currently persists deterministic versioned snapshots, not disk-backed player save slots. Tests cover:

- deterministic seed `4706`;
- title → lobby → confirmation → briefing → active Tale transitions;
- invalid-transition atomicity;
- current snapshot serialization and round trip;
- gameplay-critical state preservation;
- future-version rejection;
- missing-field rejection;
- unknown-field rejection;
- no mutation on failed restore;
- deliberately truncated synthetic fixture validation at the file-policy layer.

No unsupported save data is silently discarded. Multi-slot and filesystem recovery tests are reserved for the future disk save service.

## Asset budgets

Budgets are configured in `quality/quality_config.json`:

- maximum texture dimension: 8192 px;
- maximum individual texture: 32 MiB;
- maximum total textures: 512 MiB;
- maximum individual audio: 64 MiB;
- maximum total audio: 1 GiB;
- maximum other runtime asset: 95 MiB.

Header/extension mismatch, case collisions, and exceeded budgets block. Duplicate hashes and naming drift are advisory. The validator never recompresses or modifies approved art/audio.

## Performance smoke policy

Broad thresholds catch major regressions:

- production scene load: 5 seconds per scene;
- deterministic coordinator initialization: 5 seconds;
- snapshot round trip: 1 second.

Results are written to `game/test-results/quality-baseline.json`. They are CI smoke measurements, not claims about player hardware, frame pacing, or final performance.

## Failure evidence

The quality artifact retains:

- validator JSON/text reports;
- GDScript inventory, lint, and format results;
- complete Godot console output and JUnit;
- deterministic failure seed;
- scene/load/snapshot metrics;
- companion test/build/E2E logs;
- Godot/export logs and error classification;
- crash/screenshot directories when tools create them;
- Windows/Linux exported builds;
- SHA-256 checksums and build metadata;
- npm CycloneDX SBOM, Python inventory, and Godot add-on inventory.

Security artifacts retain Gitleaks SARIF, npm/pip audit output, workflow-policy reports, and Zizmor disposition.

## Warning and false-positive policy

Blocking errors are parser failures, missing/invalid resources, scene-load failures, failed assertions, invalid accesses identified in logs, crashes, export failures, secret findings, high dependency vulnerabilities, or high-risk workflow-policy violations.

Accepted warning patterns are narrowly listed in `quality/quality_config.json`. New exceptions require an exact pattern or fingerprint, a reason, an owner, and review in the pull request. Broad path or rule suppression is prohibited.

## Residual manual validation

Automation does not replace:

- gameplay feel and pacing review;
- art-direction and visual-composition review;
- audio quality and mix review;
- physical Windows/Linux device testing;
- real controller hot-plug, identical-controller, and multi-controller testing;
- television/readability and safe-area review;
- player usability and household playtesting;
- balancing and difficulty review;
- accessibility review with people and assistive technology;
- store/platform certification;
- code signing and notarization;
- final release approval.
