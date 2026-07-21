# v0.1.2 Portable Playtest Bundle Evidence

## Provenance and classification

- Issue: #35, including authoritative branch-correction comment 5029019162.
- Starting protected main: `8f0b18b5137072ddcc9af7fc95e1a8a31e5112db`.
- Branch: `agent/issue-35-portable-playtest-bundle`.
- Validated implementation SHA: `159bd863ef39c6369f0460b1d8980d5577cab886`.
- Final draft PR head: to be recorded after exact-head evidence synchronization.
- Engine: official Godot 4.7.1-stable, Compatibility renderer, 960×540 logical viewport.
- Templates: official `Godot_v4.7.1-stable_export_templates.tpz`, SHA-256 `86409db6200b6f8fd3230989c2d2002851f3dd18acf11d7bdbafddf5a0dd0f72`.
- Distribution: internal playtest workflow artifacts; no installer, signature, notarization, updater, storefront, public demo, or production deployment.

## Export and bundle evidence

| Surface | Identity / classification | Result |
| --- | --- | --- |
| Windows preset | `Internal Windows x86_64`; embedded PCK | PASS at validated implementation SHA |
| Linux preset | `Internal Linux x86_64`; embedded PCK | Pending final exact-head build |
| Windows execution | Local Windows native/headless direct executable and optional launcher | PASS; both exit 0 and report `accepted=true` |
| Linux execution | Ubuntu CI native/headless direct executable and optional launcher | Pending final exact-head workflow |
| Physical controllers | Human physical validation only | `not_tested` |
| TV/native display/readability | Human physical validation only | `not_tested` |
| Household/phone/router/long-session/accessibility | Human physical validation only | `not_tested` |

Bundle layouts are the exact platform executable and launcher plus `START_HERE.md`, `FACILITATOR_GUIDE.md`, `POST_SESSION_QUESTIONNAIRE.md`, `PRIVACY_AND_LIMITATIONS.md`, `MANUAL_VALIDATION_RECORD.json`, `THIRD_PARTY_NOTICES.md`, `LICENSES/GODOT_ENGINE_LICENSE.txt`, and `build_manifest.json`. Generated archives also carry separate SHA-256 files outside the bundle. The validator rejects every missing/extra entry and denylisted source, test, secret, report, screenshot, log, key, or environment path.

The exact manifest schema, privacy exclusions, per-file bounds/hashes, canonical content-digest rules, timestamp separation, overwrite refusal, repeated-build behavior, launcher success, and launcher missing-file paths are executable tests in `tools/test_portable_bundle.py`. The build-support Help regression is `game/tests/portable_build_identity_test.gd` and compares real coordinator snapshots and authority/public-history digests.

## Validation matrix

| Layer | Command / required result | Final result |
| --- | --- | --- |
| Portable policy | `python tools/portable_bundle.py validate-repository` | PASS |
| Portable tests | `python tools/test_portable_bundle.py` (6 tests) | PASS 6/6 |
| Manual schema/defaults | `python tools/portable_bundle.py validate-manual-record` | PASS; 10/10 remain `not_tested` |
| Godot import/main | official 4.7.1 typed import and main-scene smoke | PASS |
| Standalone suites | every workflow-listed standalone suite, including readiness/main route/build identity | PASS 16/16 suites |
| Deterministic simulations | Director 90/90; social 157/157; companion 40/40; vertical slice 24/24 | PASS at exact totals |
| Native-authority E2E | browser → service → native Godot → browser ACK exactly once | PASS; reconnect Seat 1, history delta 1 |
| GUT/JUnit | full passing suite plus intentional failure-propagation probe and clean rerun | PASS 20/20, 91 assertions; probe exit 1 and JUnit 1 failure; residue removed; restored 20/20 |
| Python/toolchain | Python 3.11.9, exact/hash-locked install, `pip check`, zero-finding gdlint/gdformat | PASS; 85-file first-party inventory |
| Companion | `npm ci`, audit, strict TypeScript, service 26/26, browser 10/10, builds/smoke | PASS; zero vulnerabilities; Worker/browser build and local service health/room smoke pass |
| Repository | asset/provenance, privacy, no-network, toolchain, JSON/YAML, secret, size, title, LFS, whitespace | PASS |
| Export/bundles | preset, allow/deny, manifest, repeated build, Windows/Linux archive validation | Windows PASS locally; Linux pending exact-head CI |

## Local Windows artifact evidence

The implementation-head export used the official local Windows Godot 4.7.1 console editor and the verified official templates. The direct native executable and `launch.cmd` each ran `--headless --audio-driver Dummy -- --portable-build-smoke`, exited 0, loaded the real `Main.tscn`, opened Help page 4, and returned `accepted=true`. The payload recorded the exact implementation SHA and true values for unchanged snapshot, authority digest, public-history digest, active report, and companion projection. This exercises actual exported Windows process startup and the integrated support route; the CLI flag is synthetic automation and not a physical-controller test.

- Archive: `lantern-house-internal-playtest-v0.1.2-windows-x86_64.zip`.
- Archive size: 38,293,526 bytes.
- Archive SHA-256: `437e58322922bf7e1923af36406c7690c19d7c1d69d5aa5a9c5db7273b04698f`.
- Native executable size: 109,594,200 bytes.
- Native executable SHA-256: `cd09918156608f9f47025676401a174bc8b568ae228ae33ee03806031e0adc64`.
- Deterministic runtime-content digest: `467cef18b1c05bfef3668fa0d339df81a02e4ff1ab7934b7adf18105f512f0cb`.
- Deterministic bundle-content digest: `b3125030ab0a87bbadd81729ef762e17c04d860c29df9aa65370f78095c54956`.
- Manifest build timestamp: `2026-07-21T01:55:00Z`, explicitly non-deterministic metadata.
- Bundle inventory: 10 files including `build_manifest.json`; all nine pre-manifest payload records matched exact size/SHA-256 values and the archive CRC/content check passed.

## Artifact ledger

| Workflow run | Artifact ID | Artifact name | GitHub size | GitHub digest | Inner archive SHA-256 | Runtime / bundle content digests |
| --- | ---: | --- | ---: | --- | --- | --- |
| Pending | Pending | Windows internal bundle | Pending | Pending | Pending | Pending |
| Pending | Pending | Linux internal bundle | Pending | Pending | Pending | Pending |

## Failures, corrections, warnings, and reruns

- The first preset import lacked Godot's required `export_files` property. Both presets were corrected and re-imported successfully.
- A first build-identity privacy assertion confused safe instructional wording with an actual secret value. The test now rejects concrete private-value patterns and still verifies that the support page warns users not to share secrets.
- A resources-only export could not resolve script-class dependencies from `Main.tscn`; a selected-resources fallback also admitted unintended content. The reviewed preset now uses all runtime resources with explicit exclusions for tests, vendored GUT, `.gutconfig.json`, and the unused exploration showcase. The resulting native executable reached the integrated smoke successfully.
- A denylist probe initially treated Godot's generated `.godot/exported` transforms and class/UID caches inside the embedded pack as outer bundle files. Godot 4.7.1 always emits these runtime internals and export filters do not remove them. The false-positive rule was narrowed to actual test/GUT/showcase resources; the outer bundle still rejects any `.godot` path.
- An initial PowerShell variable capture did not retain the Windows console-wrapper marker even though the native process printed it and exited zero. Final Windows evidence uses process exit results plus an explicit output log/marker check and records the rerun.
- The first Node command lacked the portable Node directory on PATH; the next explicit invocation exposed stale prior Wrangler smoke processes locking `node_modules`. Those exact repository-scoped processes were stopped. A second invocation needed the Node directory available to lifecycle scripts, and a third selected `npm.ps1` under the host execution policy. The final explicit `npm.cmd` invocation with the pinned Node directory prepended passed the full matrix. No manifest or lock changed.
- A first inline Node service-smoke command lost JavaScript quotes through PowerShell argument parsing. The here-string/stdin rerun passed health and room creation and stopped the local worker cleanly.
- Exported smoke is synthetic/headless input only. It is not physical-controller or household evidence.

## Deferred physical validation

The committed manual record deliberately leaves one/multiple physical controllers, disconnect/reconnect, keyboard fallback observation, TV-distance readability, 720p/1080p/native-4K safe margins, physical phones and no-phone route, household router/firewall behavior, long-session stability, and assistive technology at `not_tested`. No automation or virtual/offscreen evidence is reclassified as physical.
