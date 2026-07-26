# Terror Turn *(working title)*

A controller-first, 1–8 player digital horror board-game adventure about surviving living storybook Tales, navigating shifting alliances, and staying meaningfully involved even after defeat.

> **Naming status:** `Terror Turn` and `The Underteller` are provisional names pending the legal, storefront, domain, and common-law review tracked by issue #7. The repository remains `SteadyEddieSC/Tales-of-Terror` until that review is complete.

## Elevator pitch

**One sentence:** Terror Turn is a shared-screen horror board game where 1–8 players explore a living storybook world, make dangerous group and private choices, survive a mid-story **Terror Turn**, and may change sides, transform, or return in an afterlife role instead of being eliminated.

**Expanded pitch:** Friends gather around one television and enter an authored horror **Tale** hosted by **The Underteller**, an undead master of ceremonies who introduces the story, reacts to public choices, and presents the ending. Players explore a shifting **Living Board**, collect clues and items, face deterministic checks and events, and decide when to cooperate, bargain, conceal information, or pursue a private objective. The rule-based Director adjusts authored pacing within strict limits, while transformations, betrayals, third factions, and Restless afterlife forms keep the group involved until the final scene.

## What exists today

This repository contains a functional **internal vertical slice**, not a finished game.

The current runtime proves a complete controller-first route through one small authored Tale:

1. title and setup;
2. a 1–8 stable-seat local lobby;
3. mode confirmation and a Tale Library;
4. public briefing;
5. controller-owned private reveal ceremonies;
6. explicit player-owned interactions through the Tale;
7. a deterministic ending with mixed outcomes;
8. rematch or return to title.

The current production build includes foundations for:

- local shared-screen controller and keyboard play;
- stable seats that retain roles, inventory, state, and ownership through disconnect and reconnect;
- smooth shared exploration mapped onto an authoritative Living Board;
- deterministic turns, cards, events, checks, and board mutations;
- an authored, rule-based Dread Director with bounded pacing and recovery behavior;
- cooperative, betrayal, faction, transformation, and Restless afterlife systems;
- public, seat-private, faction-private, and controlled-private information boundaries;
- optional browser companion devices through a local development prototype;
- controller-first Tale selection, private reveals, replay-safe actions, and automated 1–8-seat playthrough evidence;
- Windows and Linux internal exports, including Linux validation relevant to Batocera.

### What the current build is not

The current build is not a content-complete game, public demo, commercial release, balance-certified experience, deployed online service, or finished campaign. Its visuals and content are primarily foundation and vertical-slice material.

Automated tests establish deterministic mechanical behavior, privacy boundaries, package identity, export integrity, and deadlock resistance. **Automation is not human evidence** for fun, tension, fairness, comprehension, physical-controller behavior, living-room television readability, accessibility compliance, household networking, remote-device behavior, or privacy certification.

## Current production Tale: Lantern House

**Lantern House remains the sole production Tale.**

It is a deliberately modest vertical slice used to prove that the project’s major systems can operate together. Players enter an iron threshold, reveal an archive, make public route and courage decisions, gain and play a card, experience a bounded Director response, and may continue through a Restless action after defeat before the ending resolves.

Lantern House is an integration route, not the final standard for story volume, art, balance, atmosphere, encounter variety, or replayability.

## What the finished game is aiming for

The target game is a replayable digital horror-board-game platform built around multiple authored settings and rule variants rather than one endlessly repeated scenario.

The intended experience includes:

- **multiple Tales** with distinct boards, mysteries, threats, roles, factions, transformations, items, hazards, and endings;
- **Chronicle Campaigns** that connect several Tales while remembering selected consequences;
- standalone Tales for a complete single-session story;
- shorter **Quick Fright** sessions;
- cooperative, hidden-betrayal, one-versus-many, outbreak, mystery, rival-team, and survival structures;
- a Living Board that can reveal, flood, burn, collapse, rotate, split, or otherwise change during play;
- a signature **Terror Turn** where the board, objective, allegiance, or player form changes in a memorable authored reversal;
- meaningful defeat states through **Restless** roles such as witnesses, wraiths, guardians, monster minions, or replacement investigators;
- optional private companion devices that enhance hidden information without being required to play;
- presentation profiles for **Spooky**, **Grim**, and **Gore & Dread**, with equivalent gameplay rules;
- an original modern storybook-horror look with expressive outlines, painterly materials, dramatic lighting, and readable living-room silhouettes;
- Windows and Linux first, followed later by additional living-room and companion platforms after the local game is proven.

The finished game should feel like opening a dangerous illustrated board game that can remember what the group did, turn allies against one another, and let the dead keep influencing the story.

## Story mode: Tales

A **Tale** is the project’s main story-mode unit: a self-contained authored horror adventure with its own location, premise, board, stages, encounters, social structure, transformation rules, ending logic, dialogue, visual language, sound direction, and accessibility presentation.

A Tale can be played in several ways depending on its authored support:

- **Standalone Tale** — one complete story in a single session;
- **Chronicle Campaign** — linked Tales with selected persistent consequences;
- **Quick Fright** — a shorter authored route;
- **Betrayal** — one or more hidden loyalties may be revealed;
- **Hunted** — one player may become the Horror;
- **Outbreak** — defeated or transformed players may join a growing third faction;
- **Mystery, Rival Teams, or Last Light** — Tale-specific structures with different objectives and endings.

The same Tale does not have to support every mode. Unsupported seat counts or social layouts must use an authored safe fallback rather than producing a broken or nonsensical game.

### How a Tale session should feel

A typical session is intended to flow like this:

1. players join stable seats with controllers;
2. the group chooses a Tale and supported mode;
3. The Underteller presents the premise and public objective;
4. private roles, motives, or information are revealed safely;
5. the group explores the board, resolves events, uses items, and makes public or private decisions;
6. the Director adjusts authored pressure without reading hidden information;
7. a Terror Turn may transform the board, loyalties, objectives, or player forms;
8. defeated players continue through an authored Restless or transformed role when supported;
9. the final choice resolves several possible winners, losses, escapes, transformations, or partial outcomes;
10. The Underteller delivers an epilogue based on what actually happened.

## Future Tale in design: Drowned Harbor

**Drowned Harbor is not a production Tale.** It is the first deeply developed future-Tale design package and the current visual, narrative, audio, music, voice, accessibility, UI, and interaction-trace test case for the authoring pipeline.

At an impossible low tide, a drowned coastal town rises from black tidal mud. Travelers cross a broken causeway toward a Bellhouse, Salt Market, lifeboat shed, flooded archive, and distant lighthouse. The town’s leaders once wrecked ships and used a ledger-and-bell ritual to erase the harbor from memory, but one missing name left the ritual incomplete. As the sea returns, the group must recover the truth, decide whom to trust, survive the **High Water Terror Turn**, and choose whether the harbor is sealed, released, raised, abandoned, or remembered.

Its planned stages are:

1. **Low Tide Arrival**
2. **Bellhouse Ledger**
3. **Lighthouse Council**
4. **High Water**
5. **Last Light**

Drowned Harbor currently exists as governed design material plus an export-excluded development-isolation manifest under `game/tests/`. It is not selectable from the normal Tale Library, has no production provider or Tale package, contains no final assets, and is not included in ordinary playable exports.

## The Underteller and the Director

**The Underteller** is the fictional host and interface voice. He introduces Tales, frames choices, acknowledges public consequences, recaps connected chapters, and delivers epilogues. He is not intended to secretly decide the rules.

The **Director** is the underlying authored pacing system. It begins as local, deterministic, and explainable—not as a cloud language model. It can adjust legal event weights, clues, scarcity, spawn timing, music, lighting, and hints within a Tale’s declared limits. It cannot inspect unrevealed roles, private objectives, hidden targets, private messages, or pending private transformations.

## Design pillars

1. **Board game first** — choices and state must remain understandable and reproducible.
2. **Horror is social** — tension comes from the group as well as the monsters.
3. **No player becomes irrelevant** — defeat should change participation, not end it.
4. **Every chapter tells a memorable story** — mechanics serve an authored arc.
5. **Readable on a living-room television** — silhouettes, symbols, text, and focus must remain clear.
6. **Private devices are optional** — they may improve hidden information but cannot be required.
7. **Systems before content volume** — reusable foundations come before a large Tale catalog.
8. **Quality over speed** — major claims require the right automated and human evidence.

## Development and production boundaries

- Godot **4.7.1-stable**, typed GDScript, Compatibility renderer.
- 960×540 logical world viewport with 16:9 output and scalable high-resolution UI.
- Windows and Linux first; Batocera is validated through Linux builds.
- Native Godot authority owns gameplay in the current architecture.
- The production Tale catalog contains exactly one entry: Lantern House.
- Test-only synthetic or prototype content must remain under export-excluded paths.
- Production Cloudflare deployment, accounts, matchmaking, campaign persistence, full remote play, and security certification remain deferred.
- Issue #39 remains the authority for future human household and remote playtest evidence.
- Issue #44 remains open for real Companion dependency remediation; the known audit may not be suppressed or represented as green.

## Repository map

- `game/` — Godot project and production runtime
- `game/tests/` — export-excluded automated tests, fixtures, and isolated prototype proofs
- `docs/gdd/` — canonical living Game Design Document
- `docs/tales/` — governed Tale design and authoring packages
- `docs/technical/` — architecture, contracts, tooling, and isolation rules
- `docs/preproduction/` — P0.x package records, schemas, and cross-media traceability
- `docs/decisions/` — design and architecture decisions
- `docs/playtests/` — automated evidence and carefully labeled human-test records
- `art/` and `audio/` — source and exports when approved
- `web/companion/` — accessible browser companion prototype
- `services/room-service/` — ephemeral Cloudflare-compatible room coordinator
- `tools/` — validators, generators, packaging tools, and regression suites

## Validation

GitHub Actions currently checks:

- repository integrity and formatting;
- Godot import, smoke, standalone, simulation, replay, privacy, Tale, and deadlock tests;
- GDScript linting and canonical formatting;
- Windows and Linux portable internal builds;
- Tale package, catalog, provider, and export boundaries;
- preproduction package, dialogue, media, accessibility, authoring, storyboard, interaction, and prototype-authorization contracts;
- Companion service and browser behavior.

The Companion workflow intentionally remains red while issue #44’s dependency vulnerability is unresolved. This is a tracked security gate, not a reason to weaken or suppress the audit.

## Documentation and licensing

Markdown is canonical for Git history. Polished snapshots may be generated at meaningful milestones, but source-of-truth changes belong in the repository.

The repository is public, but no final reuse license has been selected. The intended direction is source-available and noncommercial rather than an OSI open-source license. See `LICENSE-DECISION.md`.
