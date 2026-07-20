# v0.1.1 Playtest Readiness Evidence Matrix

## Release identity

- Issue/version: #33, v0.1.1 — Playtest Readiness & Guided Session UX
- Required starting protected main: `d9a5727d64f83e2c2804a1c7e461ae5a57e54cc2`
- Branch: `agent/issue-33-playtest-readiness`
- Tested implementation head: `d808abac70f0cd766b1aa256ce7e946f94baabfa`
- Final draft-PR head: recorded in the commit-linked draft-PR evidence comment because a Git commit cannot contain its own hash.
- PR #32 was not modified, merged, closed, rebased, or included.

## Authority and presentation boundary

| Surface | Input | Output | Authority effect |
| --- | --- | --- | --- |
| Compact lifecycle guidance | coordinator public state; existing seat presentation rows | stage/objective/control/wait text | none |
| Help/accessibility | copied public state, seat states, aggregate companion status | four bounded high-contrast pages | none; gameplay router blocked and sandbox presentation stopped while open |
| Report observer | allowlisted public fields, reduced seat rows, companion aggregate, explicit clock values | exact-schema in-memory report | none; no authority reference or mutation method |
| Local writer | finalized JSON/Markdown strings and validated basename | `user://playtest_exports/*.json` and `*.md` | none; no arbitrary path or network API |

Lifecycle guidance covers title, lobby, confirmation, briefing, active prompt/vote and exploration, terminal, ending, rematch, and return. Help documents stable-seat reconnect, no-phone controlled reveal, optional companions, pause, protected reset, accessibility cues, and report export. Tests prove opening, paging, and closing help preserve the complete coordinator snapshot, authority digest, public-history digest, retained prompt/vote, operation index, responses, and stage checkpoint.

## Report schema and privacy map

Schema version 1 uses exact root and nested keys. Array caps are lifecycle 64, seats 64, recovery 64, waits 64, rejection categories 32, and stage durations 8. Strings, timestamps, mode/scenario values, terminal reason, and optional notes are bounded. Events carry strictly increasing sequence numbers within each ordered collection.

| Allowed | Explicitly omitted/rejected |
| --- | --- |
| release/scenario version, seed, seat count, public mode/fallback | unrevealed role, faction, form, objective |
| lifecycle/stage elapsed summaries | unresolved private choices or raw responses |
| stable seat number, public connection category, controller/keyboard class | device ID/name, OS user, machine name, repository/absolute path |
| aggregate prompt/vote submitted and eligible counts | prompt option selection before authorized resolution |
| bounded rejection category | raw rejection payload or private authority data |
| public terminal reason and SHA-256 digests | room/join code, token/capability, client ID, request body, browser storage, IP/network data |

The planted-negative fixture supplied all denied categories. None appeared in serialized JSON. Static validation rejects unknown keys and scans report source for HTTP, WebSocket, UDP, TCP, forbidden identity fields, and arbitrary writer paths. No report code performs background work or network transmission.

## Deterministic invariance

Two independent four-seat sessions used seed `12031` and identical ordered stage inputs. One was unobserved; the other was observed after every stage. Both reached the same terminal result with:

- Authority digest: `2ff5e90731d07754e737257c4f26077a3b939d596df85369db0c3cda4e80906e`
- Public-history digest: `3d88812891b1cce64fb3f035d1d359d84664e15947524655fc1debde91144c83`

The observer also inspected aggregate status from an open optional companion bridge without changing bridge diagnostics or native authority digest. The no-phone route completed with `companion_used=false`.

## Export fixtures

| Fixture | SHA-256 |
| --- | --- |
| `game/tests/fixtures/playtest_report_v1.json` | `5d011befb06720eaf0e99daad067e08e9a5ac1648b75a939be00252d41c24713` |
| `game/tests/fixtures/playtest_report_v1.md` | `f87562e51602bddab4fde140346987b3d08861d55f69062bc5cf7b5386e35f24` |

The in-memory writer proves JSON/Markdown success and injected failure. The production writer probe created both files under the approved Godot user-data folder, rejected `../arbitrary_path`, and removed its generated probe files. The committed fixtures are synthetic and byte/semantic checked by the standalone suite.

## Local validation matrix

| Surface | Result |
| --- | --- |
| Official Godot | PASS: `4.7.1.stable.official.a13da4feb` |
| Typed import and main scene | PASS |
| Seat, visual, exploration, Living Board, rules | PASS |
| Director suite/simulation | PASS, 90 deterministic sequences |
| Roles/social suite/simulation | PASS, 157 deterministic 1–8 sequences |
| Companion authority/privacy/simulation | PASS, 40 deterministic 1–8-client sequences |
| Vertical slice lifecycle/simulation | PASS, 24/24 |
| New playtest-readiness standalone | PASS: lifecycle/help/recovery/report/privacy/export/invariance/no-network |
| GUT/JUnit | PASS: 20 tests, 91 assertions; JUnit generated |
| Intentional GUT failure propagation | PASS: temporary probe exit 1 and JUnit `<failure>`; probe removed |
| Python lock | PASS: Python 3.11.9, `--require-hashes`, `pip check`, complete frozen graph |
| Node/service/browser | PASS: npm ci; audit 0 vulnerabilities; strict TypeScript; service 26/26; browser 10/10 |
| Builds and smoke | PASS: Worker dry run, browser production build, local health and room creation |
| Genuine E2E | PASS exactly once: browser → local service → native Godot → browser ACK; Seat 1 reconnect; history delta 1 |
| Repository validators | PASS: assets/provenance, companion privacy, playtest privacy, toolchain |
| Repository hygiene | PASS: 10 tracked/release JSON files, secret/size/title/LFS checks, three workflow YAML files |
| GDScript quality | PASS: explicit 82-file first-party inventory, gdlint 0, gdformat check 0 |
| Dependency/vendor drift | PASS: no Python/Node manifest or lock change; vendored GUT diff count 0 |

## Visual evidence

All captures are synthetic Godot render output. They include no desktop, account, token, capability, room secret, client identity, private payload, network detail, machine information, or personal data.

| Capture and descriptive alt text | Classification | SHA-256 |
| --- | --- | --- |
| `docs/playtests/evidence/v0.1.1/lobby_1280x720_virtual_offscreen.png` — Three synthetic stable seats with join, leave, and help guidance | 1280×720 virtual/offscreen | `300e9ca9d670c2192624e9517f8f13cd236649fb6b85254af4409170172a1c74` |
| `docs/playtests/evidence/v0.1.1/prompt_1280x720_virtual_offscreen.png` — Threshold prompt progress 0/1 and expected Seat 1 | 1280×720 virtual/offscreen | `bd54da1291197dfaacc8e6602a74bfd404687345aebeaa206420476c17891302` |
| `docs/playtests/evidence/v0.1.1/help_1280x720_virtual_offscreen.png` — Help page with controller/keyboard equivalents and reset hold | 1280×720 virtual/offscreen | `030020558ee4f2ed5812a1a293c80af2e814e2128513634b7562c122581e1d4f` |
| `docs/playtests/evidence/v0.1.1/ending_export_1280x720_virtual_offscreen.png` — Privacy summary and successful local JSON/Markdown export | 1280×720 virtual/offscreen | `8aa653f9d2f7c7264d77fa1a492447be181c3a5a4a22822066a60ea2ff421150` |
| `docs/playtests/evidence/v0.1.1/lobby_1920x1080_virtual_offscreen.png` — Three synthetic stable seats with join, leave, and help guidance | 1920×1080 virtual/offscreen | `9bdb15c4db6a57778e46c2b409345697568c289383eba9bcf7b5568b0bc0ec87` |
| `docs/playtests/evidence/v0.1.1/prompt_1920x1080_virtual_offscreen.png` — Threshold prompt progress and expected stable seat at 1080p | 1920×1080 virtual/offscreen | `c9a76c3311bb8c993eaa14859cca523d0554d8eb2ba8ee8c72c72422689dc5ea` |
| `docs/playtests/evidence/v0.1.1/help_1920x1080_virtual_offscreen.png` — High-contrast paged help at 1080p | 1920×1080 virtual/offscreen | `319328114c2b2227685f56a81d5884ef285ef315a6e8636e9c4249e322a8f978` |
| `docs/playtests/evidence/v0.1.1/ending_export_1920x1080_virtual_offscreen.png` — Ending report privacy and export confirmation at 1080p | 1920×1080 virtual/offscreen | `56383b8b88d32e6e37f5c702b38f3a8b3f646eb3714bfc5a65bdb32dc671ee3e` |
| `docs/playtests/evidence/v0.1.1/lobby_3840x2160_virtual_offscreen.png` — Synthetic stable-seat lobby rendered at virtual 4K | 3840×2160 virtual/offscreen | `2bb6ac25a2746f6aa086dc649494210929569cabc78143236f08fbabd971ad8b` |
| `docs/playtests/evidence/v0.1.1/prompt_3840x2160_virtual_offscreen.png` — Prompt progress banner rendered at virtual 4K | 3840×2160 virtual/offscreen | `c6b2bf9497d767e0d5a9517043dd8783292d840079670e317754a70b19cbaa8b` |
| `docs/playtests/evidence/v0.1.1/help_3840x2160_virtual_offscreen.png` — Controller-accessible help rendered at virtual 4K | 3840×2160 virtual/offscreen | `271aca48026a68cbd9dc423f01d7c7068f74f5eb88442a601fdeb62e8c97f27e` |
| `docs/playtests/evidence/v0.1.1/ending_export_3840x2160_virtual_offscreen.png` — Local report export confirmation rendered at virtual 4K | 3840×2160 virtual/offscreen | `44ec53d44b7297388788dadaad98eab1883bb34e66a3c598be4a706d33d26e72` |

The 3840×2160 files are virtual/offscreen render evidence only. They are not physical/native 4K display or television-distance evidence.

## Changed-file manifest

- Presentation/input: `main.gd`, `vertical_slice_view.gd`, `guided_session_help.gd`, `player_input_router.gd`, `project.godot`.
- Public projection: one additive `scenario_version` field in `VerticalSliceCoordinator.public_state()`.
- Local reports: three `game/src/playtest/` classes, exact JSON/Markdown fixtures, and memory writer seam.
- Tests: standalone readiness suite, four focused GUT cases, synthetic capture fixture.
- CI/policy: existing Godot/repository workflows and toolchain validator extended; new report privacy validator.
- Documentation/evidence: two technical guides, facilitator checklist/questionnaire, release notes, changelog/README status, this matrix, and twelve PNGs.

No scenario, authored operation, board/rules/Director/role/pawn/companion authority, TypeScript, JavaScript, protocol JSON, scene, runtime asset, renderer, viewport, dependency manifest/lock, or vendored GUT file changed.

## Warnings, failures, fixes, and reruns

- The first local GUT run accidentally used an installed Godot 4.7.0 PATH entry and correctly failed the maintenance-version assertion. One new prompt-progress assertion also expected 3 eligible seats although the authored single-seat prompt expected 1. The exact 4.7.1 executable was located, the assertion corrected, and the suite passed 20/20 and 91 assertions.
- A first JSON sweep included local dependency/cache files and PowerShell's case-insensitive JSON conversion rejected otherwise valid dependency data. The CI-equivalent Python validation was rerun over tracked/release JSON and passed 10 files.
- A first secret scan included the ignored local `.venv` CA bundle. The clean-checkout-equivalent tracked-file scan was rerun and passed.
- The first evidence capture process did not exit because its script extended `Node` under `--script`. It was stopped, the fixture changed to `SceneTree` with deterministic exit, and every final PNG was rendered, dimension/hash checked, and visually inspected. Intermediate WAV/frame/probe outputs were moved to a task-specific temporary folder and are not in the repository.
- The initial full format check correctly identified the new capture fixture. It was formatted with pinned gdformat; the complete 82-file rerun passed lint and format with zero findings.
- `npm` was absent from PATH. The existing pinned Node 24.18.0 installation was located and used without installing or changing dependencies.
- npm warned that three locked packages have install scripts not listed in `allowScripts`; installation, audit, tests, E2E, and builds passed. No lock change was made.

## Exact-head CI and artifacts

All three workflows passed without reruns at implementation head `d808abac70f0cd766b1aa256ce7e946f94baabfa`:

| Workflow | Run/result |
| --- | --- |
| Repository checks | [run 29786745070](https://github.com/SteadyEddieSC/Tales-of-Terror/actions/runs/29786745070), success |
| Companion service and browser tests | [run 29786745078](https://github.com/SteadyEddieSC/Tales-of-Terror/actions/runs/29786745078), success |
| Godot 4.7 tests | [run 29786745133](https://github.com/SteadyEddieSC/Tales-of-Terror/actions/runs/29786745133), success |

| Artifact | ID | GitHub artifact digest |
| --- | --- | --- |
| `gdscript-quality` | `8478731857` | `sha256:33f40e6f99e9513804e9174eecf817a20cbca020819279f221e5ef4117ebada6` |
| `gut-junit-results` | `8478743685` | `sha256:18b41ec7282599371e11e66f6b157f81a9187a871ed14d7327ccd2dfc3a62aed` |

The evidence-only follow-up commit changes this matrix but no runtime, test, workflow, dependency, or vendor file. Its final exact-head workflow runs and artifact IDs/digests are repeated in the commit-linked draft-PR evidence comment.

## Deferred and unclaimed

Deferred: physical controllers, physical phones, household Wi-Fi, television-distance readability, physical/native 4K, router/firewall variation, live Cloudflare, penetration/security/privacy certification, assistive-technology sessions, balance/fun/duration testing, household playtest observation, and long-session stability. Automated and remote screenshot evidence does not certify these surfaces.
