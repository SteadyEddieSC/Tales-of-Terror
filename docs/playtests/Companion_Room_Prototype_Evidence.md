# v0.0.9 Companion Room Prototype Evidence

**Date:** July 13, 2026  
**Environment:** Windows, Godot 4.7 stable, Compatibility renderer, portable official Node 24.18.0, local Wrangler Durable Object emulation, Chromium through Playwright  
**Data:** Synthetic only

This record is committed with the implementation so each result remains tied to the pull request head. Generated captures stay outside Git because they contain intentionally revealed synthetic private-state examples; selected files may be attached to the draft PR. SHA-256 values identify the inspected originals.

| Required state | Commit-scoped implementation/test evidence | Inspected local capture | SHA-256 |
|---|---|---|---|
| Host room | `CompanionBridge.create_room`, `CompanionRoomLab`, room-coordinator creation/collision tests | `.evidence/v0.0.9/captures/companion_host_960x540.png` | `59e2a99c75747f711a9e3bbcde5346bd323ed12a5d6eadb05ab6486ca1c9728e` |
| Browser join/pending | Explicit pending claim in `EphemeralRoom.join`; browser pending-approval state test | `output/playwright/browser-join-pending.png` | `e6d23fb63b736bad077e4a0f2fc737a39134c7c5bc84da6c68bcbf008d804546` |
| Authorized private view | Recursive Godot cross-seat tests; browser privacy-gate/DOM-removal tests | `output/playwright/browser-authorized-private.png` | `8282d2bfc771490230577124f950ec32149b102e9b0c9617551cb5d0b484e273` |
| Wrong-seat denial | Godot atomic-state/RNG assertion; service wrong-seat claim, resume, and relay tests | `.evidence/v0.0.9/captures/companion_denial_960x540.png` | `2f1fe6443452d24f776ce64dc6134ece8320902162743384af03d80acf5b72f5` |
| Accepted action | Godot exactly-once `RulesSession` history assertion; live relay receipt followed by a separate synthetic native-authority acknowledgement | `output/playwright/browser-action-authority-accepted.png` | `ecac5178392d9bea53a6bbd35a776056de54e35a8bee878bfdc51a52417e61ba` |
| Reconnect | Exact room/client/seat resume tests and private-state equality assertion | `output/playwright/browser-reconnected.png` | `504b70a729b606ffc9e4fda315200953b9dfcf86f9951ff9f50094a677e2788d` |
| Sanitized diagnostics | Recursive forbidden-value assertions in Godot/service tests and log scan | `.evidence/v0.0.9/captures/companion_diagnostics_960x540.png` | `56e38c2900f0c640b0d961761868afda97cf22579e1b2c056e2622b42430a6a7` |

## Live local browser attempt

The final local attempt created one Wrangler room without credentials, joined from the real browser UI, drained one sanitized pending request, explicitly approved stable Seat 2, relayed one synthetic filtered private view, submitted exactly one bounded prompt intent at authoritative revision 7, displayed a relay-only waiting state, then displayed acceptance only after a separate host authority acknowledgement at revision 8. A prior pass also completed disconnect, exact-seat resume, private refresh, wrong-seat relay denial, sanitized diagnostics, room close, and local-storage clear. Application logs contained zero capability/private fixture markers, and temporary capability files were deleted.

## Automatic validation summary

- Godot typed import and main-scene smoke passed with every existing suite.
- 14 TypeScript service/protocol tests and 9 browser privacy/accessibility tests passed.
- Director simulation: 90 deterministic sequences.
- Social simulation: 157 deterministic 1–8-player sequences.
- Companion simulation: 40 deterministic 1–8-client sequences.
- Locked install and `npm audit --audit-level=moderate`: zero vulnerabilities.
- Worker dry-run build, browser production build, local Wrangler create/join/relay/reconnect/close flow, asset/provenance, LFS, JSON, secret-file/content, oversized-file, and whitespace validations passed.
- Windows Compatibility launches and captures passed at 1280×720 and 1920×1080. A 3840×2160 launch was requested successfully, but the current desktop capped the captured client area at 2506×1410; this is not claimed as a native 4K visual pass.

## Not performed

Multiple physical phones over household Wi-Fi, Android/iOS device testing, television-distance review, router/firewall variation testing, live Cloudflare deployment, production penetration/security testing, and long-session privacy observation remain deferred.
