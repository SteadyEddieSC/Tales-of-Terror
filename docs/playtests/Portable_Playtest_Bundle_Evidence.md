# v0.1.2 Portable Playtest Bundle Evidence

## Provenance and classification

- Issue: #35, including authoritative branch-correction comment 5029019162.
- Starting protected main: `8f0b18b5137072ddcc9af7fc95e1a8a31e5112db`.
- Branch: `agent/issue-35-portable-playtest-bundle`.
- Implementation SHA: to be recorded after the first complete implementation commit.
- Final draft PR head: to be recorded after exact-head evidence synchronization.
- Engine: official Godot 4.7.1-stable, Compatibility renderer, 960×540 logical viewport.
- Templates: official `Godot_v4.7.1-stable_export_templates.tpz`, SHA-256 `86409db6200b6f8fd3230989c2d2002851f3dd18acf11d7bdbafddf5a0dd0f72`.
- Distribution: internal playtest workflow artifacts; no installer, signature, notarization, updater, storefront, public demo, or production deployment.

## Export and bundle evidence

| Surface | Identity / classification | Result |
| --- | --- | --- |
| Windows preset | `Internal Windows x86_64`; embedded PCK | Pending final exact-head build |
| Linux preset | `Internal Linux x86_64`; embedded PCK | Pending final exact-head build |
| Windows execution | Local Windows native/headless direct executable and optional launcher | Pending final implementation-head rerun |
| Linux execution | Ubuntu CI native/headless direct executable and optional launcher | Pending final exact-head workflow |
| Physical controllers | Human physical validation only | `not_tested` |
| TV/native display/readability | Human physical validation only | `not_tested` |
| Household/phone/router/long-session/accessibility | Human physical validation only | `not_tested` |

Bundle layouts are the exact platform executable and launcher plus `START_HERE.md`, `FACILITATOR_GUIDE.md`, `POST_SESSION_QUESTIONNAIRE.md`, `PRIVACY_AND_LIMITATIONS.md`, `MANUAL_VALIDATION_RECORD.json`, `THIRD_PARTY_NOTICES.md`, `LICENSES/GODOT_ENGINE_LICENSE.txt`, and `build_manifest.json`. Generated archives also carry separate SHA-256 files outside the bundle. The validator rejects every missing/extra entry and denylisted source, test, secret, report, screenshot, log, key, or environment path.

The exact manifest schema, privacy exclusions, per-file bounds/hashes, canonical content-digest rules, timestamp separation, overwrite refusal, repeated-build behavior, launcher success, and launcher missing-file paths are executable tests in `tools/test_portable_bundle.py`. The build-support Help regression is `game/tests/portable_build_identity_test.gd` and compares real coordinator snapshots and authority/public-history digests.

## Validation matrix

| Layer | Command / required result | Final result |
| --- | --- | --- |
| Portable policy | `python tools/portable_bundle.py validate-repository` | Pending final run |
| Portable tests | `python tools/test_portable_bundle.py` (6 tests) | Pending final run |
| Manual schema/defaults | `python tools/portable_bundle.py validate-manual-record` | Pending final run |
| Godot import/main | official 4.7.1 typed import and main-scene smoke | Pending final run |
| Standalone suites | every workflow-listed standalone suite, including readiness/main route/build identity | Pending final run |
| Deterministic simulations | Director 90/90; social 157/157; companion 40/40; vertical slice 24/24 | Pending final run |
| Native-authority E2E | browser → service → native Godot → browser ACK exactly once | Pending final run |
| GUT/JUnit | full passing suite plus intentional failure-propagation probe and clean rerun | Pending final run |
| Python/toolchain | Python 3.11.9, exact/hash-locked install, `pip check`, zero-finding gdlint/gdformat | Pending final run |
| Companion | `npm ci`, audit, strict TypeScript, service 26/26, browser 10/10, builds/smoke | Pending final run |
| Repository | asset/provenance, privacy, no-network, toolchain, JSON/YAML, secret, size, title, LFS, whitespace | Pending final run |
| Export/bundles | preset, allow/deny, manifest, repeated build, Windows/Linux archive validation | Pending final run |

## Artifact ledger

| Workflow run | Artifact ID | Artifact name | GitHub size | GitHub digest | Inner archive SHA-256 | Runtime / bundle content digests |
| --- | ---: | --- | ---: | --- | --- | --- |
| Pending | Pending | Windows internal bundle | Pending | Pending | Pending | Pending |
| Pending | Pending | Linux internal bundle | Pending | Pending | Pending | Pending |

## Failures, corrections, warnings, and reruns

- The first preset import lacked Godot's required `export_files` property. Both presets were corrected and re-imported successfully.
- A first build-identity privacy assertion confused safe instructional wording with an actual secret value. The test now rejects concrete private-value patterns and still verifies that the support page warns users not to share secrets.
- A resources-only export could not resolve script-class dependencies from `Main.tscn`; a selected-resources fallback also admitted unintended content. The reviewed preset now uses all runtime resources with explicit exclusions for tests, vendored GUT, `.gutconfig.json`, and the unused exploration showcase. The resulting native executable reached the integrated smoke successfully.
- An initial PowerShell variable capture did not retain the Windows console-wrapper marker even though the native process printed it and exited zero. Final Windows evidence uses process exit results plus an explicit output log/marker check and records the rerun.
- Exported smoke is synthetic/headless input only. It is not physical-controller or household evidence.

## Deferred physical validation

The committed manual record deliberately leaves one/multiple physical controllers, disconnect/reconnect, keyboard fallback observation, TV-distance readability, 720p/1080p/native-4K safe margins, physical phones and no-phone route, household router/firewall behavior, long-session stability, and assistive technology at `not_tested`. No automation or virtual/offscreen evidence is reclassified as physical.
