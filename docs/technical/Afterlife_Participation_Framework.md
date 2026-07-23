# Afterlife Participation Framework v1

**Status:** Design contract for review  
**Scope:** Generic afterlife participation, meaningful defeat continuation, and safe return-to-play boundaries  
**Repository baseline used for design:** protected `main` at `0dde8d41c7cb1fc23bb2d85c26cb9281e311c971`  
**Production Tale:** `lantern_house_vertical_slice` / Lantern House  
**Implementation status:** Documentation only. This contract does not authorize runtime, Tale, package, catalog, provider, localization, Companion, release, or identity changes.

---

## 1. Purpose

Terror Turn promises that defeat changes how a player participates; it does not reduce that player to passive spectating.

The accepted v0.0.8 social foundation already proves the authority and data model needed for continued play:

- `RoleSession` owns role, form, faction, lifecycle, objectives, actions, transitions, uses, cooldowns, outcomes, dedicated RNG, revision, and snapshots;
- stable-seat ownership survives disconnect and reconnect;
- authored afterlife forms must not be indefinitely passive;
- Lantern House demonstrates a Lantern Wraith, Watchful Guardian, Silent Witness, and Replacement Investigator;
- afterlife actions already pass through the same validated `RulesSession` and `BoardState` proposal boundaries as living actions;
- public, seat-private, faction-private, and diagnostics projections are explicit;
- mixed individual, faction, transformed, Restless, partial, and replacement outcomes are supported.

What the current foundation does not yet fully define is the reusable **participation loop** around those capabilities:

- when an afterlife seat is invited to act;
- how often it may influence play;
- how a player chooses or changes an afterlife path;
- how a player remains engaged between interventions;
- how multiple defeated seats share attention fairly;
- how adversarial, cooperative, neutral, and transformed histories affect afterlife without leaking secrets;
- how replacement or restoration is offered without making defeat strategically desirable;
- how afterlife actions remain consequential but cannot dominate living play;
- how the system behaves with one through eight stable seats;
- how the no-phone shared-screen route remains honest and complete.

This contract defines that loop while preserving the accepted authority, determinism, privacy, controller, and release boundaries.

---

## 2. Core promise

> **Defeat changes the verb set, not the player’s ownership of a seat.**

An afterlife seat remains:

- a stable participant;
- eligible for authored decisions;
- represented in the public session;
- owner of its permitted private state;
- capable of meaningful bounded influence;
- included in outcome resolution;
- eligible for authored return, restoration, replacement, or epilogue paths;
- protected from another device or seat taking its private decisions.

An afterlife seat must not become:

- an unrestricted game master;
- a source of free hidden information;
- a second Director;
- a spectator whose only input is “continue”;
- a mandatory phone user;
- a disconnected-seat automation target;
- a reason to delay the session indefinitely;
- a way to bypass the rules, board, social, seat, or Director authorities.

---

## 3. Design principles

### 3.1 Continued agency

Every supported afterlife form must have at least one repeatable participation route or one bounded path toward another active form.

A form is not meaningfully active merely because it:

- appears in a roster;
- receives flavor text;
- has an objective that cannot be influenced;
- waits for an ending;
- can press a button that changes no state;
- watches another seat make all relevant decisions.

### 3.2 Different play, not weaker imitation

Afterlife should not simply reproduce living movement and inventory play with lower numbers.

Its strongest identity comes from verbs that living seats do not ordinarily own:

- mark;
- warn;
- witness;
- remember;
- haunt;
- reveal an authorized public clue;
- stabilize or disturb an authored board feature;
- prepare a future intervention;
- influence a public consequence within authored limits;
- accept, defer, or decline a return opportunity.

### 3.3 Bounded influence

Afterlife influence must be meaningful enough to matter and bounded enough that living play remains central.

Bounds include:

- authored action windows;
- use limits;
- per-round or per-stage limits;
- cooldowns;
- resource costs;
- legal target policies;
- effect ceilings;
- deterministic conflict resolution;
- mode-specific availability;
- explicit no-op or pass behavior;
- replacement safeguards.

### 3.4 No strategic reward for losing

A player should not seek defeat because afterlife is consistently stronger, safer, or more flexible than living play.

The framework therefore requires:

- no unconditional power increase on defeat;
- no access to unrestricted hidden state;
- no automatic extra action economy;
- no guaranteed victory through afterlife alone;
- mode-specific limits on return and repeated transformation;
- preserved consequences from defeat;
- explicit outcome semantics for Restless, replacement, escaped, transformed, and defeated states.

### 3.5 Shared-screen honesty

An ordinary television is public.

Private afterlife choices require the same controlled reveal or optional seat-private Companion projection as any other private social choice. The system must never imply that a small panel on the shared television is private.

### 3.6 Deterministic participation

Afterlife windows, action ordering, costs, cooldowns, transitions, return offers, and outcome effects are derived from authoritative semantic events and versioned state.

They do not depend on:

- frame rate;
- animation completion;
- wall-clock time;
- controller polling order;
- network timing;
- presentation profile;
- audio playback;
- which screen happened to render first.

### 3.7 Replaceable narrative presentation

“The Underteller,” spirit voices, house whispers, visual omens, and epilogue narration are presentation.

They may describe an accepted afterlife consequence but may not:

- select the action;
- select the target;
- reveal hidden authority state;
- change costs;
- decide whether a return is legal;
- mutate gameplay;
- resolve ties;
- own cooldowns or resources.

---

## 4. Existing repository foundation

### 4.1 Accepted authority

`RoleSession` remains the sole social authority.

It already owns:

- stable-seat social assignment;
- current role/form;
- current faction;
- reveal state;
- lifecycle;
- seat-private objectives and actions;
- action uses;
- last-used round;
- transition history;
- resolved outcomes;
- social revision;
- dedicated role RNG;
- versioned snapshots;
- private audit and separately authored public history.

This contract does not move afterlife state into:

- `RulesSession`;
- `BoardState`;
- `SeatManager`;
- the Dread Director;
- the shared-screen view;
- Companion clients;
- Tale Library selection state;
- reports.

### 4.2 Accepted proposal boundary

Afterlife actions continue to use the existing atomic proposal flow:

1. validate actor, lifecycle, action, targets, use limits, cooldown, phase, and mode;
2. build a complete plan;
3. preflight rules and board effects against cloned snapshots;
4. submit through public authority methods;
5. commit social action use, transition, and revision only after downstream acceptance;
6. emit separate private audit and sanitized public history;
7. generate presentation payloads from the accepted result.

Rejected work changes no:

- role/form/faction;
- lifecycle;
- objective state;
- use count;
- cooldown;
- rules state;
- board state;
- Director state;
- public success history.

### 4.3 Existing Lantern House examples

The current social-lab content demonstrates:

| Form | Lifecycle | Current meaningful verb | Current path |
|---|---|---|---|
| Lantern Wraith | afterlife | Place one public omen through `BoardState` | Guardian, Witness, or Replacement |
| Watchful Guardian | afterlife | Issue one bounded public warning | Replacement |
| Silent Witness | afterlife | Add public testimony | Replacement |
| Replacement Investigator | replacement | Resume public objective progress | Living/transformed/defeat/escape transitions |

These are evidence fixtures, not final production balance or final content volume.

### 4.4 Existing schema protection

The accepted social schema already requires role/form definitions to carry:

- lifecycle;
- action references;
- transition references;
- afterlife mapping;
- maximum inactive transition delay;
- objectives;
- reveal policy;
- visibility;
- deterministic limits.

Validation rejects afterlife forms that can become indefinitely passive.

This framework strengthens that requirement from a schema-level “has a path” check into a player-experience and runtime-cadence contract.

---

## 5. Terminology

### 5.1 Defeat

An authoritative event that causes a seat to leave its current active or transformed form under an authored transition.

Defeat is not synonymous with removal from the session.

### 5.2 Afterlife form

A social form whose lifecycle is `afterlife`.

Examples in the current Lantern House social lab:

- Lantern Wraith;
- Watchful Guardian;
- Silent Witness.

### 5.3 Afterlife path

An authored participation identity selected or assigned after defeat.

A path may determine:

- available action families;
- public/private identity;
- objective set;
- resource rules;
- replacement eligibility;
- presentation vocabulary.

A path is not necessarily a faction.

### 5.4 Afterlife window

A deterministic semantic opportunity at which one or more afterlife seats may submit a bounded action, prepare, pass, select a path, or respond to a return offer.

### 5.5 Intervention

An accepted afterlife action that changes authoritative rules, board, social, or outcome-relevant state through an existing authority boundary.

### 5.6 Presence action

An accepted afterlife action whose authoritative consequence is intentionally small or presentation-only but still records meaningful participation, such as testimony, an omen, a warning, or preparation.

### 5.7 Return offer

An authored opportunity for an afterlife seat to transition to a replacement, restored, transformed, minion, or other non-afterlife form.

### 5.8 Legacy state

The bounded facts preserved from the seat’s prior form for outcome or eligibility purposes.

Legacy state must be explicitly authored. It is not unrestricted access to the prior role’s secrets.

---

## 6. Player experience

### 6.1 Defeat transition

When a seat is defeated:

1. the current authoritative action or consequence fully resolves;
2. the social authority validates the defeat transition;
3. any downstream rules/board effects preflight and commit atomically;
4. the public screen states that the seat has changed lifecycle using friendly public language;
5. private details are shown only through controlled reveal or an authorized seat-private projection;
6. the player receives a concise explanation:
   - what changed;
   - what remains;
   - what they can do next;
   - whether path choice is required;
   - when their next opportunity will occur;
7. the stable seat remains reserved to that player.

The system must not immediately bury the transition under another player’s prompt.

#### Required public information

The table may be told:

- the seat is defeated or has entered an authored public afterlife state;
- whether its afterlife identity is public;
- whether it can still participate;
- whether the table is waiting for that seat;
- whether a public consequence occurred.

The table must not be told, unless authored for public reveal:

- the prior hidden role;
- the prior private objective;
- a private cause;
- a private path choice;
- private legacy alignment;
- private return options;
- unauthorized faction information.

### 6.2 Path selection

A mode may use one of three path-selection policies.

#### Fixed

The defeat transition assigns one afterlife form.

Use when:

- the Tale needs a clear authored continuation;
- seat count is small;
- privacy complexity should be low;
- the form is a direct narrative consequence.

#### Player choice

The defeated seat chooses among a validated set of paths.

Use when:

- the paths support meaningfully different verbs;
- all choices are legal and reasonably useful;
- selection can be private without misleading the table;
- the choice cannot reveal forbidden prior information by exclusion.

#### Deterministic authored assignment

The social authority assigns a path from authored rules using stable inputs and, only when necessary, the dedicated role RNG.

Use when:

- the Tale requires variety;
- choice would leak information;
- seat balance requires deterministic distribution;
- path scarcity must be enforced.

Invalid path plans consume no RNG and leave the prior state unchanged.

### 6.3 Afterlife participation loop

The default reusable loop is:

1. **Observe public state.**
2. **Receive an afterlife window** at an authored semantic boundary.
3. **Review legal actions** through public or controlled-private presentation.
4. **Choose action, prepare, or pass.**
5. **Select legal targets** if required.
6. **Confirm.**
7. **Resolve through existing authorities.**
8. **Show only the authorized public consequence.**
9. **Record uses, cooldowns, resources, and the window key.**
10. **Return focus to the main tale.**

The loop must make it clear whether the afterlife seat is:

- acting now;
- preparing for later;
- waiting for a legal window;
- unable to act because of a known public rule;
- disconnected with its seat reserved;
- considering a private return offer.

### 6.4 Between windows

An afterlife player should still understand the evolving game.

Public presentation should keep them oriented through:

- current public objective;
- stage/round/phase;
- public board changes;
- public social transitions;
- next known afterlife opportunity, when safe to state;
- available Help;
- their seat’s public lifecycle;
- any public resource or use status.

The system must not create a separate always-on private dashboard on the shared television.

### 6.5 Multiple afterlife seats

With multiple defeated seats, the system must avoid:

- one seat monopolizing all interventions;
- long sequential private reveals every round;
- ambiguous ownership;
- controller races;
- nondeterministic first-input wins;
- repeated targeting of the same living seat;
- afterlife turns longer than the main rules phase.

Supported authored policies:

- **simultaneous commit:** each eligible afterlife seat submits one private intent, then resolution occurs in deterministic seat order;
- **rotating priority:** one eligible seat acts per window using an authoritative rotation ledger;
- **shared pool:** multiple seats select from one bounded faction or afterlife resource pool;
- **group choice:** public afterlife forms vote through the existing prompt/vote authority;
- **path-specific windows:** different paths act at different authored boundaries.

The selected policy must be explicit in the mode or Tale contract.

### 6.6 Passing

Pass is always legal when an afterlife window is optional.

A pass:

- is explicit;
- does not consume an action use unless authored;
- does not consume RNG;
- does not create a false public consequence;
- advances the window’s completion state;
- may contribute only to explicitly authored pass-related conditions;
- cannot be interpreted as consent to a private path or return.

### 6.7 Return and replacement

A return offer must state:

- the target form using friendly language;
- whether the transition is public or private;
- whether acceptance is optional;
- which afterlife state or resources are consumed;
- whether prior objectives remain, convert, or close;
- whether the seat returns immediately or at a safe boundary;
- what happens if declined;
- whether the offer can recur.

A return is not automatically superior to remaining in afterlife.

A player may reasonably prefer afterlife when:

- its current objective remains achievable;
- the return form carries new risk;
- the return would abandon a partial outcome;
- the path’s remaining intervention is strategically valuable.

The system must not force a return merely to simplify presentation unless the mode explicitly declares that policy before play.

---

## 7. Gameplay rules

### 7.1 Window vocabulary

The framework recommends a bounded window vocabulary:

- `after_defeat_resolved`
- `round_open`
- `phase_open`
- `before_public_prompt`
- `after_public_prompt`
- `after_check_resolved`
- `after_event_resolved`
- `after_board_mutation`
- `stage_open`
- `stage_close`
- `before_finale`
- `after_finale`
- `replacement_offer`
- `ending_review`

A Tale or mode may allow a subset.

Generic runtime must not branch on literal Tale, role, form, action, or fixture IDs.

### 7.2 Window identity

Every afterlife window has a stable key, for example:

```text
<session-sequence>:<stage-sequence>:<rules-revision>:<window-kind>:<window-index>
```

The exact encoding may differ, but the identity must be derived from authoritative values.

A window key ensures:

- duplicate presentation does not duplicate actions;
- replay submits the same opportunity;
- rollback restores pending/completed status;
- held inputs do not recommit;
- Companion retries remain exactly once;
- diagnostics can explain why a seat could or could not act.

### 7.3 Eligibility

A seat is eligible only when all relevant conditions pass:

- seat participates in the social session;
- stable seat is connected, unless an explicit future disconnected policy is authored;
- lifecycle permits the action;
- current form references the action;
- mode enables afterlife;
- window kind is permitted;
- action phase/window policy permits use;
- use limit remains;
- per-round/per-stage limit remains;
- cooldown is complete;
- resource cost is affordable;
- required targets exist;
- target privacy and connection policy pass;
- no terminal outcome blocks the action;
- no accepted duplicate exists for the window;
- no conflicting transition is already committed.

Eligibility computation is side-effect free.

### 7.4 Action families

A reusable afterlife library may include these semantic families.

#### Omen

Publicly mark an authored board space, path, object, hazard, or clue.

Requirements:

- use `BoardState` for authoritative board changes;
- use public or seat-private target selection as authored;
- never expose an unrevealed private objective by highlighting it;
- carry bounded duration or removal policy.

#### Warning / Ward

Create a bounded protective condition or publicly warn of an authored danger.

Requirements:

- use validated rules effects;
- never inspect future RNG;
- never convert a resolved failure into success unless the rule explicitly authorizes a post-resolution effect;
- clearly state timing.

#### Testimony / Memory

Record or surface an authorized public fact, clue, prior public event, or epilogue contribution.

Requirements:

- no reconstruction of hidden history;
- no access to private audit;
- public testimony content comes from authored safe references;
- repeated testimony obeys limits.

#### Nudge

Help the group locate a legal route or unfinished public objective.

Requirements:

- cannot read private choices;
- cannot reveal a secret role or target;
- may use the same authorized public objective vocabulary available to Help or the Director;
- should prefer guidance over raw reward.

#### Haunt / Pressure

Apply bounded adversarial influence where the mode permits.

Requirements:

- explicit mode allowlist;
- pressure cap;
- no targeting disconnected/reserved seats;
- no use of prior hidden knowledge unless publicly revealed and authored;
- no bypass of Director fairness, rules validation, or board recovery guarantees;
- public consequence does not identify a private cause unless authored.

#### Prepare

Commit a delayed afterlife intent for a later semantic window.

Requirements:

- explicit prepared-action state;
- deterministic trigger;
- cancellable only under authored policy;
- snapshot/replay support;
- no hidden mutation before trigger;
- stale or invalid prepared actions fail atomically.

#### Intercede

Respond to a specific public prompt, transition, check, or event through a bounded reaction.

Requirements:

- reaction window is explicit;
- cannot alter already-finalized authority state;
- one reaction per authored window unless otherwise declared;
- ordering among multiple reactions is deterministic;
- reaction availability must not leak private form identity through timing alone unless the form is public.

#### Return / Restore / Replace

Transition to an authored non-afterlife form.

Requirements:

- use `RoleSession` transition authority;
- validate downstream state;
- preserve stable-seat ownership;
- explicitly handle prior objectives and uses;
- prevent infinite defeat-return chains;
- never silently assign another player’s private state.

### 7.5 Resource model

Afterlife forms may use:

- fixed action uses;
- per-round/per-stage limits;
- cooldowns;
- a form-local resource;
- a faction-shared resource;
- Tale-wide afterlife budget;
- no resource beyond window scarcity.

A new resource is justified only when it creates understandable decisions.

A generic proposed resource contract:

```text
resource_id
current
maximum
gain_policy
spend_policy
reset_policy
visibility
sharing_scope
```

Resource changes must be authoritative social state or validated rules state—not presentation counters.

The baseline implementation should prefer existing uses/cooldowns before adding a new currency.

### 7.6 Influence ceiling

Each mode should define an afterlife influence ceiling across a bounded window, round, or stage.

The ceiling may constrain:

- number of accepted interventions;
- total effect magnitude;
- number of board mutations;
- repeated target count;
- number of pressure actions;
- number of return offers;
- shared-resource spend.

When the ceiling is reached:

- remaining seats may still receive a pass/presence choice;
- no hidden action is silently discarded;
- the public view explains that the afterlife opportunity is spent;
- no RNG is consumed.

### 7.7 Conflict resolution

When multiple afterlife intents conflict:

1. validate every intent against the same pre-resolution snapshot;
2. sort by authored priority;
3. then by stable seat number;
4. then by stable action ID;
5. apply each through the normal authority boundary;
6. revalidate later intents after each accepted mutation;
7. reject newly illegal intents atomically with a sanitized reason;
8. consume use/resource only for accepted work unless the action explicitly declares a committed-cost policy.

No controller polling order or Companion arrival time decides the winner.

### 7.8 Inactivity safeguards

An afterlife seat must not block the table indefinitely.

Mode policy defines:

- whether the window is required or optional;
- deterministic auto-pass conditions;
- maximum authoritative wait steps;
- whether facilitator override is allowed;
- what public guidance appears;
- how disconnect changes the window.

Any timeout-like behavior must be based on deterministic session steps or an explicit facilitator action, not hidden wall-clock mutation.

A wall-clock accessibility reminder may exist as presentation only and cannot commit an auto-pass.

### 7.9 Defeat-chain limits

The mode must bound transitions such as:

```text
active -> afterlife -> replacement -> afterlife -> replacement
```

Limits may be:

- maximum returns per seat;
- maximum defeat transitions per seat;
- stage-specific returns;
- one replacement form per Tale;
- no return after finale lock;
- escalating return cost;
- objective conversion after repeated defeat.

Invalid chains fail before mutation.

---

## 8. Authoritative state

### 8.1 Existing authoritative fields retained

The framework preserves existing `RoleSession` ownership of:

- `seat_states`;
- current `form_id`;
- current `faction_id`;
- lifecycle;
- connected state;
- reveal state;
- defeated/transformed/escaped flags;
- action uses;
- last-used rounds;
- objectives;
- transition history;
- assignment state;
- pending late seats;
- resolved outcomes;
- role RNG;
- social revision;
- bounded audit/public history.

### 8.2 Proposed additive afterlife state

A future schema version may add:

```text
afterlife_contract_version
afterlife_path_id
afterlife_path_selected
afterlife_window_sequence
pending_window_key
completed_window_keys
afterlife_priority_cursor
afterlife_resource
prepared_action
prepared_trigger
prepared_targets
return_offer
return_offer_sequence
returns_used
defeats_recorded
legacy_state
afterlife_public_status
```

Not every field is required in the first implementation slice.

#### Minimum first slice

The smallest useful generic capability needs:

- version;
- pending window key;
- completed window keys or bounded deduplication ledger;
- deterministic eligibility projection;
- authoritative pass/action completion;
- rotation cursor only if rotating-priority policy is used.

#### Second slice

Path choice and return require:

- path ID;
- selection state;
- return offer;
- returns used;
- legacy-state policy.

### 8.3 Legacy state policy

Legacy state must be an allowlisted authored projection.

Possible fields:

- prior public faction label;
- prior public lifecycle;
- prior revealed-form tags;
- completed public objective tags;
- defeat sequence;
- prior public action tags;
- end-reveal references.

Legacy state must not automatically include:

- hidden role ID;
- hidden faction ID;
- private objective text;
- private target history;
- secret action history;
- private audit;
- future RNG;
- diagnostics-only data.

### 8.4 Window record

A window record should be JSON-compatible and bounded:

```json
{
  "version": 1,
  "window_key": "stable-key",
  "kind": "round_open",
  "source_revision": 42,
  "eligible_seats": [2, 4],
  "policy": "rotating_priority",
  "active_seat": 2,
  "status": "pending",
  "accepted_records": [],
  "passed_seats": [],
  "rejected_records": []
}
```

Public projections may omit or generalize fields that would reveal private eligibility.

### 8.5 Action record

An accepted record should capture:

- stable window key;
- actor seat;
- action ID in private audit/diagnostics;
- friendly public label where authorized;
- targets in private audit;
- sanitized public target information;
- costs;
- use/cooldown changes;
- downstream authority;
- downstream revision/result;
- social revision;
- presentation payload references;
- public consequence;
- deterministic ordering key.

---

## 9. Presentation-only state

The following remain non-authoritative:

- current focus;
- highlighted action;
- scroll position;
- tooltip visibility;
- controller glyph family;
- safe-margin setting;
- text scale;
- subtitle setting;
- animation state;
- audio cue;
- screen shake;
- reduced-motion presentation;
- shield-transition animation;
- Help page;
- facilitator explanation page;
- “waiting for spirits” flavor text;
- private-reveal curtain animation;
- public omen art;
- Underteller line variant;
- camera framing;
- local input-repeat timing.

Presentation must always regenerate from authoritative social/rules/board/seat state.

---

## 10. Deterministic behavior

### 10.1 No new RNG by default

Most afterlife participation should require no RNG.

Use stable ordering for:

- eligible seats;
- legal actions;
- legal targets;
- path lists;
- conflict resolution;
- return-offer presentation;
- public history.

The dedicated role RNG may be used only for authored random path assignment or equivalent social selection.

It must remain isolated from:

- rules/deck/check RNG;
- Director RNG;
- presentation variants;
- Companion timing.

### 10.2 Evaluation atomicity

Checking afterlife eligibility:

- does not increment social revision;
- does not consume RNG;
- does not create public history;
- does not mutate uses/cooldowns/resources;
- does not alter rules or board;
- does not close a window.

### 10.3 Replay

Replay records player intents, not presentation actions.

Relevant intents include:

- select path;
- acknowledge path;
- choose afterlife action;
- choose target;
- confirm;
- pass;
- prepare;
- accept return;
- decline return;
- close controlled reveal.

Replaying the same:

- authoritative snapshot;
- window trigger;
- stable-seat intents;
- content;
- mode;
- role RNG state;

must produce the same:

- eligibility;
- ordering;
- accepted actions;
- rejected actions;
- transitions;
- downstream results;
- public history;
- outcome state.

### 10.4 Rollback

Rollback restores:

- pending/completed windows;
- path selection;
- resources;
- uses;
- cooldowns;
- prepared action;
- return offer;
- transition counts;
- objective state;
- role RNG;
- social revision;
- private/public histories within their bounded contract.

Presentation closes and regenerates from the restored state.

### 10.5 Reset and rematch

Protected reset clears:

- all afterlife forms;
- path selections;
- resources;
- windows;
- prepared actions;
- return offers;
- transition counts;
- legacy state;
- private prompts;
- public afterlife history;
- outcome state.

Same-seed rematch reproduces authored assignment and afterlife behavior when the same intents occur.

A new-seed rematch may change only behavior that is explicitly RNG-driven.

---

## 11. Privacy

### 11.1 Public shared-screen view

May include:

- seat number and multimodal cue;
- public lifecycle;
- public form/faction or safe cover;
- connection/reserved state;
- public afterlife status;
- public actions;
- public use/resource status when authored;
- public intervention consequences;
- sanitized window progress;
- public outcome summaries.

Must exclude:

- hidden prior identity;
- private path;
- private legal-action set when revealing it would expose identity;
- private targets;
- private return choice;
- private legacy state;
- private objective;
- raw action IDs where unsafe;
- private audit;
- RNG state;
- diagnostics;
- device identity.

### 11.2 Seat-private view

May include only for the authorized stable seat:

- exact current form/faction;
- exact afterlife path;
- private objectives;
- private legal actions;
- private costs/cooldowns;
- private targets;
- return offer;
- legacy state explicitly authorized for that seat;
- private acknowledgement;
- prepared action.

It may not include another seat’s secrets.

### 11.3 Faction-private view

Exists only if the authored faction permits communication or shared knowledge.

Afterlife membership does not automatically create a private communication channel.

A Restless faction-private view, if ever enabled, requires explicit policy for:

- membership visibility;
- shared resources;
- action coordination;
- target information;
- prior-faction leakage;
- Companion projection.

### 11.4 Controlled reveal

No-phone private afterlife interaction follows the existing controlled-reveal rules:

1. opaque full-screen shield;
2. public instruction names the authorized seat without revealing the secret;
3. only that stable seat can open;
4. private content appears;
5. confirm/cancel/Help remain controller-complete;
6. screen re-shields before returning;
7. public view is regenerated;
8. prior private text is not retained in public history or screenshots generated by the application.

### 11.5 Director boundary

The Director may receive only authorized public or aggregate afterlife signals, such as:

- defeated count;
- public Restless count;
- public afterlife-support availability;
- number of connected afterlife seats;
- public intervention already spent;
- public return state.

It must not receive:

- private path;
- hidden prior faction;
- private objective;
- private legal action;
- private target;
- private return preference;
- private legacy state.

Changing hidden afterlife assignments while preserving public state must not change Director telemetry or decisions.

### 11.6 Reports

Privacy-safe session reports may include:

- aggregate defeat count;
- aggregate afterlife transitions;
- aggregate accepted/pass/recovery events;
- public intervention labels;
- public return count;
- sanitized recovery codes.

They must exclude:

- hidden identities;
- private objectives;
- private path choices;
- private targets;
- exact private action IDs where unsafe;
- Companion secrets;
- device IDs;
- raw audit;
- RNG;
- private legacy state.

---

## 12. Controller-first and no-phone behavior

### 12.1 Semantic controls

The interaction grammar applies:

- D-pad/stick: move focus;
- A/Enter: confirm;
- B/Escape: back or pass where authored;
- X/H: Help;
- Menu/P: pause where permitted;
- protected reset: unchanged hold action.

No afterlife surface requires a mouse.

### 12.2 Stable-seat ownership

Only the authorized stable seat may:

- acknowledge private defeat details;
- select a private path;
- choose a private action;
- select private targets;
- accept/decline a private return;
- confirm a prepared action.

Another controller cannot answer by being pressed first.

### 12.3 Public actions

For publicly known afterlife forms, the shared television may present a public action menu if:

- no private information is exposed;
- ownership remains seat-scoped;
- the public action list itself does not leak hidden history;
- target selection is public by design.

### 12.4 Waiting guidance

The public footer or Help view should state:

- which public interaction is active;
- which seat is expected when safe;
- completion progress;
- controller action;
- pass behavior;
- reconnect status;
- recovery options.

It should not state a private path or action name merely to explain waiting.

### 12.5 Disconnect

A disconnected afterlife seat:

- retains form, path, objectives, uses, cooldowns, prepared action, and return offer;
- has no ordinary legal action;
- is excluded from ordinary targets;
- may be deterministically auto-passed only under explicit mode policy;
- remains reserved for same-seat reconnect;
- does not leak its private state through the public disconnect notice.

Reconnect restores the same private state.

### 12.6 Optional companions

Companions may improve simultaneous privacy and reduce pass-and-play friction.

They remain:

- optional;
- non-authoritative;
- stable-seat filtered;
- exactly-once intent transports;
- constrained by issue #44 until dependency remediation;
- unable to expose another seat’s afterlife state.

The complete afterlife route must work without them.

---

## 13. Accessibility and comfort

### 13.1 Multimodal identity

Afterlife forms and seats use:

- text;
- symbols;
- patterns;
- shape;
- position;
- optional color reinforcement.

Color alone is never required.

### 13.2 Reduced motion

Afterlife presentation must not rely on:

- flashing;
- rapid opacity pulses;
- forced camera shake;
- high-frequency distortion;
- unskippable motion;
- flicker to indicate a legal action.

Reduced-motion presentation must preserve equivalent information and timing.

### 13.3 Readability

At the 960×540 logical viewport:

- public afterlife notices fit safe margins;
- long action text uses bounded pages;
- one primary decision appears at a time;
- action cost and consequence are visible before confirmation;
- private reveal clearly identifies the seat;
- return offers distinguish accept and decline.

### 13.4 Cognitive load

The first afterlife decision after defeat should not present an unbounded catalog.

Recommended maximums for the first production implementation:

- up to three immediately comparable paths;
- up to four legal actions on one page;
- one primary resource;
- one active prepared action;
- one return offer at a time.

These are design targets subject to human playtest, not claims of validated usability.

### 13.5 Content sensitivity

Defeat and afterlife language should support Tale tone settings without changing rules.

Presentation profiles may alter:

- wording intensity;
- imagery;
- audio;
- gore detail;
- spirit terminology.

They must not alter:

- action availability;
- costs;
- outcomes;
- return rules;
- privacy;
- authority.

---

## 14. Schema changes

### 14.1 Generic additive schema proposal

A future `SocialContent` version may add an `afterlife_policies` family.

Example:

```gdscript
{
  "id": "standard_afterlife",
  "version": 1,
  "enabled": true,
  "window_kinds": ["round_open", "stage_close"],
  "resolution_policy": "rotating_priority",
  "required_response": false,
  "auto_pass_steps": 1,
  "influence_limit": 1,
  "path_policy": "player_choice",
  "path_refs": ["omen_path", "guardian_path", "witness_path"],
  "return_policy_ref": "replacement_return",
  "public_progress_policy": "aggregate",
  "legacy_policy_ref": "public_legacy_only"
}
```

#### Proposed path definition

```gdscript
{
  "id": "guardian_path",
  "version": 1,
  "label": "Guardian",
  "visibility": "public",
  "form_ref": "watchful_guardian",
  "action_refs": ["guardian_warning"],
  "objective_refs": ["guard_the_lantern"],
  "resource_policy_ref": "",
  "return_policy_refs": ["replacement_return"],
  "presentation": {
    "symbol": "G",
    "pattern": "shield chevrons"
  }
}
```

#### Proposed return policy

```gdscript
{
  "id": "replacement_return",
  "version": 1,
  "trigger_kinds": ["stage_open"],
  "source_lifecycles": ["afterlife"],
  "target_form_ref": "replacement_investigator",
  "maximum_uses_per_seat": 1,
  "choice_policy": "optional_private",
  "cost_policy": "consume_remaining_afterlife_actions",
  "objective_policy": "replace_with_target_form",
  "legacy_policy_ref": "public_legacy_only"
}
```

### 14.2 Validation additions

Validation should reject:

- afterlife enabled without a legal path;
- a path with no action and no bounded transition out;
- unsupported window kinds;
- duplicate policy/path IDs;
- path/form lifecycle mismatch;
- private path with unsafe public inference;
- return cycles beyond configured bounds;
- impossible influence limits;
- negative resources or cooldowns;
- auto-pass policies without deterministic steps;
- faction-private coordination without faction permission;
- prepared actions without a legal trigger;
- legacy policies containing forbidden private fields;
- path choice sets that leak a hidden prior role by elimination;
- modes that allow afterlife but cannot generate a legal no-op/pass.

### 14.3 Backward compatibility

Existing v1 social snapshots remain valid only under their existing runtime.

A future runtime must not silently interpret missing v2 fields as a production afterlife policy unless a documented migration supplies exact defaults.

Preferred migration strategy:

1. add generic types and validators behind synthetic fixtures;
2. add snapshot version 2 with explicit migration tests;
3. preserve v1 rejection/restore behavior;
4. adopt Lantern House in a separately reviewed identity-changing release only if governed package content must change.

---

## 15. Tests

### 15.1 Unit tests

Cover:

- policy/path/return/legacy validation;
- actionless passive-form rejection;
- path selection policies;
- window identity;
- duplicate suppression;
- eligibility without mutation;
- pass;
- rotating priority;
- simultaneous intent ordering;
- resource/uses/cooldown limits;
- influence ceiling;
- prepared action;
- return offer;
- defeat-return chain bounds;
- disconnected-seat behavior;
- stable-seat ownership;
- atomic downstream rejection;
- no RNG for deterministic paths;
- isolated role RNG for authored random assignment;
- snapshot round trip;
- malformed snapshot rejection;
- reset and rematch;
- candidate-ID/form-ID branch guard.

### 15.2 Deterministic scenarios

At minimum:

#### Single defeated seat

- enters afterlife;
- sees public transition;
- receives controlled-private choice if required;
- acts at one window;
- passes at another;
- reconnects with state preserved;
- reaches an afterlife or replacement outcome.

#### Multiple defeated seats

- two or more eligible seats;
- deterministic order;
- influence ceiling;
- no controller race;
- conflict revalidation;
- fair rotation;
- bounded public wait.

#### Hidden prior role

- defeat does not reveal prior hidden identity unless authored;
- path choice does not leak prior identity;
- public history remains sanitized;
- Director telemetry remains equivalent.

#### Adversarial afterlife

Using synthetic content:

- pressure action allowed only by mode;
- disconnected targets excluded;
- pressure limit enforced;
- no resolved result changed;
- public consequence hides private cause where required.

#### Replacement

- offer occurs at authored boundary;
- accept and decline are deterministic;
- objectives transition according to policy;
- stable seat remains;
- repeated return cap enforced;
- old private actions do not remain legal.

#### No-afterlife mode

- defeat follows authored terminal/inactive policy;
- no false participation prompt appears;
- mode clearly disclosed before play;
- schema remains valid.

### 15.3 Privacy canaries

Plant unique secret values in:

- prior role ID;
- prior faction ID;
- prior private objective;
- private path ID;
- private target;
- return preference;
- prepared action;
- legacy state;
- private audit;
- Companion seat view.

Recursively prove absence from:

- public television projection;
- public history;
- public host payloads;
- sanitized errors;
- Help;
- Director telemetry;
- Director decisions;
- privacy-safe reports;
- unauthorized seat-private views;
- faction-private views without permission;
- build manifests;
- portable bundles.

### 15.4 Replay and rollback

Prove:

- identical intents produce identical outcomes;
- duplicate window presentation does not duplicate actions;
- rollback reopens only the correct pending window;
- accepted actions are not repeated after restore;
- role RNG counters match;
- rules and board revisions match;
- public histories match;
- private projections match for the authorized seat;
- presentation focus may differ without changing authority.

### 15.5 Batch simulation

Synthetic simulation should vary:

- 1–8 seats;
- 0–7 afterlife seats;
- cooperative, mixed, adversarial, and no-afterlife modes;
- connect/disconnect/reconnect;
- path choice;
- passes;
- prepared actions;
- return offers;
- resource scarcity;
- influence ceilings;
- simultaneous conflicts;
- multiple seeds where RNG is authorized.

Assert:

- no infinite loops;
- no unbounded history;
- no impossible passive afterlife form;
- no authority bypass;
- no negative resource;
- no use-limit violation;
- no disconnected ordinary action;
- no nondeterministic ordering;
- no hidden-state leak;
- no core rules RNG change from social-only evaluation;
- no Director RNG change;
- every accepted consequence has audit and downstream reference;
- every rejected consequence is atomic.

### 15.6 Human playtest items

Automation cannot establish whether afterlife feels meaningful.

Human testing must separately observe:

- time from defeat to first meaningful choice;
- perceived influence;
- boredom between windows;
- clarity of next opportunity;
- whether afterlife dominates living play;
- fairness with multiple defeated seats;
- willingness to remain in afterlife versus return;
- private-reveal friction;
- television readability;
- controller ownership clarity;
- accessibility comfort;
- emotional tone of defeat;
- session length impact;
- whether players intentionally seek defeat.

Results remain evidence for the exact tested build only.

---

## 16. Release and migration risks

### 16.1 Package identity risk

Lantern House production package identity is governed.

Adding production afterlife policies, paths, actions, objectives, transitions, or localization may change package identity and requires a separately reviewed release.

The generic contract and synthetic fixtures should land first.

### 16.2 Snapshot compatibility risk

New window/path/resource/return state requires snapshot versioning.

Silent defaulting could:

- duplicate interventions;
- lose cooldowns;
- reopen completed windows;
- expose stale private prompts;
- permit repeated returns;
- change replay digests.

### 16.3 Balance risk

Meaningful afterlife influence can become:

- too weak;
- too strong;
- repetitive;
- griefable;
- optimal to seek;
- a source of kingmaking;
- too slow with many defeated seats.

Simulation checks invariants, not fun or final balance.

### 16.4 Privacy risk

Path choice, action availability, target sets, and return timing can reveal hidden prior identity indirectly even when IDs are filtered.

Tests must compare complete public outputs across secret-equivalent states.

### 16.5 Pacing risk

Sequential controlled reveals can create long pauses.

Mitigations include:

- rotating priority;
- simultaneous Companion input when available;
- public paths;
- bounded choices;
- prepared actions;
- fewer windows;
- aggregate progress.

No-phone operation remains mandatory.

### 16.6 Authority risk

A convenience implementation may attempt to mutate rules/board directly from afterlife UI.

This is prohibited.

### 16.7 Director interaction risk

Afterlife availability could alter Director behavior based on private state.

Only allowlisted public or aggregate signals cross the boundary.

### 16.8 Companion security risk

Companion implementation remains constrained by issue #44.

This design contract does not change dependencies, protocol, service, configuration, deployment, or security status.

### 16.9 Human-evidence risk

Automated controller input, simulation, screenshots, or CI cannot be reported as physical-controller, television, household, privacy, accessibility, or fun evidence.

Issue #39 remains the human observation gate.

---

## 17. Bounded implementation sequence

### Slice A — Generic afterlife window gate

Use synthetic export-excluded content.

Deliver:

- window vocabulary;
- stable window identity;
- pending/completed state;
- eligibility projection;
- pass;
- duplicate suppression;
- deterministic ordering;
- snapshot version plan;
- focused tests.

Do not alter Lantern House production data.

### Slice B — Multi-seat participation policy

Deliver:

- rotating-priority and/or simultaneous-commit policy;
- influence ceiling;
- conflict revalidation;
- public aggregate progress;
- reconnect behavior;
- batch simulation.

### Slice C — Path selection and legacy projection

Deliver:

- fixed/player-choice/deterministic-assignment policies;
- safe path visibility;
- allowlisted legacy state;
- controlled reveal;
- secret-equivalence tests.

### Slice D — Prepared actions and return offers

Deliver:

- prepared intent;
- trigger resolution;
- optional return;
- decline;
- objective policy;
- defeat-return chain cap;
- snapshot/replay tests.

### Slice E — Presentation and Help

Deliver:

- public defeat transition;
- controlled-private flow;
- afterlife waiting guidance;
- action cost/consequence confirmation;
- public consequence;
- accessibility equivalence;
- privacy-safe report projection.

### Slice F — Lantern House production adoption

Separate reviewed release.

Before changing production data:

- rebase from accepted protected main;
- review current package/catalog/provider identities;
- decide exact paths/actions/windows;
- update governed content/localization;
- regenerate package identity evidence;
- preserve no-phone behavior;
- preserve deterministic snapshots/replay through explicit migration;
- run exact-head portable and privacy validation.

### Slice G — Exact-build human pilot

After implementation acceptance:

- physical controllers;
- 1–8 seat coverage appropriate to available participants;
- at least one defeat;
- at least one afterlife action;
- at least one return or explicit no-return case;
- television viewing;
- controlled reveal;
- facilitator burden;
- boredom and influence observations;
- honest “not tested” labels for unobserved conditions.

---

## 18. Acceptance criteria for design approval

- [ ] Defeat changes a seat’s verb set without silently removing the player.
- [ ] Existing `RoleSession`, stable-seat, rules, board, Director, and Companion authority boundaries remain intact.
- [ ] Every afterlife form has a repeatable meaningful action or bounded path out.
- [ ] Afterlife windows are semantic, deterministic, versioned, and duplicate-safe.
- [ ] Multiple afterlife seats resolve without controller races or arrival-time authority.
- [ ] Pass is explicit and deterministic.
- [ ] Influence is bounded by authored uses, cooldowns, resources, ceilings, and mode policy.
- [ ] Defeat is not consistently stronger than living play.
- [ ] Return/replacement is explicit, bounded, and optional where authored.
- [ ] Private path/action/target/return state never leaks to the ordinary television.
- [ ] Stable-seat reconnect restores the same afterlife state.
- [ ] No phone is required.
- [ ] Director receives only allowlisted public/aggregate signals.
- [ ] Presentation remains non-authoritative and replaceable.
- [ ] Snapshot, replay, rollback, reset, and rematch behavior are specified.
- [ ] Additive schema and validation requirements are explicit.
- [ ] Synthetic generic capability precedes Lantern House production adoption.
- [ ] Production package identity is not casually changed.
- [ ] Automated tests and privacy canaries are defined.
- [ ] Human evidence remains separately classified.

---

## 19. Out of scope

- runtime implementation in this documentation PR;
- changing current Lantern House package or catalog identity;
- adding a second production Tale;
- final afterlife balance;
- full combat or enemy/minion systems;
- unrestricted ghost movement;
- voice chat or secret audio channels;
- mandatory Companion devices;
- Companion dependency remediation;
- cloud AI, generated narration, or behavioral profiling;
- campaign persistence;
- matchmaking;
- accounts;
- monetization;
- legal clearance of Terror Turn or The Underteller;
- claims that afterlife is fun, fair, accessible, or television-ready without human evidence.

---

## 20. Recommended next decision

Approve this contract as the reusable afterlife participation target, then implement **Slice A — Generic afterlife window gate** only after the active Tale Library work and design-document review sequencing are accepted.

The first implementation must use synthetic export-excluded content and must not alter the production Lantern House package, catalog identity, governed localization, provider, replay digests, privacy-safe reports, Companion protocol, or portable artifacts.

---

## Appendix A — Current Lantern House capability map

| Capability | Current evidence | Framework treatment |
|---|---|---|
| Defeat transition | `fall_restless` | Preserve; add transition experience and window state |
| Generic afterlife form | Lantern Wraith | Preserve; define repeatable participation cadence |
| Public board intervention | `place_restless_omen` | Use as Omen-family example |
| Protective afterlife path | Watchful Guardian | Use as Warning/Ward example |
| Narrative afterlife path | Silent Witness | Use as Testimony/Memory example |
| Return to play | Replacement Investigator | Preserve; define offers, decline, cost, and chain bounds |
| Afterlife objective | Guide From Beyond | Preserve objective scope; avoid final balance claims |
| Guardian objective | Guard the Lantern | Preserve as evidence fixture |
| Witness objective | Bear Witness | Preserve as evidence fixture |
| Replacement objective | Return to the Light | Preserve as evidence fixture |
| No-afterlife mode | Mortal Cooperative | Preserve explicit mode option |
| Mixed outcome support | mixed fixture | Preserve multi-result semantics |
| Stable-seat reconnect | accepted authority | Extend to pending windows/path/return state |
| Shared-screen privacy | controlled reveal | Preserve and apply to afterlife choices |
| Optional Companion | filtered seat projection | Preserve as optional transport only |

---

## Appendix B — Participation quality questions

These questions guide design review and future human observation:

1. Does the player make a consequential choice soon after defeat?
2. Can the player explain their new verbs without reading diagnostics?
3. Is the next opportunity understandable?
4. Does the player affect the shared story without replacing living agency?
5. Are actions varied enough across a typical session?
6. Can several defeated seats participate without excessive delay?
7. Can a hidden prior role remain hidden where authored?
8. Does the player ever prefer pass for a meaningful reason?
9. Is return a real choice rather than an automatic upgrade?
10. Can the table understand public consequences without learning private causes?
11. Does afterlife preserve the horror tone without making defeat emotionally punitive?
12. Does the no-phone route remain practical?
13. Are accessibility settings equivalent in information and authority?
14. Is any player encouraged to seek defeat for power?
15. Can the ending recognize afterlife contributions without reducing them to a binary win/loss?

---

## Appendix C — Non-authoritative UI state example

```json
{
  "focused_action_index": 1,
  "focused_target_index": 0,
  "help_open": false,
  "private_shield_visible": true,
  "page_index": 0,
  "glyph_family": "xbox",
  "reduced_motion": true,
  "safe_margin": 24,
  "local_notice": "Choose an omen, prepare, or pass."
}
```

None of these fields may determine action legality, action cost, target legality, return eligibility, outcome resolution, or replay state.

---

## Appendix D — Sanitized rejection vocabulary

Player-facing rejections should use bounded codes and friendly recovery text.

| Internal condition | Sanitized code | Friendly recovery |
|---|---|---|
| stale window key | `afterlife_window_changed` | “That spirit opportunity has changed. Review the current choices.” |
| duplicate accepted action | `afterlife_action_complete` | “This opportunity is already complete.” |
| disconnected actor | `seat_reconnect_required` | “Reconnect the reserved controller for this seat.” |
| action on cooldown | `afterlife_action_resting` | “That ability is not ready at this opportunity.” |
| influence ceiling reached | `afterlife_influence_spent` | “The afterlife has spent its influence for this beat.” |
| illegal target | `afterlife_target_unavailable` | “Choose another available target.” |
| return no longer legal | `return_offer_changed` | “The return path is no longer available.” |
| downstream rules rejection | `afterlife_consequence_unavailable` | “That consequence cannot resolve now. Choose another action or pass.” |

Never include raw:

- file paths;
- class names;
- source-ledger data;
- package hashes;
- provider IDs;
- private role/form/faction IDs;
- private targets;
- private objectives;
- RNG counters;
- diagnostics payloads.

---

## Appendix E — Design ownership matrix

| Concern | Owner |
|---|---|
| Stable controller/device claim | Seat layer |
| Role, form, faction, lifecycle | `RoleSession` |
| Afterlife path/window/resource/use state | `RoleSession` |
| Rules effects | `RulesSession` |
| Board mutations | `BoardState` |
| Adaptive pacing | Dread Director |
| Public/seat/faction projections | Generated from `RoleSession` |
| Controlled-reveal focus and curtain | Presentation |
| Companion transport | Optional non-authoritative Companion |
| Outcome evaluation | `RoleSession` proposal over approved authorities |
| Underteller/spirit narration | Replaceable presentation |
| Reports | Local privacy-safe non-authoritative reporting |
| Human evidence | Exact-build playtest record |

---

## Appendix F — Release checklist

Before any implementation PR is considered ready:

- [ ] starts from an accepted protected-main SHA;
- [ ] contains one bounded slice;
- [ ] does not overlap an active runtime PR without explicit coordination;
- [ ] preserves production Tale/package/catalog identities unless the issue explicitly authorizes change;
- [ ] uses synthetic fixtures for generic capability;
- [ ] includes focused deterministic tests;
- [ ] includes recursive privacy canaries;
- [ ] includes snapshot/replay/rollback tests when state changes;
- [ ] preserves controller and keyboard fallback;
- [ ] preserves complete no-phone operation;
- [ ] does not change Companion dependencies/protocol/configuration;
- [ ] leaves issue #44 status truthful;
- [ ] makes no human evidence claims;
- [ ] runs repository, Godot, GUT, lint, formatting, privacy, no-network, and portable gates appropriate to the slice;
- [ ] documents exact-head validation and known deviations;
- [ ] receives independent review before merge.
