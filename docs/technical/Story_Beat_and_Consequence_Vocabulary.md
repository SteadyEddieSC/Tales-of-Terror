# Story Beat and Consequence Vocabulary v1

**Status:** Proposed design contract  
**Scope:** Documentation and future implementation guidance only  
**Repository:** `SteadyEddieSC/Tales-of-Terror`  
**Working title:** Terror Turn  
**Host name:** The Underteller, provisional and replaceable  
**Primary production Tale:** `lantern_house_vertical_slice`  
**Target engine:** Godot 4.7.1, Compatibility renderer, 960×540 logical viewport

---

## 1. Purpose

Terror Turn already has bounded authorities for Tale selection, stage sequencing, rules events, prompts, votes, cards, checks, board mutations, deterministic Director decisions, social transitions, afterlife actions, outcomes, privacy projections, snapshots, rollback, and rematch.

Those systems explain **how state changes**.

They do not yet share one cross-system language for **what the story is doing to the table**.

This contract defines that language.

A **story beat** describes the dramatic purpose of a bounded moment.

A **consequence** describes the validated, authority-owned result of resolving that moment.

The vocabulary allows Tale authors, rules content, Director candidates, social transitions, afterlife actions, presentation, tests, and reports to describe the same narrative structure without moving gameplay authority into prose, tags, the Underteller, or a generic story engine.

The contract answers questions such as:

- Is the moment orienting, inviting, revealing, forcing a choice, escalating, reversing, demanding sacrifice, transforming, defeating, allowing recovery, resolving a finale, or reflecting in an epilogue?
- Which authority owns the state change?
- What player agency exists before commit?
- Which parts are public or private?
- Is the result reversible, recoverable, persistent, or terminal?
- Can the Director select it?
- Can an afterlife seat influence it?
- How does replay reproduce it?
- Does production adoption change a governed Tale identity?

---

## 2. Non-goals

This contract does not:

- add runtime code;
- add a generic narrative scripting engine;
- add callbacks, expressions, reflection, or dynamic script loading;
- change the accepted Lantern House package, catalog, manifest, localization, or identity;
- create a second production Tale;
- rename existing stable IDs;
- replace `RulesSession`, `BoardState`, `DirectorRuntime`, `RoleSession`, or the session coordinator;
- let the Underteller choose or resolve gameplay;
- require every turn to contain a twist;
- require a phone;
- add cloud AI, generated narration, or player profiling;
- certify final story quality, fear, fun, fairness, pacing, accessibility, or household play;
- authorize merge or release action from the Design & Development Lab.

---

## 3. Core principles

### 3.1 Story semantics are not authority

A beat classification explains purpose.

It cannot directly:

- add a counter;
- reveal a board space;
- open a connector;
- grant or play a card;
- resolve a vote;
- roll a check;
- transform a role;
- complete an objective;
- select a Director candidate;
- end the Tale.

Every mutation remains a validated request to the authority that owns it.

### 3.2 Consequences are explicit

A beat is not resolved merely because narration played.

A resolved beat records whether its consequence was:

- accepted;
- rejected;
- deferred;
- intentionally omitted;
- presentation-only;
- rolled back;
- replaced by a legal fallback;
- terminal.

### 3.3 Player agency is named honestly

The vocabulary distinguishes:

- no decision;
- acknowledgement;
- exploration;
- single-seat choice;
- simultaneous choice;
- public vote;
- card or inventory response;
- check preparation;
- social action;
- afterlife action;
- pass;
- protected destructive choice.

Authored text must not imply meaningful choice when the result is fixed.

### 3.4 A reversal changes interpretation

Adding danger is escalation.

A reversal changes at least one of:

- understood objective;
- valid route;
- public allegiance;
- player lifecycle;
- faction relationship;
- meaning of a prior discovery;
- authority-approved verb set.

Not every event, round, failure, Director decision, or stage transition is a reversal.

### 3.5 Defeat changes the verb set

Where afterlife is enabled, defeat is followed by an authored bridge into continuing participation.

The stable seat is not deleted.

### 3.6 Silence is valid

An intentional hold, breath, or no-op may be the correct dramatic decision when it is authored, deterministic, bounded, and explainable.

### 3.7 Privacy is authored

Private discoveries, objectives, allegiances, targets, path preferences, and return offers cannot become public through tags, rationale, host lines, telemetry, reports, errors, or history.

### 3.8 Production identity remains governed

Adding vocabulary fields to Lantern House may change canonical package or localization identity.

Generic capability work begins with synthetic, export-excluded fixtures.

Production adoption requires separate package, manifest, localization, source-ledger, digest, catalog, replay, and migration review.

---

## 4. Existing repository grounding

The current Lantern House route already demonstrates the raw material for this vocabulary.

### 4.1 Public briefing

- orients the table;
- states the public objective;
- requires acknowledgement;
- has no private consequence.

### 4.2 Threshold

- presents an invitation;
- resolves an authored event;
- presents a single-seat approach choice;
- opens a connector;
- draws a card;
- reveals a clue.

### 4.3 Council

- opens a public vote;
- gathers stable-seat submissions;
- resolves a route commitment;
- applies the accepted result through rules or board authority.

### 4.4 Reckoning

- introduces a hazard;
- grants a useful card;
- allows a card response;
- resolves a seeded check;
- permits one bounded Director evaluation.

### 4.5 Afterlife

- defeats one eligible living role;
- transitions that stable seat into an afterlife form;
- permits one authored afterlife-support action.

### 4.6 Ending

- secures the house through rules effects;
- resolves mixed outcomes;
- presents public and controlled-reveal details;
- offers deterministic rematch or return.

The vocabulary formalizes these purposes without changing accepted content.

---

## 5. Three-layer model

### 5.1 Story beat

A story beat is a semantic record describing:

- dramatic function;
- player-facing question;
- agency pattern;
- pressure direction;
- visibility;
- expected handoff;
- allowed consequence families;
- repetition and pacing guidance.

A beat does not mutate state.

### 5.2 Consequence proposal

A consequence proposal is a bounded request expressed in an existing authority vocabulary, such as:

- rules effect bundle;
- board mutation;
- prompt or vote;
- check;
- card or item action;
- Director proposal;
- social transition or action;
- outcome-resolution request;
- presentation payload;
- intentional no-op.

### 5.3 Authority result

The owning authority returns an auditable result containing:

- accepted or rejected state;
- stable reason;
- downstream revision or history reference;
- public consequence projection;
- private projections where authorized;
- rollback behavior;
- terminality where applicable.

The resolved beat references that result.

---

## 6. Canonical beat families

The v1 families are intentionally small and reusable.

| Beat family | Core question | Typical agency | Pressure | Typical handoff |
|---|---|---|---|---|
| `orientation` | Where are we and what matters? | acknowledge | neutral | invitation or discovery |
| `invitation` | What will the table approach? | explore or choose | slight rise | discovery |
| `discovery` | What new fact becomes actionable? | inspect or acknowledge | variable | choice or reflection |
| `choice` | Which legal option will be selected? | choice or vote | variable | commitment |
| `commitment` | What cost or route is now locked? | confirm or spend | rise | escalation or consequence |
| `escalation` | How does pressure increase within bounds? | respond or endure | pressure | recovery or reckoning |
| `complication` | What obstacle changes the immediate plan? | adapt | pressure | choice or escalation |
| `reversal` | What prior assumption or relationship changed? | react or choose | sharp variable | transformation or new objective |
| `sacrifice` | What must be spent, risked, or exposed? | explicit commit | pressure with meaning | recovery or reckoning |
| `transformation` | How does an entity change category? | acknowledge or choose | variable | new verb set |
| `defeat` | What is lost now? | acknowledge or final response | pressure | afterlife, replacement, or terminal |
| `afterlife` | How does the defeated seat continue? | act, prepare, pass, return | variable | living beat or epilogue |
| `recovery` | What breathing room or repair is available? | choose or receive | relief | invitation or escalation |
| `reckoning` | What accumulated choices are tested? | prepare, commit, check | high | defeat, recovery, or finale |
| `finale` | What terminal question is resolved? | final choice/check/action | peak | epilogue |
| `epilogue` | What does the Tale remember? | review and controlled reveal | release | rematch or return |
| `hold` | Why is no intervention the fair choice? | none or acknowledge | neutral | next legal window |

### 6.1 Stability and synonyms

Family IDs are intended as stable semantic vocabulary if implemented.

New production families require design review.

Flavor terms are not duplicate families:

- omen may present discovery, escalation, afterlife, or hold;
- twist is not a canonical family;
- a Terror Turn may be the presentation name for a qualifying reversal;
- boss fight may combine reckoning and finale;
- death may combine defeat and afterlife;
- rest may be recovery or hold.

---

## 7. Beat-family contracts

### 7.1 `orientation`

**Promise**

Give every player enough public context to understand the situation, objective, controls, and immediate next action.

**Required**

- public objective or situation;
- expected acknowledgement or action;
- no-phone route;
- television-readable text;
- no spoilers.

**Forbidden**

- state mutation merely because text displayed;
- fake choice language;
- raw IDs, hashes, source paths, or private roles.

**Examples**

- Tale briefing;
- new-act public objective refresh;
- post-reconnect public recap.

### 7.2 `invitation`

**Promise**

Open a bounded opportunity and clearly identify who may approach it.

**Required**

- available approach or interaction;
- acting seat or shared scope;
- expected control;
- cancel or pass behavior where legal.

**Forbidden**

- auto-commit on focus movement;
- hidden mandatory consequences;
- wall-clock authority.

### 7.3 `discovery`

**Promise**

Reveal information that changes what the table can reasonably understand or decide.

**Required**

- explicit audience classification;
- authoritative source;
- public versus controlled-reveal distinction;
- actionable or reflective handoff.

**Forbidden**

- private identity leakage through public metadata;
- cosmetic cues treated as authoritative facts;
- effects granted by narration alone.

### 7.4 `choice`

**Promise**

Present legal authored options or an explicit pass whose selection matters.

**Required**

- scope and eligible seats;
- minimum and maximum selections;
- tie, abstain, cancel, and pass behavior;
- authority-owned commit.

**Forbidden**

- focus movement counted as selection;
- controller arrival order deciding resolution;
- another seat's private options exposed.

### 7.5 `commitment`

**Promise**

Mark the point after which a route, cost, declaration, or use has been accepted.

**Required**

- clear committed result;
- revision or history evidence;
- rollback atomicity;
- visibility of irreversible or persistent effects.

**Forbidden**

- presentation completion treated as commit;
- silent resource spend;
- unannounced post-commit substitution.

### 7.6 `escalation`

**Promise**

Increase urgency, hazard, scarcity, opposition, or uncertainty without invalidating fair recovery paths.

**Required**

- pressure budgets and caps;
- owning authority;
- legal completion route;
- recovery or hold after severe pressure.

**Forbidden**

- changed resolved dice;
- punishment for disconnect;
- unbounded hazard stacking;
- private-knowledge targeting.

### 7.7 `complication`

**Promise**

Change the immediate plan while preserving the Tale's coherent objective and recoverability.

**Required**

- concrete obstacle;
- at least one legal response;
- temporary or persistent classification;
- distinction from a full reversal.

**Forbidden**

- terminal failure disguised as complication;
- invalidation of all prior agency;
- hidden rules.

### 7.8 `reversal`

**Promise**

Change the table's interpretation of the situation and create a new coherent decision space.

**Required**

- changed assumption, route, objective, allegiance, lifecycle, relationship, or verb set;
- authored and bounded trigger;
- authorized reveal policy;
- repetition limits.

**Forbidden**

- ordinary pressure labeled as reversal;
- default every-round twists;
- erasing choices without authored consequence;
- literal content-ID branches in generic runtime.

### 7.9 `sacrifice`

**Promise**

Make a meaningful cost visible and authorized before commit.

**Required**

- cost category;
- authorizing seat or group;
- public and private portions;
- attempted benefit or protection;
- cancel behavior before commit where legal.

**Forbidden**

- silent inventory or capability loss;
- public coercion of a private seat;
- guaranteed-success language when the rules still test the result.

### 7.10 `transformation`

**Promise**

Move an entity into a new authored category with a clear new verb set and privacy policy.

**Required**

- valid source and target state;
- owning authority;
- preserved stable-seat ownership;
- regenerated public and private projections;
- new actions and objectives.

**Forbidden**

- control transfer;
- stale private views;
- unbounded chains;
- presentation-owned form or faction changes.

### 7.11 `defeat`

**Promise**

Resolve a loss honestly while preserving the player's continuing status where the mode permits it.

**Required**

- distinction from disconnect;
- clear lost capabilities;
- explicit continuation policy;
- retained stable seat;
- bounded reveal.

**Forbidden**

- seat deletion;
- disconnect converted into defeat;
- premature secret-objective reveal;
- passive-spectator language when continuation exists.

### 7.12 `afterlife`

**Promise**

Give a defeated seat bounded, meaningful, deterministic participation.

**Required**

- semantic afterlife windows;
- act, prepare, pass, or return where authored;
- influence ceilings;
- deterministic multi-spirit resolution;
- no-phone completion.

**Forbidden**

- afterlife domination of living agency;
- input-race resolution;
- private path or target leakage;
- infinite return loops.

### 7.13 `recovery`

**Promise**

Offer breathing room, clarity, repair, or regained capability without guaranteeing victory.

**Required**

- authored or fair deterministic trigger;
- automatic versus chosen distinction;
- bounded resource or effect;
- respect for resolved outcomes.

**Forbidden**

- hidden rubber-banding;
- public exposure of private resources;
- unexplained erasure of meaningful costs.

### 7.14 `reckoning`

**Promise**

Test accumulated preparation, risk, resources, and commitments at a clear high-stakes boundary.

**Required**

- preparation opportunity;
- acting seat or group;
- existing check or resolution authority;
- honest outcome bands;
- clear handoff.

**Forbidden**

- post-resolution dice changes;
- unannounced modifiers;
- host-decided results.

### 7.15 `finale`

**Promise**

Resolve the Tale's terminal dramatic question through explicit authority and mixed-outcome support.

**Required**

- terminal criteria;
- rules and social authority;
- compatible individual and faction results;
- public/private separation;
- idempotence.

**Forbidden**

- forced binary winner where mixed outcomes exist;
- presentation-owned terminal state;
- hidden unresolved objectives.

### 7.16 `epilogue`

**Promise**

Reflect accepted outcomes without mutating them.

**Required**

- resolved authoritative records;
- controlled reveal;
- public, seat-private, and faction-private separation;
- rematch or return choice;
- replaceable presentation.

**Forbidden**

- objective re-scoring;
- unauthorized secret reveal;
- raw diagnostics in player-facing text.

### 7.17 `hold`

**Promise**

Leave gameplay unchanged because silence, cooldown, fairness, spacing, or pacing makes intervention inappropriate.

**Required**

- internal reason;
- no core RNG consumption;
- safe silence or ambient presentation;
- next legal window preserved.

**Forbidden**

- treatment as an error;
- random fallback invention;
- unannounced resource use.

---

## 8. Consequence families

Consequences classify the result channel and do not replace existing payload types.

| Consequence family | Owning authority | Examples |
|---|---|---|
| `information_public` | owning source plus public projection | clue or faction reveal |
| `information_private` | `RoleSession` or prompt authority | private objective or target |
| `board_change` | `BoardState` | space, connector, hazard, blocker, feature |
| `rules_state` | `RulesSession` | flag, result, counter, history |
| `resource_change` | `RulesSession` | item, hope, resolve, scarcity |
| `card_change` | `RulesSession` | draw, grant, play, discard, exhaust, retain |
| `prompt_result` | `RulesSession` or reviewed prompt authority | single-seat choice, ready, pass |
| `vote_result` | `RulesSession` | plurality and stable tie result |
| `check_result` | `RulesSession` | critical, success, partial, failure |
| `director_intervention` | Director proposal plus downstream authority | pressure, relief, hint, event, board, ambient, hold |
| `social_transition` | `RoleSession` | reveal, transform, defeat, afterlife, replacement, cure, escape |
| `social_action` | `RoleSession` plus downstream authority | omen, warning, testimony, spread, misdirect |
| `lifecycle_change` | coordinator and owning authorities | briefing, active Tale, terminal, ending |
| `outcome_resolution` | `RoleSession` plus `RulesSession.complete` | mixed outcomes |
| `presentation_only` | replaceable presentation | narration, stinger, light, rationale |
| `intentional_no_op` | owning evaluator | hold, pass, no legal safe consequence |

### 8.1 Ownership rule

A beat may list allowed consequence families.

The payload still validates against the authority's bounded vocabulary.

Generic code must not switch on a literal Tale, stage, event, candidate, role, transition, or action ID.

### 8.2 Multi-consequence beats

A beat may contain several proposals when they form one atomic authored transaction.

The transaction declares:

- proposal order;
- preflight behavior;
- rollback boundary;
- public result;
- private results;
- whether partial acceptance is forbidden.

The existing stage checkpoint remains the current Lantern House rollback boundary.

---

## 9. Future beat-definition shape

A future generic beat definition may contain:

```json
{
  "beat_version": 1,
  "beat_id": "synthetic_threshold_approach",
  "family": "choice",
  "title_key": "synthetic.beat.threshold.title",
  "summary_key": "synthetic.beat.threshold.summary",
  "visibility": "public",
  "agency": {
    "mode": "single_seat_choice",
    "eligible_seats": "authored_scope",
    "allow_pass": false,
    "commit": "explicit_confirm"
  },
  "pressure": {
    "direction": "rising",
    "intensity": 2,
    "recovery_expected_within": 2
  },
  "consequence_refs": [
    "synthetic_open_threshold",
    "synthetic_reveal_clue"
  ],
  "handoff": {
    "allowed_next_families": ["discovery", "commitment"],
    "terminal": false
  },
  "privacy": {
    "public_fields": ["title", "summary", "agency"],
    "private_fields": [],
    "diagnostics_only_fields": ["beat_id", "consequence_refs"]
  },
  "presentation": {
    "speaker_key": "scenario_host",
    "tone": "hushed",
    "reduced_motion_safe": true
  }
}
```

This is guidance, not an implemented schema.

### 9.1 Definition identity

If implemented, every definition requires:

- stable lowercase snake_case ID;
- positive version;
- canonical family;
- explicit source ownership;
- explicit visibility;
- explicit agency;
- explicit consequence references;
- explicit handoff;
- governed localization references.

### 9.2 Runtime instance identity

A resolved instance requires stable identity derived from authoritative semantic state, for example:

```text
<tale_id>:<session_epoch>:<stage_id>:<beat_id>:<occurrence_index>
```

The exact format may differ but must:

- avoid wall-clock values;
- avoid device IDs;
- avoid Companion arrival order;
- survive presentation rebuild;
- distinguish legal repeats;
- suppress duplicates;
- survive snapshot restore;
- support rollback.

### 9.3 Runtime status

A future beat instance may track:

- definition identity;
- stage and operation reference;
- occurrence index;
- unopened, presented, collecting, committed, resolved, rejected, rolled-back, or skipped status;
- eligible seats;
- submitted and pass status;
- accepted consequences;
- downstream revisions;
- public result key;
- authorized private result keys;
- next handoff;
- no-op or rejection reason.

Focus, animation, scroll, glyphs, and audio position remain presentation-only.

---

## 10. Agency vocabulary

| Agency mode | Meaning | Commit rule |
|---|---|---|
| `none` | no player input | authority or authored boundary |
| `acknowledge` | read and continue | explicit confirm |
| `explore` | world interaction opens or discovers | accepted interaction |
| `single_seat_choice` | one stable seat selects | seat-owned confirm |
| `simultaneous_choice` | several seats select independently | collect then resolve |
| `public_vote` | public options aggregate | authored vote rule |
| `card_response` | eligible card may be played | accepted card transaction |
| `inventory_response` | item or resource may be committed | accepted spend/use |
| `check_preparation` | modifiers precede a check | explicit ready or commit |
| `social_action` | role or faction action | `RoleSession` acceptance |
| `afterlife_action` | afterlife seat acts, prepares, passes, or returns | afterlife-window resolution |
| `pass_only` | declining is the decision | explicit pass |
| `protected_choice` | destructive action | hold plus protected confirmation |

### 10.1 Honest labels

Player-facing text must not use:

- choose when only acknowledge is legal;
- vote when one seat owns the decision;
- sacrifice when no cost commits;
- save when success remains uncertain;
- reveal when the fact is still private.

### 10.2 No wall-clock coercion

Core decisions do not auto-select because a player took too long.

Deterministic steps may inform Help or Director telemetry but do not impersonate a real-time timeout without separate review.

---

## 11. Consequence attributes

Every future consequence record should make these attributes explicit.

### 11.1 Visibility

- public;
- controlled-reveal private;
- seat-private;
- faction-private;
- diagnostics-only.

### 11.2 Scope

- Tale-wide;
- board-wide;
- region;
- space;
- connector;
- group;
- faction;
- stable seat;
- card or item instance;
- objective;
- presentation-only.

### 11.3 Persistence

- momentary;
- until beat completion;
- until stage completion;
- until round or phase boundary;
- until explicitly cleared;
- session-persistent;
- terminal record only.

### 11.4 Reversibility

- reversible before commit;
- reversible by authored counter-action;
- reversible by authored reversal;
- irreversible for the session;
- terminal.

### 11.5 Recoverability

- no recovery needed;
- immediate legal recovery;
- recovery expected within N semantic windows;
- recovery conditional on player action;
- intentionally unrecoverable but non-terminal;
- terminal.

### 11.6 Pressure polarity

- relief;
- neutral;
- pressure;
- mixed;
- informational.

### 11.7 Intensity

Recommended metadata scale:

- 0: no pressure change;
- 1: light texture or clue;
- 2: meaningful complication;
- 3: severe pressure or sacrifice;
- 4: reckoning, finale, or major reversal.

Intensity guides pacing validation and does not directly alter rules.

### 11.8 Terminality

- non-terminal;
- terminal candidate requiring authority validation;
- accepted terminal;
- epilogue-only.

---

## 12. Beat grammar

A complete interactive beat generally follows:

1. **Open**
   - semantic window becomes available;
   - duplicate identity is checked.

2. **Present**
   - public or private projection explains context and agency;
   - animation alone changes no authority.

3. **Collect**
   - eligible stable-seat intents are accepted;
   - focus movement remains non-authoritative.

4. **Validate**
   - authority validates choice, target, resources, lifecycle, revision, and privacy.

5. **Commit**
   - owning authority changes state atomically;
   - revision or history evidence is recorded.

6. **Explain**
   - public and private consequence projections are generated independently.

7. **Reflect**
   - optional acknowledgement, rationale, or silence.

8. **Handoff**
   - next legal family or lifecycle boundary opens.

### 12.1 Non-interactive beat

For orientation, discovery, escalation, or hold without choice:

1. open window;
2. validate eligibility;
3. apply or deliberately omit consequence;
4. present privacy-safe result;
5. record handoff.

### 12.2 Failed transaction

When a consequence fails:

- do not claim success;
- do not advance the family;
- roll back the enclosing transaction where required;
- retain seat ownership;
- consume no unrelated RNG;
- present sanitized recovery;
- keep diagnostic cause separate.

---

## 13. Sequencing and pacing

### 13.1 Repetition guidance

Recommended future defaults:

- no more than two consecutive escalation or complication beats without choice, recovery, reckoning, or hold;
- no back-to-back major reversals without a comprehension and action window;
- no repeated sacrifice request to the same seat in one bounded window;
- no afterlife action while the seat is resolving a private path choice;
- no epilogue before terminal authority accepts the result.

These are design defaults, not current runtime rules.

### 13.2 Example arc

```text
orientation
→ invitation
→ discovery
→ choice
→ commitment
→ escalation
→ recovery or complication
→ reckoning
→ defeat, transformation, or reversal where authored
→ afterlife or finale
→ epilogue
```

This is not a mandatory formula.

### 13.3 Reversal budget

A future Tale profile may declare:

- maximum major reversals per act;
- minimum distance between reversals;
- whether social, board, objective, and lifecycle reversals may stack;
- required comprehension window;
- recovery restrictions;
- finale reserve.

The Director cannot invent a reversal outside authored candidates and windows.

### 13.4 Sacrifice clarity

Before commit, the authorized seat or group sees:

- what is lost;
- whether the loss is public;
- whether success is guaranteed, tested, or only enabled;
- whether another seat is affected;
- whether cancel is available;
- what persists.

### 13.5 Recovery obligation

After severe pressure, defeat, or major reversal, the Tale or Director profile should identify a legal recovery opportunity or intentionally terminal path.

Recovery may be:

- resource relief;
- clue;
- safer route;
- reduced targeting;
- afterlife action;
- replacement offer;
- comprehension window;
- hold.

---

## 14. Cross-system mapping

### 14.1 Tale stage

A stage is an orchestration container and may contain several beats.

A stage ID is not automatically a family.

### 14.2 Rules event

An event may provide opening presentation, prompts, checks, effects, and follow-ups.

The event remains rules content.

### 14.3 Prompt and vote

Prompt and vote definitions own response rules.

The beat supplies semantic purpose and context.

### 14.4 Card and inventory

Cards and items remain player capabilities.

Their use may satisfy sacrifice, recovery, commitment, or reckoning.

### 14.5 Living Board

Board changes are consequences.

The beat explains whether the change functions as discovery, complication, escalation, reversal, recovery, or finale.

### 14.6 Director candidate

A candidate may declare compatible beat intents.

The Director:

- evaluates only at legal windows;
- selects authored candidates;
- proposes consequences;
- never writes new story logic;
- may select hold.

### 14.7 Social transition

A transition may realize discovery, reversal, transformation, defeat, afterlife, recovery, or escape.

`RoleSession` remains authority.

### 14.8 Social and afterlife action

Lifecycle, targets, uses, cooldowns, visibility, and proposals remain authoritative in social content.

The beat explains narrative purpose and handoff.

### 14.9 Underteller presentation

The Underteller may:

- introduce a beat;
- state a public consequence;
- frame a controlled reveal;
- provide authored rationale;
- reflect in an epilogue;
- remain silent.

The Underteller may not:

- inspect unfiltered hidden state;
- select a candidate;
- validate a response;
- mutate rules;
- decide a winner;
- change a consequence because of line choice.

### 14.10 Companion

A Companion may display or submit a filtered intent.

It never owns beat state, consequence authority, ordering, RNG, timeout, or result.

---

## 15. Lantern House documentation-only mapping

| Current moment | Proposed family | Existing consequence authority |
|---|---|---|
| public briefing | `orientation` | coordinator public state |
| Threshold Whispers opens | `invitation` | rules event presentation |
| listen or force prompt | `choice` | prompt result |
| hall gate opens | `commitment` result | `BoardState` |
| card drawn | `recovery` opportunity | `RulesSession` |
| clue revealed | `discovery` | `BoardState` feature |
| Council opens | `choice` | public vote |
| route result | `commitment` | vote consequence |
| echo mist added | `escalation` | `BoardState` hazard |
| Steady Flame granted | `recovery` | card grant |
| Steady Flame played | `commitment` or `sacrifice` | card transaction |
| courage check | `reckoning` | `RulesSession` |
| Director evaluates | authored family or `hold` | Director proposal/application |
| living seat defeated | `defeat` | social transition |
| seat becomes Wraith | `transformation` and `afterlife` | `RoleSession` |
| omen placed | `afterlife` | social action plus board change |
| house secured | `finale` consequence | rules effects |
| outcomes resolved | `finale` | social and rules terminal authority |
| The House Remembers | `epilogue` | public and controlled reveal |

This table is descriptive.

It must not be inserted into production JSON without separate schema and identity review.

---

## 16. Privacy contract

### 16.1 Public shared screen

May include:

- friendly title;
- public situation;
- public agency;
- safe seat ownership cues;
- completion progress;
- public consequence;
- public next step;
- generic recovery guidance.

Must exclude:

- raw IDs unless diagnostics;
- hidden roles, factions, or forms;
- private objectives, options, or targets;
- private card or item identities unless already public;
- unrevealed cause;
- return preference;
- secret sacrifice terms;
- package hashes;
- source paths;
- device or network data.

### 16.2 Controlled reveal

A private beat:

- obscures the full television;
- names only the authorized stable seat publicly;
- requires that seat's input;
- reveals the minimum private context;
- returns to a regenerated public view;
- does not preserve private text in public history.

### 16.3 Seat-private Companion

May include:

- the authorized seat's private summary;
- legal options;
- own consequence;
- own objective relation;
- own submitted status;
- own cooldowns and uses.

It may not include another seat's private information.

### 16.4 Faction-private view

Exists only when authored faction communication policy permits it.

A beat cannot create communication permission.

### 16.5 Diagnostics

May include:

- stable IDs;
- family;
- consequence references;
- full validation reason;
- authority revisions;
- RNG counters;
- privacy-canary results;
- projection diffs;
- source locations.

Spoiler diagnostics require explicit opt-in.

### 16.6 Privacy-safe report

May include:

- counts of resolved public families;
- public stage sequence;
- accepted public consequences;
- aggregate pass, retry, and recovery events;
- public ending summary.

It must not expose private content or correlation that reveals assignments.

---

## 17. Determinism and replay

### 17.1 No implicit RNG

Fixed authored family selection consumes no RNG.

Dynamic selection uses only the reviewed authority stream:

- Director uses Director RNG;
- roles use role RNG;
- checks and decks use rules RNG.

Presentation variants consume no gameplay RNG.

### 17.2 Replay contract

The same package identity, content identities, seed, roster, mode, snapshots, semantic windows, and ordered accepted inputs produce the same:

- beat sequence;
- proposals;
- authority results;
- public and private projections;
- outcomes.

### 17.3 Duplicate suppression

Repeated controller events, Companion request IDs, presentation rebuilds, Help, pause, scene re-entry, or restore do not resolve a beat twice.

### 17.4 Rollback

A rolled-back beat:

- restores enclosing authority snapshots;
- restores occurrence and open-window state;
- retains no public success history;
- consumes no additional RNG on replay before the same legal draw point.

### 17.5 Rematch

Same-seed rematch rebuilds clean authorities, resets beat runtime state, and reproduces structure for the same ordered inputs.

---

## 18. Controller-first and no-phone operation

### 18.1 Existing semantic controls

- navigation: D-pad or stick, keyboard fallback;
- confirm/interact: A or Enter/Space according to route;
- back/pass: B or Escape where legal;
- Help: X or H;
- pause: Menu or P;
- protected reset: hold Y or R for 1.5 seconds.

### 18.2 Interactive beat display

Every interactive beat shows:

- who may act;
- expected control;
- pass/back legality;
- public or private status;
- submitted and remaining state where safe;
- appropriate consequence preview.

### 18.3 Multiple seats

Resolution order is authored and deterministic.

It never depends on polling order, frame order, controller hardware, wireless latency, Companion arrival, or color alone.

### 18.4 Help

Help may explain public purpose, controls, waiting state, public consequence class, recovery, and privacy mode.

It may not expose hidden options or causes.

### 18.5 Accessibility

Comprehension uses text, symbol, pattern, shape, seat numeral, focus, contrast, safe margins, reduced-motion alternatives, and no required audio.

Human validation remains required.

---

## 19. Presentation contract

### 19.1 Presentation-only state

May include:

- panel and focus;
- scroll;
- animation;
- subtitle progress;
- portrait;
- stinger;
- ambient cue;
- glyph family;
- reduced-motion rendering.

It never determines consequence.

### 19.2 Underteller line families

A replaceable host adapter may receive only a filtered payload containing public family, public pressure direction, public result category, public target label where allowed, act, presentation profile, and sensory preferences.

It may not receive private state merely to personalize prose.

### 19.3 Presentation profiles

Spooky, Grim, and Gore & Dread may vary wording, imagery, sound, gore detail, and animation intensity.

Gameplay remains equivalent.

### 19.4 Queueing

Presentation may queue or replace lower-priority presentation.

It may not cancel a consequence, reorder authority history, skip private acknowledgement, or auto-advance a choice.

---

## 20. Director integration

### 20.1 Candidate compatibility

A future candidate may declare:

- compatible families;
- forbidden families;
- whether it opens a beat or decorates one;
- pressure polarity;
- severity;
- required recovery distance;
- public rationale key.

### 20.2 Boundaries

The Director evaluates only at approved semantic windows.

It cannot:

- interrupt private choice;
- act during rollback;
- create a duplicate consequence;
- turn hold into hidden pressure;
- classify private state;
- consume rules RNG.

### 20.3 Coherence

Candidate scoring must obey authored constraints such as:

- no major reversal inside another unresolved reversal;
- no repeated escalation beyond caps;
- no clue that reveals private information;
- no board pressure that removes required recovery;
- no recovery that invalidates terminal authority.

---

## 21. Social, transformation, and afterlife

### 21.1 Social reveal

A reveal is usually:

- discovery when it makes identity public;
- reversal when it changes alliances or objectives;
- transformation when form or faction changes.

One transition may serve several purposes but has one primary family for pacing.

### 21.2 Changed and Horror

Transformations preserve stable-seat ownership, close stale views, open new legal verbs, separate public/private consequences, and remain chain-bounded.

### 21.3 Defeat bridge

Defeat records lost capabilities, retained seat, public lifecycle, and continuation policy.

The following afterlife beat records path, actions, pass, preparation, and return offer where authored.

### 21.4 Mixed outcomes

Finale and epilogue support multiple winning factions, individual victory or defeat, escaped, Changed, Restless, partial, and unresolved outcomes.

A public epilogue does not collapse compatible results into one binary winner.

---

## 22. Schema and validation proposal

No schema changes occur in this documentation PR.

A future implementation validates at least:

### 22.1 Beat definitions

- supported schema version;
- stable unique IDs;
- known family;
- known agency;
- known visibility;
- governed localization;
- valid consequence references;
- legal handoffs;
- bounded intensity;
- coherent persistence, recovery, and terminality;
- legal hold route where needed;
- no executable fields, URLs, secrets, absolute paths, or generated references.

### 22.2 Consequences

- known authority;
- bounded payload type;
- valid references;
- valid targets;
- explicit visibility;
- explicit atomicity;
- result projection;
- no direct callbacks.

### 22.3 Graph validation

- reachable entry;
- reachable terminal and epilogue;
- no unbounded cycles;
- no dead-end interactive beat;
- no private beat with zero authorized seats;
- no defeat path that strands a seat when afterlife is required;
- no finale before terminal authority;
- no epilogue mutation.

### 22.4 Privacy validation

- public projections contain no private canaries;
- private references resolve to authorized audiences;
- host lines do not interpolate private fields;
- report fields are allowlisted;
- Director inputs are public or aggregate.

### 22.5 Production identity

If vocabulary fields enter a Tale package, manifest, localization, or referenced content:

- bump applicable schema or content version;
- update source ledgers;
- recalculate hashes;
- update catalog bindings;
- update replay and identity tests;
- document migration.

---

## 23. Testing contract

### 23.1 Unit tests

Cover every family, agency mode, consequence family, visibility, handoff, intensity, persistence, recoverability, terminality, hold, localization reference, and unknown-field rejection.

### 23.2 Authority tests

Prove:

- presentation alone does not mutate;
- proposals use public authority methods;
- rejections are atomic;
- accepted results record revisions;
- epilogue is read-only;
- host adapter is non-authoritative.

### 23.3 Determinism tests

Prove:

- identical inputs reproduce sequence;
- presentation variants do not affect gameplay RNG;
- duplicates resolve once;
- restore reproduces next consequence;
- rollback is stable;
- rematch starts clean.

### 23.4 Privacy-canary tests

Plant private canaries in hidden role, objective, option, target, return preference, card/item, and rationale.

Recursively scan public view, public history, host payloads, Director telemetry, reports, errors, unauthorized seat views, and Companion public view.

### 23.5 Sequence tests

Cover:

1. orientation to invitation to discovery;
2. choice to commitment;
3. escalation to recovery;
4. escalation to sacrifice to reckoning;
5. reversal to transformation;
6. defeat to afterlife;
7. finale to epilogue;
8. hold to next legal window;
9. rejection to rollback to retry;
10. disconnect to reserved seat to reconnect to same private beat.

### 23.6 Stable-seat coverage

Cover one-seat and two-seat cooperative fallback, three-to-eight hidden mode, all numerals, reserved seats, simultaneous responses, multiple afterlife seats, and maximum-seat privacy.

### 23.7 Simulation

A synthetic harness may measure family repetition, pressure streaks, recovery distance, reversal spacing, sacrifice targeting, hold frequency, unresolved windows, rollback stability, and terminal reachability.

Simulation is not evidence of fun or story quality.

---

## 24. Human playtest contract

Human evidence is required for claims about:

- comprehension;
- meaningful choice;
- earned reversals;
- understood sacrifice;
- recovery timing;
- afterlife engagement;
- host usefulness;
- social comfort of public/private transitions;
- television readability;
- controller handoff;
- sensory alternatives;
- repetition and emotional pacing.

### 24.1 Exact-build evidence

Record commit SHA, Godot version, renderer, resolution, viewing distance, controllers, seat count, mode, Tale/package identity, Companion state, presentation profile, accessibility settings, observed sequence, confusion, privacy incidents, boredom, overload, and reactions.

### 24.2 Claim boundaries

Automation may claim determinism, validation, reachability, and leakage resistance.

It may not claim fun, fear, fairness, memorability, accessibility, or good pacing.

---

## 25. Release and migration risks

### 25.1 Vocabulary inflation

Risk: near-synonym families make the system meaningless.

Mitigation: small canonical list, review for additions, flavor through tags and presentation.

### 25.2 Twist inflation

Risk: every moment becomes a reversal.

Mitigation: strict reversal definition, spacing, and reserve.

### 25.3 Authority leakage

Risk: a beat engine mutates gameplay directly.

Mitigation: proposal-only design and nonmutation tests.

### 25.4 Identity drift

Risk: fields silently alter Lantern House identity.

Mitigation: synthetic capability first and separate adoption review.

### 25.5 Privacy leakage

Risk: tags or rationale expose secrets.

Mitigation: audience projections and canary scans.

### 25.6 Snapshot incompatibility

Risk: runtime beat state breaks replay.

Mitigation: explicit versioning and atomic rejection.

### 25.7 Presentation coupling

Risk: animation timing controls consequence.

Mitigation: authority result and presentation state remain separate.

### 25.8 Authoring duplication

Risk: metadata is repeated across stages, events, Director, and social content.

Mitigation: one semantic source, derived projections, reference validation, and tooling before production adoption.

---

## 26. Recommended implementation sequence

### Slice A — Synthetic vocabulary validator

- generic definitions;
- synthetic export-excluded content;
- family, agency, consequence, privacy, graph, and terminal validation;
- no Lantern House changes.

### Slice B — Runtime beat-instance gate

- semantic window identity;
- duplicate suppression;
- open, present, collect, validate, commit, explain, handoff;
- snapshots and rollback;
- synthetic fixtures only.

### Slice C — Authority adapters

- rules;
- board;
- Director;
- social;
- outcomes;
- presentation;
- no-op.

No adapter bypasses public validation.

### Slice D — Projections and controller surfaces

- television;
- controlled reveal;
- seat and faction views;
- Help;
- optional Companion;
- diagnostics;
- privacy-safe report.

### Slice E — Authoring diagnostics

- graph inspection;
- repetition and recovery analysis;
- reversal spacing;
- source diagnostics;
- synthetic simulation.

### Slice F — Lantern House mapping review

- decide whether existing stages and content receive metadata;
- analyze package, manifest, localization, and identity impact;
- preserve accepted stable IDs and behavior;
- recalculate identity only in a separately approved release.

### Slice G — Exact-build narrative pilot

- controller-first household sessions;
- several seat counts;
- no-phone and optional Companion routes;
- public/private comprehension;
- reversal, sacrifice, recovery, afterlife, and epilogue feedback.

---

## 27. Acceptance criteria

- [ ] Beats are semantic and non-authoritative.
- [ ] Consequences remain authority-owned.
- [ ] Canonical families are bounded and distinct.
- [ ] Reversal differs from escalation.
- [ ] Sacrifice requires clear cost and authorization.
- [ ] Defeat preserves continuation where allowed.
- [ ] Hold is legal and authored.
- [ ] Agency is explicit and honest.
- [ ] Public and private projections are distinct.
- [ ] Director and Underteller boundaries remain intact.
- [ ] Controller-first no-phone operation is complete.
- [ ] Determinism, duplicate suppression, replay, rollback, rematch, and reset are specified.
- [ ] Schema and identity changes are deferred.
- [ ] Tests cover privacy, sequences, authority, and 1–8 seats.
- [ ] Human evidence requirements are explicit.
- [ ] The documentation PR changes no runtime or production Tale content.

---

## 28. Authoring checklist

Before approving a future beat, answer:

1. What is the primary family?
2. What question does the moment ask?
3. Which seats may act?
4. Is agency real, acknowledgement-only, or absent?
5. Which authority owns each consequence?
6. What commits it?
7. What can be canceled?
8. What is public?
9. What is private?
10. What may the Underteller receive?
11. What may the Director receive?
12. What persists?
13. What is reversible?
14. What recovery exists?
15. Is this actually a reversal?
16. Does it repeat a recent family?
17. What happens on disconnect?
18. What happens on pass?
19. What happens on rejection?
20. What snapshot reproduces the next step?
21. Does adoption change identity?
22. Which tests prove the contract?
23. Which claims still require humans?

---

## 29. Glossary

**Authority**  
The component permitted to validate and commit a category of state.

**Beat**  
A semantic description of a bounded dramatic moment.

**Consequence**  
A validated authority-owned result.

**Commitment**  
The accepted point after which a choice, cost, or route affects state.

**Complication**  
An obstacle that changes the immediate plan without redefining the whole situation.

**Controlled reveal**  
A fully obscured shared-screen flow authorized to one stable seat.

**Defeat**  
An authored loss of current capability or objective state, distinct from disconnect.

**Epilogue**  
Read-only reflection over accepted terminal outcomes.

**Finale**  
The terminal dramatic resolution, not merely the last panel.

**Hold**  
An intentional and explainable no-op or silent pacing beat.

**Reckoning**  
A high-stakes test of preparation and commitments.

**Recovery**  
A bounded opportunity for relief, clarity, repair, or regained capability.

**Reversal**  
An authored change to objective, route, allegiance, lifecycle, relationship, or verb set.

**Sacrifice**  
An explicit cost committed for an attempted benefit or protection.

**Semantic window**  
An authoritative event boundary at which a beat may open or an adaptive system may evaluate.

**Stable seat**  
The local privacy and input principal that survives reconnect.

**Transformation**  
An authority-owned change of category.

**Underteller**  
The provisional replaceable host and presentation layer, not an authority.

---

## 30. Candidate future implementation issue

**Title:** Implement generic Story Beat and Consequence Vocabulary with synthetic fixtures

**Goal**

Add a scene-independent, deterministic, non-authoritative semantic beat layer above existing authorities using synthetic export-excluded content only.

**Required work**

- canonical families;
- consequence families;
- validation;
- semantic-window identity;
- duplicate suppression;
- runtime snapshots;
- authority adapters;
- public/private/diagnostics projections;
- controller-first no-phone surfaces;
- privacy canaries;
- graph and pacing diagnostics;
- synthetic simulation.

**Exclusions**

- no Lantern House production changes;
- no package, catalog, or localization identity change;
- no second production Tale;
- no Companion deployment change;
- no cloud AI;
- no host authority;
- no merge or release claim from the Design & Development Lab.

---

## 31. Review decision requested

Reviewers should determine whether this is a sufficiently small and useful cross-system vocabulary for future Tales without creating a second gameplay authority.

Approval means only that the vocabulary is suitable for later bounded implementation planning.

It does not approve runtime implementation, production adoption, schema migration, localization changes, release, final narrative quality, or final branding.
