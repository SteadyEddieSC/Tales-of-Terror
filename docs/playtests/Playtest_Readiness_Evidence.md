# v0.1.1 Playtest Readiness Evidence Matrix

## Release identity

- Issue/version: #33, v0.1.1 — Playtest Readiness & Guided Session UX
- Required starting protected main: `d9a5727d64f83e2c2804a1c7e461ae5a57e54cc2`
- Branch: `agent/issue-33-playtest-readiness`
- Reviewed pre-correction head: `aa9ae664c0b80a4ed398b47134fb02425285b643`
- Correction implementation head: `79f8fc68c3757754b843db2ec3b3b47f480a50f0`.
- Final draft-PR head: recorded in the commit-linked draft-PR evidence comment because a Git commit cannot contain its own hash.
- PR #32 was not modified, merged, closed, rebased, or included.

## Authority and presentation boundary

| Surface | Input | Output | Authority effect |
| --- | --- | --- | --- |
| Compact lifecycle guidance | coordinator public state; existing seat presentation rows | stage/objective/control/wait text | none |
| Help/accessibility | copied public state, seat states, aggregate companion status | four bounded high-contrast pages | none; gameplay router blocked and sandbox presentation stopped while open |
| Report observer | allowlisted public fields, reduced seat rows, companion aggregate, explicit clock values | exact-schema in-memory report | none; no authority reference or mutation method |
| Local writer | finalized JSON/Markdown strings and validated basename | `user://playtest_exports/*.json` and `*.md` | none; no arbitrary path or network API |

Lifecycle guidance covers title, lobby, confirmation, briefing, active prompt/vote and exploration, terminal, ending, rematch, and return. An unowned A/Enter claims one stable seat without confirming on the same event; a later owned A/Enter or Space advances, and all joypad mappings accept every connected device. Help documents stable-seat reconnect, no-phone controlled reveal, optional companions, pause, protected reset, accessibility cues, and report export. Tests prove opening, paging, and closing help preserve the complete coordinator snapshot, authority digest, public-history digest, retained prompt/vote, operation index, responses, and stage checkpoint. Main-scene layers place the ExplorationSandbox HUD at 10, compact guidance at 20, and help at 30; static rectangle checks keep the compact panel clear of the top, bottom, and prompt/vote regions at 960×540.

## Report schema and privacy map

Schema version 2 uses exact root and nested keys. Array caps are lifecycle 64, seats 64, recovery 64, waits 64, rejection categories 32, and stage durations 8. Strings, timestamps, mode/scenario values, terminal reason, and optional notes are bounded. Events carry strictly increasing sequence numbers within each ordered collection. `completion_reason` is `ending` or `reset`; ending reports begin with disposition `pending` and accept one non-overwriting update to `rematch`, `return_to_title`, or `reset`, while pre-ending reset uses `not_applicable`.

| Allowed | Explicitly omitted/rejected |
| --- | --- |
| release/scenario version, seed, seat count, public mode/fallback, completion/disposition | unrevealed role, faction, form, objective |
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
| `game/tests/fixtures/playtest_report_v2.json` | `4d73aebffb37ba2d6dbe9b25b5381d6ab4391f65fcfb650176adf2c956c3de09` |
| `game/tests/fixtures/playtest_report_v2.md` | `20a768d677caa2bb87a3e961f87c89cbc763e8c3451dcfa5c49cad8dfcb91f1b` |

The in-memory writer proves JSON/Markdown success and injected failure. The production writer probe created both files under the approved Godot user-data folder, rejected an existing basename and `../arbitrary_path`, and removed its generated probe files. The committed fixtures are synthetic and byte/semantic checked by the standalone suite. The integrated main route proves export at ending, then preserves the same completed report while recording rematch or return-to-title disposition; protected reset finalizes the pre-reset snapshot separately. JSON/Markdown fields and stored authority/public-history digests remain consistent.

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
| New main-route input integration | PASS: two-controller join, no double-action, confirmation, briefing, terminal, ending, export, reset, title, rematch, keyboard fallback, rendered strings/layout |
| GUT/JUnit | PASS: 20 tests, 91 assertions; JUnit generated |
| Intentional GUT failure propagation | PASS: temporary probe exit 1 and JUnit `<failure>`; probe removed |
| Python lock | PASS: Python 3.11.9, `--require-hashes`, `pip check`, complete frozen graph |
| Node/service/browser | PASS: npm ci; audit 0 vulnerabilities; strict TypeScript; service 26/26; browser 10/10 |
| Builds and smoke | PASS: Worker dry run, browser production build, local health and room creation |
| Genuine E2E | PASS exactly once: browser → local service → native Godot → browser ACK; Seat 1 reconnect; history delta 1 |
| Repository validators | PASS: assets/provenance, companion privacy, playtest privacy, toolchain |
| Repository hygiene | PASS: 10 current JSON files, six YAML files (including three workflows), 594 clean-checkout-scope files; secret/size/title/LFS/whitespace checks |
| GDScript quality | PASS: explicit 83-file first-party inventory, gdlint 0, gdformat check 0 |
| Dependency/vendor drift | PASS: no Python/Node manifest or lock change; vendored GUT diff count 0 |

## Visual evidence

All captures are synthetic Godot render output. They include no desktop, account, token, capability, room secret, client identity, private payload, network detail, machine information, or personal data.

| Capture and descriptive alt text | Classification | SHA-256 |
| --- | --- | --- |
| `docs/playtests/evidence/v0.1.1/lobby_1280x720_virtual_offscreen.png` — Full main-route three-controller lobby with explicit owned-seat roster confirmation and Space fallback | 1280×720 virtual/offscreen | `6e6a3497e518d73c9c94b4426b43f12433ee44122dc8656614ffef370fa3d252` |
| `docs/playtests/evidence/v0.1.1/prompt_1280x720_virtual_offscreen.png` — Full main-route ExplorationSandbox council vote with compact 0/8 wait guidance and the eight-seat Rules HUD | 1280×720 virtual/offscreen | `47a4cd2a8afce35684c7ce40aac1805e2a24055d06e34852066acaf993314c6c` |
| `docs/playtests/evidence/v0.1.1/help_1280x720_virtual_offscreen.png` — High-contrast Help controls over the composed ExplorationSandbox route | 1280×720 virtual/offscreen | `8f86ff31b6a4650223fd4e403392a77279d3482b9ad3dc99ff22398c01248125` |
| `docs/playtests/evidence/v0.1.1/ending_export_1280x720_virtual_offscreen.png` — Full-route ending report privacy summary and successful local JSON/Markdown export | 1280×720 virtual/offscreen | `06b38fb839e6d6d5e909990ffb21811a4bb163bd86bdbb1c826219159d8aa8ef` |
| `docs/playtests/evidence/v0.1.1/lobby_1920x1080_virtual_offscreen.png` — Full main-route three-controller lobby with explicit roster confirmation | 1920×1080 virtual/offscreen | `94e14165b83fa49555535691a72884384472a454c14ac7cb05fa02ab94b34c29` |
| `docs/playtests/evidence/v0.1.1/prompt_1920x1080_virtual_offscreen.png` — Full main-route eight-seat vote with ExplorationSandbox, Help/Diagnostics controls, and bounded wait guidance | 1920×1080 virtual/offscreen | `3a750bf5783236672db7df791b3c825b33fbfd5b29f83963353b881965c87b76` |
| `docs/playtests/evidence/v0.1.1/help_1920x1080_virtual_offscreen.png` — High-contrast Help over the composed active route at 1080p | 1920×1080 virtual/offscreen | `cb6da7d3b199eb5f95d27c7b548b574dd9c3362488e4e7a35813c451681a9742` |
| `docs/playtests/evidence/v0.1.1/ending_export_1920x1080_virtual_offscreen.png` — Full-route ending report privacy and export confirmation at 1080p | 1920×1080 virtual/offscreen | `accaf636f5b86ee7026fdedddb56f104fb0d453408ee237060899af29247bb12` |
| `docs/playtests/evidence/v0.1.1/lobby_3840x2160_virtual_offscreen.png` — Full main-route synthetic stable-seat lobby rendered at virtual 4K | 3840×2160 virtual/offscreen | `9077df4139a80ee090aeeeea86f4116e7d59a16a1689b6e034b626dd91138760` |
| `docs/playtests/evidence/v0.1.1/prompt_3840x2160_virtual_offscreen.png` — Full main-route eight-seat ExplorationSandbox vote rendered at virtual 4K | 3840×2160 virtual/offscreen | `a7ca5b171c41c0922841fa4e11cbf39f2b2ef4b57cea5f2c10683767f55f0a0b` |
| `docs/playtests/evidence/v0.1.1/help_3840x2160_virtual_offscreen.png` — Controller-accessible Help over the composed active route at virtual 4K | 3840×2160 virtual/offscreen | `438f4035cae248e074496aac779312ae721d2891a6526b2dd8eef54b6fa4244f` |
| `docs/playtests/evidence/v0.1.1/ending_export_3840x2160_virtual_offscreen.png` — Full-route local report export confirmation rendered at virtual 4K | 3840×2160 virtual/offscreen | `e8caddc8943353b751bf440a5a0364edc56c9e24a01168e50f2126d10c6bfed4` |

The 3840×2160 files are virtual/offscreen render evidence only. They are not physical/native 4K display or television-distance evidence.

## Changed-file manifest

- Presentation/input: `main.gd`, `vertical_slice_view.gd`, `guided_session_help.gd`, `exploration_sandbox.gd`, focused HUD strings, and device-agnostic joypad bindings in `project.godot`.
- Public projection: one additive `scenario_version` field in `VerticalSliceCoordinator.public_state()`.
- Local reports: three `game/src/playtest/` classes, exact schema-v2 JSON/Markdown fixtures, non-overwriting local writer, and memory writer seam.
- Tests: standalone readiness suite, main-scene input/report integration suite, four focused GUT cases, and full-route capture fixture.
- CI/policy: existing Godot/repository workflows and toolchain validator extended; new report privacy validator.
- Documentation/evidence: two technical guides, facilitator checklist/questionnaire, release notes, changelog/README status, this matrix, and twelve PNGs.

No scenario, authored operation, board/rules/Director/role/pawn/companion authority, TypeScript, JavaScript, protocol JSON, scene, runtime asset, renderer, logical viewport, dependency manifest/lock, or vendored GUT file changed.

## Warnings, failures, fixes, and reruns

- The first local GUT run accidentally used an installed Godot 4.7.0 PATH entry and correctly failed the maintenance-version assertion. One new prompt-progress assertion also expected 3 eligible seats although the authored single-seat prompt expected 1. The exact 4.7.1 executable was located, the assertion corrected, and the suite passed 20/20 and 91 assertions.
- A first JSON sweep included local dependency/cache files and PowerShell's case-insensitive JSON conversion rejected otherwise valid dependency data. The CI-equivalent Python validation was rerun over tracked/release JSON and passed 10 files.
- A first secret scan included the ignored local `.venv` CA bundle. The clean-checkout-equivalent tracked-file scan was rerun and passed.
- The first evidence capture process did not exit because its script extended `Node` under `--script`. It was stopped, the fixture changed to `SceneTree` with deterministic exit, and every final PNG was rendered, dimension/hash checked, and visually inspected. Intermediate WAV/frame/probe outputs were moved to a task-specific temporary folder and are not in the repository.
- The initial full format check correctly identified the new capture fixture. It was formatted with pinned gdformat; that pre-correction 82-file rerun passed. The correction added one first-party suite, and the complete final 83-file inventory passes lint and format with zero findings.
- The first complete correction standalone run found two inherited exact-string assertions that still expected the superseded HUD and confirmation legends. Both assertions were updated to the rendered X/H Help, T-only Diagnostics, and B/Escape return-to-lobby wording; their suites and every remaining standalone suite then passed.
- The first correction JSON/YAML working-tree sweep used the unstaged index list and therefore tried to open the intentionally deleted schema-v1 fixture. The sweep was rerun over current cached-plus-untracked files, including the schema-v2 replacements, and passed 10 JSON and six YAML files.
- `node` was absent from PATH, and PowerShell policy rejected the discovered `npm.ps1` shim. The existing pinned Node 24.18.0 installation and its `npm.cmd` entrypoint were used without installing or changing dependencies.
- npm warned that three locked packages have install scripts not listed in `allowScripts`; installation, audit, tests, E2E, and builds passed. No lock change was made.
- The first correction integration run showed that serialized joypad bindings were device-0-only; the action map was corrected to device-agnostic events and the rerun proved controller 2 can join and all mapped controller actions accept every device.
- The first correction capture probe used the headless dummy renderer, which cannot supply the required rendered viewport texture and was stopped by exact task-scoped PID. Final captures used the Compatibility renderer in an offscreen-positioned virtual window. A first 720p eight-seat vote frame exposed an unsettled glyph atlas and a one-line bottom-control ellipsis; a render-settle interval and 64-pixel HUD region corrected both before all twelve final images were regenerated and inspected.

## Exact-head CI and artifacts

The pre-correction workflow links and artifact claims are superseded. The correction implementation head passed all three workflows without reruns. The final evidence-only head results are kept in the draft PR body because a commit cannot contain its own hash or resulting run IDs.

| Workflow | Run/result |
| --- | --- |
| Repository checks | PASS: [run 29790518724](https://github.com/SteadyEddieSC/Tales-of-Terror/actions/runs/29790518724) |
| Companion service and browser tests | PASS: [run 29790518746](https://github.com/SteadyEddieSC/Tales-of-Terror/actions/runs/29790518746) |
| Godot 4.7 tests | PASS: [run 29790518727](https://github.com/SteadyEddieSC/Tales-of-Terror/actions/runs/29790518727) |

| Artifact | ID | GitHub artifact digest |
| --- | --- | --- |
| `gdscript-quality` | `8480070136` | `sha256:0db39265604c866cb278675aeab054a50b55af02fa72cc3f74e93ce36f9f1b1c` |
| `gut-junit-results` | `8480083516` | `sha256:73ff631c879dcf5105a6dbf61b8f2f731b7226856c0de854ed99fd9060a24d60` |

The evidence-only follow-up commit changes this matrix but no runtime, test, workflow, dependency, or vendor file. Its final exact-head workflow runs and artifact IDs/digests are repeated in the commit-linked draft-PR evidence comment.

## Deferred and unclaimed

Deferred: physical controllers, physical phones, household Wi-Fi, television-distance readability, physical/native 4K, router/firewall variation, live Cloudflare, penetration/security/privacy certification, assistive-technology sessions, balance/fun/duration testing, household playtest observation, and long-session stability. Automated and remote screenshot evidence does not certify these surfaces.
