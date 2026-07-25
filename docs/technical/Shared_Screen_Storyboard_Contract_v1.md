# Shared-Screen Storyboard Contract v1

**Status:** P0.10 preproduction interaction contract
**Runtime authority:** None
**Human usability evidence:** None
**Target context:** Controller-first, 16:9 shared-screen play for 1–8 stable seats

## 1. Purpose

This contract defines how a Tale may be represented as reviewable shared-screen storyboards before runtime UI implementation is authorized.

A storyboard records:

- public state and current purpose;
- stable-seat ownership and control source;
- legal actions and confirmation behavior;
- privacy surface;
- captions, transcript, and persistent text;
- controller focus order;
- entry and exit conditions;
- layout regions and visual hierarchy;
- state variants;
- source authority and traceability;
- explicit human-validation questions.

It is not a Godot scene, UI theme, runtime state machine, or accessibility claim.

## 2. Shared-screen principles

### 2.1 Board readability wins

The shared display must make it possible to understand:

1. where every public stable seat is;
2. which seat may act;
3. what the current stage and tide state are;
4. which routes are open, flooded, damaged, or water-only;
5. which objective, mechanism, or hazard currently matters;
6. what actions are legal;
7. what will happen before a choice commits;
8. which information is public.

Atmosphere may frame this information. It may not hide it.

### 2.2 Stable seats remain visible

Each public seat summary supplements color with:

- stable seat label;
- public character or form identity;
- public location;
- public condition;
- public items or objective markers where authorized;
- control-source label:
  - `PLAYER`;
  - `GAME CONTROL`;
  - `RECONNECTING`;
  - `TAKEOVER PENDING`;
- required-action indicator.

Controller changes must not imply a new character, respawn, healing, inventory reset, or faction reset.

### 2.3 Private state never appears on the shared board

Seat-private, faction-private, and controlled-reveal-private information requires an authorized private surface.

Where local play uses the television for a temporary private reveal:

- the shared board is replaced by a neutral shield;
- other seats are told only that a private handoff is in progress;
- the private text cannot enter public captions or transcript;
- the reveal requires acknowledgement;
- the shield is restored before authority transfers or public play resumes;
- interruption clears the private surface immediately without narrating its content.

No player may browse several private seats before choosing one.

## 3. Baseline 16:9 layout

The baseline shared-screen composition uses safe regions rather than fixed pixels.

### 3.1 Global safe area

- Keep critical text and controls inside the inner 90 percent of width and height.
- Decorative art may extend to the edge.
- Enlarged text may reduce decorative margins before reducing readable scale.
- No legal action or consequence may sit behind overscan-sensitive edges.

### 3.2 Persistent regions

#### Stage and public objective — upper left

Contains:

- Tale stage;
- current public objective;
- objective progress or unresolved public requirement;
- optional plain-system details.

#### Tide and transformation state — upper center

Contains:

- tide-state label;
- multiple-channel tide indicator;
- public transformation status;
- warning-versus-committed distinction.

#### Host and authority status — upper right

Contains:

- active authority or current decision owner;
- optional Underteller replay control;
- pause or facilitator indicator;
- network or admission state only when relevant.

#### Playable board — center

Contains:

- authored camera framing;
- spaces and routes;
- stable-seat markers;
- objective and hazard markers;
- route-state encoding not dependent on color;
- no essential interaction hidden behind scenery.

#### Decision and consequence panel — center or right drawer

Appears only when required.

Reading order:

1. context;
2. public state;
3. required action;
4. legal choices;
5. public consequence preview;
6. confirm or cancel;
7. replay, transcript, details, or help.

#### Captions — lower center

- no more than two lines at the design target;
- generally up to 42 characters per line where the language permits;
- high-contrast configurable background;
- above seat rail and controller prompts;
- never the only representation of critical information.

#### Stable-seat rail — bottom

Supports 1–8 seats without horizontal scrolling during ordinary play.

Each seat tile remains compact but must preserve:

- seat identity;
- public state;
- control source;
- action requirement;
- sufficient shape and text differentiation without color.

#### Controller prompt strip — bottom edge within safe area

Shows currently legal global controls only.

Prompts may include:

- select;
- back;
- confirm;
- details;
- replay;
- transcript;
- help;
- facilitator actions where authorized.

Do not show controls that are disabled or irrelevant merely to fill the strip.

## 4. Layout modes

### Board-first

Use during exploration and ordinary movement.

- Board receives the largest region.
- Objective and seat rails remain persistent.
- Decision panel is absent or compact.

### Decision-focus

Use for Bellhouse, Lighthouse Council, bargains, Last Light, confirmations, and invalid-action recovery.

- Decision content becomes primary.
- Board remains visible enough to preserve context unless privacy requires shielding.
- Consequence text persists until commitment or cancellation.

### Transformation

Use for High Water and public form changes.

- Before and after state are clearly distinguished.
- The committed result is not obscured by cinematic effects.
- Player control does not resume until public route and rule changes are visible.
- Skipping animation must still apply the same deterministic state and summary.

### Outcome-attribution

Use for mixed endings.

- Each seat and faction receives a separately attributable result.
- No universal victory or defeat banner replaces mixed outcomes.
- Public and controlled-private results use their authorized surfaces.

### Private shield

Use for seat-private, faction-private, and controlled-reveal-private presentation.

- Shared-screen public board and transcript are hidden.
- Neutral shield contains no private hint.
- Acknowledgement and safe return are explicit.

### System overlay

Use for reconnecting, admission, settings, transcript, replay, or facilitator operations.

- Must not silently change game authority.
- Must preserve current atomic action and legal decision.
- Lower-priority overlays cannot interrupt critical decisions.

## 5. Controller-first focus

Every storyboard declares one deterministic focus order.

Requirements:

- visible focus and programmatic focus describe the same item;
- no pointer-only or hover-only action;
- entering a decision focuses the question or first legal choice according to the authored pattern;
- confirm is separate from initial selection for irreversible actions;
- cancel returns to the prior stable context;
- replay and transcript are reachable without abandoning the active decision;
- changing text scale does not lose focus or move essential controls off-screen;
- an inactive local controller cannot steal authority focus;
- safe handoff queues rather than interrupting atomic action.

## 6. Choice and confirmation patterns

### Reversible selection

- movement preview;
- details inspection;
- transcript navigation;
- seat-summary review.

Selection may update preview state but not authoritative game state.

### Confirmed commitment

Required for:

- Lighthouse Council direction;
- Harbor bargain acceptance;
- public reveal where choice exists;
- Last Light ending choice;
- destructive item or route action;
- voluntary departure;
- human takeover after private acknowledgement.

The panel states:

- selected action;
- public consequence;
- private consequence only on an authorized private surface;
- whether commitment is irreversible;
- confirm and cancel controls.

### Acknowledgement-only

Allowed only when no legal choice exists and the authoritative result has already committed.

The UI must not visually imply several choices when only acknowledgement exists.

## 7. Warning, commit, and recovery

Warnings and committed consequences use different states.

### Warning

- names the affected public route, seat, or mechanism;
- states that the consequence has not committed;
- presents legal responses;
- persists through the response window;
- remains available in transcript or details.

### Commit

- occurs once;
- clearly changes the board or seat state;
- removes unavailable actions;
- adds newly legal actions;
- records the result.

### Recovery

Invalid input or unavailable actions:

- do not mutate authoritative state;
- do not consume RNG;
- do not mock the player;
- state why the action is unavailable in public-safe terms;
- preserve and refocus legal alternatives.

## 8. Seat continuity storyboards

### Reconnecting

- reserve the same seat;
- show `RECONNECTING` publicly;
- preserve current action and private state;
- start grace behavior only when authored;
- never imply departure, defeat, or reset.

### Game control active

- show `GAME CONTROL`;
- retain the same public seat tile and history;
- do not reveal hidden strategy profile or faction;
- keep human takeover available at a safe handoff.

### Takeover selection

Before assignment show only public-safe summaries.

After assignment:

1. queue a safe handoff;
2. shield the shared screen;
3. reveal inherited private state;
4. require acknowledgement;
5. transfer authority;
6. restore the public board with the same evolved seat.

### Returning player

- reclaim the same reserved seat;
- present public recap on shared screen;
- present new private information only on the private surface;
- do not rewind surrogate decisions.

## 9. Public transformation storyboards

### High Water

The storyboard set must show:

- the final pre-transformation public board;
- transition acknowledgement or cinematic state;
- the transformed public board;
- new route types;
- blocked or removed routes;
- water-only connectors;
- current seat locations;
- changed legal actions;
- persistent plain-system summary.

High Water is not only a color grade, overlay, or cutscene.

### Tidebound

- reveal only after authoritative public commitment;
- retain original seat identity visibly;
- show public capabilities and restrictions;
- preserve active agency;
- do not use zombie, possession, elimination, or replacement shorthand.

### Restless

- retain stable-seat tile and action ownership;
- clearly identify Bell-Witness, Drowned Guide, or Lighthouse Guardian;
- show public continuation actions;
- do not present the seat as a passive spectator.

## 10. Captions, transcript, and plain-system presentation

Critical narrative must remain understandable with voice and music disabled.

Each storyboard declares:

- subtitle behavior;
- closed-caption behavior;
- persistent plain-system text;
- transcript entry behavior;
- replay behavior;
- screen-reader announcement priority;
- focus behavior after interruption.

Private text cannot enter public history.

## 11. Visual language

Drowned Harbor UI uses the P0.3 visual language without becoming decorative clutter.

### Preferred

- hand-inked contours;
- simplified silhouettes;
- fog-paper and salt-bone text surfaces;
- restrained brass and cloudy-glass framing;
- oxidized mechanism motifs;
- clear route and seat shapes;
- scarce Lantern Amber for active light, temporary safety, selected objectives, human intervention, and meaningful guidance;
- cool-dark atmosphere with distinct materials and local color.

### Avoid

- muddy brown or sepia wash;
- blue-gray applied to everything;
- essential text inside distressed textures;
- bright amber used as general decoration;
- dense ornamental borders around every panel;
- photoreal inventory art mixed with storybook board art;
- color-only seat, route, speaker, privacy, or hazard encoding;
- unreadably dark inactive states;
- cinematic overlays that hide legal choices.

## 12. Storyboard record requirements

Every record declares:

- stable storyboard ID;
- title and category;
- Tale and stage context;
- layout mode;
- privacy surface;
- entry and exit conditions;
- public purpose;
- required information;
- primary layout regions;
- legal actions;
- confirmation pattern;
- controller focus order;
- caption, transcript, and persistent-text behavior;
- stable-seat and authority behavior;
- state variants;
- visual guidance and negative constraints;
- source paths and P0.8 traceability concepts;
- human-validation questions;
- preproduction status and approval boundary.

## 13. Storyboard categories

- Tale entry;
- lobby and admission;
- public board;
- public decision;
- private reveal;
- seat continuity;
- transformation;
- transcript and replay;
- accessibility settings;
- ending attribution;
- system recovery.

## 14. Human validation deferred

Future exact-build testing must evaluate:

- living-room readability;
- 1–8-seat rail legibility;
- controller focus and ownership;
- caption pacing and reflow;
- transcript access;
- privacy shielding;
- Low Tide and High Water route comprehension;
- handoff clarity;
- transformed and Restless agency;
- mixed ending attribution;
- color-vision and low-vision resilience;
- fatigue and session duration.

No storyboard, schema, static viewer, or automated validator proves these outcomes.

## 15. Approval boundary

This contract does not approve:

- final UI composition;
- final typography or fonts;
- final icons or art;
- final text scale or safe-area values;
- final controller mapping;
- Godot scenes, scripts, themes, resources, or transitions;
- Companion UI;
- production accessibility behavior;
- human usability claims;
- Drowned Harbor runtime implementation;
- a second production Tale.
