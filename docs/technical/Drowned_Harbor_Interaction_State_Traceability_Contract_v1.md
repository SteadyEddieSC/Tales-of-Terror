# Drowned Harbor Interaction-State and Implementation Traceability Contract

**Version:** 1.0
**Release stream:** P0.11
**Status:** Preproduction technical contract
**Tale status:** Design-only
**Production Tale:** Lantern House remains the sole production Tale
**Runtime authorization:** None

## 1. Purpose

P0.10 defines what each shared-screen state must communicate and how players may interact with it.

P0.11 defines the preproduction state contract underneath those storyboards:

- which authoritative public or private state permits a storyboard to appear;
- which actor or controller source may provide input;
- which guards must pass before an interaction may commit;
- which state changes are permitted;
- which public events may be emitted;
- which private data must remain on an authorized surface;
- which captions, transcript entries, and persistent text are required;
- how invalid, interrupted, stale, disconnected, or unavailable interactions recover;
- which future implementation seams may be planned without selecting concrete runtime classes;
- which automated and human checks remain required.

The contract connects authored design intent to a future implementation plan. It is not the implementation.

## 2. Authority hierarchy

An interaction trace must preserve this authority order:

1. authoritative Tale and stable-seat state;
2. deterministic transition and validation rules;
3. privacy classification and authorized surface;
4. legal-action set and confirmation requirement;
5. public event projection;
6. storyboard presentation;
7. voice, audio, music, animation, and decorative treatment.

A lower layer may not invent or override a higher-layer fact.

## 3. Source contracts

P0.11 depends on, but does not replace:

- `docs/preproduction/shared_screen_storyboard_schema_v1.json`;
- the 22 P0.10 storyboard records;
- `docs/technical/Shared_Screen_Storyboard_Contract_v1.md`;
- `docs/tales/drowned_harbor/authoring/drowned_harbor_authoring_reference_v1.json`;
- the four P0.9 authoring content manifests;
- `docs/design/Seat_Continuity_and_Admission.md`;
- `docs/tales/drowned_harbor/Drowned_Harbor_Design_Bible.md`;
- governed dialogue, audio, music, voice, accessibility, and cross-media traceability packages.

The production Tale schema, production catalog, providers, runtime scenes, scripts, resources, input maps, and Companion protocol are outside P0.11.

## 4. Stable interaction identity

Every interaction trace uses a stable ID:

```text
DH-IS-001
```

Each trace maps to exactly one P0.10 storyboard record.

The trace ID remains stable if:

- a working title changes;
- the host name changes;
- visual layout changes;
- copy is localized;
- a future implementation changes internal class names;
- a different controller or human temporarily controls the stable seat.

The trace ID changes only when the authored interaction contract itself becomes a different interaction.

## 5. State domains

Every trace declares the authoritative state domains it reads and may write.

Allowed preproduction domains:

- `session_public` — session mode, stage, public options, public timers, public admission state;
- `board_public` — spaces, routes, landmarks, tide state, hazards, visible objectives, public resources;
- `seat_public` — stable-seat number, public location, public form, public control source, public status;
- `seat_private` — private role, faction, objective, inventory, bargain terms, inherited private recap;
- `tale_public` — public Tale flags, truth state, Bellhouse state, lighthouse state, ending state;
- `tale_private` — hidden director or Tale state that may govern outcomes but cannot enter public presentation;
- `accessibility_public` — caption, transcript, plain-system, text scale, reduced-density, and related public preferences;
- `admission_public` — join requests, spectator status, host authority, reservations, and public admission result;
- `diagnostic_nonplayer` — validation or diagnostic information unavailable to ordinary players.

A trace must list every domain it reads and every domain it may write.

Undeclared state access fails closed.

## 6. Privacy surfaces

P0.11 uses the same surface classes as P0.10:

- `public_shared`;
- `neutral_shared_shield`;
- `controlled_private_surface`.

### Public shared

May contain only authoritative public state.

### Neutral shared shield

May state that a private handoff is in progress, which stable seat is involved where public, and what public acknowledgement or waiting action remains.

It may not contain private content.

### Controlled private surface

May display only the private state authorized for the active stable seat and current handoff.

It must declare:

- the stable seat receiving the information;
- the authorized control source;
- the acknowledgement or completion action;
- the public shield behavior;
- the private-data clearing condition;
- the return-to-public transition.

Private state may not enter public captions, transcript, replay, audio, music, screenshots, mirrored display, or public event payloads.

## 7. Actor and control authority

Every trace declares one or more allowed actors:

- `host`;
- `active_stable_seat`;
- `specific_public_seat`;
- `returning_reserved_controller`;
- `approved_takeover_controller`;
- `game_control`;
- `spectator`;
- `system`.

An actor is not the same as a character.

Controller authority may change while the stable seat remains unchanged.

No interaction may infer that control transfer creates:

- a new character;
- a reroll;
- healing;
- restored inventory;
- objective reset;
- faction reset;
- removed history;
- a new ending identity.

## 8. Interaction lifecycle

Every trace declares this lifecycle:

1. `eligible` — authoritative state and actor satisfy entry conditions;
2. `presented` — the storyboard is projected on the authorized surface;
3. `focused` — one legal action or navigable region has focus;
4. `previewed` — reversible effects or consequences may be displayed;
5. `confirming` — a governed confirmation is active where required;
6. `committed` — one authoritative transition is accepted exactly once;
7. `projected` — public and private results are emitted to their authorized surfaces;
8. `settled` — focus, transcript, persistence, and next-state ownership are established.

A trace may omit lifecycle steps only when its declared confirmation pattern permits it.

## 9. Preconditions and guards

### Preconditions

Preconditions determine whether the interaction state may be entered.

Examples:

- current stage is `lighthouse_council`;
- public legal options are nonempty;
- the active stable seat exists;
- a join request is pending;
- a returning controller matches the reserved seat authority;
- private content has not yet been acknowledged;
- High Water has committed but transformed-board projection has not settled.

### Guards

Guards determine whether a proposed action may commit.

Examples:

- action remains in the current legal-action set;
- actor still owns authority;
- confirmation token matches the current state revision;
- route remains available;
- required public choice count is satisfied;
- private acknowledgement belongs to the correct stable seat;
- a takeover occurs at an authorized safe handoff;
- a bargain term has not changed since preview;
- a once-only transition has not already committed.

Stale or failed guards use the declared recovery path and may not partially commit.

## 10. Inputs

Every trace declares typed input intents rather than device-specific button codes.

Examples:

- `navigate_focus`;
- `inspect_public_state`;
- `preview_action`;
- `confirm_action`;
- `cancel_or_back`;
- `open_transcript`;
- `replay_narration`;
- `acknowledge_private_state`;
- `request_takeover`;
- `approve_join_request`;
- `change_accessibility_setting`.

Future controller, keyboard, browser, or accessibility mappings may bind to these intents.

P0.11 does not select the runtime input implementation.

## 11. Outputs and events

Every trace declares permitted outputs.

### Public projection

May include:

- updated public board state;
- active-seat and control-source changes;
- committed public decisions;
- public transformations;
- route or hazard changes;
- public stage transitions;
- public ending attribution;
- captions, transcript entries, and persistent text.

### Private projection

May include only the exact private state authorized for the current stable seat and surface.

### Event requirements

A committed interaction should produce one deterministic event identity suitable for future replay, diagnostics, and test assertions.

An event declaration includes:

- stable event key;
- public or private classification;
- actor stable-seat identity where authorized;
- source state revision;
- committed action;
- resulting authoritative revision;
- replay and transcript behavior;
- no raw controller, account, network, or voice-derived identity.

P0.11 does not prescribe the runtime event-bus technology.

## 12. Determinism and idempotency

Committed interactions must be deterministic for the same:

- authoritative state;
- actor authority;
- legal-action set;
- deterministic seed where applicable;
- selected action;
- confirmation revision.

Once-only transitions include:

- High Water transformation;
- public Bellmarked reveal;
- public Tidebound transformation;
- Restless continuation assignment;
- accepted Harbor bargain;
- committed final ending choice;
- stable-seat takeover or return handoff at the selected safe point.

Retrying a committed event may replay its projection but may not commit it twice.

## 13. Failure and recovery

Every trace declares recovery for relevant failures:

- stale action;
- authority changed;
- controller disconnected;
- private surface unavailable;
- Companion unavailable;
- caption or voice interrupted;
- legal-action set changed;
- confirmation expired;
- route or target became invalid;
- unsupported mode;
- malformed or missing projection data;
- transcript or replay temporarily unavailable.

Recovery rules:

- no partial authoritative mutation;
- no hidden penalty;
- no private-state exposure;
- no stable-seat reset;
- legal options are refreshed from authority;
- persistent plain-system text explains the next legal step;
- focus returns to a deterministic safe region;
- game control may preserve continuity only under the existing seat contract;
- local shared-screen play does not require Companion recovery.

## 14. Presentation obligations

Each trace inherits its P0.10 storyboard obligations and may add technical assertions for:

- required layout regions;
- focus owner and focus restoration;
- confirmation pattern;
- caption and transcript behavior;
- persistent text;
- public/private clearing;
- seat and control-source visibility;
- visual state variants;
- no-audio and no-voice operation.

The interaction trace may not weaken its storyboard.

## 15. Future implementation seams

A trace may name neutral implementation seams such as:

- authoritative state reader;
- legal-action query;
- command validator;
- deterministic reducer;
- public projection builder;
- private projection builder;
- focus coordinator;
- caption and transcript adapter;
- replay adapter;
- controller-authority adapter;
- admission adapter;
- diagnostic recorder.

These are responsibilities, not approved class names or files.

P0.11 does not authorize:

- new Godot scenes;
- GDScript classes;
- production resources;
- Companion endpoints;
- localization files;
- input-map changes;
- Tale catalog or provider registration;
- runtime imports or production assets.

## 16. Automated validation targets

The P0.11 validator should reject:

- missing or duplicate interaction IDs;
- missing or duplicate storyboard coverage;
- unknown storyboard IDs;
- unknown state domains;
- undeclared reads or writes;
- private reads on public-only traces;
- public outputs that include private payloads;
- private traces without a neutral shield and clearing rule;
- missing actor authority;
- missing preconditions or guards;
- a committed action without deterministic event identity;
- non-idempotent once-only transitions;
- missing stale-state or authority-change recovery;
- missing persistent text for critical interactions;
- lost caption, transcript, focus, confirmation, or seat-continuity obligations;
- production or runtime authorization;
- nonexistent source paths or traceability concepts;
- removal of required human-review questions.

## 17. Human validation remains required

Automation cannot prove:

- players understand action ownership;
- focus order works with several controllers;
- private handoffs feel private in a living room;
- confirmation is neither accidental nor tedious;
- invalid-action recovery is understandable;
- High Water transformation remains legible;
- controller disconnect and takeover feel fair;
- captions and transcript remain readable;
- mixed outcomes remain understandable;
- the interaction is enjoyable.

Each trace retains explicit human-review questions.

## 18. Planned first-wave traces

P0.11 should define one interaction trace for each P0.10 storyboard:

- Tale preview;
- local stable-seat lobby;
- Low-Tide arrival board;
- Bellhouse decision;
- Lighthouse Council;
- public Harbor bargain;
- controlled-private bargain terms;
- High Water transition;
- High Water transformed board;
- Tidebound transformation;
- Last Light;
- mixed ending attribution;
- reconnecting;
- game control;
- takeover selection;
- controlled-private inherited-state handoff;
- returning-player recap;
- Restless continuation;
- invalid-action recovery;
- transcript and replay;
- accessibility settings;
- remote admission queue.

## 19. Approval boundary

This contract does not approve:

- Drowned Harbor implementation;
- a production Tale package;
- catalog or provider registration;
- runtime state classes, reducers, events, commands, scenes, resources, or UI;
- Companion protocol changes;
- final controller mappings;
- final accessibility behavior;
- production assets or localization;
- human usability or playtest claims;
- closing issues #7, #39, or #44.
