# v0.1.2 Portable Playtest Bundle Evidence

## Provenance and head classification

- Issue: #35, including authoritative branch-correction comment 5029019162.
- Formal change request: review 4740733256 against original reviewed head `b038ab75a490337038d000e12368acc77540d8c5`.
- Starting protected main: `8f0b18b5137072ddcc9af7fc95e1a8a31e5112db`.
- Branch: `agent/issue-35-portable-playtest-bundle`.
- Correction implementation head: `b92c1d6d21a6eed10624a9d20b4c89d6db491d27`.
- Correction artifact-source head: `b92c1d6d21a6eed10624a9d20b4c89d6db491d27`.
- Local Windows execution head: `b92c1d6d21a6eed10624a9d20b4c89d6db491d27`.
- Final evidence-only PR head: a commit cannot contain its own resulting SHA; the resulting final SHA is recorded in draft PR #36 and a commit-linked top-level PR evidence comment.
- Final exact-head workflows and artifact IDs/digests: recorded only in draft PR #36 and that final commit-linked evidence comment after all final-head runs and artifacts exist.
- Engine: official Godot 4.7.1-stable, Compatibility renderer, 960x540 logical viewport.
- Templates: official `Godot_v4.7.1-stable_export_templates.tpz`, 1,280,486,955 bytes, SHA-256 `86409db6200b6f8fd3230989c2d2002851f3dd18acf11d7bdbafddf5a0dd0f72`.
- Distribution: internal playtest workflow artifacts; no installer, signature, notarization, updater, storefront, public demo, or production deployment.

The correction artifact-source runs below are not labeled final exact-head evidence. They validate the committed functional correction that this evidence-only commit describes. The final self-referential synchronization is deliberately external to the commit.

## Execution and validation classification

| Surface | Source / artifact | Classification | Result |
| --- | --- | --- | --- |
| Original independent review | `b038ab75a490337038d000e12368acc77540d8c5` | Original reviewed head, superseded by bounded corrections | Sound baseline; three blockers recorded in review 4740733256 |
| Correction implementation | `b92c1d6d21a6eed10624a9d20b4c89d6db491d27` | Functional/test/document correction head | Complete local source validation and four successful CI workflows |
| Local Windows build | Locally exported archive from `b92c1d6...` | Actually executed correction implementation artifact | Native executable and `launch.cmd` both exited 0 with exact SHA, `internal_playtest`, and all invariance flags true |
| Correction CI Windows artifact | Artifact 8482450708 from `b92c1d6...` | Structural, cryptographic, manifest, privacy, and archive validation only | PASS; this specific CI-produced Windows native file was not executed |
| Correction CI Linux artifact | Artifact 8482451229 from `b92c1d6...` | Actually executed correction artifact-source artifact | CI native and `launch.sh` both exited 0; downloaded logs revalidated exact SHA/classification/all invariance flags |
| Final evidence-only Windows and Linux artifacts | Resulting final PR head | External final exact-head evidence | IDs, digests, execution classification, and run links are recorded in PR #36 plus the final commit-linked evidence comment |
| Physical controllers and displays | Human physical validation only | Manual | `not_tested` |
| Household, phone/router, long-session, accessibility | Human physical validation only | Manual | `not_tested` |

Synthetic/headless input is process and integration evidence, not a physical-controller test.

## Corrected build identity and support surface

The generated identity retains exactly `schema_version`, `release`, `source_commit`, `platform`, `architecture`, and `classification`. An internal artifact accepts only:

- release `v0.1.2`;
- a source commit of exactly 40 lowercase hexadecimal characters;
- platform `windows` or `linux`;
- architecture `x86_64`;
- classification `internal_playtest`;
- no extra keys.

Help page 4 visibly renders release, short build ID, platform, architecture, `INTERNAL PLAYTEST (internal_playtest)` or the distinctly labeled source-checkout state, scenario `lantern_house_vertical_slice v1`, report schema v2, the provisional project folder, protected reset guidance, actionable report location, and bounded support-reporting guidance. A source checkout is accepted only through the editor-bearing fallback context. A missing or malformed exported identity is visibly invalid and fails exported smoke rather than masquerading as an internal artifact.

Opening and paging Help preserves the complete coordinator snapshot, authority digest, public-history digest, active report, RNG-backed Rules/Director/Role state, and companion projection.

## Actionable local report locations

Production export remains fixed to `user://playtest_exports`; destination authority, privacy schema, and non-network behavior are unchanged. The exact current Godot project folder is `Terror Turn`, and its title remains provisional pending issue #7.

- Windows: `%APPDATA%\Godot\app_userdata\Terror Turn\playtest_exports`
- Linux: `$XDG_DATA_HOME/godot/app_userdata/Terror Turn/playtest_exports`
- Linux default when `XDG_DATA_HOME` is unset: `~/.local/share/godot/app_userdata/Terror Turn/playtest_exports`

The corrected text is included in `START_HERE.md`, `FACILITATOR_GUIDE.md`, and `PRIVACY_AND_LIMITATIONS.md`, and is consistent with the technical privacy/bundle guidance. Tests reject concrete usernames, home directories, repository paths, machine/room/token/IP/device identity, and report contents.

## Complete local validation at correction implementation head

| Gate | Result |
| --- | --- |
| Official Godot 4.7.1 typed import and main smoke | PASS |
| Standalone SceneTree suites | PASS 16/16 |
| Director / social / companion / vertical simulations | PASS 90/90, 157/157, 40/40, 24/24 |
| Controller-first main route and report integration | PASS |
| Portable identity/support regression | PASS, including exact negatives and Help presentation invariance |
| Portable repository/manual/bundle policy | PASS; 8/8 Python tests; 10/10 manual checks remain `not_tested` |
| GUT/JUnit baseline | PASS 20/20, 91 assertions, zero failures |
| Intentional GUT failure-propagation probe | PASS as a gate: process exit 1; JUnit 21 tests, 92 assertions, 1 failure; probe source/XML removed |
| Restored GUT/JUnit | PASS 20/20, 91 assertions, zero failures |
| Python toolchain | PASS Python 3.11.9, hash-locked install, `pip check` |
| First-party GDScript quality | PASS 85-file inventory; gdlint zero findings; gdformat check zero differences |
| Companion dependency/audit/typecheck | PASS Node 24.18.0, npm 11.16.0, clean `npm ci`, zero vulnerabilities, strict TypeScript |
| Companion service/browser | PASS 26/26 and 10/10 |
| Worker/browser builds and local Worker smoke | PASS |
| Browser -> service -> native Godot -> browser ACK exactly once | PASS; reconnect retained Seat 1; history delta 1 |
| Asset/provenance, privacy, no-network, toolchain | PASS |
| Tracked JSON/YAML, secrets, size, obsolete-title, LFS, whitespace | PASS |
| Export preset, manifest, launcher, repeated build, manual schema/defaults | PASS |

No dependency manifest/lock or vendored GUT file changed. No executable, PCK, TPZ, ZIP, report, cache, or generated identity is committed.

## Local Windows correction implementation artifact

The local build used the exact correction implementation SHA and the official Windows Godot 4.7.1 console editor/templates. Both native and launcher smokes loaded the real main scene and Build & Support page, exited zero, and printed `accepted=true`, exact source `b92c1d6d21a6eed10624a9d20b4c89d6db491d27`, platform `windows`, architecture `x86_64`, classification `internal_playtest`, visible classification/report guidance, and true snapshot/digest/history/report/RNG/companion invariance flags.

- Archive: `lantern-house-internal-playtest-v0.1.2-windows-x86_64.zip`.
- Archive size: 38,297,224 bytes.
- Archive SHA-256: `87d5c38d5340fa91d4bc1586021efad62d323d172f86784a2c2e26feaa19bcc4`.
- Native executable size: 109,597,128 bytes.
- Native executable SHA-256: `4452dcb27cf743a4c3aa6c838b20a65e7bfb43a34bbcdfeee2a1276db31db282`.
- Runtime-content digest: `78a7cfcffd996035c6d9b1494f7e5323eb7c54ceb750f43b2f4e86f3b9e5eefb`.
- Bundle-content digest: `3c83adc3ef4655e630ee7c9c72265c1e12bc94bb657d4787125a2cd55e63a343`.
- Manifest timestamp: `2026-07-21T02:59:02Z`, labeled non-deterministic metadata excluded from content identity.
- Inner sidecar, CRC, 10-file exact bundle inventory, 9 manifest payload records, every size/SHA-256, allowlist, denylist, and privacy check: PASS.

## Correction artifact-source workflow ledger

All four workflows ran against `b92c1d6d21a6eed10624a9d20b4c89d6db491d27` and succeeded:

- [Godot 4.7 tests 29797302900](https://github.com/SteadyEddieSC/Tales-of-Terror/actions/runs/29797302900)
- [Companion service and browser tests 29797302903](https://github.com/SteadyEddieSC/Tales-of-Terror/actions/runs/29797302903)
- [Repository checks 29797302906](https://github.com/SteadyEddieSC/Tales-of-Terror/actions/runs/29797302906)
- [Portable internal playtest builds 29797302919](https://github.com/SteadyEddieSC/Tales-of-Terror/actions/runs/29797302919)

| Artifact | GitHub outer evidence | Inner ZIP | Native executable | Content digests |
| --- | --- | --- | --- | --- |
| Windows 8482450708, `lantern-house-internal-playtest-v0.1.2-windows-x86_64` | 38,159,491 bytes; `sha256:df0bd170299c64b75132def183a5c811410a288b316dd7c20dd9494e357ecebe` | 38,297,383 bytes; `f85e1034464d2ef356111ac73550185430a6467d26c71773461428eefa5ff571` | 109,597,112 bytes; `e7547918f639cdfd1213dba0d1d05f66485ef55ba46f9c9020bff7622b4d9ce1` | runtime `0ca3cf58aed7e4bd039f6e208d1868eb3b04cb20aec47c6cc11a5ed3dcaf1b98`; bundle `17e26185e452ab4ade8d87c1ad441d3845eb01aec6f8fc2444ef73c9ad10aead` |
| Linux 8482451229, `lantern-house-internal-playtest-v0.1.2-linux-x86_64` | 28,743,103 bytes; `sha256:0773a9884ea2f82ef4c889c4a3b6d538ada25bcc2ec7ce1eeb706120842fd825` | 28,775,187 bytes; `41bfbcdba9bda52b831eeff3581e67cd256d18c32c9ac1bc9c006f9fedcf55f6` | 73,996,008 bytes; `d1ee57cf08d3ca32aa67778c2ec40a380071f7eee308d49a44e28718b1d36f44` | runtime `99360f2e92510bd0557ea766921cd236d351b080afeb598115fdcbf740c05da8`; bundle `8f6a0103f5e68e58f43b25e97e8589bf8911e4b61edb269f4f765b8e9c24d7fb` |
| GDScript quality 8482439578 | 1,206 bytes; `sha256:51981c175e08d1862a6bfcd932a2ac5b94b2d0779395c9d0fb7b5eb7cb643555` | Not applicable | 85-file inventory | gdlint 0; format differences 0 |
| GUT JUnit 8482452444 | 1,147 bytes; `sha256:f053f1ef65089353bfa24549ccedc5b3691f5a8ea11d96217e9c57ad3482a4cb` | Not applicable | 20 tests | 91 assertions; zero failures |

Both portable artifacts were downloaded as the original GitHub outer ZIP. Their downloaded byte sizes and SHA-256 values exactly matched the GitHub artifact API. Outer and inner ZIP CRC tests passed. Inner sidecars matched. Extracted inventories matched the exact platform allowlists and denylists. Every manifest file size/SHA-256, source SHA, release, platform, architecture, scenario/report versions, provisional-title status, timestamp classification, native hash, runtime digest, and bundle digest revalidated.

The Linux outer artifact correctly preserves the inner ZIP and sidecar under `artifacts/` because the upload also includes root smoke logs. Both downloaded Linux smoke logs contain the exact correction source SHA, Linux/x86_64 target, `internal_playtest`, `accepted=true`, visible classification/report guidance, and every invariance flag true.

## Failures, fixes, warnings, retries, and reruns

- The formal review identified three blockers: missing visible classification, non-actionable report locations, and a superseded-run ledger labeled as exact-head. All three are corrected here.
- The first Python source-text policy probe compared rendered Windows backslashes with escaped GDScript source. It was corrected to assert the constant/policy structure while document and runtime tests assert the rendered exact path.
- Initial edited GDScript exceeded the 100-column gate and differed from canonical formatting. Only the three edited GDScript files were formatted; line lengths were wrapped; full 85-file lint/format checks then passed.
- A first over-broad local JSON probe inspected an ignored historical `.evidence` file with a BOM. The repository-equivalent tracked inventory passed JSON/YAML validation.
- The first tracked-structured-data retry used an invalid PowerShell here-string pipeline and never executed a gate. Python then obtained `git ls-files` directly and the gate passed.
- GUT passed 20/20 and printed 91 assertions, but the first parser looked for assertions on suite nodes. It was corrected to sum testcase assertions, and both intentional-failure and restored JUnit totals were verified.
- Node was not on the host PATH. The first Node command did not start; the pinned Node 24.18.0 directory was explicitly prepended and the full matrix passed. Dependency manifests/locks did not change.
- A Windows process-enumeration local Worker harness was rejected by command safety before launch. A bounded inline Node harness started and terminated only the pinned Wrangler child; health and room creation passed.
- The first downloaded Linux artifact validator assumed the inner ZIP was at the outer root. GitHub preserved it under `artifacts/` because smoke logs are uploaded from another path. The corrected exact-layout validator passed; no artifact content failed.
- Exported smoke remains synthetic/headless automation and is not classified as physical-controller or household evidence.

## Deferred physical validation

The committed manual record leaves one/multiple physical controllers, disconnect/reconnect, keyboard fallback observation, TV-distance readability, 720p/1080p/native-4K safe margins, physical phones and no-phone route, household router/firewall behavior, long-session stability, and assistive technology at `not_tested`. No automation or virtual/offscreen evidence is reclassified as physical.

## Protected scope

PR #32 remains open and separate. Issue #7 remains open. Repository naming/final branding, dependency manifests/locks, and vendored GUT remain untouched. The PR stays draft and is not merged or marked ready.
