# Playtest Readiness and Local Reports

## Guided presentation map

The presentation remains a consumer of `VerticalSliceCoordinator.public_state()` and sanitized seat/companion summaries. It does not own lifecycle or gameplay decisions.

| State | Public guidance | Recovery guidance |
| --- | --- | --- |
| Title | Join the first stable seat; open help | Protected reset consequences in help |
| Lobby | Unowned A/Enter joins; owned A/Enter or Space locks the roster | Reserved-seat reconnect and empty-lobby return |
| Confirmation | Selected mode and 1–2-seat cooperative fallback | Cancel returns to the retained roster |
| Briefing | Public story and objective hierarchy | Confirm begins; no phone required |
| Active | Stage title, controls, prompt/vote submitted and eligible counts | Pause, help, reserved-seat reconnect, protected reset |
| Terminal | Outcome is fixed | Confirm opens the filtered ending |
| Ending | Public outcome, report export, rematch, return | Rematch retains policy-approved stable seats; return resets |

The help surface has five bounded pages: controls, current session, privacy/recovery, build/support identity, and report export. It uses high contrast, television-scale theme text, safe margins, text plus symbols, no flashing, and left/right pagination. X/H and B/Escape close it. The normal route requires no mouse.

## Observation boundary

`PlaytestReport` is a `RefCounted` observer. It accepts public view dictionaries, reduced seat rows, companion aggregates, explicit elapsed seconds, and explicit timestamps. It does not hold authority references and cannot submit prompt/vote responses. `PlaytestReportWriter` is the replaceable writer seam; production uses `LocalPlaytestReportWriter`, whose destination is fixed to `user://playtest_exports` and whose basename validator rejects traversal or arbitrary paths.

Schema version 2 has exact root and nested keys. Bounded arrays retain ordered lifecycle, seat, recovery, prompt/vote progress, rejection-category, and stage-duration observations. Strings and tester feedback are bounded. `completion_reason` is `ending` or `reset`. An ending snapshot begins with `post_ending_disposition=pending` and accepts exactly one bounded update to `rematch`, `return_to_title`, or `reset`; a pre-ending reset uses `not_applicable`. This keeps export available at ending without relabeling or replacing the completed report. Export is deliberate: open help after a report is finalized, go to page 5, then press A/Enter. JSON and Markdown are written together or the operation reports failure. Existing basenames reject instead of being silently overwritten.

The report is finalized before destructive reset. Normal ending finalizes an immutable gameplay/outcome snapshot before export; rematch, return-to-title, or an ending reset updates only its bounded disposition. A clean report begins after reset, return-to-title, or successful rematch. The previous finalized report remains exportable from the title, briefing, or ending help page. Reporting never writes in the background and has no HTTP, WebSocket, UDP, TCP, analytics, crash-reporting, or cloud path.

## Recovery behavior

- Disconnect reserves the same stable seat. Reconnect requires the existing identity rules; another seat cannot answer private input.
- Help during prompt/vote waits leaves the retained transaction, pending definition, revision, responses, operation index, RNG, and all authority digests byte-equivalent.
- Pause remains coordinator-owned. Help does not toggle it.
- Protected reset from help, pause, prompt, vote, or developer lab closes the companion room, clears all authority/session state, closes presentation overlays, and returns to a fresh title.
- Rematch retains only the authored stable roster and constructs clean authorities through the accepted candidate-first path.
- Joypad actions are device-agnostic in the action map. During title/lobby, an unowned A claims one stable seat and consumes that lifecycle event; a later A from an owned seat advances. Unowned devices cannot confirm a locked roster or later lifecycle state. Enter follows the same keyboard ownership rule, while Space remains the explicit confirmation fallback.
- The exploration HUD is canvas layer 10, compact lifecycle guidance is layer 20, and help is layer 30. The 960×540 layout keeps compact guidance clear of the top HUD, bottom controls/reset, and the 1–8-seat prompt/vote panel.

## Test seams

`PlaytestMemoryWriter` provides deterministic success/failure coverage without writing outside approved test locations. The main-scene integration suite drives controller button-0, X, D-pad, B, Y, Enter, and Space events through `Main.tscn`; it covers two-controller joining, every non-active lifecycle transition, export, reset, return-to-title, rematch, report availability, schema contents, JSON/Markdown consistency, and preserved completed-session digests. The standalone suite also exercises the production writer under the Godot user-data folder and deletes its two generated probe files. Committed synthetic schema-v2 JSON and Markdown fixtures live under `game/tests/fixtures/` and contain no personal, desktop, account, token, network, or machine data.
