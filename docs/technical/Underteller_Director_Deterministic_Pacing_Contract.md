# Underteller / Director Deterministic Pacing Contract

**Status:** Design contract for review  
**Version:** 1.0  
**Repository:** `SteadyEddieSC/Tales-of-Terror`  
**Working title:** Terror Turn — provisional under issue #7  
**Fictional host name:** The Underteller — provisional under issue #7  
**Production Tale:** `lantern_house_vertical_slice` / Lantern House  
**Scope:** Documentation and implementation planning only

---

## 1. Purpose

This contract defines the production-facing relationship between:

- the **Dread Director**, a local deterministic authored pacing authority;
- the **Underteller**, a replaceable fictional host and presentation layer;
- the existing `RulesSession`, `BoardState`, `RoleSession`, stable-seat, replay, and view boundaries;
- authored Tale packages, Director profiles, intervention candidates, and presentation variants.

The contract does not replace the accepted v0.0.7 Director implementation. It preserves the existing deterministic scoring, dedicated RNG, fairness, recovery, snapshot, proposal, and authority boundaries while specifying the next layer required for a complete playable Tale:

1. when Director evaluation may occur;
2. how isolated decisions become a coherent dramatic rhythm;
3. how player-facing explanations differ from diagnostics;
4. how Underteller presentation remains replaceable and non-authoritative;
5. how privacy, no-phone play, accessibility, replay, and migration remain safe.

This document does not authorize runtime changes, Tale identity changes, a second production Tale, Companion changes, or merge/release action.

---

## 2. Existing accepted foundation

The current Director foundation already establishes:

- local authored logic rather than cloud AI or an LLM;
- a dedicated deterministic RNG stream derived from the session seed, a stable salt, and the profile ID;
- read-only JSON-compatible telemetry;
- separate `DirectorContent`, `DirectorTelemetry`, `DirectorRuntime`, and `DirectorProposalApplier` responsibilities;
- authored profiles: Off/Authored Only, Story/Gentle, Standard, Relentless/Dread, and Fixed Test;
- authored Lantern House pressure, relief, hint, board, event, ambient, and no-op candidates;
- explainable integer score components for every eligible candidate;
- explicit ineligibility reasons;
- deterministic highest-score selection with Director-RNG tie resolution;
- mercy pressure suppression;
- recovery windows;
- candidate and tag cooldowns;
- rolling pressure caps;
- per-seat negative-target caps;
- disconnected-seat exclusion;
- budget enforcement;
- intentional no-op behavior;
- proposal-only evaluation;
- downstream application through `RulesSession`, `BoardState`, or replaceable presentation;
- versioned Director snapshots and audit history;
- 90 deterministic simulation sequences across struggling, cruising, and stalled trajectories.

The accepted implementation is therefore the baseline, not a prototype to discard.

---

## 3. Non-goals

This contract does not introduce:

- cloud inference;
- generated narration;
- arbitrary scripts, callbacks, reflection targets, or executable provider declarations;
- emotion recognition;
- voice analysis;
- camera analysis;
- biometric input;
- individual psychological profiling;
- cross-session player tracking;
- telemetry upload;
- accounts;
- matchmaking;
- authoritative Companion logic;
- hidden network requirements;
- procedural Tale authorship;
- guaranteed victory;
- final balance certification;
- final Underteller branding, voice, portrait, or legal clearance;
- a second production Tale;
- direct changes to PR #46;
- Companion dependency, source, protocol, service, configuration, or deployment changes while issue #44 remains open.

---

# Part I — Experience contract

## 4. Player experience

Players should experience the Director as the Tale’s dramatic rhythm, not as a visible difficulty calculator.

A successful session should feel as though the house:

- notices when the group is moving confidently;
- allows a breath after severe pressure;
- offers a clue when progress has genuinely stalled;
- varies the form of tension rather than repeating the same punishment;
- responds to public consequences without knowing secret plans;
- remembers recent beats within the current session;
- permits authored silence when intervention would be unfair or theatrically weaker.

Players should not feel that:

- successful rolls are secretly invalidated;
- good play is automatically punished;
- one seat is repeatedly singled out;
- the game reads hidden roles or private objectives;
- the host knows private information that has not been publicly revealed;
- every action causes an interruption;
- difficulty is changing continuously or opaquely;
- the Director guarantees rescue or victory;
- a phone is necessary to understand or answer a Director beat.

### 4.1 Public readability

When the Director produces a visible consequence, the shared display should communicate:

1. **what happened**;
2. **whether it is pressure, relief, a clue, an event, or only an omen**;
3. **whether a specific public seat is affected**;
4. **what players may do next**;
5. **whether the beat changed gameplay or presentation only**.

The ordinary player view must not show:

- raw metric values;
- score formulas;
- RNG counters;
- internal candidate IDs;
- rejected candidate lists;
- source paths;
- provider identifiers;
- package hashes;
- hidden social state;
- diagnostics-only audit records.

### 4.2 Dramatic promise

The Director should create alternating dramatic functions rather than a monotonic difficulty ramp:

- **orientation** — establish place, objective, and tone;
- **pressure** — increase urgency within authored limits;
- **revelation** — expose a clue, consequence, or changed situation;
- **decision space** — leave players room to discuss and act;
- **recovery** — prevent pressure from becoming noise or hopelessness;
- **pivot** — support a Tale-authored reversal;
- **reckoning** — concentrate tension near the finale;
- **aftermath** — stop adaptive pressure and let outcomes speak.

The Tale remains the author of what can happen. The Director only chooses among legal authored options at legal authored times.

---

## 5. Underteller experience

The Underteller is fiction and interface.

The Underteller may:

- introduce a Tale;
- present public objectives;
- announce an authored Director consequence;
- provide a friendly rationale;
- call attention to a clue or change;
- bridge transitions;
- recap publicly known events;
- present deterministic epilogues;
- remain silent when silence is the selected beat.

The Underteller must not:

- own gameplay state;
- select candidates;
- calculate scores;
- inspect telemetry directly;
- reveal private roles or objectives;
- resolve prompts, checks, votes, cards, or board mutations;
- decide whether a proposal is accepted;
- branch generic gameplay on the literal name `The Underteller`;
- require voice playback;
- require a portrait or animation;
- require network access;
- produce freeform generated text.

A future host replacement must be possible without changing gameplay authority, snapshots, outcomes, or candidate selection.

---

# Part II — Gameplay rules

## 6. Director evaluation windows

Director evaluation must occur only at explicit deterministic windows.

It must never run:

- every frame;
- from wall-clock timers;
- from animation completion;
- from audio completion;
- because a UI panel opened or closed;
- while an authoritative transaction is partially applied;
- while a private reveal shield is active;
- while Help owns input;
- while the session is paused;
- while an unresolved prompt or vote lacks required responses;
- while the game is waiting for a reserved seat when the authored policy requires that seat;
- after terminal outcome commitment;
- during aftermath presentation unless a Tale explicitly defines a presentation-only epilogue cue.

### 6.1 Standard evaluation window types

The reusable vocabulary should include:

| Window | Meaning | Typical allowed categories |
| --- | --- | --- |
| `tale_started` | Public briefing accepted and initial snapshot committed | ambient, no-op |
| `round_started` | New deterministic rules round begins | ambient, hint, pressure, no-op |
| `objective_progressed` | Accepted progress mutation occurred | pressure, board, ambient, no-op |
| `objective_stalled` | Authored deterministic stall threshold reached | hint, event, ambient, relief, no-op |
| `check_resolved` | Check outcome is final and recorded | pressure, relief, ambient, no-op |
| `event_resolved` | Authored event transaction completed | ambient, pressure, relief, no-op |
| `public_reveal_resolved` | Social reveal is already public and committed | event, pressure, relief, ambient, no-op |
| `seat_defeated` | Defeat and lifecycle transition committed | relief, hint, ambient, no-op |
| `afterlife_activated` | Meaningful afterlife path committed | ambient, hint, no-op |
| `pivot_entered` | Tale-authored pivot boundary reached | event, pressure, ambient, no-op |
| `finale_entered` | Finale authority state committed | pressure, hint, ambient, no-op |
| `recovery_completed` | Authored recovery opportunity resolved | ambient, no-op |

A Tale may use only a validated subset.

### 6.2 Window identity

Every evaluation request should have a stable identity:

```text
evaluation_window_id =
  session_revision
  + semantic_window_type
  + authoritative_source_revision
  + authored_sequence
```

The exact serialization may differ, but the identity must guarantee:

- the same accepted window is evaluated at most once;
- duplicate input or repeated presentation cannot create another decision;
- rollback restores whether the window was evaluated;
- replay can prove which authoritative event opened the window;
- rejected or malformed windows consume no Director RNG.

### 6.3 Window gating result

The runtime should record one of:

- `evaluated`;
- `held_by_spacing`;
- `held_by_recovery`;
- `held_by_transaction`;
- `held_by_pending_input`;
- `held_by_pause`;
- `held_by_private_reveal`;
- `held_by_profile`;
- `held_by_tale_policy`;
- `duplicate_window`;
- `invalid_window`.

A held window is not automatically retried unless the Tale policy explicitly declares a later retry window.

---

## 7. Dramatic beat state

The current pacing act and target tension remain authoritative Director state.

A future additive beat contract may track:

- current dramatic function;
- prior dramatic function;
- consecutive pressure count;
- consecutive relief count;
- consecutive presentation-only count;
- last meaningful gameplay intervention step;
- last clue step;
- last public host line family;
- silence/no-op streak;
- current recovery obligation;
- current escalation allowance;
- act-local category budgets;
- finale reserve;
- evaluation-window history.

### 7.1 Beat sequence rules

Default production rules:

1. No more than the profile’s authored maximum consecutive pressure beats.
2. Severe pressure creates a recovery obligation, not merely a score penalty.
3. Recovery obligation may be satisfied by:
   - accepted relief;
   - accepted hint;
   - authored safe opportunity;
   - a sufficient number of intentional no-op/breath windows.
4. Repeated ambient cues cannot indefinitely substitute for required gameplay recovery.
5. Clues should not repeat while the prior clue remains unresolved unless the Tale explicitly declares escalation.
6. Finale pressure may spend only the reserved finale allowance.
7. The Director cannot spend future-act budget early unless the profile explicitly permits borrowing.
8. Silence is valid and should be preferred over a weak, repetitive, or unfair intervention.

### 7.2 Pressure is not difficulty

Pressure metadata represents dramatic load, not a hidden difficulty level.

Pressure may include:

- public dread;
- scarcity;
- a legal hazard;
- a pacing event;
- urgency;
- an environmental warning;
- limited route friction.

Pressure must not mean:

- changing a resolved result;
- secretly improving enemy odds;
- drawing a known future bad card;
- bypassing a recovery route;
- invalidating a player’s accepted plan;
- adding arbitrary damage;
- targeting a disconnected seat;
- punishing a seat for needing more reading time;
- escalating because a player used accessibility settings.

---

## 8. Profiles

Profiles are authored gameplay configuration.

Required profile semantics remain:

- **Off / Authored Only** — no adaptive selection; Tale-authored fixed beats may still occur outside the adaptive Director.
- **Story / Gentle** — lower volatility, stronger recovery, more breathing room.
- **Standard** — intended default authored pacing.
- **Relentless / Dread** — more pressure opportunities inside identical fairness and recoverability guarantees.
- **Fixed Test** — deterministic comparison baseline.

### 8.1 Profile invariants

All profiles must preserve:

- legal completion paths;
- Director RNG isolation;
- stable-seat fairness;
- privacy boundaries;
- no-phone completeness;
- downstream authority validation;
- snapshot/replay behavior;
- deterministic no-op;
- the same resolved check and deck outcomes for equivalent player inputs;
- presentation-profile independence.

A stronger profile may:

- use higher pressure budgets;
- use shorter legal spacing;
- assign stronger pressure affinities;
- reserve more finale pressure;
- reduce non-required breath frequency.

It may not:

- remove mercy entirely;
- remove recovery after severe pressure;
- exceed per-seat targeting caps;
- target disconnected seats;
- read private state;
- change rules RNG;
- turn invalid proposals into accepted work.

### 8.2 Accessibility relationship

Director intensity and presentation profile are independent.

Examples:

- Spooky + Standard;
- Grim + Gentle;
- Gore & Dread + Off;
- Spooky + Relentless/Dread.

Reduced motion, flashing limits, subtitle preferences, text speed, and audio settings must not alter candidate eligibility or gameplay results.

A future reduced-cognitive-load option may reduce host interruptions or consolidate public explanations, but must not silently alter gameplay unless it is explicitly a Director profile.

---

# Part III — Authoritative state

## 9. Authority ownership

| Concern | Owner |
| --- | --- |
| Authored Director profiles and candidates | `DirectorContent` / reviewed Tale content |
| Read-only pacing inputs | `DirectorTelemetry` projection |
| Pacing state, budgets, cooldowns, RNG, audit | `DirectorRuntime` |
| Rules events/effects | `RulesSession` |
| Board mutations | `BoardState` |
| Social roles and public signal derivation | `RoleSession` |
| Stable-seat ownership | `SeatManager` |
| Evaluation-window orchestration | Session coordinator / future dedicated gate |
| Host text, portrait, animation, sound | Presentation |
| Optional Companion rendering | Filtered non-authoritative view |
| Reports | Local privacy-safe reporting layer |

The Director never owns rules, board, roles, seats, or outcomes.

### 9.1 Candidate lifecycle

A candidate moves through:

```text
AUTHORED
→ VALIDATED
→ CONSIDERED
→ ELIGIBLE or REJECTED
→ SCORED
→ SELECTED or NOT_SELECTED
→ PROPOSED
→ ACCEPTED or REJECTED
→ RECORDED
→ PRESENTED
```

Only `ACCEPTED` downstream work may update Director budget, cooldown, targeting, momentum, and revision state.

Presentation failure must not retroactively reject an accepted gameplay consequence.

### 9.2 Atomicity

An evaluation must leave all non-Director authorities unchanged.

A rejected application must leave:

- `RulesSession`;
- `BoardState`;
- `RoleSession`;
- `SeatManager`;
- gameplay RNG streams;
- active prompt/vote ownership;
- stable-seat state

unchanged.

If a downstream authority reports rejection after partial mutation, the integration gate must fail closed and surface an internal atomicity defect rather than recording success.

---

## 10. Proposed additive runtime state

A future runtime snapshot version may add:

```text
evaluation_windows
last_evaluated_window_id
dramatic_function
prior_dramatic_function
consecutive_pressure
consecutive_relief
consecutive_ambient
recovery_obligation
recovery_satisfied_step
act_budgets
finale_reserve
last_clue_step
last_public_line_family
silence_streak
```

These additions require:

- a new snapshot version;
- exact-key validation;
- atomic restore;
- replay-equivalence tests;
- migration policy;
- no mutation of existing production snapshots in place.

The current v1 snapshot remains valid only under its existing contract.

---

# Part IV — Presentation-only state

## 11. Underteller presentation contract

The selected Director decision may produce a presentation request containing only authored, bounded fields such as:

```text
presentation_key
line_family
speaker_key
tone
symbol
pattern
portrait_cue
audio_cue
music_cue
lighting_cue
camera_emphasis
subtitle_key
priority
interruption_policy
reduced_motion_safe
public_target_label
```

No field may name:

- a script;
- a method;
- a class;
- an executable;
- a URL;
- a network endpoint;
- an arbitrary expression;
- an unreviewed file outside allowlisted resources.

### 11.1 Presentation derivation

A presentation variant should be derived deterministically from:

- selected candidate stable ID;
- decision key;
- current public act;
- governed locale;
- stable authored variant set.

Variant selection should not consume:

- rules RNG;
- deck RNG;
- check RNG;
- role RNG;
- Director gameplay-selection RNG after the decision is fixed.

A stable hash or a separately salted presentation-only deterministic stream is preferred.

Presentation variants are not gameplay authority. They may be excluded from authority digests while still being reproducible in replay presentation.

### 11.2 Interruption policy

Allowed authored policies should remain bounded:

- `queue`;
- `replace_lower_priority`;
- `coalesce_same_family`;
- `defer_until_public_idle`;
- `subtitle_only`;
- `silent`.

The Underteller must not interrupt:

- private reveal;
- required reading of a new private objective;
- an unresolved seat-private choice;
- accessibility Help;
- protected-reset confirmation/progress;
- terminal outcome commitment.

### 11.3 Failure behavior

If portrait, voice, animation, or audio assets are missing:

- gameplay continues;
- public text and symbol fallback remain available;
- no candidate is reselected;
- no RNG is consumed;
- no authority is rolled back;
- diagnostics record a presentation fallback code;
- raw paths are not shown to players.

---

## 12. Player explanation tiers

### Tier 1 — Ordinary shared display

May show:

- friendly event name;
- short public consequence;
- symbol and pattern;
- public target seat when relevant;
- one-sentence friendly rationale;
- next expected action.

### Tier 2 — Help/facilitator explanation

May show:

- selected Director profile;
- general category;
- plain-language statement such as:
  - “The group had room for more pressure.”
  - “The group needed recovery space.”
  - “Progress had stalled, so the Tale offered a clue.”
  - “The Director held the beat.”

It must not show private state or raw candidate scoring.

### Tier 3 — Developer diagnostics

May show:

- telemetry values;
- content/profile versions;
- pacing act;
- target-tension band;
- estimated tension;
- all candidate evaluations;
- rejection reasons;
- score components;
- tie-break data;
- RNG counters;
- budgets;
- cooldowns;
- target ledger;
- evaluation-window identity;
- application result;
- downstream revision;
- audit history.

### Tier 4 — Privacy-safe report

May record only bounded aggregate information, such as:

- profile label;
- count of Director evaluations;
- count by public category;
- accepted/rejected/no-op counts;
- recovery-trigger count;
- public pacing act transitions;
- reset/disconnect recovery events already allowed by the report schema.

It must not include:

- raw telemetry;
- private role/objective information;
- seat-target history unless de-identified and explicitly reviewed;
- RNG state;
- source paths;
- package/provider provenance;
- Companion room secrets;
- device identities.

Any report schema change requires its own reviewed version.

---

# Part V — Deterministic behavior

## 13. Deterministic input tuple

A Director decision is a pure function of:

```text
validated Director content identity
+ selected profile identity
+ Director runtime snapshot
+ validated telemetry snapshot
+ evaluation-window identity
+ legal candidate set
```

The result includes:

- selected candidate;
- selected target;
- score components;
- ineligibility reasons;
- tie-break record;
- proposal;
- public explanation metadata;
- no-op reason.

### 13.1 RNG rules

1. Invalid telemetry consumes no Director RNG.
2. Duplicate evaluation windows consume no Director RNG.
3. Held windows consume no Director RNG.
4. A unique highest-score candidate consumes no Director RNG.
5. An exact tie consumes the minimum deterministic draw required.
6. Target selection should remain deterministic without RNG unless the profile explicitly declares a reviewed target-randomization policy.
7. Presentation variant selection uses no gameplay RNG.
8. Rejected downstream applications do not rewind or repeat selection unless the contract defines a bounded deterministic retry.
9. Any retry must use a stable retry index and exclude the rejected proposal deterministically.
10. Exceeding retry limits produces an intentional no-op/application-failed record.

### 13.2 Replay records

A replay-capable event record should be able to prove:

- which authoritative change opened the evaluation window;
- whether the window was evaluated or held;
- telemetry digest;
- Director snapshot revision;
- selected candidate and target;
- Director RNG before/after;
- downstream result;
- resulting Director revision;
- public presentation key.

Raw telemetry may remain in debug snapshots rather than public replay exports, but equivalence tests must verify the digest.

---

## 14. Rollback

Rollback to a snapshot before an evaluation window must restore:

- whether the window has been evaluated;
- Director RNG;
- budgets;
- cooldowns;
- targeting history;
- recovery obligations;
- act budgets;
- audit history;
- downstream rules/board/role state through their own snapshots.

After rollback, replaying identical accepted inputs must reproduce the same decision and application result.

Rollback must not preserve presentation animation progress. Presentation rehydrates from the restored public decision record.

---

## 15. Rematch and reset

### 15.1 Same-seed rematch

The current rematch contract may rebuild all session authorities with the same session seed and selected Director profile.

If all player inputs are repeated, Director decisions should repeat.

### 15.2 New-seed rematch

A future explicit new-seed rematch must:

- display that a new variation is being started;
- rebuild every RNG stream from the new seed;
- preserve stable seats only where the rematch contract allows;
- create a fresh Director audit history;
- not reuse prior targeting or recovery state.

### 15.3 Protected reset

Protected reset must erase:

- Director runtime;
- evaluation windows;
- audit records;
- budgets;
- cooldowns;
- targeting history;
- recovery state;
- presentation queue;
- session-scoped Companion projections.

It returns to the production default setup without leaking prior decisions.

---

# Part VI — Privacy

## 16. Allowed Director inputs

The Director may receive:

- public rules phase and progress;
- bounded recent public check-result categories;
- approved aggregate resource pressure;
- approved aggregate hazard pressure;
- public board reveal/occupancy spread;
- deterministic objective-stall steps;
- deterministic prompt-latency steps;
- public pass/readiness frequency;
- bounded participation imbalance;
- bounded rejected-action count;
- connected/reserved seat status;
- allowlisted public or aggregate social signals;
- recent public intervention tags;
- public Tale flags explicitly declared Director-safe.

### 16.1 Aggregate resource rule

Raw card IDs, item IDs, private hand contents, private objective IDs, and seat-private resource identities are prohibited.

A Tale may expose only an approved aggregate such as:

- total resource units;
- percentage of seats with at least one public recovery option;
- public scarcity counter.

The aggregate must be tested for hidden-state equivalence where appropriate.

### 16.2 Prohibited inputs

The Director must never receive:

- hidden role IDs;
- hidden faction IDs;
- private objective text;
- secret target choices;
- unrevealed transition plans;
- private messages;
- Companion capability tokens;
- join/resume secrets;
- device IDs;
- controller identity strings;
- account information;
- names;
- voice;
- camera;
- biometric data;
- network addresses;
- filesystem paths;
- package hashes as scoring inputs;
- future RNG results;
- player history from another session;
- accessibility settings as difficulty signals.

### 16.3 Hidden-state equivalence

Two states that differ only in unrevealed private information must produce:

- the same telemetry;
- the same telemetry digest;
- the same candidate eligibility;
- the same score components;
- the same selected candidate;
- the same selected public target;
- the same Director RNG consumption.

Only an authored public reveal or approved public aggregate may change that result.

---

## 17. Target privacy

A public negative target may be identified only when the consequence itself is public.

A candidate must not publicly imply:

- that a seat holds a secret role;
- that a seat has a private objective;
- that a seat selected a hidden target;
- that a seat is privately weak or strong;
- that the Director inferred behavior from private device use.

When a candidate applies a private benefit or private prompt:

- the public display shows only a neutral consequence;
- the seat-private view receives the authorized detail;
- the no-phone path uses controlled reveal;
- the Director audit may record stable seat number but not private content;
- privacy-safe reports omit or de-identify the target.

---

# Part VII — Controller and no-phone behavior

## 18. Profile selection

Director profile selection must be possible with controllers and keyboard fallback before authority initialization.

The setup surface should show:

- profile name;
- one-sentence effect;
- fairness invariant;
- statement that presentation profile is separate;
- no-phone compatibility.

Changing profile after session initialization is prohibited unless a future authored mode explicitly supports an atomic public change and snapshots it.

### 18.1 Controls

Use the established semantic grammar:

- navigation — D-pad/stick or arrows/WASD;
- confirm — A/Enter;
- back — B/Escape;
- Help — X/H;
- protected reset — hold Y/R for 1.5 seconds.

No mouse is required.

### 18.2 Director beats

A Director consequence must never require a phone.

Public choices use the normal shared-screen prompt/vote grammar.

Seat-private Director choices use:

- optional authorized Companion; or
- controlled shared-screen reveal/pass-the-controller.

The public game waits deterministically for the authorized seat, without exposing private content.

### 18.3 Waiting and disconnect

If the selected candidate targets or requires an active seat that disconnects before application:

- application revalidates current authority;
- the candidate does not silently retarget unless the authored policy explicitly allows deterministic retargeting;
- a rejected application is recorded;
- bounded retry may select from remaining legal candidates if allowed;
- the disconnected seat is not punished;
- the game presents sanitized recovery guidance.

---

# Part VIII — Data and schema

## 19. Proposed Director content additions

A future schema version may add profile fields such as:

```text
evaluation_windows
max_consecutive_pressure
max_consecutive_relief
max_consecutive_ambient
recovery_satisfaction_policy
act_budgets
finale_reserve
allow_budget_borrowing
minimum_breath_windows
host_interruption_limit
public_explanation_level
target_randomization_policy
retry_policy
```

Candidate additions may include:

```text
allowed_windows
forbidden_windows
dramatic_function
recovery_satisfaction
act_budget_kind
finale_eligible
public_explanation_key
line_family
coalesce_family
interruption_policy
private_consequence_policy
retarget_policy
```

### 19.1 Evaluation policy location

The preferred ownership is:

- reusable window vocabulary in generic validated Director/session code;
- Tale-specific allowed windows in reviewed Tale/Director content;
- no runtime callback names;
- no script/class names in JSON;
- no literal candidate-ID branches in generic code.

### 19.2 Versioning

Any schema extension requires:

- new content/schema version;
- explicit migration/rejection behavior;
- new tests;
- updated documentation;
- snapshot version review;
- Tale package/provider/catalog/replay review;
- identity impact analysis.

Do not mutate v1 semantics silently.

---

## 20. Lantern House production identity risk

Current production identities must not change as a side effect of design review:

- Tale ID: `lantern_house_vertical_slice`;
- catalog identity: `2b478fd0d11fa075c2050409193aa06e6b9ca4dcf6efd4e4c550a9f3a5ff9db6`;
- package identity: `abb39d6bfbdf8d7de108379f08180c13efb99bbffa3e53f30eaaa8de7f459dee`;
- Director content ID: `lantern_house_director`;
- Director content version: `1`.

A future implementation should separate:

1. generic runtime/evaluation-window capability proven with synthetic export-excluded fixtures;
2. production Lantern House content adoption;
3. any package/provider/catalog identity migration;
4. portable-build and replay evidence.

A second Tale remains a separate release.

---

# Part IX — Testing

## 21. Unit tests

Required tests include:

### Evaluation windows

- valid semantic window accepts;
- invalid window rejects;
- duplicate window does not evaluate twice;
- duplicate window consumes no RNG;
- paused session holds;
- Help/private reveal holds;
- pending prompt/vote holds;
- partially applied transaction holds;
- terminal state rejects adaptive evaluation;
- rollback restores window eligibility.

### Scoring and selection

- current score arithmetic remains exact;
- unique winner uses no draw;
- tie uses one deterministic draw;
- ineligible candidates record stable reasons;
- zero/empty legal set selects authored no-op;
- invalid telemetry consumes no RNG;
- pressure/recovery/spacing/category streak rules compose correctly.

### Beat state

- severe pressure creates recovery obligation;
- accepted recovery satisfies obligation;
- no-op breath may satisfy only when policy allows;
- ambient does not falsely satisfy gameplay recovery;
- pressure streak cap holds;
- clue repetition policy holds;
- act budgets never go negative;
- finale reserve cannot be spent early;
- silence remains legal.

### Authority

- evaluation mutates no rules/board/role/seat state;
- rejected downstream application is atomic;
- accepted rules effect records rules authority revision;
- accepted board mutation records board revision;
- presentation-only cue changes no gameplay state;
- presentation failure does not roll back accepted gameplay;
- retry is bounded and deterministic.

### Privacy

- hidden-role permutations produce identical telemetry and decisions;
- private objective changes produce identical telemetry and decisions;
- raw card/item IDs do not cross telemetry;
- accessibility settings do not cross telemetry;
- disconnected seats are excluded from negative targeting;
- public explanation contains no internal identifiers;
- report projection contains no raw telemetry or target ledger.

### Presentation

- variant derivation is deterministic;
- variant derivation consumes no gameplay RNG;
- missing portrait/audio falls back to text and symbol;
- interruption rules protect private reveal, Help, and reset;
- reduced-motion fallback exists;
- host replacement changes no authority digest.

---

## 22. Simulation

Extend comparative simulation beyond the current short 90-sequence suite while keeping CI practical.

Recommended layers:

### Fast CI layer

- multiple seeds;
- Gentle, Standard, Dread, Fixed, Off;
- struggling, cruising, stalled, mixed, disconnect, and finale trajectories;
- deterministic replay;
- category-streak invariants;
- pressure and recovery obligations;
- window deduplication;
- budget and targeting caps;
- no-op safety.

### Scheduled/developer layer

Longer synthetic sessions should measure:

- intervention frequency by act;
- pressure/relief alternation;
- repeated candidate/tag rate;
- seat-target distribution;
- clue latency after stall;
- recovery latency after severe pressure;
- no-op frequency;
- rejected application rate;
- host-line family repetition;
- profile separation;
- finale reserve use.

These statistics are engineering evidence, not certification of fun or fairness.

---

## 23. View-level tests

At 960×540 and safe margins 0, 24, and 48:

- public beat card fits;
- profile label fits;
- friendly rationale wraps intentionally;
- seat target uses text plus Roman numeral/symbol;
- no raw metrics appear;
- no private information appears;
- Help explanation is controller-accessible;
- fallback without portrait/audio remains readable;
- long localized text uses bounded pagination or scrolling;
- no flashing is introduced.

Physical television readability remains a future human test.

---

## 24. Snapshot and replay tests

- v1 snapshot remains accepted under v1 runtime;
- future snapshot version round-trips new beat/window state;
- malformed keys reject atomically;
- mismatched content/profile identity rejects;
- unknown evaluated window rejects;
- restored snapshot reproduces next decision;
- rollback before decision reproduces decision;
- rollback after decision reproduces next window state;
- rules RNG remains unchanged;
- presentation variant reproduces from decision key;
- public history digest excludes private diagnostics;
- authority digest excludes replaceable presentation state.

---

## 25. Static and repository guards

Automated checks should prohibit:

- literal candidate-ID branches in generic runtime/presentation;
- literal Underteller-name branches in gameplay;
- scripts/classes/callbacks in Director declarations;
- network imports;
- telemetry upload;
- raw private fields in Director telemetry;
- package/provider hashes in gameplay scoring;
- dynamic code execution;
- unbounded audit history;
- wall-clock pacing decisions;
- frame-count pacing decisions.

First-party `gdlint` and `gdformat --check` remain zero-finding.

---

# Part X — Human validation

## 26. Required future human playtest evidence

Automation cannot establish:

- whether pacing feels fair;
- whether Gentle feels meaningfully gentler;
- whether Dread feels tense rather than arbitrary;
- whether host commentary is repetitive;
- whether silence is used enough;
- whether clues feel helpful but not patronizing;
- whether pressure arrives at satisfying moments;
- whether recovery feels earned;
- whether one player feels singled out;
- whether eight-player interruptions are excessive;
- whether text is readable from a television distance;
- whether audio/lighting cues are comfortable;
- whether reduced-motion presentation is adequate;
- whether controlled reveal remains socially workable.

These remain under issue #39 or later focused playtests.

No automated simulation, screenshot, virtual controller, or developer observation may be labeled as human pacing evidence.

---

# Part XI — Implementation sequence

## 27. Bounded implementation slices

### Slice A — Evaluation-window contract

Implement:

- semantic window IDs;
- once-only gate;
- pause/Help/private/pending-input holds;
- snapshot support;
- deterministic tests.

Use synthetic export-excluded fixtures first.

### Slice B — Beat and recovery obligations

Implement:

- dramatic function;
- pressure streak;
- recovery obligation;
- act budgets;
- finale reserve;
- tests and simulation.

Do not change Lantern House production content yet.

### Slice C — Underteller presentation adapter

Implement:

- bounded presentation request;
- deterministic line-family selection;
- interruption/coalescing policy;
- text/symbol fallback;
- no gameplay RNG use;
- view/privacy tests.

### Slice D — Explanation projections

Implement:

- player explanation;
- Help/facilitator explanation;
- diagnostics extension;
- privacy-safe report proposal if separately approved.

### Slice E — Lantern House adoption

Only after A–D are accepted:

- author allowed evaluation windows;
- author beat policies;
- review profile/candidate adjustments;
- run replay, package, provider, catalog, portable, and privacy evidence;
- determine identity changes explicitly.

### Slice F — Human pacing pilot

After an exact candidate build exists:

- run focused household/remote observation;
- record de-identified pacing findings;
- open bounded follow-up issues;
- do not treat one pilot as certification.

---

## 28. Dependencies and blockers

### May proceed now

- design review;
- synthetic schema examples;
- test-plan design;
- issue drafting;
- generic implementation planning.

### Must wait for PR #46

- implementation that touches the accepted Tale Library/setup route;
- profile-selection UX integrated into the new Library route;
- end-to-end selection-to-Director initialization tests based on final v0.1.6 interfaces.

### Must wait for issue #44

- Companion source/protocol/dependency/configuration implementation;
- public deployment;
- claims of fully security-green main.

Game-only native Director work may continue under the existing temporary policy if Companion files remain unchanged and no new Companion failure appears.

### Requires issue #39 or later human test

- fairness perception;
- emotional pacing;
- interruption comfort;
- TV readability;
- physical-controller usability;
- accessibility comfort;
- household group dynamics.

### Requires issue #7

- final Underteller name;
- final title;
- commercial host branding;
- logo, voice identity, storefront, merchandise, and marketing claims.

---

# Part XII — Risks

## 29. Design risks

### Over-intervention

Evaluating too often turns authored horror into notification noise.

**Mitigation:** explicit windows, spacing, coalescing, silence, and host interruption caps.

### Punishing success

Pressure that always follows strong play feels like hidden rubber-banding.

**Mitigation:** pressure is bounded dramatic escalation, not outcome correction; preserve visible benefit of success and legal recovery paths.

### Mercy exploitation

Players might intentionally create failure pressure to trigger relief.

**Mitigation:** relief is bounded, authored, budgeted, and not guaranteed; telemetry should combine several public signals.

### Hidden-state leakage

Aggregate telemetry might accidentally reveal private resources or roles.

**Mitigation:** approved aggregate vocabulary, hidden-state equivalence tests, no raw IDs, privacy review.

### Narrative repetition

A small candidate set may repeat even when mechanics remain fair.

**Mitigation:** line families, category streak rules, candidate/tag cooldowns, silence, human review before content expansion.

### Snapshot churn

Adding beat/window state can invalidate replay fixtures.

**Mitigation:** new snapshot version, atomic migration/rejection, synthetic proof before production adoption.

### Identity drift

Changing Lantern House Director content may affect package/provider/catalog evidence.

**Mitigation:** separate generic capability from production adoption and explicitly review identities.

### Host coupling

Gameplay may begin to depend on a named character or presentation asset.

**Mitigation:** `speaker_key`, presentation adapter, text/symbol fallback, host-replacement equivalence tests.

### False confidence from simulation

Synthetic trajectories may look ideal while real groups feel frustrated.

**Mitigation:** label simulation as engineering evidence only and require human playtests.

---

# Part XIII — Acceptance checklist for this design

## 30. Review criteria

The design is ready for implementation issue drafting when reviewers agree that:

- [ ] The Dread Director remains local, deterministic, authored, and non-generative.
- [ ] The Underteller remains replaceable presentation rather than gameplay authority.
- [ ] Evaluation occurs only at deterministic semantic windows.
- [ ] Duplicate windows cannot create duplicate decisions.
- [ ] Pause, Help, private reveal, pending input, and partial transactions block evaluation.
- [ ] Pressure, relief, clue, ambient, event, board, and no-op remain authored categories.
- [ ] Dramatic beats include explicit silence and recovery obligations.
- [ ] Stronger profiles preserve identical fairness, privacy, authority, and recoverability invariants.
- [ ] Director intensity remains separate from presentation profile and accessibility presentation.
- [ ] Read-only telemetry excludes private IDs, personal data, and accessibility settings.
- [ ] Hidden-state equivalence is mandatory.
- [ ] Director evaluation mutates no external authority.
- [ ] Downstream work remains validated and atomic.
- [ ] Presentation variants consume no gameplay RNG.
- [ ] Missing presentation assets cannot alter gameplay.
- [ ] Shared-screen, Help, diagnostics, and report explanation tiers are distinct.
- [ ] Controller and no-phone paths are complete.
- [ ] Snapshot, rollback, replay, rematch, and reset behavior are explicit.
- [ ] Schema additions are versioned and cannot silently mutate v1.
- [ ] Lantern House identities remain unchanged during design.
- [ ] Production adoption is separate from generic capability work.
- [ ] Issue #44, issue #39, issue #7, and PR #46 boundaries are preserved.
- [ ] Human pacing conclusions are not inferred from automation.

---

## 31. Recommended next action after review

After this document is approved, draft one bounded implementation issue for **Director Evaluation Windows & Beat State Foundation**.

That issue should:

- start from accepted protected main after PR #46 if it needs setup-route integration;
- use synthetic export-excluded fixtures for the first implementation;
- avoid Lantern House production identity changes;
- add deterministic window, beat, snapshot, privacy, and simulation tests;
- preserve existing Director score arithmetic unless a separately reviewed defect requires change;
- leave Companion files untouched;
- remain a game-only release under the issue #44 temporary policy.

---

## 32. Final boundary statement

This contract defines how a deterministic authored Director can shape dramatic pacing without cheating, profiling players, replacing authored Tales, or becoming an opaque AI authority.

The Director decides only among reviewed legal options at reviewed legal moments.

The Underteller tells the table what the Tale permits them to know.

Rules, board, roles, seats, snapshots, and outcomes remain owned by their existing native Godot authorities.
