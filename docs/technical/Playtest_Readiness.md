# Playtest Readiness and Local Reports

## Guided presentation map

The v0.1.1 presentation remains a consumer of `VerticalSliceCoordinator.public_state()` and sanitized seat/companion summaries. It does not own lifecycle or gameplay decisions.

| State | Public guidance | Recovery guidance |
| --- | --- | --- |
| Title | Join the first stable seat; open help | Protected reset consequences in help |
| Lobby | Join/leave and roster count | Reserved-seat reconnect and empty-lobby return |
| Confirmation | Selected mode and 1–2-seat cooperative fallback | Cancel returns to the retained roster |
| Briefing | Public story and objective hierarchy | Confirm begins; no phone required |
| Active | Stage title, controls, prompt/vote submitted and eligible counts | Pause, help, reserved-seat reconnect, protected reset |
| Terminal | Outcome is fixed | Confirm opens the filtered ending |
| Ending | Public outcome, report export, rematch, return | Rematch retains policy-approved stable seats; return resets |

The help surface has four bounded pages: controls, current session, privacy/recovery, and report export. It uses high contrast, television-scale theme text, safe margins, text plus symbols, no flashing, and left/right pagination. X/H and B/Escape close it. The normal route requires no mouse.

## Observation boundary

`PlaytestReport` is a `RefCounted` observer. It accepts public view dictionaries, reduced seat rows, companion aggregates, explicit elapsed seconds, and explicit timestamps. It does not hold authority references and cannot submit prompt/vote responses. `PlaytestReportWriter` is the replaceable writer seam; production uses `LocalPlaytestReportWriter`, whose destination is fixed to `user://playtest_exports` and whose basename validator rejects traversal or arbitrary paths.

Schema version 1 has exact root and nested keys. Bounded arrays retain ordered lifecycle, seat, recovery, prompt/vote progress, rejection-category, and stage-duration observations. Strings and tester feedback are bounded. Finalization reasons are exactly `ending`, `reset`, `return_to_title`, or `rematch`. Export is deliberate: open help after a report is finalized, go to page 4, then press A/Enter. JSON and Markdown are written together or the operation reports failure.

The report is finalized before destructive reset. A clean report begins after reset or successful rematch. The previous finalized report remains exportable from the title or ending help page. Reporting never writes in the background and has no HTTP, WebSocket, UDP, TCP, analytics, crash-reporting, or cloud path.

## Recovery behavior

- Disconnect reserves the same stable seat. Reconnect requires the existing identity rules; another seat cannot answer private input.
- Help during prompt/vote waits leaves the retained transaction, pending definition, revision, responses, operation index, RNG, and all authority digests byte-equivalent.
- Pause remains coordinator-owned. Help does not toggle it.
- Protected reset from help, pause, prompt, vote, or developer lab closes the companion room, clears all authority/session state, closes presentation overlays, and returns to a fresh title.
- Rematch retains only the authored stable roster and constructs clean authorities through the accepted candidate-first path.

## Test seams

`PlaytestMemoryWriter` provides deterministic success/failure coverage without writing outside approved test locations. The standalone suite also exercises the production writer under the Godot user-data folder and deletes its two generated probe files. Committed synthetic JSON and Markdown fixtures live under `game/tests/fixtures/` and contain no personal, desktop, account, token, network, or machine data.
