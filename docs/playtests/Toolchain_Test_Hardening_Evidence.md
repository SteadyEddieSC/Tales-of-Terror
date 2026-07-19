# v0.0.9.1 Toolchain Test Hardening Evidence

**Issue:** #26

**Correction implementation source commit:** `3c940beea41c3295b195e06297537619bde8cad3` (this later evidence-only documentation update does not change toolchain or runtime behavior)

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
| GDScript Toolkit | PyPI `gdtoolkit==4.5.0`, source commit `b7a4935fc6483d51837f7080598dad456f4f7645`; direct selection in `requirements-dev.in`; complete hash lock in `requirements-dev.txt` | Installed with `--require-hashes` on Windows and Linux; MIT notice retained |
| Python lock generator | `pip-tools==7.6.0` under Python 3.11.9 | Verified from PyPI; local maintenance only; exact command is recorded below and in the technical guide |
| Python | 3.11.9; `actions/setup-python` commit `ece7cb06caefa5fff74198d8649806c4678c61a1` | Exact local/CI runtime pin; bootstrap pip was 24.0 on Windows and 26.1.2 on Linux |

## Corrected Python lock evidence

`requirements-dev.in` contains only `gdtoolkit==4.5.0`. The lock was generated from a temporary clean Python 3.11.9 environment with `pip-tools==7.6.0`:

```text
python -m piptools compile --generate-hashes --allow-unsafe --resolver=backtracking --strip-extras --no-emit-index-url --output-file=requirements-dev.txt requirements-dev.in
```

The resolved install set is `colorama==0.4.6`, `docopt-ng==0.9.0`, `gdtoolkit==4.5.0`, `lark==1.2.2`, `mando==0.7.1`, `PyYAML==6.0.3`, `radon==6.0.1`, `regex==2026.7.19`, `setuptools==83.0.0`, and `six==1.17.0`. Every package has one or more SHA-256 distribution hashes in the committed lock. No editable, ranged, wildcard, URL, or moving-branch requirement is present.

Windows PC-Office and Linux GitHub Actions both ran:

```text
python -m pip install --disable-pip-version-check --require-hashes --requirement requirements-dev.txt
python -m pip check
python -m pip freeze --all
```

Both hash-enforced installs passed. Both `pip check` invocations reported no broken requirements, and both freezes contained the same ten-package lock; only the interpreter bootstrap pip differed (`24.0` Windows, `26.1.2` Linux). Local `gdlint --version` returned `gdlint 4.5.0`.

## Corrected whitespace evidence

The clean correction implementation range passed with exit `0`:

```text
git diff --check 217b570374e68043128e1264f9fe3a2f1bee59a6...3c940beea41c3295b195e06297537619bde8cad3 -- . ':(exclude)game/addons/gut/**'
```

For the negative probe, a temporary first-party `docs/playtests/whitespace_negative_probe.md` containing trailing spaces was added to a synthetic, unreferenced commit through a temporary Git index. The exact range command was:

```text
git diff --check HEAD...c334e8e84d8a46953043dd0184fbaca438316979 -- . ':(exclude)game/addons/gut/**'
```

It reported `docs/playtests/whitespace_negative_probe.md:1: trailing whitespace.` and returned exit `2`. The probe file and temporary index were removed before the correction commit. GitHub Actions `Foundation validation` also passed its committed-range whitespace step on the real pull-request range.

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
| Hash-locked Python install | Python 3.11.9 Windows and Linux; `--require-hashes`, `pip check`, `pip freeze --all` | PASS on both platforms; same ten locked packages; no broken requirements |
| TypeScript/service/browser | locked install, audit, typecheck, 26 service tests, 10 browser tests, production builds | PASS; `npm ci`, zero-vulnerability audit, strict typecheck, 26/26 service, 10/10 browser, Worker/browser builds |
| Repository policy | asset/provenance, companion privacy, toolchain lock, tracked JSON, secrets, oversized files, title, LFS, workflow YAML, committed-range whitespace | PASS locally and in GitHub Actions at `3c940beea41c3295b195e06297537619bde8cad3` |

## GitHub Actions evidence

All preserved status-check identities passed at correction implementation commit `3c940beea41c3295b195e06297537619bde8cad3`:

- `Godot 4.7 headless validation`: PASS, [run `29708341466`](https://github.com/SteadyEddieSC/Tales-of-Terror/actions/runs/29708341466), job `88248829929`; Linux hash-lock install, `pip check`, freeze, every listed legacy test/simulation, native E2E, and GUT completed successfully.
- `Foundation validation`: PASS, [run `29708341481`](https://github.com/SteadyEddieSC/Tales-of-Terror/actions/runs/29708341481), job `88248829962`; the corrected committed-range whitespace step passed.
- `Protocol, room service, and browser validation`: PASS, [run `29708341485`](https://github.com/SteadyEddieSC/Tales-of-Terror/actions/runs/29708341485), job `88248829951`.
- `gdscript-quality-baselines`: artifact `8448518879`, digest `sha256:2af74408a1470138d8853e14cfe7b63e41c97baafb76d21095ab20af128f9a2e`, expires August 2, 2026.
- `gut-junit-results`: artifact `8448521870`, digest `sha256:654721b4cf02727bdbf68c2aefc3100fc09c8009314f7ea567d58feb978c88a3`, expires August 2, 2026; CI reported five tests and 19 assertions passing.

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
| 1280×720 | `docs/playtests/evidence/v0.0.9.1/main_scene_1280x720_virtual_offscreen.png`; SHA-256 `13743BB38D7D309ED75DB9F6305956A92F9679C861699B39FE05F81A508FABB9` | Repository-published virtual/off-screen exact-resolution capture produced by the official Windows engine | No new clipping, scaling, focus, rendering, or safe-margin defect observed |
| 1920×1080 | `docs/playtests/evidence/v0.0.9.1/main_scene_1920x1080_virtual_offscreen.png`; SHA-256 `0E374F825C73FFF92A604D77785D669E4FD3F125C23C3301C035E124807DFE83` | Repository-published virtual/off-screen exact-resolution capture produced by the official Windows engine | No new clipping, scaling, focus, rendering, or safe-margin defect observed |
| 3840×2160 | `docs/playtests/evidence/v0.0.9.1/main_scene_3840x2160_virtual_offscreen.png`; SHA-256 `8860C7E1847A80221B9FBD4FDCE229818645A232A34E0A44652AB1A7AC61E37F` | Repository-published virtual/off-screen exact-resolution capture; never treated as physical 4K display or television evidence | No new clipping, scaling, rendering, or safe-margin defect observed |

The original ignored captures still match the hashes recorded in the earlier PR evidence (`039DAE…`, `E065F9…`, and `2BA7E3…`). Pillow 12.1.0 losslessly optimized the committed copies from 182,182 to 177,404 bytes, 248,371 to 239,934 bytes, and 543,221 to 525,759 bytes. Pixel-by-pixel comparison confirmed identical modes, dimensions, and pixels. Visual inspection confirmed synthetic unassigned-seat game data only, with no desktop, account, token, capability, private payload, or personal information.

The project was also opened in the official 4.7.1 editor and the main scene was launched in a real visible window on PC-Office. The project render was 1920×1080 and scaled into the editor's embedded game area. On the clean single-editor run, Output showed the debug adapter and language server starting, OpenGL 3.3 Compatibility on the Radeon RX 6650 XT, and `Terror Turn exploration loaded: v0.0.9`; the Debugger was empty with zero errors and warnings. A first attempt while the legacy 4.7 editor still held both server ports was discarded and repeated cleanly.

Pre-existing presentation note kept outside this tooling release: the prototype screen still displays `VISUAL LANGUAGE LAB / v0.0.3 / PROVISIONAL MARK` even though the runtime identifies v0.0.9. No player-facing redesign or label change was made.

## Warnings and deferred checks

- The large lint/format baseline is an explicit warning and v0.1.0 gate, not a passing required check.
- The initial GitHub Godot run at `99ac64be3d84a0ff3d8e69b8081e474780f0a32c` stopped before tests because `setup-python`'s pip cache did not know about `requirements-dev.txt`. Commit `f99127f169d6582bb421503fd28ebbf4b6459647` adds the explicit cache dependency path; this was CI wiring only and did not change runtime or gameplay behavior.
- Three local command-shaping attempts were rerun correctly and are not product failures: `python -m gdlint --version` was replaced by the installed `gdlint.exe --version`; an ignored `.tmp` whitespace probe was replaced by the tracked-shape Markdown probe above; and an overbroad JSON walk that entered ignored `node_modules` was replaced by the clean-checkout-equivalent tracked-JSON check.
- npm 11.16.0 completed the locked install but warned that three dependency install scripts are not allowlisted by npm's local `allowScripts` feature. No install failed, the lockfile was unchanged, the audit found zero vulnerabilities, and no policy was weakened in this PR.
- Physical controllers, physical phones, household Wi-Fi, television-distance review, native-4K-display inspection, router/firewall variation, live Cloudflare deployment, penetration/security testing, balance/fun testing, and long-session observation were not performed and are not claimed.
- Generated JUnit, lint/format logs, engine archives/executables, caches, and original local captures remain ignored local or GitHub Actions artifacts. Only the three small, sanitized, losslessly optimized review PNGs listed above are committed.
