# Tale Library UX and Route Boundary

## Player route

v0.1.6 uses this normal shared-screen route:

`Title -> Seat Lobby -> Mode Confirmation -> Tale Library -> Public Briefing -> Active Tale -> Ending -> Rematch or Title`

The production Library truthfully enumerates one entry from `TaleCatalog`: `lantern_house_vertical_slice`, displayed as “Lantern House” through its governed localization record. It does not imply locked, upcoming, purchasable, or unavailable Tales.

## Presentation projection

`TaleSelectionState.library_entries()` creates the only Library projection. `TaleLibraryFlow` owns only pre-session route/focus orchestration and delegates candidate construction to the coordinator. Every entry contains the stable Tale ID, governed display name, governed briefing, governed objective, catalog compatibility seat bounds, and booleans for focused, selected, and confirmed state. The normal view never receives or renders package paths, provider IDs, hashes, source-ledger records, runtime classes, or internal diagnostics.

The UI may render and request focus or confirmation. It does not parse catalog files, validate packages, interpret provider declarations, or construct board/rules/Director/social authorities.

## Controls

| Input | Library behavior |
| --- | --- |
| D-pad or left stick | Move focus in stable catalog order |
| Arrow keys or WASD | Development keyboard focus fallback |
| A or Enter | Validate, select, prepare, and enter Public Briefing |
| B or Escape | Return to Mode Confirmation |
| X or H | Open the shared Help surface |
| Hold Y or R for 1.5 seconds | Existing protected reset to Title |

One-entry focus wraps deterministically to the same entry. Multi-entry ordering and non-default selection are proven only with export-excluded synthetic fixtures.

## Atomicity and restoration

Confirmation prepares a complete candidate through `TaleSelectionState`, `TaleProviderRegistry`, package validation, manifest/content validation, mode authorization, and the existing coordinator authority builder. Selection and session authorities commit only after every step succeeds. Failure retains the previous selected entry, focus, lifecycle, stable seats, ownership, and mode.

The normal UI shows a fixed internal-build recovery message and points the facilitator to Help for build identity. Detailed diagnostics remain internal and never enter normal UI, snapshots, reports, public history, or Companion projections.

B/Escape from Public Briefing discards prepared authorities and returns to the Library with focus, confirmed/selected Tale, seats, ownership, and mode retained. Starting Active Tale locks selection for the session. Rematch reuses the validated selection; protected reset returns to the production default.

## Security-release boundary

Issue #44 remains open. v0.1.6 changes no npm dependency, Companion source/protocol/configuration, room-service source, Wrangler/Miniflare configuration, Cloudflare behavior, or GitHub Action pin. Companion services are not deployed or publicly released. The known unchanged GHSA-f88m-g3jw-g9cj audit failure is recorded separately from functional Companion results.
