# v0.0.9.1 Toolchain Test Hardening Evidence

**Issue:** #26

**Implementation commit:** `IMPLEMENTATION_COMMIT_PENDING`

**Environment:** PC-Office, Windows, official Godot 4.7.1-stable, Compatibility renderer

**Data:** Synthetic only; no credentials, capabilities, private payloads, or real personal data

## Pre-edit baseline inventory

The clean inventory was recorded on protected `main` at `217b570374e68043128e1264f9fe3a2f1bee59a6` before the issue branch was created:

- 254 tracked files, 64 tracked GDScript files, 55 documentation files, and three GitHub Actions workflows.
- Twelve existing direct Godot entrypoints: eleven regressions/simulations plus the live native companion host harness.
- Existing required check identity `Godot 4.7 headless validation`, companion validation, and `Foundation validation` present.
- Local Godot `4.7.stable.official.5b4e0cb0f` installed through WinGet; Python 3.11.9 present; GUT, GDScript Toolkit, Node, and npm absent from the active shell path.
- Compatibility renderer, 960×540 viewport, Godot 4.7 feature marker, native authority, locked npm dependency graph, direct official Godot CI download, and all legacy coverage confirmed before editing.

## Pinned artifact and tool evidence

| Item | Exact evidence | Result |
| --- | --- | --- |
| Godot release | Official `godotengine/godot-builds` tag `4.7.1-stable`, published July 14, 2026; newest stable release at implementation time | Verified |
| Windows archive | `Godot_v4.7.1-stable_win64.exe.zip`; SHA-512 `a6b02c527c18ba9936e63562032701432b2dc57d98d6483ceaccb00fe14af16af5773ae8a55e7b4d614edf121c4d9e420d870f804edb1dac16362298a01ce6c4` | Published checksum matched downloaded archive |
| Windows executable | `C:\Users\Eddie\Documents\Codex\Tools\Godot\4.7.1-stable\Godot_v4.7.1-stable_win64_console.exe`; output `4.7.1.stable.official.a13da4feb` | Verified; external and uncommitted |
| Linux archive | `Godot_v4.7.1-stable_linux.x86_64.zip`; SHA-512 `4ccdab7a48eeccbe8819a2fc1f6262f8d72065d98601bcb3743fcbd7ebd39f373758a788ee3293a05ec5b2c48538266c437404312e372225cd2df273945a2de9` | Published checksum pinned before CI execution |
| GUT | Tag `v9.7.1`, commit `aeb5d4f3f7f0a6c9b5e178876d6c99b791fda605`, `game/addons/gut` | 259 tagged files copied byte-for-byte; MIT and bundled font notices retained |
| GDScript Toolkit | PyPI `gdtoolkit==4.5.0`, source commit `b7a4935fc6483d51837f7080598dad456f4f7645`; `requirements-dev.txt` | Installed in local virtual environment; MIT notice retained |
| Python | 3.11.9; `actions/setup-python` commit `ece7cb06caefa5fff74198d8649806c4678c61a1` | Exact local/CI runtime pin |

## Automated validation matrix

| Surface | Exact command/scope | Result at implementation commit |
| --- | --- | --- |
| Typed script/import | Godot 4.7.1 `--headless --editor --path game --quit` | PASS; all first-party and vendored scripts/classes imported without error |
| Main scene | Godot 4.7.1 `--headless --path game --quit-after 3` | PASS; `Terror Turn exploration loaded: v0.0.9` |
| Seat lifecycle | `seat_manager_test.gd` | PASS |
| Visual language | `visual_language_test.gd` | PASS |
| Shared exploration | `exploration_test.gd` | PASS |
| Living Board | `living_board_test.gd` | PASS |
| Turn/Event/Card | `turn_event_card_test.gd` | PASS |
| Dread Director | `dread_director_test.gd` | PASS |
| Director simulation | `director_simulation_test.gd`; 90 deterministic sequences | PASS: 90/90 |
| Roles/Factions/Afterlife | `role_session_test.gd` | PASS |
| Social simulation/privacy | `social_simulation_test.gd`; 157 deterministic 1–8-seat sequences | PASS: 157/157 |
| Companion authority/privacy | `companion_room_test.gd` | PASS |
| Companion simulation | `companion_simulation_test.gd`; 40 deterministic 1–8-client sequences | PASS: 40/40 |
| Native local E2E | browser protocol client → local room service → native host adapter → `CompanionBridge` → existing authority → browser ACK, exactly once | PASS; reconnect retained Seat I and rules history delta was exactly one |
| GUT/JUnit | Three scripts, five tests, 19 assertions; `gut-junit.xml` | PASS: 5/5 and 19/19; intentional temporary failure probe returned exit 1 and produced failure XML |
| `gdlint` baseline | 67 first-party files, vendored/cache excluded | INFORMATIONAL: exit 1, 1,235 findings; complete local/CI artifact; no parser blocker; new GUT files clean |
| `gdformat --check` baseline | Same explicit first-party list; no rewrite | INFORMATIONAL: exit 1, 64 existing files after two new GUT files were locally formatted; initial pre-correction baseline was 66/67 |
| TypeScript/service/browser | locked install, audit, typecheck, 26 service tests, 10 browser tests, production builds | PASS; `npm ci`, zero-vulnerability audit, strict typecheck, 26/26 service, 10/10 browser, Worker/browser builds |
| Repository policy | asset/provenance, companion privacy, toolchain pins, JSON, secrets, oversized files, title, LFS, workflow YAML, whitespace | PASS locally; GitHub Actions pending |

## Finding categorization

| Category | Count/observation | Disposition |
| --- | --- | --- |
| Correctness/typed-GDScript | No parser or typed-syntax incompatibility | No standards weakened |
| Targeted style/complexity | 25 non-line-length findings | Separate bounded cleanup |
| Line-length/style | 1,210 | Separate bounded cleanup |
| Formatter-only | 66/67 initial files | Separate formatting change; no mass diff here |
| Parser/tool limitations | None | gdtoolkit 4.5.0 retained |

v0.1.0 remains blocked until required lint/format cleanup is merged. No follow-up or v0.1.0 issue was created by this release.

## Windows launch and capture matrix

| Requested output | Capture path | Classification | Inspection result |
| --- | --- | --- | --- |
| 1280×720 | Pending | Pending | Pending |
| 1920×1080 | Pending | Pending | Pending |
| 3840×2160 | Pending | Pending; never treated as native 4K TV evidence | Pending |

Output/Debugger inspection, focus, clipping, scaling, rendering, and safe-margin observations will be recorded after the final implementation commit. Pre-existing visual defects, if any, remain separate and do not expand this tooling PR.

## Warnings and deferred checks

- The large lint/format baseline is an explicit warning and v0.1.0 gate, not a passing required check.
- npm 11.16.0 completed the locked install but warned that three dependency install scripts are not allowlisted by npm's local `allowScripts` feature. No install failed, the lockfile was unchanged, the audit found zero vulnerabilities, and no policy was weakened in this PR.
- Physical controllers, physical phones, household Wi-Fi, television-distance review, native-4K-display inspection, router/firewall variation, live Cloudflare deployment, penetration/security testing, balance/fun testing, and long-session observation were not performed and are not claimed.
- Generated JUnit, lint/format logs, engine archives/executables, caches, and local captures remain ignored local or GitHub Actions artifacts rather than repository files.
