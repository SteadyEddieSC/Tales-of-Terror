# ADR-0020: Toolchain and test strategy

- **Status:** Accepted
- **Date:** July 19, 2026
- **Decision scope:** v0.0.9.1 toolchain and test infrastructure only

## Context

The v0.0.9 project has broad deterministic coverage, but its Windows and Linux validation still targets the initial Godot 4.7 release. Most tests are deliberately direct `SceneTree` entrypoints because they exercise full scene-independent authorities and long deterministic simulations clearly. The repository needs maintenance-patch reproducibility, a gradual unit-test framework, and an honest GDScript quality baseline before v0.1.0 gameplay work begins.

## Decision

1. Pin the external Windows development engine and the directly downloaded Linux CI engine to official Godot `4.7.1-stable`. Verify each official archive against the release's published SHA-512 file before execution. Keep `config/features=PackedStringArray("4.7", "GL Compatibility")`, the Compatibility renderer, the 960×540 logical viewport, Windows/Linux priority, typed GDScript, and all gameplay authority boundaries unchanged.
2. Keep GitHub Actions as the transparent validation orchestrator. Preserve the existing workflow and job identities, download the official Linux archive directly, verify its checksum, and do not introduce `godot-ci`, export templates, deployment, or packaging.
3. Preserve every direct regression and deterministic simulation. Add GUT incrementally for focused toolchain, pure-model, protocol, atomicity, and privacy boundaries where a compact unit test improves feedback. Large stateful simulations remain direct scripts.
4. Vendor only the reviewed upstream `addons/gut` directory from GUT tag `v9.7.1`, commit `aeb5d4f3f7f0a6c9b5e178876d6c99b791fda605`. Preserve its MIT license and bundled font notices. GUT emits JUnit XML; a normal nonzero GUT process fails the Godot job while an `always()` artifact step retains the report.
5. Pin GDScript Toolkit exactly as `gdtoolkit==4.5.0` and CI Python as `3.11.9` through immutable `actions/setup-python` commit `ece7cb06caefa5fff74198d8649806c4678c61a1`. Run `gdlint` and `gdformat --check` only on first-party `.gd` files, excluding caches and `game/addons/gut`. CI never rewrites source.
6. Apply the issue's baseline rule without suppressing meaningful checks. The initial baseline is large: 1,235 lint findings across 67 files, dominated by 1,210 line-length findings, and 66 files would be reformatted. The tool parsed the full first-party tree, so this is not a parser incompatibility. Both checks remain informational in v0.0.9.1, their complete outputs are uploaded, and v0.1.0 remains blocked until separately bounded lint/format cleanup is reviewed and merged.

## Test-layer contract

| Layer | Purpose | Authority and determinism rule |
| --- | --- | --- |
| Godot import/main smoke | Typed script registration, resource import, main-scene startup | Uses the pinned engine and project renderer/viewport unchanged |
| Direct `SceneTree` tests | Existing subsystem regression and integration coverage | Remains the primary auditable coverage for full authorities |
| Direct simulations | 90 Director, 157 social, and 40 companion deterministic sequences | Fixed seeds, isolated RNG streams, bounded histories, no migration to GUT |
| Focused GUT tests | Fast framework, pure-model, protocol, atomicity, and privacy checks | Typed test code, public APIs, deterministic inputs, no scene-owned authority |
| TypeScript/browser/service tests | Relay protocol, privacy, accessibility, service timing, build, and native E2E | Browsers submit intents; native Godot remains sole gameplay authority |
| Repository checks | Secrets, privacy policy, JSON, LFS, provenance, size, title, and whitespace | No generated reports, engine binaries, credentials, or private payloads committed |

## Consequences

- Maintenance validation is reproducible from official immutable artifacts without adding engine binaries to Git.
- Contributors gain GUT/JUnit feedback without losing the clearer legacy harnesses.
- Quality debt is visible and downloadable instead of hidden by broad suppressions or an unreviewable formatting diff.
- A dedicated lint/format cleanup is an explicit prerequisite to v0.1.0. That follow-up must not change gameplay behavior.
- Export, deployment, physical-device certification, production Cloudflare work, and player-facing redesign remain separate future decisions.
