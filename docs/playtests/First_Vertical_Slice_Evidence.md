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
- Terminal reason: `social_outcome`; snapshot version 2 adds pawn/exploration state to the authority digest, so the corrected exact digests supersede the pre-review values.
- Snapshot: a pawn moved from spawn into the Sealed Archive round-trips with exact position, device/seat ownership, connection/input/focus state, BoardState occupancy, authority digest, and public-history digest. Negative/oversized indices, impossible history, paused briefing, invalid pawn ownership/position, inconsistent occupancy, empty confirmation, and assigned-seat boot/title state all reject without changing the receiver snapshot. A validated assigned roster round-trips in the lobby.
- Stage transaction: a later authored `clue_revealed` no-change rejection after a real prompt wait restores the exact stage-start snapshot, including pawn/board/rules/Director/role/progression state and the cleared prompt; the clean retry commits exactly once.
- Rematch/restore: failed candidate construction preserves the ending and open room byte-for-byte. Successful replacement closes the former room, discards claims/pending/cache/sequence/history, retains stable seats, and creates clean authorities. Restore over an open room closes it before adopting the detached candidate.
- Failed initialization: missing/malformed manifest leaves the pre-attempt coordinator snapshot unchanged.

### Corrected deterministic public-history digests

| Seats | Seed 4706 | Seed 9017 | Seed 22031 |
| --- | --- | --- | --- |
| 1 | `d1b6970dd4bece3fa53ee69324703a07032386598b9cc97d7d7fd683334b2a4b` | `88032c3153f523f5ad4753408b60612420ad8090f0ed666b719cc1ae5de55975` | `83da4755ec8c281d8af0068f2feb9f035c1d1531de69eed385db7375f6c2de2c` |
| 2 | `b89d3126f9c5105a6907ca0c4d8de46f121832e26c6777f24b7677eb999a886a` | `d49c3ba7e354260ee53fd5779a63bf9f4802e3f80774eaf7c76ad94d901c22f9` | `07d73f0b478d47ffce055ec42f59f936a9f4990599176004c0ee5a4233448b5a` |
| 3 | `c5dc4fe8146b745f1bbd321fc6c6ff7f270aef65e1a2f2e2af0b0a540c9eb429` | `3b339eb66dd5fbd409797a948188c73834f9b1e140b37905dd45ef9cbebbbef4` | `2759b4d201249c54cbf9b56f98f709f51fac1226402fa275cd8ce62ecaf825ae` |
| 4 | `5074f7eb869e7abec6835be9c62a60a3c6c31f0c22a63199e735632b642bc284` | `1996aee3cae8894c74da542892d1589036e951862ae92ab8ca17f477806f31e3` | `53a8325d583f1f78249baf9ded5bad7a4cd92603415a66ae8caa668eeebff6d6` |
| 5 | `986b55542bc94a0a466ef24377477ced1924bfd6801f402e64aa499b88e5c642` | `79802194dbce360285d2de69a606f87dbaf754f1938fa44f9635064b49d8fb29` | `989880b7bc19d56f9f664a26e70945f2c9ac8de7e4d3af6fbbbcb4ddd13cda15` |
| 6 | `47c1ad77f894d7c6a00f8a411a24d3eb033c4a72de2c831acc3ac011e6572021` | `65d68519fa479949c96c17509ecaf688b313f10c39d0b99373731aa678846803` | `1335263a55cbf081e4d59308bdad1afe96a03a18aff90a4ae851a6e1e6f1b00e` |
| 7 | `e9d57a0521742591cabe7e6408c1e05afe7bfb8615b655063c1fd9b5c189ecc3` | `96dc0dbed32769f8c9ee03688d7a03c05e891b56346e432ecc51ceb2f30cdda1` | `05f1cea8f8b9c7566ac985cbef55c4de2a4e7e4d90c2c69f4fce3bd5501865c0` |
| 8 | `8b7a38aef59080f47120434b1a0da74dfad13a1d0a90af287675901431f421b5` | `4afb2573f9318142de5a8618bb4e2373e2e0c0611b75c81af037c6eefd29dcc4` | `fa9aa8cdcb890e0da75f429040f0c3ec5711f0d4d371c4c9420b3cc5c43fe4e5` |

## Strict manifest and mode negatives

The corrected validator rejects unknown check IDs, role selectors, transition triggers, action tags, incompatible selector/trigger or selector/action combinations, unknown nested policy keys, non-native companion authority, malformed or duplicate/out-of-range fixture seeds, malformed ordered inputs, incoherent stage conditions/order, and an illegal default/fallback relationship. `initialize_session()` rejects the existing but undeclared `hunted` mode before changing the confirmation snapshot.

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
| Focused GUT | PASS, 10 tests / 44 assertions |
| Inherited Godot suites | PASS: seat, visual, exploration, Living Board, rules, Director, roles, companion |
| Inherited simulations | PASS: Director 90/90, social 157/157, companion 40/40 |
| Companion service/browser | PASS: service 26/26, browser 10/10, strict TypeScript, production dry-run/build |
| Genuine local E2E | PASS exactly once; browser → service → native Godot → browser ACK, history delta 1 |
| Repository/quality | PASS: 74-file lint/format zero, assets, privacy, toolchain, JSON, secrets, size, title, LFS, YAML, whitespace. Inventory increased by one typed first-party `VerticalSliceSnapshotPolicy` helper so the strict coordinator remains within the enforced file-size rule. |
| Exact-head GitHub Actions | Pending corrected push; final links and artifacts are added to the draft PR evidence comment |

## Visual evidence

The captures contain only the synthetic title screen; no desktop, account, token, capability, private payload, or personal information is present.

| Capture and descriptive alt text | Dimensions/classification | SHA-256 |
| --- | --- | --- |
| `docs/playtests/evidence/v0.1.0/title_1280x720_virtual_offscreen.png` — “Lantern House first vertical slice title with controller-first join instruction” | 1280×720 virtual/offscreen | `1411358d3ecf291b81c4f256e6e124d9b5d2e5806bef1f18276b3d22cfe8cb1a` |
| `docs/playtests/evidence/v0.1.0/title_1920x1080_virtual_offscreen.png` — “Lantern House first vertical slice title at 1080p with no-phone authority statement” | 1920×1080 virtual/offscreen | `3c77856f228ba79ad644ebc47aec48099d445136952384d9815ba2f7124142da` |
| `docs/playtests/evidence/v0.1.0/title_3840x2160_virtual_offscreen.png` — “Lantern House first vertical slice title rendered at virtual 4K” | 3840×2160 virtual/offscreen | `d62a6446b083a849ad4db860eb6a1256c2d012c9e00a0c4cd40358909313c124` |

The 3840×2160 capture is virtual/offscreen evidence only, not physical/native 4K or television evidence.

## Warnings, reruns, and deferred checks

- The first correction import exposed that `PackedStringArray(...)` constructor calls are not Godot constant expressions. They were replaced with typed literal constants; typed import then passed.
- An occupancy-negative probe initially changed only the top-level BoardState snapshot while RulesSession still carried its embedded board copy. This exposed and then added an explicit cross-authority board-snapshot equality rule; the negative restore now fails closed.
- During focused development, JSON integer normalization, one incorrect RulesSession initialization-field assumption, one invalid synthetic join-code character, and one outcome-operation ordering conflict were corrected; every affected test was rerun successfully.
- A temporary focused GUT failure probe produced exit code 1 and a failing JUnit report. The probe script, UID, and generated report were removed; the restored suite passed 10 tests and 44 assertions.
- Strengthening pre-session seat coherence temporarily raised the coordinator to 1,003 lines, and `gdlint` correctly rejected it. The pure predicate moved into the typed snapshot-policy helper; the rerun passed all 74 files without a suppression or threshold change.
- The first local JSON sweep included an ignored prior-release evidence file with a UTF-8 BOM and failed. The CI-equivalent tracked-file sweep then passed all nine committed JSON files; the ignored file is not part of the repository or Actions checkout.
- Two attempted PowerShell wrappers for the local service smoke were rejected before execution by the command safety layer. The service was instead run as a managed tool process; health and room creation passed, and the process was terminated.
- `npm ci` warned that three locked packages have install scripts not yet listed in npm `allowScripts`; install, audit, tests, and builds all succeeded with zero reported vulnerabilities. No dependency file changed.
- Windows headless dummy rendering crashed during the first AVI capture attempt. No evidence file survived. The normal Compatibility renderer then produced exact-dimension PNG-sequence frames; temporary AVI/WAV/probe files were removed and the committed PNGs were inspected.
- No balance, fun, duration, security, or physical-device certification is claimed.
- Deferred: physical controllers/phones, household Wi-Fi, TV distance, native physical 4K, router/firewall variations, live Cloudflare, penetration/privacy certification, balance/fun sessions, and long-session observation.
