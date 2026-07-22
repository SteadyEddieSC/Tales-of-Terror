# Controller-First Interaction Grammar v1

**Status:** Proposed design and implementation contract  
**Scope:** Documentation only; no runtime, input-map, Tale, Companion, identity, or release change  
**Repository:** `SteadyEddieSC/Tales-of-Terror`  
**Repository baseline used for review:** protected `main` at `0dde8d41c7cb1fc23bb2d85c26cb9281e311c971`  
**Tracked by:** issue #49  
**Related proposals:** issue #47 and draft PR #48  
**Implementation dependency:** changes touching the finalized Tale Library route must wait for the bounded PR #46 correction and merge  
**Working-title notice:** “Terror Turn” and “The Underteller” remain provisional pending issue #7 legal clearance

## 1. Purpose

This contract defines one reusable interaction language for every controller-first Terror Turn surface.

It covers:

- title and first-seat join;
- local stable-seat lobby;
- mode confirmation;
- Tale Library and Public Briefing;
- shared exploration;
- board interactions;
- rules prompts, cards, checks, and votes;
- controlled private reveal;
- pause, Help, accessibility, and reporting;
- sanitized recovery;
- terminal review, ending, rematch, return, and protected reset.

The objective is not to add controls. It is to make existing and future controls behave predictably across all surfaces while preserving stable-seat ownership, native authority, deterministic replay, shared-screen privacy, and the complete no-phone path.

## 2. Player promise

The player-facing interaction promise is:

> The same button means the same kind of thing everywhere. The game always shows whose input is expected, never lets a join press accidentally skip a screen, never requires a mouse or phone, and always provides a safe way to get Help or return through protected reset.

The developer-facing promise is:

> Raw device events are normalized into bounded semantic intents. Presentation may request an action, but only the appropriate native authority may validate and commit it. Focus, animation, glyphs, and Help state never become gameplay authority.

## 3. Existing repository-grounded baseline

The current repository already provides the following behavior:

- Godot 4.7.1 with a 960×540 logical viewport and Compatibility renderer;
- 1–8 stable seats;
- controller-first play with keyboard development fallback;
- `SeatManager` ownership and reconnect reservation;
- `PlayerInputRouter` per-device movement, interaction, diagnostics, and rules navigation;
- a top-level main input path that distinguishes the device that generated the event;
- an explicit guard preventing one A/Enter event from both joining and advancing;
- semantic actions for navigation, confirm, cancel, join, pause, Help, diagnostics, interaction, safe area, movement, and protected reset;
- Help that blocks presentation input while open;
- controller-accessible Help pagination and explicit report export;
- stable-seat response status for rules prompts and votes;
- deterministic coordinator lifecycle and stage progression;
- protected reset through a 1.5-second hold;
- native Godot authority when Companion services are absent;
- a no-mouse and no-phone player path.

This contract formalizes those behaviors. It does not imply that physical-controller, television, accessibility, or household usability has been human-tested.

## 4. Current semantic input map

The accepted baseline maps the following semantic actions:

| Semantic action | Controller baseline | Keyboard development fallback | Intended meaning |
| --- | --- | --- | --- |
| `ui_navigate_up` | D-pad Up | W / Up | Move focus or selection up |
| `ui_navigate_down` | D-pad Down | S / Down | Move focus or selection down |
| `ui_navigate_left` | D-pad Left | A / Left | Move focus left or previous |
| `ui_navigate_right` | D-pad Right | D / Right | Move focus right or next |
| `ui_confirm` | South face button / A | Enter / Space | Select, acknowledge, or submit |
| `ui_cancel_action` | East face button / B | Escape | Return, close, or cancel where safe |
| `player_join` | South face button / A | J / Enter | Claim an unassigned stable seat |
| `pause_options` | Menu | P | Pause or resume active play |
| `help_accessibility` | West face button / X | H | Open or close Help |
| `reset_seats` | North face button / Y hold | R hold | Protected return/reset |
| `interact` | South face button / A | E | Request world interaction |
| movement | Left stick / D-pad | WASD / arrows | Move an owned pawn |
| safe-area decrease/increase | shoulder buttons | - / = | Development display adjustment |
| diagnostics | no normal controller binding | T | Developer-only diagnostics |

Button letters are the current Xbox-style baseline. Player-facing glyph rendering SHOULD use detected or configured controller glyph families when available, while always retaining text labels and semantic wording.

## 5. Design goals

A conforming implementation must:

1. make input ownership visible and consistent;
2. prevent one raw event from producing more than one semantic commit;
3. preserve stable seats through disconnect and reconnect;
4. use the same confirm, back, Help, pause, and reset meaning across surfaces;
5. keep focus deterministic and recoverable;
6. make waiting and submitted state clear for 1–8 seats;
7. support public and private interactions without requiring phones;
8. keep presentation timing outside gameplay authority;
9. reject wrong-seat, stale, duplicate, malformed, and ineligible input atomically;
10. preserve keyboard as a single development seat rather than a global bypass;
11. remain readable and usable at the 960×540 logical viewport;
12. provide deterministic automated tests without claiming human usability evidence.

## 6. Non-goals

This contract does not authorize:

- changing the current Godot input map;
- player-remappable controls;
- mouse-first menus;
- touch-first controls;
- a radial menu, cursor, or broad HUD redesign;
- simultaneous private information on one television;
- controller reassignment during an active private interaction;
- new Tale operations, cards, roles, factions, board spaces, or outcomes;
- new Companion source, protocol, dependencies, deployment, or authority;
- telemetry, account input profiles, cloud control synchronization, or device fingerprinting;
- final controller compatibility, television readability, accessibility, or fun claims;
- branding or legal-clearance claims.

Future remapping and accessibility alternatives may be designed later against this semantic grammar without changing gameplay authority.

## 7. Normative interaction layers

Input is evaluated through a strict priority stack. A higher layer consumes eligible events before lower layers may act.

| Priority | Layer | Examples | Authority impact |
| ---: | --- | --- | --- |
| 1 | protected reset hold | Y/R held for 1.5 seconds | explicit session reset only after hold completes |
| 2 | controlled private reveal | shield entry, private page, private close | seat-scoped authorization and bounded private intent |
| 3 | modal public overlay | Help, pause, recovery callout, confirmation dialog | presentation-only unless explicit safe action is chosen |
| 4 | focused rules interaction | prompt, vote, card, target, ending choice | bounded semantic intent to rules/role/coordinator authority |
| 5 | route navigation | title, lobby, mode, Library, briefing, ending | coordinator/seat route request |
| 6 | world interaction | interactable focus and A/E request | bounded board/rules request |
| 7 | continuous movement | pawn movement vectors | pawn/board occupancy path |
| 8 | developer-only diagnostics | T and internal overlays | no player authority |

### 7.1 Consumption rule

One pressed event MUST be consumed by at most one layer that can mutate authority.

A layer MAY update presentation focus and consume the event without gameplay mutation. It MUST NOT allow the same event to fall through into a lower authoritative action.

### 7.2 Join-versus-confirm rule

Because A/Enter maps to both `player_join` and `ui_confirm`, the top-level input path MUST continue to detect whether the event claimed a seat.

If the event claimed a seat:

- the seat join commits;
- the event is considered consumed for route progression;
- no roster confirmation, Tale preparation, briefing start, stage advance, or prompt response may occur from that same event.

### 7.3 Held-input rule

Navigation repeat and reset hold are different concepts.

- Reset progresses only while the protected-reset semantic action remains held.
- A release before completion cancels the reset and clears progress.
- Navigation repeat MAY be presentation-driven after an initial delay.
- Held confirm, Help, Back, Pause, Interact, or Join MUST NOT repeatedly submit authority work.

## 8. Stable-seat ownership contract

### 8.1 Seat is the player principal

Gameplay ownership belongs to the stable seat.

The current device ID is an input transport detail. A controller cannot act for a seat unless `SeatManager` currently maps that device to the active seat or restores it through the accepted reconnect identity policy.

### 8.2 Unassigned device behavior

An unassigned device MAY:

- join during title/lobby when seats are available;
- open only explicitly approved public Help before joining, if the route allows it;
- provide no active gameplay, private, vote, prompt, pause, ending, or reset authority except the global protected-reset policy explicitly approved for the local host.

An unassigned device MUST NOT:

- advance setup after joining from the same event;
- move a pawn;
- interact with the board;
- answer a prompt or vote;
- enter a private reveal;
- act for another stable seat.

### 8.3 Owned device behavior

An owned device MAY act only for its stable seat and only when that seat is eligible for the current semantic interaction.

Public route confirmation MAY accept one owned active seat where the route is table-wide. The UI MUST say that any owned seat may continue.

### 8.4 Disconnect and reservation

When a controller disconnects:

- continuous movement strength is cleared;
- the seat transitions through disconnected to reserved under current behavior;
- private and gameplay ownership remain attached to that stable seat;
- a pending required interaction waits;
- public guidance identifies the stable seat and reconnect need without exposing private information;
- another controller cannot silently answer for it.

### 8.5 Reconnect

Reconnect restores the same stable seat only through the accepted identity match.

On reconnect:

- focus for that seat SHOULD restore to the current valid option or a deterministic safe default;
- stale input state MUST be cleared;
- no held button state may be inferred from before disconnect;
- the first reconnect event MUST NOT also submit the pending choice unless separately released and pressed again.

### 8.6 Reassignment

Facilitator reassignment of a reserved seat is outside this contract. It requires a separate privacy and consent design because it can transfer private authority.

## 9. Semantic action meanings

## 9.1 Navigate

Navigate changes presentation focus or a bounded selection index. It does not itself commit gameplay.

Requirements:

- focus movement follows authored visual order;
- left/right and up/down behavior is consistent within each layout;
- lists wrap only when the surface explicitly declares wrapping;
- a one-item list deterministically retains the same item;
- disabled choices are skipped only when the reason is public and the remaining route is clear;
- private disabled reasons are not exposed on public surfaces;
- analog and D-pad navigation resolve to the same semantic direction.

## 9.2 Confirm

Confirm means one of four things, selected by the active interaction context:

1. **Select** a focused presentation item.
2. **Acknowledge** already committed public information.
3. **Submit** one bounded authoritative intent.
4. **Continue** through a public route transition.

The UI MUST use a verb-specific label where practical: `JOIN`, `LOCK ROSTER`, `PREPARE`, `BEGIN`, `SUBMIT`, `REVEAL`, `CONTINUE`, `REVIEW`, `REMATCH`, or `RETRY` rather than only `CONFIRM`.

Confirm MUST NOT:

- both join and continue;
- both submit and acknowledge a result;
- repeat because the button remains held;
- submit from an ineligible seat;
- bypass a privacy shield;
- advance during unresolved authoritative work.

## 9.3 Back / Cancel

Back means the safest reversible action available at the current boundary.

Possible meanings:

- close Help;
- return from Tale Library to Mode Confirmation;
- return from Public Briefing to Tale Library before the Tale begins;
- cancel an uncommitted private selection back to the privacy shield;
- leave a stable seat during the lobby;
- return from Ending to Title through the approved route.

Back MUST NOT:

- reverse an already committed gameplay result;
- expose private content while leaving a reveal;
- silently abandon another seat’s pending required interaction;
- act as a universal undo;
- bypass a confirmation where destructive state loss requires protected reset.

When Back is unavailable, the footer SHOULD omit it rather than show a misleading command.

## 9.4 Help

Help opens a public, presentation-only overlay.

Requirements:

- Help consumes navigation, confirm, Back, and Help inputs while open;
- movement strengths are cleared or presentation input is blocked;
- active gameplay does not progress because Help is open;
- Help pages use left/right and Confirm for pagination;
- Back or Help closes Help;
- Help opened from private reveal first returns to or preserves the neutral privacy shield;
- Help content is audience-safe and contains no private state or raw diagnostics;
- report export remains an explicit local action on the approved report page.

## 9.5 Pause

Pause is available only in active Tale play under current behavior.

Pause:

- stops presentation and pawn processing as implemented;
- preserves all authority state;
- consumes no gameplay RNG;
- does not resolve prompts, votes, timers, Director work, or role transitions;
- displays Resume, Help, and protected-reset guidance;
- requires a fresh press to resume.

A future options menu may be added under Pause, but it must remain presentation/configuration state unless an explicit authoritative action is separately selected.

## 9.6 Interact

Interact requests use of the currently focused world interactable for the requesting seat’s pawn.

Requirements:

- device resolves to an owned active pawn;
- focus comes from authoritative or validated world proximity state;
- simultaneous requests use the accepted deterministic arbitration;
- an interaction request does not automatically advance a rules prompt unless that interaction explicitly opens it;
- the public HUD distinguishes world Interact from route Continue when both could otherwise use A.

## 9.7 Protected reset

Protected reset is the universal escape from an unrecoverable or unwanted session state.

Requirements:

- hold duration remains 1.5 seconds under current behavior;
- visible progress is presentation-only;
- release cancels before completion;
- completion finalizes or records the current report disposition as already approved;
- closes Help and private reveal;
- unblocks presentation input;
- closes optional Companion room;
- clears session authorities, seats, prompts, votes, private caches, and current progress;
- returns to a clean Title state;
- does not expose raw reset diagnostics.

A future accessibility alternative to holding requires a separate design that preserves protection against accidental activation.

## 10. Interaction context model

A future implementation SHOULD derive one small read-only interaction context for presentation and input routing rather than allowing each view to reinterpret raw authority state independently.

Recommended conceptual fields:

```text
context_version
surface_id
interaction_kind
interaction_revision
visibility
eligible_seats
completed_seats
focus_policy
confirm_verb
back_policy
help_allowed
pause_allowed
reset_allowed
waiting_reason_code
public_instruction_key
```

This is a design model, not an approved schema change.

### 10.1 Authoritative fields

The following are authoritative only when they gate gameplay work:

- interaction revision;
- interaction kind;
- eligible stable seats;
- completed stable seats;
- pending choice IDs or target IDs owned by the appropriate rules/role authority;
- whether the interaction is resolved.

### 10.2 Presentation-only fields

The following remain presentation-only:

- current focused control;
- visual row/column;
- highlight animation;
- glyph family;
- tooltip visibility;
- footer layout;
- navigation repeat timer;
- sound and vibration cue state;
- Help page;
- reset progress before completion.

### 10.3 Ownership

The coordinator MAY expose a normalized context assembled from existing authorities. It MUST NOT duplicate the underlying prompt, vote, card, role, board, or ending authority.

## 11. Focus contract

### 11.1 Initial focus

Every interactive surface MUST define a deterministic initial focus.

Preferred rules:

- first valid action in authored order;
- current selected Tale in Tale Library;
- current seat’s prior uncommitted selection when returning from Help;
- `Rematch` or another explicitly reviewed safe default at Ending;
- `Retry` on a recoverable failure only when retry is safe and idempotent;
- neutral shield, not private content, after private-flow interruption.

### 11.2 Focus retention

Focus SHOULD be retained when:

- Help opens and closes;
- a recoverable notice appears without replacing the current card;
- a disconnected seat reconnects during the same interaction;
- the view refreshes from an equivalent authority revision;
- the player returns from Public Briefing to Tale Library under the accepted route.

### 11.3 Focus invalidation

If the focused choice becomes invalid:

1. preserve the semantic selection if an equivalent option still exists;
2. otherwise move to the nearest valid item in authored order;
3. otherwise focus the safe Back, Help, or reset action;
4. never leave invisible focus on a removed control.

### 11.4 Multi-seat focus

Public route surfaces use one shared focus.

Seat-specific prompts may use per-seat private focus in a controlled reveal or Companion. A public multi-seat vote SHOULD avoid showing individual current option focus before resolution when selections are concealed.

### 11.5 Focus and replay

Presentation focus is excluded from gameplay replay unless the focus movement itself is the accepted semantic choice. Replay records the submitted option or action, not every navigation step.

## 12. Surface grammar

## 12.1 Title

Player experience:

- the screen invites A/Enter to join;
- Help is always visible as an option;
- no selected Tale, role, or private prior-session state is shown.

Rules:

- the first valid join creates Seat I and moves to Lobby;
- the join event does not confirm the roster.

Presentation-only:

- title animation, focus pulse, controller glyphs, and Help hint.

Tests:

- one press produces one seat and one lifecycle change;
- held A/Enter does not create multiple seats or advance again.

## 12.2 Local Lobby

Player experience:

- every joined seat appears using number, Roman numeral, symbol/pattern, friendly controller label, and public connection state;
- unassigned A/Enter joins;
- an owned seat’s fresh A/Enter or Space locks the roster;
- B/Escape from an owned device leaves that seat before roster lock.

Rules:

- seat order follows first accepted join order;
- maximum eight stable seats;
- duplicate device join is idempotent;
- reserved reconnect restores the original seat.

Privacy:

- no raw device IDs or stable identity strings appear publicly.

Tests:

- mixed keyboard/controller joins;
- identical-controller identities and ambiguous reconnect fail safely under existing policy;
- join/confirm collision guard;
- leave and rejoin ordering.

## 12.3 Mode Confirmation

Player experience:

- the selected mode and truthful player-count fallback are explained publicly;
- any owned active seat may Prepare;
- Back returns to Lobby.

Rules:

- no role assignment or gameplay RNG is consumed merely by focus movement;
- preparation remains atomic through existing selection/provider boundaries.

Privacy:

- no hidden assignment plan, weights, role inventory, or future betrayer identity is shown.

## 12.4 Tale Library

Player experience:

- D-pad/stick or keyboard navigation moves focus in stable catalog order;
- Confirm prepares the focused Tale;
- Back returns to Mode Confirmation;
- Help remains available;
- a valid focused card remains visible during sanitized recoverable failure.

Rules:

- focus is presentation/setup state;
- Tale selection and complete candidate authority commit only after validation succeeds;
- a one-entry production Library retains focus on the same entry.

Recovery:

- `tale_selection_unavailable` and `tale_preparation_unavailable` show fixed Retry, Back, Help, and reset guidance;
- successful retry clears the notice.

Dependency:

- implementation changes wait for the bounded PR #46 correction and merge.

## 12.5 Public Briefing

Player experience:

- public premise, objective, seat count, mode/fallback, Begin, Back, Help, and reset are clear;
- phones are explicitly optional.

Rules:

- Confirm begins the Tale exactly once;
- Back discards prepared authorities and restores the Library state before active play;
- selection locks after Begin.

## 12.6 Shared Exploration

Player experience:

- every owned active controller moves its own pawn;
- nearby interactable focus is visible with multimodal cues;
- Interact is distinct from stage Continue;
- group-separation warnings do not steal focus from an active prompt.

Rules:

- movement is continuous and device-scoped;
- board occupancy remains authoritative;
- deterministic conflict rules resolve simultaneous interaction requests;
- Help/pause/private overlays clear or block movement strengths.

## 12.7 Single-seat prompt

Player experience:

- the public screen identifies the eligible seat when that fact is public;
- only the eligible controller can navigate and submit;
- other seats see a waiting state;
- submitted state is acknowledged without double-advance.

Rules:

- prompt revision, seat ownership, option ID, lifecycle, and operation are revalidated;
- stale/wrong-seat/duplicate input rejects without mutation or RNG use.

Private variant:

- use controlled reveal or authorized Companion;
- public screen shows only neutral waiting status.

## 12.8 Public vote

Player experience:

- question and public options are shown;
- each seat submits with its owned controller;
- submitted/waiting markers use seat number plus symbol/pattern;
- individual selections remain concealed until resolution unless the authored policy says open vote;
- final result and tie rule are explained.

Rules:

- response collection follows stable-seat ownership;
- quorum, abstain, plurality, and stable tie policy remain authoritative;
- a disconnected required seat remains reserved and waiting under current policy.

## 12.9 Guided card/check/Director sequence

Player experience:

- the sequence is broken into understandable committed beats;
- Confirm acknowledges or triggers only the current eligible beat;
- displayed dice/card/Director result reflects already committed authority state;
- animation may be skipped without rerolling.

Rules:

- Rules and Director RNG remain separate;
- Help, pause, animation skip, and view refresh consume no RNG;
- one confirm cannot play a card and immediately acknowledge the check result.

## 12.10 Controlled private reveal

Player experience:

1. public neutral shield;
2. identify the authorized stable seat without revealing the secret;
3. require that seat’s fresh Confirm;
4. display only that seat’s allowlisted private view;
5. accept a bounded choice or acknowledgement;
6. return to neutral shield;
7. resume public play through a fresh public Continue.

Rules:

- wrong-seat input rejects without exposing what was attempted;
- timeout and Back return to shield with uncommitted authority unchanged;
- Help opens only from the shield or first restores it;
- disconnect pauses at the shield and waits for the same seat;
- private caches clear on close, reset, rematch, return, scene destruction, or authorization change.

No-phone behavior:

- complete on the television and controller;
- Companion is optional.

## 12.11 Pause

Player experience:

- clear paused title;
- Resume, Help, and protected reset guidance;
- no suggestion that private content remains visible.

Rules:

- no gameplay clocks, prompts, votes, movement, Director work, or replay order advance.

## 12.12 Help and accessibility

Player experience:

- five-page current Help model remains controller accessible;
- current session guidance is public and contextual;
- privacy, reconnect, reset, build/support, and report behavior are explained;
- report export is explicit and local.

Rules:

- Help is presentation-only;
- export result uses sanitized player text;
- raw writer reason should not be concatenated into a normal player-facing message in future hardening.

## 12.13 Recovery callout

Player experience:

- fixed title, explanation, and safe actions;
- underlying valid context remains visible where safe;
- Retry is focused only when idempotent and appropriate;
- Back, Help, and reset remain available as declared.

Rules:

- no raw reason, path, hash, class, provider, source-ledger, stack trace, or security detail;
- success clears the notice;
- repeated Retry cannot create duplicate authority work.

## 12.14 Terminal and Ending

Player experience:

- Terminal offers Review Ending;
- Ending presents public mixed outcomes and controlled private details;
- Rematch and Return have distinct labels and require fresh presses;
- Help/report export remains available.

Rules:

- outcome authority is fixed before review;
- Rematch rebuilds clean authorities under the accepted same-seed policy;
- Return/protected reset clears seats/session/room according to the approved route.

## 13. Waiting-state grammar

Every waiting state MUST answer five public questions:

1. **What is happening?**
2. **Who may act?**
3. **How many required seats are complete?**
4. **What control is expected?**
5. **What recovery options are available?**

Preferred public fields:

- interaction title;
- public instruction;
- eligible public seat markers;
- submitted count and total;
- disconnected/reserved seat markers;
- Help hint;
- pause or reset hint where available.

A waiting screen MUST NOT expose:

- private option focus;
- another seat’s choice;
- hidden role-based eligibility when that eligibility is itself secret;
- raw device identity;
- internal failure reason.

## 14. Input timing and repeat policy

### 14.1 Press semantics

Authoritative discrete actions respond to a fresh press edge, not a held level.

Applicable actions:

- Join;
- Confirm;
- Back;
- Help;
- Pause;
- Interact.

### 14.2 Navigation repeat

Navigation MAY repeat after a presentation-only delay and interval.

A future implementation SHOULD centralize these values so every menu behaves consistently. The values must not enter gameplay snapshots or authority digests.

### 14.3 Analog deadzones

The current baseline uses a 0.5 deadzone for UI actions and 0.25 for movement axes.

Future tuning MAY occur only with regression tests and human hardware evidence. UI navigation should resolve one semantic step per threshold crossing or controlled repeat, not flood focus from stick noise.

### 14.4 Input echo

Keyboard echo events MUST remain ignored for discrete semantic actions. Controller button hold MUST receive equivalent one-shot handling through action-edge logic.

### 14.5 Simultaneous local input

When two eligible local events arrive in the same frame or processing interval:

- independent seat-specific submissions may both be accepted in deterministic processing order;
- conflicting requests use the existing lowest-seat or authored arbitration rule;
- route-wide transitions commit once, and later events see the new lifecycle and reject/no-op;
- accepted semantic sequence, not frame timing, is recorded for replay.

## 15. Deterministic behavior and replay

A conforming implementation MUST preserve:

- stable seat order;
- explicit interaction revision;
- stable authored option order;
- one accepted semantic intent per authority commit;
- no RNG consumption from focus, Help, pause, reconnect, glyph selection, animation, or failed input;
- no wall-clock dependence for gameplay outcomes;
- atomic rollback when a cross-authority operation fails;
- replay recording of submitted semantic choices rather than raw key/button events;
- identical authority and public-history digests for the same seed, roster, mode, and accepted semantic intent sequence.

Presentation may record separate non-authoritative usability evidence, but that evidence must not drive replay or outcomes.

## 16. Privacy implications

The shared television is public except during a fully obscured, seat-authorized reveal.

Interaction presentation MUST NOT leak private information through:

- focus highlight;
- disabled-state reason;
- controller glyph or vibration;
- waiting-seat wording;
- prior-choice summary;
- Help context;
- recovery message;
- report export result;
- reconnect prompt;
- ending navigation.

Private input belongs to the stable seat and uses the Shared-Screen Information and Privacy Matrix contract tracked by issue #47 and draft PR #48.

Optional Companion input maps to the same semantic intent contract after authorization, but remains non-authoritative and constrained by issue #44.

## 17. Accessibility and multimodal behavior

Automated acceptance requires the following design properties:

- text plus controller symbol/glyph;
- seat number plus Roman numeral, shape, or pattern rather than color alone;
- visible focus with more than a color shift;
- no required mouse pointer;
- no required haptics, controller light, audio-only cue, or phone;
- safe-margin compliance;
- no flashing as a required attention cue;
- reduced-motion-compatible transitions;
- bounded text length or pagination at 960×540;
- persistent Help and reset guidance;
- clear distinction between selected, submitted, waiting, disabled, disconnected, reserved, and error states.

The following remain human-test questions:

- actual television readability;
- controller model glyph recognition;
- stick repeat comfort;
- hold-reset motor accessibility;
- color/shape distinction in a living room;
- private reveal practicality;
- eight-player waiting comprehension.

## 18. Data and schema impact

### 18.1 Documentation-only effect

Approval of this contract changes no input map, runtime data, snapshot, report, Tale package, catalog, provider, or Companion schema.

### 18.2 Preferred implementation strategy

Use existing semantic actions and authority state.

A bounded implementation may add:

- a reusable read-only interaction-context projection;
- a presentation focus helper;
- a one-shot semantic input gate;
- common footer/control-label formatting;
- deterministic waiting-state presentation;
- shared tests for consumption and focus behavior.

### 18.3 Changes requiring separate review

The following require separate design or ADR work:

- changing existing action names or bindings;
- controller remapping;
- accessibility alternative to reset hold;
- mouse/touch navigation;
- seat reassignment;
- gameplay timeouts or automatic votes;
- new interaction kinds or Tale operation types;
- new private-delivery mechanisms;
- new Companion input protocol;
- recording raw input for telemetry or analytics.

## 19. Test requirements

### 19.1 Semantic action tests

- every mapped controller/keyboard action produces the intended semantic action;
- discrete actions are one-shot;
- keyboard echo does not repeat authority work;
- held controller buttons do not repeat submissions;
- navigation and movement use their separate deadzones.

### 19.2 Consumption tests

- one A/Enter event joins but does not confirm;
- Help consumes input and blocks lower layers;
- private reveal consumes input before public route handling;
- pause consumes active-route input;
- resolved route transition prevents same-frame duplicate advance;
- protected reset completion prevents lower-layer actions.

### 19.3 Ownership tests

- unassigned device cannot act in gameplay;
- owned device acts only for its seat;
- wrong-seat prompt/vote/private input rejects;
- disconnect clears movement;
- reconnect restores the same seat and requires a fresh press;
- keyboard is one stable development seat, not global authority.

### 19.4 Focus tests

- deterministic initial focus on every surface;
- Help close restores focus;
- retry callout preserves underlying Tale focus;
- removed/disabled choice moves to deterministic safe focus;
- one-item list remains stable;
- focus is never invisible or outside safe bounds;
- focus movement consumes no gameplay RNG.

### 19.5 Route tests

For Title, Lobby, Mode, Library, Briefing, Active Tale, Terminal, and Ending:

- accepted Confirm transition;
- Back policy;
- Help availability;
- protected reset;
- duplicate/stale press behavior;
- public footer matches actual available actions.

### 19.6 Prompt and vote tests

- 1–8 stable-seat response status;
- submitted and waiting markers;
- concealed individual selections;
- wrong-seat/stale/duplicate rejection;
- disconnect/reserve/reconnect;
- deterministic tie and processing order;
- no double-advance after final submission.

### 19.7 Controlled-reveal tests

- neutral shield first;
- authorized-seat fresh press;
- wrong-seat rejection;
- Back/timeout/Help to shield;
- disconnect and same-seat reconnect;
- private cache clearing;
- fresh public Continue after close;
- no private text in public history, Help, report, screenshot fixture, or Companion public view.

### 19.8 Recovery tests

- sanitized fixed notice content;
- actual action availability matches footer;
- Retry idempotence;
- successful recovery clears notice;
- Back preserves declared prior state;
- raw diagnostics never enter player UI.

### 19.9 Replay and RNG tests

- same seed and semantic intents produce identical authority digests;
- extra focus movement, Help, pause, animation skip, or rejected input does not change outcomes;
- rollback restores interaction revision, stage/operation, authorities, and RNG;
- raw device event ordering is normalized to deterministic accepted semantic order.

### 19.10 Human test requirements

Issue #39 or a future authorized human test must assess:

- physical controller join and reconnect;
- identical controller models;
- actual TV distance and overscan;
- focus readability;
- eight-player waiting states;
- private pass-and-play comfort;
- Help discoverability;
- reset-hold accessibility;
- controller glyph comprehension;
- social pacing and accidental input.

Automation must not mark those as passed.

## 20. Implementation-ready slices

### Slice I-1 — Interaction inventory and conformance tests

Deliverables:

- inventory every current surface and semantic action;
- map current handlers to the priority stack;
- add documentation/static tests for footer-to-action consistency;
- identify gaps without changing gameplay.

Risk: low. Safe after design review.

### Slice I-2 — One-shot input consumption hardening

Deliverables:

- centralize consumed-event rules where needed;
- prove join-versus-confirm, modal blocking, pause, and route duplicate protection;
- preserve current bindings and player-visible behavior.

Risk: low to medium. Must not broaden PR #46.

### Slice I-3 — Reusable interaction-context projection

Deliverables:

- derive public interaction kind, revision, eligible/completed seats, and safe controls from existing authorities;
- no parallel rules or role authority;
- deterministic exact-key tests.

Risk: medium. Best after PR #46 merges.

### Slice I-4 — Focus and footer component

Deliverables:

- deterministic initial/restore focus;
- consistent semantic control labels;
- multimodal focus state;
- safe-area and 960×540 tests.

Risk: medium; visual direction still requires human review.

### Slice I-5 — Waiting, disconnect, and recovery presentation

Deliverables:

- reusable submitted/waiting/reserved markers;
- reconnect guidance;
- sanitized retry/back/help/reset model;
- no private eligibility leaks.

Risk: medium. Coordinate with privacy matrix and merged PR #46.

### Slice I-6 — Controlled-reveal hardening

Deliverables:

- shield/authorize/reveal/close/public-continue states;
- fresh-press and cache-clearing rules;
- deterministic privacy tests.

Risk: medium to high. Human privacy/usability remains deferred.

## 21. Release and migration risks

| Risk | Consequence | Control |
| --- | --- | --- |
| A/Enter produces two commits | skipped setup or stage | keep explicit claimed-seat event consumption and one-shot tests |
| Overlay input falls through | hidden gameplay mutation | strict priority stack and consumed-event handling |
| Presentation duplicates authority | drift and nondeterminism | derive read-only context from existing authorities |
| Wrong seat acts | privacy and rules violation | stable-seat ownership and revision validation |
| Held input repeats | duplicate choice or rapid route advance | edge-trigger discrete actions and release-before-repress tests |
| Analog noise moves focus | inaccessible or accidental selection | centralized threshold/repeat policy and hardware playtest |
| Back behaves as undo | authority corruption | route-specific reversible boundaries only |
| Help leaks private context | spoiler/privacy failure | public allowlisted Help and shield-first private handling |
| Reconnect submits stale press | unintended private action | clear state and require fresh press |
| Focus disappears after refresh | soft lock/confusion | deterministic invalidation and safe fallback |
| Footer advertises unavailable action | player trust failure | footer-to-context conformance tests |
| Reset hold inaccessible | player trapped | future separately reviewed accessible alternative; Help explains current path |
| PR #46 scope expands | delayed bounded correction | no Library code in this design PR; implement later from merged main |
| Companion input changes early | issue #44 violation | documentation only; no source/protocol/dependency change |
| automated tests called usability evidence | false confidence | issue #39 remains human evidence gate |

## 22. Acceptance criteria

This contract is ready for bounded implementation planning when reviewers agree that:

1. the semantic meanings of Navigate, Confirm, Back, Help, Pause, Interact, and Reset are stable;
2. input priority and consumption prevent fallthrough and double commits;
3. stable-seat ownership governs every gameplay and private action;
4. focus has deterministic initialization, retention, and invalidation rules;
5. every route and waiting state displays only actions that actually work;
6. the complete no-phone private path uses shielded seat-scoped reveal;
7. presentation-only input state remains outside authority and replay;
8. wrong-seat, stale, duplicate, held, malformed, and disconnected input fails safely;
9. existing input bindings and production identities remain unchanged by approval;
10. implementation touching Tale Library waits for PR #46;
11. Companion implementation remains constrained by issue #44;
12. physical usability conclusions remain constrained by issue #39.

## 23. Recommended next action after approval

The first implementation issue should be **Interaction Inventory and One-Shot Conformance**, not a broad UI rewrite.

Recommended objective:

> Map every existing input handler and player-facing footer to the Controller-First Interaction Grammar; add deterministic tests for event consumption, stable-seat ownership, Help/modal blocking, join-versus-confirm, held-input protection, focus restoration, and footer/action consistency; preserve all current bindings, gameplay authority, production identities, Companion boundaries, and player-visible outcomes.

That bounded implementation can begin after this document is reviewed. Any work touching the Tale Library route must start from the accepted post-PR-#46 protected main.
