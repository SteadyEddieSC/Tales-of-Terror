# v0.0.9.2 GDScript Quality Gate Cleanup Evidence

## Scope and exact commits

- Issue/version: GitHub issue #28, v0.0.9.2 only.
- Protected starting commit: `44a364dd90a134a9ee91c3485df5435d4dbc80e1`.
- Formatter-only commit: `ddc7a7cfb7b645a2b6566acffda222dc87c47e72`.
- Targeted lint/regression commit: `4f1c7456142946cb91e35402c93390bd7480b170`.
- Enforced-gate commit: `c1ab37e2f94c24f35e3f0b07fd907ddd37556407`.
- The final documentation head and exact-head GitHub Actions/artifact evidence are recorded in draft PR #29 after publication; a commit cannot truthfully contain the identity of itself.

No gameplay, rules content, public behavior, native authority, companion behavior, visual design, balance, branding, assets, renderer, viewport, dependency, export, or deployment change is intended.

## Inventory and findings

The inventory is the sorted set of `game/**/*.gd` excluding only `game/addons/gut/**` and `game/.godot/**`. A generated ignored `game/test-results/capture_main_scene.gd` was found before baseline capture, verified as untracked output, removed, and never included. The tracked/reviewed inventory then reproduced the authoritative issue baseline exactly.

| Rule/surface | Baseline | Final |
| --- | ---: | ---: |
| First-party files | 67 | 67 |
| `max-line-length` | 1,210 | 0 |
| `max-returns` | 17 | 0 |
| `max-public-methods` | 3 | 0 |
| `function-arguments-number` | 3 | 0 |
| `unused-argument` | 1 | 0 |
| `class-definitions-order` (issue shorthand: class-order) | 1 | 0 |
| Total `gdlint` findings | 1,235, exit 1 | 0, exit 0 |
| Files failing `gdformat --check` | 64, exit 1 | 0, exit 0 |

No threshold, `.gdlintrc`, suppression, exclusion, dependency, or tool version changed.

## Formatter-only files

Commit `ddc7a7cfb7b645a2b6566acffda222dc87c47e72` contains canonical formatting only for these 64 files:

- `game/assets/theme/visual_tokens.gd`
- `game/src/board/board_debug_overlay.gd`
- `game/src/board/board_definition.gd`
- `game/src/board/board_mutation.gd`
- `game/src/board/board_state.gd`
- `game/src/board/lantern_house_board_definition.gd`
- `game/src/companion/companion_bridge.gd`
- `game/src/companion/companion_fake_transport.gd`
- `game/src/companion/companion_protocol.gd`
- `game/src/companion/companion_room_lab.gd`
- `game/src/companion/companion_room_service_host.gd`
- `game/src/companion/companion_view_builder.gd`
- `game/src/companion/companion_websocket_transport.gd`
- `game/src/companion/companion_wire_codec.gd`
- `game/src/director/director_content.gd`
- `game/src/director/director_diagnostics.gd`
- `game/src/director/director_hud.gd`
- `game/src/director/director_proposal_applier.gd`
- `game/src/director/director_runtime.gd`
- `game/src/director/director_telemetry.gd`
- `game/src/director/lantern_house_director_content.gd`
- `game/src/exploration/exploration_diagnostics.gd`
- `game/src/exploration/exploration_pawn.gd`
- `game/src/exploration/exploration_room.gd`
- `game/src/exploration/exploration_sandbox.gd`
- `game/src/exploration/exploration_showcase.gd`
- `game/src/exploration/interaction_coordinator.gd`
- `game/src/exploration/interaction_resolver.gd`
- `game/src/exploration/pawn_registry.gd`
- `game/src/exploration/pawn_state.gd`
- `game/src/exploration/sandbox_interactable.gd`
- `game/src/exploration/shared_camera_coordinator.gd`
- `game/src/exploration/shared_camera_policy.gd`
- `game/src/input/device_registry.gd`
- `game/src/input/player_input_router.gd`
- `game/src/input/seat_manager.gd`
- `game/src/main/main.gd`
- `game/src/rules/deterministic_rng.gd`
- `game/src/rules/lantern_house_rules_content.gd`
- `game/src/rules/rules_content.gd`
- `game/src/rules/rules_hud.gd`
- `game/src/rules/rules_session.gd`
- `game/src/social/lantern_house_social_content.gd`
- `game/src/social/role_diagnostics.gd`
- `game/src/social/role_hud.gd`
- `game/src/social/role_session.gd`
- `game/src/social/social_content.gd`
- `game/src/ui/input_display_lab.gd`
- `game/src/ui/lab_backdrop.gd`
- `game/src/ui/safe_area_overlay.gd`
- `game/src/ui/seat_accent.gd`
- `game/src/ui/seat_card.gd`
- `game/tests/companion_live_host_test.gd`
- `game/tests/companion_room_test.gd`
- `game/tests/companion_simulation_test.gd`
- `game/tests/director_simulation_test.gd`
- `game/tests/dread_director_test.gd`
- `game/tests/exploration_test.gd`
- `game/tests/living_board_test.gd`
- `game/tests/role_session_test.gd`
- `game/tests/seat_manager_test.gd`
- `game/tests/social_simulation_test.gd`
- `game/tests/turn_event_card_test.gd`
- `game/tests/visual_language_test.gd`

The complete formatter diff was reviewed for strings, multiline strings, operational comments, annotations, typed declarations, collection/call order, condition grouping, node paths, serialized values, protocol fields, action names, and deterministic seed behavior. A normalized gdtoolkit parse/token-tree comparison found no semantic token difference after accounting only for formatter-added parentheses nodes and equivalent string-quote representations.

Pinned gdformat produced Godot-invalid closing indentation for five multiline test lambdas. The formatter-only commit retained those original one-line expressions. Commit 2 replaced them with typed named predicates, which are both Godot-valid and formatter-clean.

## Manual lint-correction files

Commit `4f1c7456142946cb91e35402c93390bd7480b170` manually changes only these 19 first-party GDScript/test files:

- `game/src/board/board_mutation.gd`
- `game/src/board/board_state.gd`
- `game/src/companion/companion_bridge.gd`
- `game/src/companion/companion_room_lab.gd`
- `game/src/director/director_diagnostics.gd`
- `game/src/director/director_runtime.gd`
- `game/src/exploration/exploration_sandbox.gd`
- `game/src/rules/rules_content.gd`
- `game/src/rules/rules_session.gd`
- `game/src/social/lantern_house_social_content.gd`
- `game/src/social/role_diagnostics.gd`
- `game/src/social/role_hud.gd`
- `game/src/social/role_session.gd`
- `game/src/social/social_content.gd`
- `game/tests/dread_director_test.gd`
- `game/tests/exploration_test.gd`
- `game/tests/gut/test_board_privacy_atomicity.gd`
- `game/tests/living_board_test.gd`
- `game/tests/role_session_test.gd`

Behavior-relevant structural refactors are limited to `board_state.gd`, `companion_bridge.gd`, `director_runtime.gd`, `rules_content.gd`, `rules_session.gd`, `role_diagnostics.gd`, `role_session.gd`, `social_content.gd`, and their focused regression helpers. The remaining manual files split exact string literals without changing their values, reorder the enum before constants, apply the underscore unused-argument convention, reshape authored builder inputs into equivalent grouped data, or replace formatter-incompatible test lambdas with typed predicates.

The structural changes preserve rejection priority, mutation order, serialized keys, public names/signatures, and deterministic data order:

- Board snapshot parsing is split into typed header/space/connector/occupancy/history validators; `BoardState` retains mutation authority.
- Companion envelope and intent validation is split into typed fail-closed helpers; exactly-once caching, sequencing, seat authorization, and public authority calls are unchanged.
- Director and rules return-count paths use typed result/rejection helpers; candidate ordering, effect preflight/application, event order, RNG, and snapshots remain unchanged.
- Public methods that exceeded the default class limit remain callable with identical names and signatures through typed inherited contract adapters.
- Rules/social serialization and snapshot validation move to deterministic nested data helpers.
- Read-only role public/private/faction/diagnostics projections and outcome evaluation move to `RoleDiagnostics.SessionProjection`; `RoleSession` retains every assignment, transition, action, effect, outcome commit, history, signal, rejection, state, and RNG mutation.

## Added/strengthened regression

`game/tests/gut/test_board_privacy_atomicity.gd` adds `test_role_projection_split_preserves_privacy_and_diagnostics_contracts`. It verifies inherited public and seat-private dispatch, complete diagnostics previews/eligibility, and the recursive privacy report. Final GUT result is six tests, 24 assertions, zero failures. All inherited direct tests and simulations remain present.

## Negative enforcement probes

Both probes used the explicit inventory, were removed before the documentation/final head, and were never committed:

| Probe | Command/result |
| --- | --- |
| Format | Temporary `game/tests/format_negative_probe.gd`; `gdformat --check` over 68-file probe inventory; identified only that file; exit `1`; 67 other files unchanged |
| Lint | Temporary `game/tests/lint_negative_probe.gd`; `gdlint` over 68-file probe inventory; identified `function-arguments-number` only in that file; exit `1` |
| Residue | Both paths `exists=False`, `tracked=False`; restored inventory `67`; final `gdformat --check` exit `0`; final `gdlint` exit `0` |

PowerShell inventory command:

```powershell
$files = Get-ChildItem game -Recurse -File -Filter *.gd |
  Where-Object { $_.FullName -notlike '*\game\addons\gut\*' -and $_.FullName -notlike '*\game\.godot\*' } |
  Sort-Object FullName
```

## Local validation results

| Surface | Result |
| --- | --- |
| Godot version | `4.7.1.stable.official.a13da4feb` |
| Typed editor/import | PASS, exit 0; zero script/parse/compile/load errors |
| Main-scene smoke | PASS, exit 0; `Terror Turn exploration loaded: v0.0.9` |
| Seat lifecycle | PASS |
| Visual language | PASS |
| Shared exploration | PASS |
| Living Board | PASS |
| Turn/Event/Card | PASS |
| Dread Director | PASS |
| Director simulation | PASS, 90/90 |
| Roles/Factions/Afterlife | PASS |
| Social privacy simulation | PASS, 157/157 |
| Companion authority/privacy | PASS |
| Companion simulation | PASS, 40/40 |
| GUT/JUnit | PASS, 6 tests, 24 assertions, zero failures; JUnit generated |
| Intentional GUT failure propagation | EXPECTED FAIL, exit 1; temporary test identified by JUnit `<failure>`; all probe content removed |
| Python | 3.11.9; hash-enforced install PASS; `pip check`: no broken requirements |
| `pip freeze --all` | Reviewed ten locked packages plus bootstrap `pip==24.0`; exact lock unchanged |
| `gdlint` | PASS, exit 0, zero findings |
| `gdformat --check` | PASS, exit 0, 67 files unchanged |
| Node/npm | Portable Node 24.18.0, npm 11.16.0 |
| `npm ci` | PASS, 117 packages installed/audited |
| `npm audit --audit-level=moderate` | PASS, zero vulnerabilities |
| Strict TypeScript | PASS |
| Service tests | PASS, 26/26 |
| Browser tests | PASS, 10/10 |
| Production builds | PASS, Worker dry-run and Vite browser build |
| Local service smoke | PASS; exact health payload, six-character join code, distinct host capability |
| Browser → service → native Godot → browser E2E | PASS exactly once; authoritative ACK, Seat 1 reconnect, history delta 1 |
| Asset/provenance | PASS, 11 LFS patterns, zero provenance entries |
| Companion privacy policy | PASS |
| Toolchain validator | PASS |
| Tracked JSON | PASS, eight files |
| Secret-file rejection | PASS |
| Oversized-file rejection | PASS, no tracked file over 95 MiB |
| Title/working-name | PASS |
| Git LFS | PASS; reviewed 11 patterns, no unexpected LFS object |
| Workflow YAML | PASS for all three workflows using locked PyYAML 6.0.3 |
| Committed-range whitespace | PASS from starting SHA through enforced-gate head, vendored GUT only excluded |

## Semantic diff review

Review commands:

```text
git diff --ignore-all-space 44a364dd90a134a9ee91c3485df5435d4dbc80e1...c1ab37e2f94c24f35e3f0b07fd907ddd37556407
git diff --name-only 44a364dd90a134a9ee91c3485df5435d4dbc80e1...HEAD -- game/addons/gut requirements-dev.in requirements-dev.txt package.json package-lock.json
```

Every non-whitespace GDScript difference is covered by the manual-file and structural explanations above. No vendored GUT file changed. No dependency file changed. No TypeScript, JavaScript, JSON protocol, scene, asset, `project.godot`, renderer, viewport, or action-pin change occurred. CI/documentation changes are isolated after the GDScript commits.

## Warnings, mistakes, and reruns

- The first post-format regression exposed gdformat 4.5.0's invalid indentation for five multiline test lambdas. The original expressions were restored in the formatter commit, replaced by typed predicates in the lint commit, and the full affected suite passed.
- An intermediate batch runner incorrectly summarized aggregate success after individual failures because of PowerShell script scope. Individual exit lines exposed the failures; the helper was discarded, the failing tests were corrected, and a fail-immediate rerun passed every surface.
- The first unused-argument edit renamed a used parameter instead of the actual unused validation parameter. Strict import caught the compile errors; the used name was restored, the correct unused name received the underscore convention, and import/tests passed.
- The first compact test helper used `PackedStringArray.any()`, which standalone Godot correctly rejected. It was changed to `Array(failures).any(...)`; role/social/companion and GUT reruns passed.
- The first Node attempt found no PATH installation; the next found exact portable Node 24.18.0 but PowerShell blocked `npm.ps1`. Explicit `npm.cmd` then ran every Node surface successfully. The first global-Python YAML attempt lacked PyYAML; the locked virtual-environment interpreter passed all three files.
- npm reported three install scripts pending `allowScripts` review (`esbuild`, `sharp`, `workerd`) after successful install/build; no dependency or lock change was made.

## GitHub Actions and artifacts

All three required workflows must pass on the final exact draft PR head. Workflow URLs, run/job IDs, artifact IDs, and SHA-256 digests are published in the draft PR body and commit-linked evidence comment after GitHub produces them. Expected artifacts are `gdscript-quality` (inventory, lint, format), `gut-junit-results`, and the inherited workflow logs/artifacts.

## Deferred and local-only evidence

Deferred and unclaimed: physical controllers, physical phones, household Wi-Fi, television-distance review, physical/native 4K display review, router/firewall variations, live Cloudflare, penetration/security certification, balance/fun testing, and long-session observation.

Local-only evidence consists of console output, ignored JUnit/build output, the external official Windows Godot binary, the external portable Node runtime, and temporary probe output removed before commit. No engine binary, archive, cache, JUnit, lint log, build output, capability, private payload, or generated report is committed.
