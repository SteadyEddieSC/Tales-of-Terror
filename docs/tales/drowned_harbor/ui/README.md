# Drowned Harbor Shared-Screen Storyboards

**Release stream:** P0.10
**Status:** Design-only preproduction
**Tale status:** Drowned Harbor is not a production Tale
**Production inventory:** Lantern House remains the sole production Tale

## Purpose

This directory turns the governed Drowned Harbor narrative, continuity, visual, dialogue, voice, caption, accessibility, and authoring contracts into a reviewable shared-screen interaction pack.

It defines what the room may see, what one authorized stable seat may see privately, which controls are legal, where confirmation occurs, what information persists, how focus returns, and which questions still require human review.

The files do not create Godot scenes, runtime UI, Tale data, controller bindings, Companion behavior, or production assets.

## Contents

### `drowned_harbor_core_storyboards_v1.json`

Twelve core-play records:

1. `DH-UI-001` — Drowned Harbor Tale Preview
2. `DH-UI-002` — Local Stable-Seat Lobby
3. `DH-UI-003` — Low-Tide Arrival Board
4. `DH-UI-004` — Bellhouse Ledger Decision
5. `DH-UI-005` — Lighthouse Council Direction Choice
6. `DH-UI-006` — Public Harbor Bargain Offer
7. `DH-UI-007` — Private Harbor Bargain Terms
8. `DH-UI-008` — High Water Commitment and Transition
9. `DH-UI-009` — High Water Transformed Board
10. `DH-UI-010` — Tidebound Public Transformation
11. `DH-UI-011` — Last Light Final Decision
12. `DH-UI-012` — Mixed Public Outcome Attribution

### `drowned_harbor_continuity_accessibility_storyboards_v1.json`

Ten continuity, recovery, transcript, accessibility, and admission records:

13. `DH-UI-013` — Stable Seat Reconnecting
14. `DH-UI-014` — Stable Seat Under Game Control
15. `DH-UI-015` — Public Takeover Seat Selection
16. `DH-UI-016` — Inherited Private State Handoff
17. `DH-UI-017` — Returning Player Recap
18. `DH-UI-018` — Restless Continuation Activation
19. `DH-UI-019` — Invalid Action Recovery
20. `DH-UI-020` — Transcript and Replay Drawer
21. `DH-UI-021` — Narrative Accessibility Settings
22. `DH-UI-022` — Remote Join Request and Admission Queue

## Record contract

Every storyboard declares:

- stable storyboard ID;
- category and stage context;
- layout mode and privacy surface;
- entry and exit conditions;
- public purpose;
- required information;
- named layout regions;
- stable legal-action IDs;
- confirmation pattern;
- deterministic focus order;
- caption and transcript policy;
- persistent-text behavior;
- stable-seat authority behavior;
- state variants;
- visual guidance and negative constraints;
- source authorities and cross-media concepts;
- human-validation questions;
- preproduction status and approval boundary.

The closed schema is:

`docs/preproduction/shared_screen_storyboard_schema_v1.json`

The governing design contract is:

`docs/technical/Shared_Screen_Storyboard_Contract_v1.md`

## Core information rules

### Public shared screen

The television may show public Tale state, legal actions, stable-seat identity, public control source, public forms, public outcomes, captions, transcript access, and recovery guidance.

It may not expose unrevealed roles, factions, objectives, bargains, conditions, inventory, route knowledge, or future transformations.

### Neutral shared shield

A neutral shield indicates only that an authorized private review is occurring. It must not reveal the private topic, affected seat, desirability, target, or likely result through text, icon, color, animation, sound, captions, transcript, or mirrored content.

### Controlled private surface

Exact private terms or inherited private state appear only after authorization and safe handoff. The public screen remains neutral. Private material does not enter public history or public replay.

## Stable-seat continuity

The stable seat owns state through:

- disconnect;
- reconnect grace;
- game control;
- takeover request;
- inherited-state acknowledgement;
- returning-player recap;
- Tidebound transformation;
- defeat and Restless continuation;
- ending attribution.

A control or form change does not create a fresh character, reset health, restore inventory, reroll objectives, erase history, or remove the seat from participation.

## Controller-first requirements

Every record includes legal actions, focus order, confirmation behavior, and focus-restoration expectations.

One pressed event may cause at most one authoritative commit. Merely moving focus cannot commit a decision. Private acknowledgement and irreversible public choices require explicit boundaries.

The complete local path remains possible without accounts, phones, Companion devices, remote services, or internet access.

## Caption and transcript rules

Each record supports subtitles and full captions as design targets, with no more than two displayed lines and a provisional maximum of 42 characters per line where language permits.

Critical information also exists outside captions. Public governed lines may enter transcript and replay. Controlled-private material does not.

These are preproduction targets, not accessibility-compliance or human-readability claims.

## High Water pair

`DH-UI-008` and `DH-UI-009` are deliberately separate:

1. the first preserves the committed before-state, deterministic transformation, changed-category summary, and skip-equivalent presentation;
2. the second presents the transformed playable geography and currently legal public actions.

High Water may not be reduced to a visual overlay or cinematic that hides changed routes, objectives, forms, resources, encounters, or ending eligibility.

## Offline review renderer

Generate a deterministic standalone HTML review file:

```text
python tools/render_shared_screen_storyboards.py --output /tmp/drowned_harbor_storyboards.html
```

The renderer:

- uses only Python standard-library modules;
- requires no network access;
- embeds no JavaScript, external stylesheets, remote images, fonts, or tracking;
- sorts by stable storyboard ID;
- displays the canonical storyboard identity;
- produces review wireframes, not runtime screenshots or approved UI.

Generated HTML is temporary review output and is not committed by the workflow.

## Validation

Run:

```text
python tools/validate_shared_screen_storyboards.py --identity
python tools/test_validate_shared_screen_storyboards.py
python tools/test_render_shared_screen_storyboards.py
```

Validation checks include:

- exact manifest and record fields;
- all 22 required IDs;
- globally unique IDs;
- all required categories;
- source-path resolution;
- known cross-media traceability IDs;
- controller action identity and ordering;
- confirmation boundaries;
- caption and transcript rules;
- persistent critical text;
- stable-seat preservation;
- private-shield and authority-transfer boundaries;
- High Water transition/board pairing;
- production-status protection.

The mutation suite proves rejection of representative defects. It does not prove the absence of all defects or replace human review.

## Human review still required

Later exact-build review must address:

- television-distance readability;
- eight-seat identification;
- controller focus and restoration;
- confirmation comprehension;
- private-shield leakage;
- caption pacing and enlargement;
- transcript usability;
- High Water before/after comprehension;
- Tidebound and Restless identity continuity;
- mixed-ending attribution clarity;
- audio, voice, animation, and visual masking;
- household pacing, tension, fairness, and comprehension.

## Prohibited interpretations

This package does not authorize or prove:

- a production Drowned Harbor package or catalog entry;
- Godot scenes, resources, scripts, or provider registration;
- final UI layout, camera, art, typography, animation, captions, audio, or controller behavior;
- a remote-admission service;
- security or privacy certification;
- accessibility compliance;
- human usability, fun, balance, readability, or comprehension;
- final branding for Terror Turn or The Underteller.
