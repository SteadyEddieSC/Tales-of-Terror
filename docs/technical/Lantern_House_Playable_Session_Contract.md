# Lantern House Playable Session Contract v1

**Status:** Proposed design and implementation contract  
**Scope:** Documentation only; no production content or identity change  
**Repository baseline:** `SteadyEddieSC/Tales-of-Terror` protected `main` at `0dde8d41c7cb1fc23bb2d85c26cb9281e311c971`  
**Intended implementation dependency:** v0.1.6 Tale Library correction, review, and merge  
**Working title notice:** “Terror Turn” and “The Underteller” remain provisional pending issue #7 legal clearance

## 1. Purpose

This contract defines the minimum coherent, player-driven Lantern House session that begins after a valid Tale selection and ends at rematch or protected reset.

It does not replace the accepted board, rules, Director, roles, Tale package, catalog, replay, privacy, or stable-seat authorities. It specifies how those existing authorities are presented and orchestrated as an understandable local shared-screen experience.

The target player journey is:

`Tale Library -> Public Briefing -> Threshold -> Council -> Reckoning -> Afterlife -> Ending -> Rematch or Title`

The contract is deliberately bounded. It turns the accepted vertical-slice sequence into a clear playable session without adding a second Tale, expanding Lantern House into a full-length scenario, redesigning the core rules engine, or changing Companion dependencies.

## 2. Identity and change guard

The following production identities remain unchanged by this design document:

- Tale stable ID: `lantern_house_vertical_slice`
- Display name: `Lantern House`
- Catalog SHA-256: `2b478fd0d11fa075c2050409193aa06e6b9ca4dcf6efd4e4c550a9f3a5ff9db6`
- Tale package SHA-256: `abb39d6bfbdf8d7de108379f08180c13efb99bbffa3e53f30eaaa8de7f459dee`

Any future implementation that changes the scenario manifest, Tale package, governed localization, provider construction, source ledger, or catalog must follow the existing package/catalog identity review and migration rules. Approval of this document does not itself approve such a change.

## 3. Existing repository-grounded baseline

The current accepted runtime already provides:

- 1–8 stable local seats with controller-first ownership and keyboard development fallback;
- lifecycle states for title, lobby, confirmation, briefing, active Tale, terminal resolution, and ending;
- a versioned Tale package and closed catalog/provider boundary;
- five ordered Lantern House stages:
  - `threshold`
  - `council`
  - `reckoning`
  - `afterlife`
  - `ending`
- authoritative board, rules, Director, role, pawn, and seat state;
- stage-level transaction snapshots and rollback on rejected operations;
- deterministic rules, role, and separately salted Director randomness;
- public, seat-private, faction-private, controlled-reveal, and diagnostics projections;
- a complete native Godot path when optional companions are unavailable;
- rematch that rebuilds session authorities using the retained roster, seed, requested mode, and selected Tale;
- protected reset that closes the Companion room, clears session authorities, resets seats, and restores the production default Tale.

The current vertical slice is an integration fixture, not a claim of final balance, duration, fun, television readability, or human playtest success.

## 4. Design goals

A successful implementation of this contract must make the existing Lantern House sequence:

1. understandable without developer knowledge;
2. fully operable with controllers and no phones;
3. deterministic and replayable;
4. privacy-safe on a shared television;
5. recoverable after rejected input or unavailable Tale preparation;
6. clear about which seat may act;
7. resistant to accidental double-advance;
8. skippable in presentation timing without skipping authority work;
9. explicit about ending, rematch, return, and protected reset;
10. suitable for later human playtest without claiming that playtest has occurred.

## 5. Non-goals

This contract does not authorize:

- a second production Tale;
- new Companion dependencies, protocol, room-service, Worker, or Cloudflare work;
- deployment or public release of Companion services;
- accounts, cloud saves, matchmaking, telemetry, or authoritative browser clients;
- a broad Director redesign;
- a full Lantern House narrative expansion;
- new factions, roles, cards, monsters, board spaces, or campaign persistence;
- title, trademark, storefront, domain, merchandise, or public-marketing claims;
- final balance, accessibility, television, controller, household, or remote-play conclusions;
- changes inside draft PR #46 beyond its separately bounded recovery-callout correction.

## 6. Authority model

### 6.1 Session orchestration authority

`VerticalSliceCoordinator` remains the session-scoped orchestration authority. It owns or references:

- lifecycle;
- selected Tale binding;
- stage and operation progression;
- stage history;
- retained seed and requested mode;
- pause state;
- stage transaction checkpoint;
- session-scoped references to the existing authorities.

It must not duplicate mutable board, rules, Director, role, pawn, or seat state.

### 6.2 Existing domain authorities

| Authority | Owns | Must not be owned by presentation |
| --- | --- | --- |
| `SeatManager` | stable seats, device ownership, reconnect reservation | seat reassignment or progression rights |
| `PawnRegistry` | seat-owned pawn state | authoritative movement results from visual nodes |
| `BoardState` | spaces, connectors, features, hazards, occupancy, revision/history | direct UI mutations |
| `RulesSession` | phases, prompts, votes, checks, cards, inventory, counters, flags, history, terminal result | prompt outcome or random results |
| `DirectorRuntime` | pacing state, budgets, cooldowns, separately salted RNG, decisions/applications | decisions selected by animation or audio |
| `RoleSession` | mode, faction/form, reveal/lifecycle, private objectives/actions, transitions, outcomes | private identity in public UI |
| `CompanionBridge` | filtered views and bounded intents only | gameplay authority or required session progression |

### 6.3 Proposed orchestration-only additions

Implementation may add a small explicit interaction gate to session orchestration when the current pending rules/role state is not enough to explain who may act.

Recommended fields:

- `interaction_revision: int`
- `interaction_kind: String`
- `eligible_seats: Array[int]`
- `completed_seats: Array[int]`
- `public_prompt_key: String`
- `cancel_policy: String`

These fields are authoritative only as orchestration state. They must be derived from validated authored operations and existing authority state, serialized in deterministic order, and excluded when empty.

Do not add a parallel prompt, vote, role, or card system.

## 7. Lifecycle and lock boundaries

### 7.1 Tale Library

Expected post-v0.1.6 behavior:

- Focus and selected Tale remain pre-session state.
- Confirmation prepares a complete candidate atomically.
- Preparation failure keeps the player in the Library and preserves seats, ownership, mode, focus, and prior valid selection.
- The valid focused Tale card remains visible while a fixed sanitized recovery callout is shown.
- Retry, Back, Help, and protected reset remain available.
- No session authority is committed after a failed preparation.

The Library is not part of gameplay snapshots or gameplay RNG.

### 7.2 Public Briefing

Entering Public Briefing means:

- catalog, provider, package, manifest, content, mode, roster, and authority construction have succeeded;
- complete candidate authorities have committed;
- no Tale stage has executed;
- selection remains reversible by returning to the Library;
- starting the Tale locks the selected Tale for that session.

Public Briefing must show only governed public information:

- Tale display name;
- public briefing;
- public objective;
- seat count;
- selected social mode or truthful cooperative fallback;
- controller instructions for Begin, Back, Help, and protected reset.

The briefing must not show package paths, provider IDs, hashes, classes, source-ledger information, role assignments, private objectives, or diagnostics.

### 7.3 Active Tale

Beginning the Tale:

- transitions lifecycle from `briefing` to `active_tale`;
- sets the first authored stage to `threshold`;
- preserves the prepared authorities and deterministic seed;
- creates no extra random draw solely because an animation starts or ends;
- enables the shared exploration presentation and active Tale HUD;
- prevents Tale reselection until rematch, return, or protected reset.

### 7.4 Terminal and Ending

The ending stage commits rules and social outcomes before the lifecycle becomes terminal. Terminal is a completed authority state awaiting public review. Ending is the review surface that allows rematch or return.

Presentation may animate or paginate the ending, but authority outcomes are already fixed.

## 8. Player-driven operation contract

Every playable operation follows the same sequence:

1. **Present** — show the public situation and identify eligible seats.
2. **Collect** — receive bounded controller intents from eligible stable seats.
3. **Validate** — revalidate lifecycle, stage, operation, seat ownership, revision, option, and authority conditions.
4. **Commit** — apply the accepted authority mutation atomically.
5. **Explain** — show a sanitized public result and any seat-private result through the correct channel.
6. **Advance** — increment operation/stage only after the commit succeeds.

A confirm press must never both claim a seat and advance the session. Repeated, stale, wrong-seat, disconnected, malformed, or ineligible inputs must fail without consuming gameplay RNG or partially advancing state.

### 8.1 Local intent envelope

A future implementation may normalize controller input into an internal bounded intent before authority application:

```text
intent_version
intent_sequence
seat_number
lifecycle
stage_id
operation_index
interaction_revision
intent_type
choice_ids
```

Requirements:

- `intent_sequence` is assigned by the native host in accepted processing order;
- no wall-clock timestamp participates in gameplay outcomes;
- invalid intents do not enter accepted replay history;
- raw device identifiers do not enter exported public reports;
- optional Companion intents map into the same bounded semantic contract but remain non-authoritative until native validation.

## 9. Stage contracts

## 9.1 Public Briefing — “The Lantern House is waking”

### Player experience

Players see the Tale name, public premise, public objective, current seat count, and selected mode. The screen clearly states that phones are optional. One owned active-seat Confirm begins the Tale; Back returns to the Tale Library before any stage executes.

### Gameplay rules

No board, rules, Director, or role operation resolves on this screen. Private role/objective review, when required by the selected social mode, must complete through the controlled-reveal flow before active play requires that information.

### Authoritative state

Prepared authorities, selected Tale, retained seed, requested/authorized mode, stable roster, and lifecycle `briefing`.

### Presentation-only state

Narration playback, subtitle progress, panel focus, Help visibility, role-reveal curtain animation, controller glyphs, and transition timing.

### Deterministic behavior

Confirming Begin transitions once. Duplicate confirms after the lifecycle change reject or become no-ops. Back discards prepared session authorities and restores the Library state defined by v0.1.6.

### Privacy

Only public briefing and mode/fallback information appears on the shared display. Role/faction/private objective details use controlled reveal or optional filtered Companion views.

### Controller/no-phone behavior

- Confirm: Begin Tale
- Back: Return to Library
- Help: Open shared Help
- Hold protected reset: Return to Title

No phone is required.

### Data/schema changes

None required for the public briefing itself.

### Tests

- Begin commits exactly one lifecycle transition.
- Back restores Library focus/selection/seats/mode and clears prepared authorities.
- No private role/objective data appears in public state.
- Duplicate Begin consumes no RNG and does not skip `threshold`.

### Release/migration risk

Must wait for the accepted final v0.1.6 Library/briefing boundary.

## 9.2 Threshold — “The Threshold Whispers”

### Player experience

The Underteller introduces the iron gate. The board highlights the threshold. Seat 1, or the authored acting seat resolved to the lowest eligible stable seat, chooses between the governed prompt options. Other seats see that the game is waiting for that seat without seeing private data that does not belong to them.

The accepted current content offers:

- Listen at the gate
- Force it open

The current automated fixture always supplies `listen`; player-driven play must use the actual selected option.

### Gameplay rules

The stage queues and resolves `threshold_whisper`, opens its single-seat prompt, waits for one valid response, resolves the prompt/event, opens the hall gate, draws one card for the authored acting seat, records the public history result, and reveals the clue fixture.

### Authoritative state

Pending prompt revision, eligible/acting seat, selected option, rules history, hall-gate connector state, acting-seat hand, revealed clue feature, stage/operation indices, and stage transaction checkpoint.

### Presentation-only state

Gate animation, host portrait/silhouette, paper-whisper audio, subtitle timing, option focus, board highlight, input glyph, and result emphasis.

### Deterministic behavior

- The acting seat is resolved deterministically.
- Prompt options remain in authored order.
- Wrong-seat or stale-revision responses reject.
- Rejection consumes no rules, role, or Director RNG.
- A failed operation restores the full stage checkpoint.
- Presentation skip does not skip prompt validation or effects.

### Privacy

The threshold choice is public unless the authored prompt classification later changes through reviewed content. Public history may record the selected public option and resulting public effect, but not raw input device data.

### Controller/no-phone behavior

The eligible seat uses directional input to focus an option and Confirm to submit. Back may move focus or close non-authoritative Help but must not cancel an already committed response. No phone is required.

### Data/schema changes

Prefer existing pending-prompt state and current operation gates. Avoid changing the Tale package merely to add presentation timing. If acting-seat policy must become data-driven rather than content-defined seat 1, treat that as a reviewed content/runtime contract change.

### Tests

- Listen and Force are both selectable through the rules HUD.
- Seat ownership is enforced.
- Duplicate/stale/wrong-seat responses do not mutate state.
- Each accepted option produces deterministic history/effects.
- Stage rollback restores gate, hand, clue, rules history, indices, and RNG snapshots after a later operation rejection.
- Public view contains no unrelated private role data.

### Release/migration risk

The current content explicitly names seat 1. Generalizing actor selection is valuable but must not be smuggled into this bounded UX release.

## 9.3 Council — “Council in the Gallery”

### Player experience

Every active or reserved stable seat receives one public vote prompt. The shared display shows:

- the question;
- the two public options;
- which seats have submitted;
- which seats are disconnected/reserved;
- the deterministic tie rule in Help or concise helper text;
- no live vote totals before resolution unless explicitly approved as a future rule.

Current options:

- Seal the Gallery
- Protect the Vault

### Gameplay rules

The stage opens `archive_route_vote`, collects one response from each eligible stable seat or an explicit abstention where allowed, resolves plurality with quorum 1, and uses stable option ID as the tie policy.

Resolved effects remain authoritative RulesSession/BoardState work:

- Gallery result collapses `archive_route`.
- Vault result sets `vault_protected`.

### Authoritative state

Vote definition, vote revision, eligible seats, response map, abstentions, resolved option, rules/board result, stage/operation indices, and transaction checkpoint.

### Presentation-only state

Per-seat submitted markers, vote-card focus, controller glyphs, reveal animation, tally animation, and audio sting.

### Deterministic behavior

- Stable seat order defines response presentation and accepted replay order where simultaneous local events occur.
- Tie resolution uses the authored `stable_option_id` policy.
- Disconnected reserved seats do not silently transfer ownership.
- A future timeout may not auto-cast a gameplay vote unless an authored deterministic timeout policy is separately approved.
- Duplicate responses at the same revision reject or replace only if the existing vote contract explicitly allows replacement.

### Privacy

The vote is public in topic and final result. Individual selections should remain concealed until resolution to preserve table discussion unless the approved rules contract says otherwise. Optional Companion views may show only the submitting seat’s own current selection.

### Controller/no-phone behavior

Each owned controller navigates and confirms its seat’s vote. Shared-screen seat markers use number, symbol, and pattern, not color alone. Keyboard remains a development fallback for its claimed stable seat.

### Data/schema changes

No new vote engine. The UI consumes the existing vote definition and pending response state. Any conceal-until-resolution flag should be derived from or added to reviewed vote presentation metadata, not inferred from option text.

### Tests

- 1–8 seat vote collection in stable order.
- Quorum, abstain, plurality, and tie policy.
- Disconnect/reserve/reconnect during an open vote.
- No vote-value leakage before resolution.
- Same seed and ordered inputs produce the same result and public history digest.
- Rejected responses consume no gameplay RNG.

### Release/migration risk

Actual social pacing and whether concealed public voting feels good require human playtest.

## 9.4 Reckoning — “The Vault Reckoning”

### Player experience

The game clearly presents a short escalation sequence rather than making one Confirm button silently execute several unrelated systems:

1. Echo mist appears and Steady Flame is granted.
2. The eligible seat confirms playing Steady Flame.
3. The mist clears and Hope increases.
4. The Courage check is previewed.
5. The check resolves visibly from authoritative results.
6. The Director makes one bounded decision or intentional hold.
7. The public consequence is summarized before advancement.

This can remain a guided fixed sequence. It does not need to become a free-form card-selection system in this contract.

### Gameplay rules

The current stage:

- activates `echo_mist` in `narrow_gallery`;
- grants `steady_flame` to the first active seat;
- plays that card, clearing the mist and adding Hope;
- resolves a 2d6 Courage check with +1 plus the Resolve counter;
- applies critical/success/partial/failure effects;
- evaluates and records one Director proposal/application.

### Authoritative state

Hazard state, granted card instance, hand/discard state, Hope/Resolve and check result, rules history, Director telemetry input, decision, application record, Director budgets/cooldowns/RNG, stage/operation indices, and transaction checkpoint.

### Presentation-only state

Card animation, dice animation, displayed roll timing, suspense pause, Director narration, lighting/music cue, board emphasis, and summarized result panel.

### Deterministic behavior

- Dice results come only from RulesSession RNG.
- Director evaluation uses its separately salted RNG and normalized allowed telemetry.
- Director cannot inspect unrevealed roles, private objectives, targets, messages, or transition plans.
- Animated dice must display the already committed authoritative result.
- Skipping an animation cannot reroll or reevaluate.
- Reopening Help cannot consume randomness.
- Stage rollback restores rules, board, Director, role, seat, pawn, operation, and checkpoint state.

### Privacy

The check and applied public consequence are public. The Director explanation may expose approved public component summaries but never private role or objective information. Developer diagnostics remain excluded from normal UI, reports, snapshots intended for players, and Companion views.

### Controller/no-phone behavior

The eligible seat confirms fixed guided actions. All players may open Help through the shared Help surface. No phone is required to play the card, see the check, or receive the Director result.

### Data/schema changes

No card-choice schema is required for the bounded session. A future release may replace fixed card play with an authored player choice, but that would be new gameplay/content scope and may change package identity.

### Tests

- Fixed Steady Flame sequence executes once.
- Displayed check equals authoritative check result.
- Same seed and accepted intent sequence reproduce rules and Director history.
- Director private-data denylist remains enforced.
- Rejected card/check/Director operation rolls back the entire stage.
- Help, pause, animation skip, and view refresh consume no RNG.

### Release/migration risk

Do not mistake a visually clear guided fixed sequence for final card-system depth or final Director balance.

## 9.5 Afterlife — “A Voice Beyond the Lantern”

### Player experience

The session intentionally demonstrates that defeat does not remove a player from play. One eligible Living seat transitions through the authored defeat path and immediately receives one meaningful Restless action.

The shared display must:

- explain that the seat has changed state;
- identify the seat publicly only to the extent allowed by the role transition;
- provide a controlled reveal for any private form/objective information;
- show the available afterlife action in accessible language;
- return a public consequence after the action commits.

### Gameplay rules

The current stage selects the seat tagged `living`, requests the authored `defeat` transition, then selects the resulting seat tagged `afterlife` and performs the authored action tagged `afterlife_support`.

The accepted social content includes multiple afterlife-capable actions/roles, but this vertical-slice operation may remain a deterministic authored demonstration rather than a player-selected afterlife framework.

### Authoritative state

Role lifecycle, current faction/form, reveal state, objective/action state, uses/cooldowns, rules/board effects caused by the action, outcome references, role RNG snapshot, stage/operation indices, and checkpoint.

### Presentation-only state

Screen curtain, pass-and-play instructions, reveal animation, role portrait, subtitle/audio timing, action focus, public consequence animation, and return-to-table transition.

### Deterministic behavior

- Selector-tag resolution must be stable and unambiguous.
- Invalid or missing selector matches reject before mutation.
- The role transition and cross-authority consequence commit atomically.
- Invalid work consumes no role, rules, board, or Director RNG.
- Controlled reveal timing does not alter assignment or outcome.

### Privacy

Private role/form/objective details never appear on the public television outside an explicit whole-screen controlled reveal authorized to one stable seat. The reveal must obscure prior and following frames enough to avoid accidental shoulder-surfacing during normal pass-and-play operation.

Optional Companion devices may receive the same filtered seat-private view only after the existing host approval and privacy gate. They are not required.

### Controller/no-phone behavior

The affected seat uses its owned controller during controlled reveal and action confirmation. The complete path must work with the television and controller alone. If the controller is disconnected, the seat remains reserved and the game waits with public sanitized guidance rather than reassigning the secret.

### Data/schema changes

No new afterlife role or action is authorized. If player choice among afterlife paths is introduced later, it requires a separate Afterlife Participation Framework and content/package review.

### Tests

- Defeat transitions the correct deterministic seat.
- Controlled-reveal public view contains no private fields.
- Wrong-seat controller cannot acknowledge or act for the transformed seat.
- Disconnect/reconnect preserves seat ownership and private state.
- Cross-authority action failure restores role, rules, and board snapshots.
- The player returns to an active interaction rather than a spectator state.

### Release/migration risk

Whether the afterlife moment feels meaningful, understandable, private enough, or socially awkward requires human playtest.

## 9.6 Ending — “The House Remembers”

### Player experience

Players receive a concise public recap that separates:

- what happened to the house;
- faction results;
- individual public results;
- partial, escaped, Changed, Restless, or defeated outcomes;
- private details that require controlled reveal;
- available next actions.

The ending must not reduce all results to a single generic win/loss banner.

### Gameplay rules

The current stage secures the house, increments objective progress, resolves role/social outcomes against final rules and board state, and commits the terminal result.

### Authoritative state

Final RulesSession result, role/faction/individual outcomes, public ending projection, private ending references, stage history, authority digest, public history digest, report disposition, and lifecycle.

### Presentation-only state

Recap pagination, character/seat emphasis, epilogue animation, audio, subtitle pacing, focus between Rematch and Return, and controlled-reveal navigation.

### Deterministic behavior

- Ending evaluation occurs once from committed authority state.
- Presentation order is stable and authored.
- Public history digest is independent of animation timing.
- Private reveal order may use stable seat order and must not alter outcomes.
- Rematch begins only after an explicit accepted choice.

### Privacy

The public recap contains only public outcomes. Seat-private or faction-private ending details use controlled reveal or the optional filtered Companion. Reports and portable bundles must retain existing privacy exclusions.

### Controller/no-phone behavior

- Confirm on Rematch: rebuild same Tale, roster, seed, and requested mode under current accepted behavior.
- Back/alternate explicit action on Return: protected return path as implemented by the approved route.
- Help: explain result categories and controls.
- Protected reset: always available.

No phone is required to review any required result.

### Data/schema changes

None required for a first public recap if existing ending projections are sufficient. New personalized epilogue text requires governed localization/content review and may change package identity.

### Tests

- Terminal result commits exactly once.
- Public and private endings remain separated recursively.
- Rematch reconstructs clean authorities with no previous session mutation.
- Same-seed rematch produces the same initial authority digest before new input.
- Return/protected reset closes Companion room and clears session state.
- Reports contain no prohibited private or provenance data.

### Release/migration risk

Same-seed rematch is deterministic but may surprise players expecting a new variation. A future explicit “Replay Same Tale” versus “New Seed” choice should be designed separately rather than silently changing current behavior.

## 10. Presentation-only state contract

The following state must remain presentation-only and excluded from gameplay authority, RNG, outcomes, and deterministic digest unless a separate evidence format explicitly records it:

- focused UI control;
- hover or selection animation;
- subtitle character index;
- narration playback position;
- current portrait animation;
- card/dice animation progress;
- camera target and interpolation progress;
- temporary emphasis/highlight;
- transition-curtain progress;
- controller glyph family;
- Help page and scroll position;
- sanitized notice animation;
- safe-area visualization;
- volume, subtitle, motion, and display preferences;
- frame rate and render timing.

Presentation may request an authoritative action. It may never infer, fabricate, reroll, or directly commit an outcome.

## 11. Determinism and replay contract

### 11.1 Required invariants

- One recorded session seed initializes all authorities.
- Rules, roles, and Director use their accepted separated/salted RNG behavior.
- Stable seat ordering is explicit wherever ordering affects resolution.
- Candidate collections are sorted before random selection unless authored order is semantic.
- Invalid input consumes no gameplay randomness.
- Wall-clock time, frame count, animation completion, audio completion, and network latency do not decide gameplay outcomes.
- Accepted semantic intents, not raw input events, form replay input.
- Every accepted stage operation has a stable sequence position.
- Rollback restores RNG and all participating authority state.
- Restoring an incompatible Tale/manifest/schema snapshot fails closed before adoption.

### 11.2 Pause behavior

Pause may stop presentation and pawn processing, but it must not:

- advance gameplay clocks;
- resolve pending votes/prompts;
- consume RNG;
- change Director telemetry;
- expire a seat’s turn;
- convert a disconnected seat;
- mutate replay order.

### 11.3 Rematch behavior

The current contract retains:

- stable roster;
- selected Tale;
- seed;
- requested mode;

and rebuilds all session authorities. Any future new-seed option must be explicit, logged, deterministic in how the new seed is produced, and separately reviewed.

## 12. Shared-screen privacy matrix

| Information | Classification | Shared TV | Controlled reveal | Optional Companion | Public report/history |
| --- | --- | --- | --- | --- | --- |
| Tale name, briefing, public objective | Public | Yes | Not needed | Yes | Yes |
| Seat count and public connection state | Public | Yes | Not needed | Yes | Yes |
| Public vote question/options/final result | Public | Yes | Not needed | Yes | Yes |
| Individual vote before resolution | Temporarily concealed | Submitted marker only | No | Own seat only | No |
| Public check/card/board result | Public | Yes | Not needed | Yes | Yes |
| Hidden faction/role | Seat-private until reveal policy permits | No | Yes | Own seat only | No |
| Seat-private objective/action | Seat-private | No | Yes | Own seat only | No |
| Faction-private information | Faction-private | No | Only if authored safe flow exists | Approved faction view only | No |
| Public afterlife transition/result | Public as authored | Yes | Not needed | Yes | Yes |
| Private afterlife form/objective | Seat-private | No | Yes | Own seat only | No |
| Public ending | Public | Yes | Not needed | Yes | Yes |
| Private ending details | Controlled-reveal private | No | Yes | Own seat only | No |
| Package path, provider ID, class, source ledger, hashes | Diagnostics/provenance | Never | Never | Never | Never |
| Raw rejection reason or stack trace | Diagnostics | Never | Never | Never | Never |

Recursive privacy tests must scan nested dictionaries, arrays, snapshots, reports, public history, and Companion projections rather than checking only top-level keys.

## 13. Controller-first and no-phone interaction grammar

### 13.1 Standard controls

- D-pad/left stick: navigate
- A/Confirm: select, acknowledge, or submit when eligible
- B/Back: return or close only where the current boundary permits
- X/Help: shared Help and accessibility guidance
- Hold Y/protected-reset action for 1.5 seconds: return to Title through protected reset
- Keyboard arrows/WASD, Enter, Escape, H, and R remain development fallback equivalents

### 13.2 Eligibility communication

Every waiting state must show:

- interaction title;
- eligible seat number/symbol/pattern;
- submitted/waiting seat markers where relevant;
- required control;
- Help availability;
- disconnected/reserved status without exposing private information;
- protected-reset guidance.

### 13.3 No-phone private path

Required private information uses a controlled reveal:

1. Obscure the entire shared display.
2. Identify the authorized stable seat publicly without revealing the secret.
3. Require input from that seat’s owned controller.
4. Reveal only that seat’s filtered private content.
5. Require acknowledgement.
6. Re-obscure before returning to public content.
7. Record only the semantic acknowledgement, not the secret content, in public history.

The flow must remain usable when all Companion services are disabled.

## 14. Failure and recovery contract

### 14.1 Pre-session preparation failures

For `tale_selection_unavailable` and `tale_preparation_unavailable`:

- retain the focused Tale card;
- show fixed sanitized recovery guidance;
- offer Retry, Back, Help, and protected reset;
- preserve selection/focus/seats/mode/lifecycle as defined by the accepted v0.1.6 correction;
- clear the notice after successful recovery;
- expose no raw reason, path, hash, provider ID, class, source-ledger information, or diagnostics.

### 14.2 Active-stage failures

An operation rejection must:

- roll back the full stage transaction;
- restore operation/stage indices and all participating authorities;
- restore RNG snapshots;
- leave the session at a deterministic resumable boundary;
- present a fixed sanitized notice;
- allow Retry, Help, and protected reset;
- keep diagnostics available only through explicit internal/developer surfaces.

### 14.3 Disconnect behavior

- Stable seat ownership is retained.
- The game waits if that seat is required for a private or single-seat interaction.
- Public UI shows a sanitized reconnect instruction.
- Another controller cannot silently assume the seat or private prompt.
- A future facilitator reassignment flow requires separate design and explicit consent.

## 15. Data and schema impact

### 15.1 Documentation-only effect

This document changes no runtime data or schema.

### 15.2 Preferred implementation approach

Use the existing:

- Tale package stage graph;
- scenario stages/operations;
- RulesSession pending prompt and vote state;
- RoleSession private/public projections;
- Director decision/application records;
- coordinator transaction snapshots;
- stable-seat input router;
- governed localization catalogs.

Add only the minimum orchestration/view state needed to explain the current interaction.

### 15.3 Changes requiring separate review

The following are not incidental UX changes and require a reviewed ADR/content/package decision:

- new operation types;
- generalized actor-selection policy replacing authored seat 1;
- new Tale package fields;
- new governed narration or epilogue content;
- selectable card play instead of the fixed Steady Flame demonstration;
- selectable afterlife paths;
- new seed/rematch policy;
- new public/private classification;
- new stage, event, card, role, action, objective, board space, or Director candidate;
- any package, manifest, localization, provider, source-ledger, or catalog identity change.

## 16. Deterministic test plan

### 16.1 View-level tests

- Briefing contains only governed public fields.
- Every stage identifies eligible seats and controls.
- Waiting/submitted/disconnected states are deterministic.
- Provider/package rejection keeps the Tale card visible and shows sanitized recovery guidance.
- Successful retry clears the notice.
- No raw reason, path, hash, provider ID, class, source ledger, or diagnostics appear in normal UI.

### 16.2 Input tests

- Confirm never both joins and advances.
- Wrong-seat, stale, duplicate, disconnected, malformed, and ineligible intents reject without mutation.
- Help and presentation navigation consume no gameplay RNG.
- Protected reset works from every lifecycle/stage/waiting state.
- Keyboard fallback behaves as one claimed stable seat, not a global authority bypass.

### 16.3 Authority tests

- Each stage begins with a transaction checkpoint.
- A forced rejection at every operation boundary restores all authorities and RNG.
- Public state and snapshots remain coherent after rollback.
- Terminal outcomes commit exactly once.
- Rematch rebuilds clean authorities.

### 16.4 Replay tests

For each accepted fixture seed (`4706`, `9017`, `22031`):

- run the same stable roster, mode, and semantic intent sequence twice;
- compare authority digests after every committed operation;
- compare public history digests at stage boundaries and ending;
- verify invalid-intent insertion does not change later accepted outcomes;
- verify animation skip/pause/Help differences do not change digests;
- verify same-seed rematch returns to the same initial authority digest.

### 16.5 Privacy tests

- Recursive denylist scans across public view, public history, reports, snapshots intended for sharing, and Companion public/seat projections.
- Hidden role/objective information never appears in shared-screen state.
- Individual vote values remain concealed until resolution.
- Private ending details require controlled reveal.
- Package/catalog provenance remains outside gameplay/public outputs.

### 16.6 Seat-count tests

Automated coverage should exercise 1–8 stable seats for:

- briefing;
- prompt eligibility;
- vote collection;
- disconnect/reserve/reconnect;
- hidden-betrayer supported counts;
- cooperative fallback counts;
- afterlife transition;
- ending and rematch.

This is structural evidence only, not human balance or usability evidence.

## 17. Human playtest requirements

The following claims require actual future human testing and must remain unclaimed until performed:

- physical controller discovery, identical-controller identity, disconnect, and reconnect behavior;
- television readability at normal room distance;
- safe-area behavior on real televisions;
- whether players understand eligible-seat prompts without explanation;
- public-vote discussion and waiting time at larger seat counts;
- controlled-reveal privacy and social comfort;
- whether the afterlife transition feels meaningful;
- whether Director presentation feels dramatic rather than intrusive;
- whether Help, Retry, Back, and protected reset are discoverable;
- accessibility involving motion, flashing, reading load, color/shape distinction, audio, and motor timing;
- household tone response;
- Companion-device usability after issue #44 is resolved.

## 18. Release and migration risks

| Risk | Mitigation |
| --- | --- |
| Designing against draft PR #46 internals | Keep this contract interface-level; implement only after final merge review |
| Casual package/catalog identity drift | Treat content/schema changes as separate reviewed work |
| UI becoming gameplay authority | Enforce present/collect/validate/commit/explain/advance boundary |
| Double-advance from controller input | Retain claimed-seat event guard and lifecycle/revision validation |
| Private information leaking on television | Use independent projections and recursive privacy tests |
| Animation timing changing outcomes | Commit authority before displaying result; exclude presentation timing |
| Stage failure leaving partial state | Keep full transaction checkpoint and rollback across all authorities/RNG |
| Overstating playability | Label automated evidence accurately; defer human conclusions |
| Companion advisory contamination | Change no Companion dependency/source/protocol/config and do not deploy |
| Same-seed rematch confusing players | Document current behavior; design new-seed choice separately |
| Expanding a bounded vertical slice into broad redesign | Keep fixed five-stage content and guided actions for this contract |

## 19. Recommended implementation slices after PR #46

### Slice A — Active Tale interaction status

- Add or derive a deterministic interaction-gate projection.
- Show stage, eligible seat, waiting/submitted status, Help, and reset guidance.
- No content or package change.

### Slice B — Threshold and Council player input hardening

- Exercise real prompt and vote input through stable-seat controllers.
- Add stale/wrong-seat/duplicate/reconnect tests.
- Preserve existing authority APIs.

### Slice C — Reckoning presentation sequencing

- Present fixed card, check, and Director results as distinct guided beats.
- Ensure animations consume no RNG and can be skipped safely.

### Slice D — Afterlife controlled reveal

- Provide the complete no-phone private transition and action path.
- Add recursive privacy and reconnect tests.

### Slice E — Ending and rematch clarity

- Present mixed public outcomes, controlled private details, and explicit next actions.
- Verify clean same-seed rematch and protected return.

Each slice should remain independently reviewable and should not absorb Companion remediation, a second Tale, legal branding, or broad content expansion.

## 20. Exit criteria for this design contract

This contract is ready to become implementation work when:

- the bounded PR #46 correction is accepted and merged;
- the final Tale Library/Public Briefing interface is known;
- reviewers agree that the five existing stages remain the bounded content scope;
- authority, privacy, determinism, controller, and rollback requirements are accepted;
- any required schema/content change is separated into an ADR or explicit package migration proposal;
- a candidate implementation issue references this document without claiming human playtest evidence.

## 21. Candidate implementation issue summary

**Title:** Lantern House — Player-Driven Session UX and Deterministic Interaction Gates

**Goal:** Turn the existing five-stage Lantern House vertical slice into a clear controller-first, no-phone, player-driven session while preserving all accepted authorities, content identities, deterministic replay, rollback, stable seats, and privacy boundaries.

**Required:**

- final merged v0.1.6 Tale Library/Public Briefing boundary;
- explicit eligible-seat and waiting-state presentation;
- real stable-seat prompt/vote input;
- guided Reckoning presentation;
- controlled-reveal afterlife flow;
- mixed-outcome ending and clear rematch/return actions;
- deterministic view/input/rollback/replay/privacy tests;
- no Companion, second-Tale, legal-branding, telemetry, cloud, or authority expansion.

**Deferred:**

- human controller/television/household/accessibility evidence;
- selectable afterlife framework;
- new-seed rematch choice;
- full-length Lantern House content and balance;
- Companion deployment or remediation work.
