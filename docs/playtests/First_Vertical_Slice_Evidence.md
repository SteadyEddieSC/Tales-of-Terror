# v0.1.0 First Vertical Slice Evidence Matrix

## Identity

- Issue: #30, v0.1.0 First Vertical Slice.
- Starting protected main: `35d0dbf13fa03c787d432a7b8b8b8fbdc00eb8e2`.
- Branch: `agent/issue-30-first-vertical-slice`.
- Validated implementation/test commit before documentation: `566f299b01b6c2b43ca7b4922cad9f0999480bb5`.
- Exact final implementation head, workflow links, artifact IDs, and artifact SHA-256 digests are published in the commit-linked draft PR evidence comment because a commit cannot contain its own SHA.

## Lifecycle and authority map

| Lifecycle | Player surface | Authority route |
| --- | --- | --- |
| Title/lobby | join, stable-seat roster | `SeatManager` |
| Confirmation/briefing | mode policy, public objective | validated manifest → coordinator |
| Active tale | movement, interactions, prompt/vote/check/card | pawn registry / `BoardState` / `RulesSession` |
| Director opportunity | public/aggregate telemetry | `DirectorTelemetry` → `DirectorRuntime` → proposal applier |
| Social/afterlife | controlled reveal, defeat, Restless action | `RoleSession` |
| Optional companion | claim, filtered view, bounded intent | browser/service relay → `CompanionBridge` → native authority |
| Terminal/ending | mixed public result, rematch/title | Rules/Role public views → coordinator presentation |

The coordinator owns session-scoped references and lifecycle only. Mutable domain state remains exclusively in the named authorities.

## Deterministic and atomic evidence

- Seeds: 4706, 9017, 22031.
- Coverage: every seat count 1–8, 24/24 fixtures, with two independent same-seed executions compared per fixture.
- Terminal reason: `social_outcome`; per-fixture canonical SHA-256 public-history digests are printed by `vertical_slice_simulation_test.gd` and retained in the Godot workflow log.
- Snapshot: mid-tale round-trip preserves the complete authority digest; malformed nested rules version rejects without changing the receiving snapshot.
- Rematch: retains stable seats, clears stage history, reconstructs board at revision zero, and creates fresh rules/Director/role/companion state.
- Failed initialization: missing/malformed manifest leaves the pre-attempt coordinator snapshot unchanged.

## Privacy and companion evidence

- Public coordinator state and ending omit `assigned_role_id` and unrevealed role IDs.
- Director receives only `RoleSession.director_safe_signals()`; no private assignment or objective is supplied.
- No-phone flow acknowledges a private role only through the controlled seat reveal method.
- Optional fake-transport integration proves host-approved stable-seat binding and one prompt intent applied exactly once; duplicate request ID returns the cached idempotent acknowledgement without a second rules-history entry.
- The inherited genuine browser → local service → native Godot → browser acknowledgement E2E remains the cross-runtime proof.

## Automated results

| Surface | Result |
| --- | --- |
| New lifecycle/manifest/privacy/snapshot/rematch test | PASS |
| New multi-seed vertical-slice simulation | PASS, 24/24 |
| Focused GUT | PASS, 8 tests / 36 assertions |
| Inherited Godot suites | PASS: seat, visual, exploration, Living Board, rules, Director, roles, companion |
| Inherited simulations | PASS: Director 90/90, social 157/157, companion 40/40 |
| Companion service/browser | PASS: service 26/26, browser 10/10, strict TypeScript, production dry-run/build |
| Genuine local E2E | PASS exactly once; browser → service → native Godot → browser ACK, history delta 1 |
| Repository/quality | PASS: 73-file lint/format zero, assets, privacy, toolchain, JSON, secrets, size, title, LFS, YAML, whitespace |
| Exact-head GitHub Actions | Pending push; final links and artifacts are added to the draft PR evidence comment |

## Visual evidence

The captures contain only the synthetic title screen; no desktop, account, token, capability, private payload, or personal information is present.

| Capture and descriptive alt text | Dimensions/classification | SHA-256 |
| --- | --- | --- |
| `docs/playtests/evidence/v0.1.0/title_1280x720_virtual_offscreen.png` — “Lantern House first vertical slice title with controller-first join instruction” | 1280×720 virtual/offscreen | `1411358d3ecf291b81c4f256e6e124d9b5d2e5806bef1f18276b3d22cfe8cb1a` |
| `docs/playtests/evidence/v0.1.0/title_1920x1080_virtual_offscreen.png` — “Lantern House first vertical slice title at 1080p with no-phone authority statement” | 1920×1080 virtual/offscreen | `3c77856f228ba79ad644ebc47aec48099d445136952384d9815ba2f7124142da` |
| `docs/playtests/evidence/v0.1.0/title_3840x2160_virtual_offscreen.png` — “Lantern House first vertical slice title rendered at virtual 4K” | 3840×2160 virtual/offscreen | `d62a6446b083a849ad4db860eb6a1256c2d012c9e00a0c4cd40358909313c124` |

The 3840×2160 capture is virtual/offscreen evidence only, not physical/native 4K or television evidence.

## Warnings, reruns, and deferred checks

- During focused development, JSON integer normalization, one incorrect RulesSession initialization-field assumption, one invalid synthetic join-code character, and one outcome-operation ordering conflict were corrected; every affected test was rerun successfully.
- A temporary focused GUT failure probe produced exit code 1 and a failing JUnit report. The probe script, UID, and generated report were removed; the restored suite passed 8 tests and 36 assertions.
- `npm ci` warned that three locked packages have install scripts not yet listed in npm `allowScripts`; install, audit, tests, and builds all succeeded with zero reported vulnerabilities. No dependency file changed.
- Windows headless dummy rendering crashed during the first AVI capture attempt. No evidence file survived. The normal Compatibility renderer then produced exact-dimension PNG-sequence frames; temporary AVI/WAV/probe files were removed and the committed PNGs were inspected.
- No balance, fun, duration, security, or physical-device certification is claimed.
- Deferred: physical controllers/phones, household Wi-Fi, TV distance, native physical 4K, router/firewall variations, live Cloudflare, penetration/privacy certification, balance/fun sessions, and long-session observation.
