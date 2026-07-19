# v0.0.9 Companion Room Prototype Evidence

**Correction date:** July 19, 2026
**Environment:** Windows, Godot 4.7 stable, Compatibility renderer, official portable Node 24.18.0, local Wrangler Durable Object emulation, Chromium through Playwright
**Data:** Synthetic only

This record is committed with the corrected implementation and is linked from the draft PR by commit SHA. Generated browser captures remain ignored because they contain intentionally revealed synthetic private examples; their exact paths and SHA-256 values identify the inspected originals for PR attachment.

| Required state | Commit-scoped implementation/test evidence | Inspected local capture | SHA-256 |
|---|---|---|---|
| Host room | `CompanionRoomServiceHost.create_room`; `test:e2e:local` waits for the native `COMPANION_E2E_ROOM` event without exposing host authorization | Automated sanitized transcript; no capability-bearing capture | — |
| Browser join/pending | Real Chromium joined the generated local Durable Object room; service pending discovery preceded explicit Godot approval | Prior `output/playwright/browser-join-pending.png` | `e6d23fb63b736bad077e4a0f2fc737a39134c7c5bc84da6c68bcbf008d804546` |
| Authorized private view | Real service approval produced the Seat I privacy gate and filtered view through the native adapter | `.playwright-cli/page-2026-07-19T18-28-04-705Z.png` | `fb299dcb85d7ae67634e521ed41edf6c9141a16dfc52e921578c595611f29824` |
| Wrong-seat denial | Godot atomic authority/RNG assertion; coordinator claim/relay/resume denial tests; browser wrong-seat payload retention test | `.evidence/v0.0.9/captures/companion_denial_960x540.png` | `2f1fe6443452d24f776ce64dc6134ece8320902162743384af03d80acf5b72f5` |
| Accepted action | Genuine browser → local room service → native Godot adapter → `CompanionBridge` → `RulesSession` → room service → browser authoritative ACK; automated history delta is exactly one | `.playwright-cli/page-2026-07-19T18-35-54-427Z.png` | `426c227abf7f0c844b42ebffc7fbe2be0611c2670232908087465ec7be62b7a7` |
| Reconnect | Real Chromium disconnected, removed private DOM state, resumed the exact room/client/Seat I capability tuple, and returned to the privacy gate; native transcript emitted `sameStableSeat: true` | `.playwright-cli/page-2026-07-19T18-35-19-748Z.png` | `37fc08df09b426b76ff70be064fd89d2020e0dc8165206c3a20de9cdaf618a30` |
| Sanitized diagnostics | Recursive forbidden-value assertions, adapter/service log scan, bounded metadata-only diagnostics, and live E2E output scan | `.evidence/v0.0.9/captures/companion_diagnostics_960x540.png` | `56e38c2900f0c640b0d961761868afda97cf22579e1b2c056e2622b42430a6a7` |

## Corrected genuine local path

The real Chromium companion joined room `GZWPB4` over the local Worker WebSocket and waited for host approval. The Durable Object exposed the pending transient client only to the native host endpoint. `CompanionRoomServiceHost` approved existing stable Seat I, retained the host capability only in memory/Authorization headers, drained the reconnect and intent envelopes, and converted them to snake-case internal protocol dictionaries.

After a real disconnect/resume of the exact room/client/seat tuple, the browser revealed its refreshed private view and submitted `Listen at the gate`. `CompanionBridge` revalidated room, connection, seat, message ordering, aggregate authoritative revision, request ID, intent shape, and prompt revision, then called `RulesSession.submit_response`. Godot recorded `historyDelta: 1` and `appliedOnce: true`. The adapter relayed the resulting native acknowledgement; the Durable Object replaced its provisional receipt; only then did Chromium display `Action accepted by the authoritative host` and `Last result: accepted`. No synthetic acknowledgement or independently executed authority fixture was used.

The native transcript contained only a truncated client display, Seat I, room/join metadata, queue counts, revision, history delta, and the explicit path label. A scan found none of the host/resume capability values, private objective payloads, `sealed_archive`, `The Sealed Archive`, `sealed_shelves`, `archive_route`, or `archive_stairs`.

## Automatic validation summary

- Shared cross-runtime fixture: TypeScript-produced wire → Godot internal, Godot-produced wire → TypeScript validation, bidirectional round trip, and malformed/mixed-schema closed failures.
- 26 service/protocol/Worker-Durable-Object tests, including real elapsed rate recovery, heartbeat preservation, client-traffic-independent host loss, inactivity expiry, close/expiry destruction, acknowledgement replacement/expiry, and persisted restart/reload behavior.
- 10 browser privacy/accessibility tests, including wrong-seat/error/acknowledgement/reconnect hidden-board retention checks.
- Godot companion authority/privacy tests plus 40 deterministic 1–8-client simulation sequences.
- `npm run test:e2e:local` repeats the real credential-free local service/native path, same-seat reconnect, authoritative browser ACK, exact one-history-entry application, and sanitized log scan.
- Final full-suite, build, repository, provenance, LFS, JSON, secret, size, whitespace, and GitHub Actions results are recorded in the draft PR handoff rather than pre-claimed here.

## Not performed

Multiple physical phones over household Wi-Fi, Android and iOS device testing, television-distance review, router/firewall variation testing, live Cloudflare deployment, production penetration/security testing, and long-session privacy observation were not performed and are not claimed.
