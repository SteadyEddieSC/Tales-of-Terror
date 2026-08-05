# DH-UX-001 — Shared-Screen UX Architecture and Stage Flows v1

## Standing

This document registers an external advisory planning direction with Release
Coordination corrections. It is not a Godot scene, runtime state machine, final
layout, final localization, accessibility claim, or human-evidence record.

## Board-first questions

At all times the shared display should make it possible to answer:

1. What stage is active?
2. What Tide or transformation state is active?
3. What public objective matters?
4. Which stable seat owns the current action?
5. Where are the public seats?
6. Which routes and actions are legal?
7. What is only a reversible preview?
8. What will commit if confirmed?
9. Which information is public?
10. How can authorized narration, transcript, help, or recovery be reached?

Atmosphere may frame these answers. It may not hide them.

## Authority ownership

| Concern | Authoritative owner | Presentation responsibility |
|---|---|---|
| Board geometry, spaces, connectors, pawn positions, Tide mutations, and route reachability | `BoardState` | Draw the authorized public board without inventing legality |
| Legal intents, stage progression, Bellhouse/Council/High Water/Last Light/public-ending resolution | `RulesSession` | Render authorized public state and legal choices |
| Private roles, objectives, factions, transformations, attribution, and controlled reveal | `RoleSession` | Never expose outside an authorized private surface |
| Safe handoff, control transfer, rematch, and title cleanup | Session coordinator | Display status and request only when the authority exposes a legal intent |
| Focus, preview, animation, emphasis, captions, and presentation replay | Presentation | Never mutate authoritative state |

No advisory control creates a new runtime field or legal action.

## Layout modes

### Board-first

Use for Low Tide, ordinary movement, inspection, route preview, and settled High
Water.

- The board remains primary.
- Upper status and stable-seat rail remain persistent.
- Captions may use the governed lower-board reserve.
- A persistent decision drawer is absent.
- Route and seat occlusion require later implementation evidence.

### Decision-focus

Use for Bellhouse, Lighthouse Council, authorized bargains, Last Light,
confirmations, and invalid-action recovery.

- Board context remains visible.
- A right-side drawer may present context, public state, legal choices,
  reversible preview, consequences, confirm/cancel, details, transcript,
  replay, and help.
- Every listed control is conditional on current legal authority.
- An irreversible commitment always requires a second explicit action.

### Transformation

Use for High Water and authorized public form changes.

- Before, transition, and settled states remain distinguishable.
- Played, skipped, reduced-motion, interrupted, restored, and presentation-
  replay paths converge on the same authoritative public state.
- Presentation may not rerun reducers, RNG, events, transformations, ending
  resolution, attribution, or cleanup.
- Critical objective, route summary, and seat identity remain visible after the
  effect settles.

### Outcome-attribution

Use for ending resolution and epilogue.

- Show the authority-owned public ending result and public seat outcomes.
- Do not replace mixed outcomes with a universal victory/defeat banner.
- Private attribution remains behind controlled reveal.
- Public epilogue, acknowledgement, transcript, and presentation replay may be
  offered only where authorized.

### Private shield

When an authorized private surface is used, the shared screen shows only:

> Private handoff in progress. Shared play will resume after acknowledgement.

The shield shows no seat identity, desirability, role, faction, target,
objective, item, transformation, result category, or timing hint. Private
content never enters public captions, transcript, presentation replay, mirrored
output, diagnostics, Director input, or other seat summaries.

Private-surface technology remains unresolved.

### System overlay

Use for settings, pause, reconnecting, game control, takeover, transcript,
replay, help, admission, and facilitator operations only when those operations
are already authorized.

- Preserve the current atomic action.
- Do not steal focus from a critical confirmation.
- Queue authority transfer to a safe handoff.
- State whether the overlay is informational or authority-affecting.

## Stable-seat identity

Each stable seat should use at least four non-color channels:

- stable-seat number or Roman numeral;
- fixed base silhouette;
- fixed edge pattern;
- fixed public crest;
- optional color accent;
- persistent left-to-right order.

Public form may change. Stable-seat identity does not.

A tile may show only authorized public state: seat identity, public character or
form, public location, public condition, authorized public counts, control
source, and required-action state. It may not expose private role, private
objective, hidden faction, private item marker, private transformation terms,
desirability, or private ending attribution.

## Interaction state model

| State | Meaning | Authority mutation |
|---|---|---|
| `available` | A legal action exists | None |
| `focused` | Current controller focus | None |
| `selected_preview` | Reversible public-safe preview | None |
| `confirmation_pending` | Explicit commit boundary | None |
| `committed` | Authority accepted the action | Authority only |
| `resolving` | Presentation depicts the committed result | No additional mutation |
| `settled` | Persistent public result | None |
| `unavailable` | Action is not legal now | None |
| `warning` | Consequence has not committed | None |
| `recovery` | Public-safe correction | None |
| `private_shield` | Shared display is neutral | None |
| `reconnecting` | Same seat reserved | No identity reset |
| `game_controlled` | Same seat under surrogate control | No identity reset |
| `takeover_pending` | Existing authorized safe handoff queued | No transfer yet |

Required planning sequence:

`available → focused → selected_preview → confirmation_pending → committed → resolving → settled`

No first focus movement may commit an irreversible action.

## Stage flows

### `low_tide_arrival_v1`

- Mode: board-first.
- Primary task: understand board, objective, routes, seats, Tide evidence, and
  current actor.
- Entry focus: objective, then active stable seat.
- Selection remains reversible until an existing legal action confirms.

### `bellhouse_ledger_v1`

- Mode: decision-focus.
- Primary task: compare public record evidence, unresolved position, and legal
  priorities.
- No hidden-seat highlight, correct-answer glow, moral label, or focus commit.
- Selected priority → public consequence preview → explicit confirmation.

### `lighthouse_council_v1`

- Mode: decision-focus.
- Primary task: support group discussion among legal public directions.
- No hidden-faction hint or false urgency.
- Preview and inspection remain non-mutating.

### `high_water_v1`

- Mode: transformation, then board-first.
- Present final pre-transform state, warning/acknowledgement, optional
  presentation, route submergence, water-only route reveal, localized landmark
  reaction, settled summary, and control return.
- The resulting Tide, routes, mechanisms, public seats, objective, and legal
  actions come from authority.

### `last_light_v1`

- Mode: decision-focus with board context.
- Preview may show only an already-authorized public-safe reversible state.
- It may not predict hidden outcomes, rank desirability, or create a legal
  action.
- Preview → explicit confirmation → authority-owned commitment → presentation
  → settled public state.

### `ending_resolution_v1`

- Mode: outcome-attribution.
- Present the `RulesSession` public ending result.
- Do not reveal private attribution, hidden faction, private target, or private
  objective.

### `epilogue_attribution_v1`

- Mode: public outcome-attribution plus authorized private surface.
- Public sequence: epilogue, consequence montage, public seat outcomes,
  acknowledgement, and optional presentation replay.
- Private sequence: neutral shield, authorized private surface,
  acknowledgement, clear private projection, return to public epilogue.
- `RoleSession` retains private attribution authority.

### `rematch_title_cleanup_v1`

- Mode: system overlay.
- Presentation may request a currently legal cleanup option.
- The session coordinator owns reset, rematch, exit, and title return.
- Interrupted cleanup preserves the last authoritative checkpoint.

## Cross-cutting continuity

### Reconnecting

The same stable seat remains visible as `RECONNECTING`; state and current atomic
action remain. The UI does not imply defeat, replacement, healing, or reset.

### Game control

The same stable seat remains visible as `GAME CONTROL`. Human takeover is shown
only when the coordinator reports it legal at a safe handoff.

### Takeover

The advisory flow is conditional on existing takeover authority:

1. show public-safe eligible seat summaries;
2. select one legal seat;
3. confirm the existing takeover request;
4. queue the coordinator-owned safe handoff;
5. activate the neutral shield;
6. reveal inherited private state on the authorized private surface;
7. acknowledge;
8. coordinator transfers authority;
9. restore the same evolved public seat.

No player may browse several private seats.

### Transcript and replay

Transcript and presentation replay contain public content only. They preserve
the active decision and never rerun authoritative logic.

## Microcopy boundary

All proposed labels are placeholder planning language, not final localization.
Critical icons are paired with text. Prompts show only currently legal actions.
Recovery is actionable and non-punitive.

## Profile invariance

Spooky, Grim, and any later authorized profile may alter presentation intensity
only. They do not change routes, objectives, legal actions, seat identity,
privacy, mechanism state, outcome, focus order, confirmation requirements, or
information hierarchy. A profile-change control exists only if an existing
system authority exposes it.
