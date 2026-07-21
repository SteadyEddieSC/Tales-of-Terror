# v0.1.2 Portable Playtest Bundle Evidence

## Provenance and classification

- Issue: #35, including authoritative branch-correction comment 5029019162.
- Starting protected main: `8f0b18b5137072ddcc9af7fc95e1a8a31e5112db`.
- Branch: `agent/issue-35-portable-playtest-bundle`.
- Validated implementation SHA: `159bd863ef39c6369f0460b1d8980d5577cab886`.
- Validated CI artifact source SHA: `d6323e0dfea62665ead3029c600f177de17a9dbe`.
- Final draft PR head: the self-referential final value is recorded in draft PR #36 and the main-chat handoff after evidence synchronization.
- Engine: official Godot 4.7.1-stable, Compatibility renderer, 960×540 logical viewport.
- Templates: official `Godot_v4.7.1-stable_export_templates.tpz`, SHA-256 `86409db6200b6f8fd3230989c2d2002851f3dd18acf11d7bdbafddf5a0dd0f72`.
- Distribution: internal playtest workflow artifacts; no installer, signature, notarization, updater, storefront, public demo, or production deployment.

## Export and bundle evidence

| Surface | Identity / classification | Result |
| --- | --- | --- |
| Windows preset | `Internal Windows x86_64`; embedded PCK | PASS locally and in CI artifact-source run |
| Linux preset | `Internal Linux x86_64`; embedded PCK | PASS in Ubuntu CI artifact-source run |
| Windows execution | Local Windows native/headless direct executable and optional launcher | PASS; both exit 0 and report `accepted=true` |
| Linux execution | Ubuntu CI native/headless direct executable and optional launcher | PASS; both exit 0 and report `accepted=true` |
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
| Export/bundles | preset, allow/deny, manifest, repeated build, Windows/Linux archive validation | PASS locally and in CI for both platform archives |

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

## Exact build and validation commands

The local Windows implementation-head build used these commands from repository root (the absolute ignored output root is abbreviated as `<repo>/builds/local-windows-159bd86` only to avoid committing a user path):

```text
python tools/portable_bundle.py write-build-identity --platform windows --source-commit 159bd863ef39c6369f0460b1d8980d5577cab886
Godot_v4.7.1-stable_win64_console.exe --headless --path game --export-release "Internal Windows x86_64" <repo>/builds/local-windows-159bd86/export/lantern_house_internal.exe
python tools/portable_bundle.py assemble --platform windows --source-commit 159bd863ef39c6369f0460b1d8980d5577cab886 --timestamp 2026-07-21T01:55:00Z --output-root <repo>/builds/local-windows-159bd86 --exported-binary <repo>/builds/local-windows-159bd86/export/lantern_house_internal.exe
python tools/portable_bundle.py validate-bundle <repo>/builds/local-windows-159bd86/bundles/lantern-house-internal-playtest-v0.1.2-windows-x86_64
lantern_house_internal.exe --headless --audio-driver Dummy -- --portable-build-smoke
launch.cmd --headless --audio-driver Dummy -- --portable-build-smoke
```

The exact CI equivalents are committed in `.github/workflows/portable-builds.yml`: the verified Linux editor writes a platform identity, invokes `--export-release` for each named preset, assembles each platform through `tools/portable_bundle.py`, revalidates both output directories, executes the Linux native file and launcher, checks missing-file exit behavior, and uploads the two versioned artifacts. Local source/repository validation used the workflow-listed Godot scripts plus:

```text
python tools/portable_bundle.py validate-repository
python tools/portable_bundle.py validate-manual-record
python tools/test_portable_bundle.py
python tools/validate_assets.py
python tools/validate_companion.py
python tools/validate_playtest_readiness.py
python tools/validate_toolchain.py
python -m pip install --disable-pip-version-check --require-hashes --requirement requirements-dev.txt
python -m pip check
gdlint <85-file-first-party-inventory>
gdformat --check <85-file-first-party-inventory>
npm ci
npm audit --audit-level=moderate
npm run typecheck
npm run test:service
npm run test:browser
npm run build
npm run test:e2e:local
```

The repeated-assembly test used identical fixture bytes/source SHA and timestamps `2026-07-21T01:00:00Z` and `2026-07-21T02:00:00Z`. Both runtime identities were `b02eaf648d4374cdffd1fc5accc02975b9a3389f12066e58f45f0c35389e756f`; both bundle identities were `2fff03bf9262db37ca1c9aaa40dc07008afb107e02d99c82cbf90f6f400d420b`. The archives intentionally differed (`d89d7a870a7819ac9cdba167589e77492ccfee8c6e57deb624356298593a254e` versus `08968a4b7ad2ba8b28a318c28ac2f89a62c50e523011531cebaaf92a11507c95`) because their manifest timestamps differ.

## Changed-file manifest

Relative to starting main `8f0b18b5137072ddcc9af7fc95e1a8a31e5112db`, the bounded branch changes exactly these paths (`A` added, `M` modified):

```text
M .github/workflows/godot-tests.yml
A .github/workflows/portable-builds.yml
M .github/workflows/repository-checks.yml
M .gitignore
M CHANGELOG.md
M README.md
A docs/playtests/Portable_Playtest_Bundle_Evidence.md
A docs/playtests/v0.1.2-facilitator-guide.md
A docs/playtests/v0.1.2-manual-hardware-validation.json
A docs/playtests/v0.1.2-post-session-questionnaire.md
A docs/releases/v0.1.2-portable-playtest-build-session-bundle.md
M docs/technical/First_Vertical_Slice.md
M docs/technical/Playtest_Readiness.md
M docs/technical/Playtest_Report_Privacy.md
A docs/technical/Portable_Playtest_Bundles.md
M docs/technical/Toolchain_and_Testing.md
A game/export_presets.cfg
M game/project.godot
A game/src/build/internal_build_identity.gd
A game/src/build/internal_build_identity.gd.uid
M game/src/main/main.gd
M game/src/session/guided_session_help.gd
M game/tests/fixtures/playtest_report_v2.json
M game/tests/fixtures/playtest_report_v2.md
M game/tests/playtest_capture_fixture.gd
M game/tests/playtest_main_route_test.gd
A game/tests/portable_build_identity_test.gd
A game/tests/portable_build_identity_test.gd.uid
A packaging/manual_validation_schema.json
A packaging/portable/GODOT_ENGINE_LICENSE.txt
A packaging/portable/PRIVACY_AND_LIMITATIONS.md
A packaging/portable/START_HERE.md
A packaging/portable/THIRD_PARTY_NOTICES.md
A packaging/portable/bundle_spec.json
A packaging/portable/launch_linux.sh
A packaging/portable/launch_windows.cmd
A tools/portable_bundle.py
A tools/test_portable_bundle.py
M tools/validate_playtest_readiness.py
M tools/validate_toolchain.py
```

No dependency manifest/lock, vendored GUT file, generated executable/archive, PR #32 file, or issue #7 naming decision is included.

## Artifact ledger

| Workflow run | Artifact ID | Artifact name | GitHub size | GitHub digest | Inner archive SHA-256 | Runtime / bundle content digests |
| --- | ---: | --- | ---: | --- | --- | --- |
| [29794377746](https://github.com/SteadyEddieSC/Tales-of-Terror/actions/runs/29794377746) | 8481488168 | `lantern-house-internal-playtest-v0.1.2-windows-x86_64` | 38,155,659 | `sha256:913a1c80e3651df12b1d12af15bda2f534dce55a8d79d153dc299fac2d6a31a2` | `c7c18b9bb88232d81a4ded11f5686f41db2ddf734082aa24f549fc2733c4b371` (38,293,814 bytes) | runtime `8bffc0a40c927fbc0e452228f983048437dd9510dfca98296bdf1f2442bc2cd6`; bundle `cebb557eed52d65f6be4a228e15de824d2309228643869ed7c8ba6356a06b328` |
| [29794377746](https://github.com/SteadyEddieSC/Tales-of-Terror/actions/runs/29794377746) | 8481488836 | `lantern-house-internal-playtest-v0.1.2-linux-x86_64` | 28,739,457 | `sha256:83aaf0322bb6b5b2a82e67b0c48eaaeb2490c1f6fae6f6649d469a9d05f3c848` | `102c80471dacbc967628bdc2889894a98873ffdea75533e86130526c2907ba69` (28,771,748 bytes) | runtime `c3098d8fb6d17cdea561156bd61743773289611e1f36c9c19ba370ae8ced3658`; bundle `8ed147a95ecedcdb401816ab82ba485aede9b7125d030c9ab6c0fc55aa3e0594` |
| [29794377684](https://github.com/SteadyEddieSC/Tales-of-Terror/actions/runs/29794377684) | 8481474523 | `gdscript-quality` | 1,206 | `sha256:4a533849f25e8870dde80180b818fa148f29411ffc52dcde36f0bff02c9978d2` | Not applicable | 85-file inventory, lint 0, format differences 0 |
| [29794377684](https://github.com/SteadyEddieSC/Tales-of-Terror/actions/runs/29794377684) | 8481486257 | `gut-junit-results` | 1,146 | `sha256:5725bed4a730780ecd5d589bccc79a75c62a2f8007045601d06349c35e17ff5a` | Not applicable | 20/20 tests, 91 assertions |

Both portable artifacts were downloaded. Their sibling checksum files matched the inner archives, archive CRC/content checks passed, exact bundle allowlists and every manifest file size/SHA-256 revalidated, and both manifests recorded source `d6323e0dfea62665ead3029c600f177de17a9dbe`. The Windows native file was 109,594,184 bytes with SHA-256 `02b45cd9e93bf8e9c626d97bdf122ac2713380e36fa7fedaf5747be2cd46cdb6`; Linux was 73,993,080 bytes with SHA-256 `a86b8930d552b69015079b6f1109c5a73f50ebd83086d2e9cc4af2d4c1d1cbe2`.

## Exact-head workflow links

- [Godot 4.7 tests run 29794377684](https://github.com/SteadyEddieSC/Tales-of-Terror/actions/runs/29794377684): success.
- [Companion service and browser tests run 29794377688](https://github.com/SteadyEddieSC/Tales-of-Terror/actions/runs/29794377688): success.
- [Repository checks run 29794377714](https://github.com/SteadyEddieSC/Tales-of-Terror/actions/runs/29794377714): success.
- [Portable internal playtest builds run 29794377746](https://github.com/SteadyEddieSC/Tales-of-Terror/actions/runs/29794377746): success; Linux direct and launcher smoke logs both record exact source and every invariance flag true.

## Failures, corrections, warnings, and reruns

- The first preset import lacked Godot's required `export_files` property. Both presets were corrected and re-imported successfully.
- A first build-identity privacy assertion confused safe instructional wording with an actual secret value. The test now rejects concrete private-value patterns and still verifies that the support page warns users not to share secrets.
- A resources-only export could not resolve script-class dependencies from `Main.tscn`; a selected-resources fallback also admitted unintended content. The reviewed preset now uses all runtime resources with explicit exclusions for tests, vendored GUT, `.gutconfig.json`, and the unused exploration showcase. The resulting native executable reached the integrated smoke successfully.
- A denylist probe initially treated Godot's generated `.godot/exported` transforms and class/UID caches inside the embedded pack as outer bundle files. Godot 4.7.1 always emits these runtime internals and export filters do not remove them. The false-positive rule was narrowed to actual test/GUT/showcase resources; the outer bundle still rejects any `.godot` path.
- An initial PowerShell variable capture did not retain the Windows console-wrapper marker even though the native process printed it and exited zero. Final Windows evidence uses process exit results plus an explicit output log/marker check and records the rerun.
- The first Node command lacked the portable Node directory on PATH; the next explicit invocation exposed stale prior Wrangler smoke processes locking `node_modules`. Those exact repository-scoped processes were stopped. A second invocation needed the Node directory available to lifecycle scripts, and a third selected `npm.ps1` under the host execution policy. The final explicit `npm.cmd` invocation with the pinned Node directory prepended passed the full matrix. No manifest or lock changed.
- A first inline Node service-smoke command lost JavaScript quotes through PowerShell argument parsing. The here-string/stdin rerun passed health and room creation and stopped the local worker cleanly.
- Exact-head portable CI run 29794247789 passed template verification, both exports/assemblies, Linux direct and launcher smoke, and missing-launcher checks, then failed its cleanliness assertion because the downloaded editor/template archives and staging directories were placed at checkout root. No bundle upload occurred. The workflow was corrected to keep all tool downloads/staging under `RUNNER_TEMP` and to print any future dirty paths before failing; the complete workflow was rerun at the corrected head.
- Exported smoke is synthetic/headless input only. It is not physical-controller or household evidence.

## Deferred physical validation

The committed manual record deliberately leaves one/multiple physical controllers, disconnect/reconnect, keyboard fallback observation, TV-distance readability, 720p/1080p/native-4K safe margins, physical phones and no-phone route, household router/firewall behavior, long-session stability, and assistive technology at `not_tested`. No automation or virtual/offscreen evidence is reclassified as physical.
