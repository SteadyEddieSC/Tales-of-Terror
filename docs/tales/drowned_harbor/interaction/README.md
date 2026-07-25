# Drowned Harbor Interaction-State Traceability

**Release stream:** P0.11
**Status:** Preproduction interaction and implementation traceability only
**Tale status:** Design-only
**Production Tale:** Lantern House remains the sole production Tale
**Runtime authorization:** None

## Purpose

P0.10 defines what the shared display communicates and how players navigate it.

P0.11 defines the authoritative state and interaction contract beneath those storyboards without creating runtime code.

Every trace records:

- the one P0.10 storyboard it covers;
- public and private state domains read or written;
- permitted actor and controller authority;
- entry preconditions and action guards;
- interaction lifecycle;
- typed input intents;
- deterministic commit and retry behavior;
- public, private, and diagnostic event outputs;
- privacy shield and clearing requirements;
- stale, disconnected, unavailable, and interrupted recovery;
- inherited focus, captions, transcript, persistent-text, and stable-seat obligations;
- neutral future implementation responsibilities;
- source documents and cross-media concepts;
- human-review questions;
- explicit non-approval boundary.

The controlling technical document is:

`docs/technical/Drowned_Harbor_Interaction_State_Traceability_Contract_v1.md`

The closed record schema is:

`docs/preproduction/interaction_state_trace_schema_v1.json`

## Inventory

P0.11 defines exactly **22 interaction traces across three manifests**, one for every P0.10 storyboard.

### Core interactions — 6

- `DH-IS-001` — Tale preview
- `DH-IS-002` — Local stable-seat lobby
- `DH-IS-003` — Low-Tide board
- `DH-IS-004` — Bellhouse decision
- `DH-IS-005` — Lighthouse Council
- `DH-IS-006` — Public Harbor bargain offer

### Resolution interactions — 6

- `DH-IS-007` — Controlled-private bargain terms
- `DH-IS-008` — High Water transformation
- `DH-IS-009` — High Water transformed board
- `DH-IS-010` — Tidebound transformation
- `DH-IS-011` — Last Light final choice
- `DH-IS-012` — Mixed ending attribution

### Continuity and accessibility interactions — 10

- `DH-IS-013` — Reconnecting
- `DH-IS-014` — Game control
- `DH-IS-015` — Public takeover selection
- `DH-IS-016` — Inherited private-state handoff
- `DH-IS-017` — Returning-player recap
- `DH-IS-018` — Restless continuation
- `DH-IS-019` — Invalid-action recovery
- `DH-IS-020` — Transcript and replay
- `DH-IS-021` — Narrative accessibility settings
- `DH-IS-022` — Remote admission queue, deferred

## State domains

Declared domains are:

- session public;
- board public;
- seat public;
- seat private;
- Tale public;
- Tale private;
- accessibility public;
- admission public;
- nonplayer diagnostics.

Undeclared state access is prohibited.

## Actor authority

Traces may authorize:

- host;
- active stable seat;
- a specific public seat;
- returning reserved controller;
- approved takeover controller;
- deterministic game control;
- spectator;
- system.

Actor authority does not change stable-seat identity.

A handoff, departure, reconnect, takeover, return, transformation, defeat, or continuation may not create:

- a replacement character;
- a reroll;
- healing;
- restored inventory;
- objective reset;
- removed history;
- lost ending identity;
- spectator elimination.

## Privacy

Shared public traces may project public state only.

Controlled-private traces require:

- a neutral shared-screen shield;
- an authorized private actor;
- exact stable-seat identity;
- acknowledgement before commitment;
- private-content clearing before public restoration;
- no private content in public transcript, audio, captions, replay, mirrored output, or screenshots.

Private bargain terms and inherited private-state handoffs are the current controlled-private traces.

## Determinism

An authoritative interaction declares:

- source revision;
- legal action and actor authority;
- deterministic commit;
- result revision;
- exactly-once event identity;
- idempotent reprojection;
- no raw account, controller, network, or voice-derived identity.

Once-only transitions include High Water, public form changes, private bargain commitment, Last Light, takeover handoffs, and Restless continuation.

## Recovery

Every trace includes at least two recovery cases.

Recovery must preserve:

- no partial authoritative mutation;
- no hidden penalty;
- no private-state exposure;
- no stable-seat reset;
- deterministic focus restoration;
- current legal alternatives;
- persistent plain-system text;
- local shared-screen play when Companion is unavailable.

## Validation

Run:

```bash
python tools/validate_interaction_state_traces.py
python tools/test_validate_interaction_state_traces.py
```

The validator checks:

- exact `DH-IS-001` through `DH-IS-022` coverage;
- exact one-to-one `DH-UI-001` through `DH-UI-022` coverage;
- unique event keys;
- storyboard privacy and confirmation compatibility;
- public/private projection boundaries;
- deterministic and exactly-once commit behavior;
- recovery and stable-seat preservation;
- layout-region, caption, transcript, focus, and persistent-text obligations;
- source-path and cross-media concept resolution;
- human-review questions;
- design-only and no-implementation status.

The mutation suite intentionally corrupts eighteen contract conditions and requires fail-closed rejection.

## Future implementation seams

Records name responsibilities, not classes or files:

- authoritative state reader;
- legal-action query;
- command validator;
- deterministic reducer;
- public and private projection builders;
- focus coordinator;
- caption/transcript and replay adapters;
- controller-authority adapter;
- admission adapter;
- diagnostic recorder.

## Boundaries

P0.11 does not approve:

- Drowned Harbor runtime implementation;
- production Tale package or catalog registration;
- Godot scenes, scripts, resources, reducers, commands, events, or input maps;
- Companion endpoints or account identity;
- final accessibility implementation;
- final media or localization;
- human usability, privacy, controller, playtest, or accessibility claims;
- closing issues #7, #39, or #44.
