# Terror Turn *(working title)*

A controller-first, 1–8 player digital horror board-game adventure about surviving living storybook Tales, navigating shifting alliances, and staying meaningfully involved even after defeat.

> **Naming status:** `Terror Turn` and `The Underteller` remain provisional pending the legal and common-law review tracked by issue #7. The repository remains `SteadyEddieSC/Tales-of-Terror` until that gate is resolved.

## Current project status

This repository contains a functional **internal vertical slice**, a completed isolated future-Tale prototype program, and an active production-architecture planning contract. It is not a finished game, public demo, commercial release, deployed online service, or content-complete campaign.

- **Current playable version:** `v0.1.9`
- **Sole production/default Tale:** `lantern_house_vertical_slice` — Lantern House

Lantern House remains the sole production/default Tale.

- **Protected-main baseline for P0.21:** `58f6f4e4ece9bbdd5932216c87aacc064e48e05a`
- **Latest completed planning package:** P0.20 — Post-Prototype Reconciliation & Production Decision Pack
- **Current active package:** P0.21 — Production Architecture & Tale-Compilation Contract
- **Next runtime stage:** v0.2.0-alpha.1 — planned, blocked, and not active
- **Companion dependency security issue #44:** completed
- **Human-evidence issue #39:** deferred and still authoritative
- **Naming issue #7:** open
- **Unrelated Dependabot PR #32:** not part of feature releases

## Elevator pitch

**One sentence:** Terror Turn is a shared-screen horror board game where 1–8 players explore a living storybook world, make dangerous group and private choices, survive a mid-story **Terror Turn**, and may change sides, transform, or return in an afterlife role instead of being eliminated.

**Expanded pitch:** Friends gather around one television and enter an authored horror **Tale** hosted by **The Underteller**, an undead master of ceremonies who introduces the story, reacts to public choices, and presents the ending. Players explore a shifting **Living Board**, collect clues and items, face deterministic checks and events, and decide when to cooperate, bargain, conceal information, or pursue a private objective. A rule-based Director adjusts authored pacing within strict limits, while transformations, betrayals, third factions, and Restless afterlife forms keep the group involved until the final scene.

## What exists today

The current production runtime proves a complete controller-first route through Lantern House:

1. title and setup;
2. a 1–8 stable-seat local lobby;
3. mode confirmation and a Tale Library;
4. public briefing;
5. controller-owned private reveal ceremonies;
6. explicit player-owned interactions through the Tale;
7. deterministic mixed outcomes;
8. rematch or return to title.

The reusable production foundations include:

- local shared-screen controller and keyboard play;
- stable seats that retain roles, inventory, state, and ownership through disconnect and reconnect;
- an authoritative Living Board;
- deterministic turns, cards, events, checks, and board mutations;
- an authored, rule-based Dread Director with bounded pacing and recovery behavior;
- cooperative, betrayal, faction, transformation, and Restless afterlife systems;
- public, seat-private, faction-private, and controlled-private information boundaries;
- optional browser companion devices through a local development prototype;
- controller-first Tale selection, replay-safe actions, and automated 1–8-seat completion evidence;
- Windows and Linux internal exports, including Linux validation relevant to Batocera.

## Current production Tale: Lantern House

Lantern House remains the sole production Tale. It is an integration route used to prove that the project’s major systems work together, not the final standard for story volume, art, atmosphere, encounter variety, balance, or replayability.

## Future Tale in design: Drowned Harbor

**Drowned Harbor is not a production Tale and is not ordinarily playable.**

The P0.1–P0.19 program produced a deep governed design package and then proved selected high-risk interaction families under `game/tests/`:

- seven synthetic deterministic state/projection fixtures;
- Low Tide shared-screen presentation;
- Bellhouse decision and invalid-action recovery;
- controlled-private Harbor bargain and inherited-state handoff;
- High Water deterministic transformation and transformed-board presentation;
- aggregate cross-family deterministic automation;
- permanent Windows/Linux ordinary-export exclusion evidence.

The isolated prototype remains:

- development-only;
- explicit-test-script-only;
- unregistered in the production Tale catalog and provider;
- absent from the normal Tale Library;
- without production saves, reports, reducer authority, networking, or final assets;
- excluded from ordinary Windows and Linux exports.

P0.19 completed every authorized prototype child issue, #80 through #86. P0.20 reconciled that state and authorized only the next planning stage.

### Drowned Harbor premise

At an impossible low tide, a drowned coastal town rises from black tidal mud. Travelers cross a broken causeway toward a Bellhouse, Salt Market, lifeboat shed, flooded archive, and distant lighthouse. The town’s leaders once wrecked ships and used a ledger-and-bell ritual to erase the harbor from memory, but one missing name left the ritual incomplete. As the sea returns, the group must recover the truth, decide whom to trust, survive the **High Water Terror Turn**, and choose whether the harbor is sealed, released, raised, abandoned, or remembered.

Its planned stages remain:

1. **Low Tide Arrival**
2. **Bellhouse Ledger**
3. **Lighthouse Council**
4. **High Water**
5. **Last Light**

## Story mode: Tales

A **Tale** is a self-contained authored horror adventure with its own location, board, stages, encounters, roles, social structure, transformation rules, ending logic, dialogue, visual language, sound direction, and accessibility presentation. A Tale may support standalone, Chronicle, Quick Fright, cooperative, betrayal, hunted, outbreak, mystery, rival-team, or survival structures. Unsupported seat counts or social layouts must use an authored safe fallback rather than producing a broken session.

## Active P0.21 architecture contract

P0.21 defines the seam between Drowned Harbor’s design-only authoring reference and future production authorities. It does not compile, register, expose, or ship Drowned Harbor.

The contract establishes:

- authoring references as compilation inputs, never runtime inputs;
- separate reviewed outputs for scenario, board, rules/reducer, Director, social/private, localization, package, provider, catalog, migration, and validation;
- `RulesSession` ownership of stage progression and authoritative mutations;
- `BoardState` ownership of board authority;
- `RoleSession` ownership of social and private authority;
- named native-authority RNG streams;
- public and authorized aggregate Director inputs only;
- read-only presentation projections;
- state-and-RNG no-op rejection for invalid, stale, duplicate, wrong-seat, unavailable, or malformed actions;
- explicit versioned migration or fail-closed restore;
- developer-only explicit admission that cannot affect the normal Tale Library or ordinary exports;
- asset, localization, provenance, fallback, rollback, and removal rules.

The planning-only future identities are Tale ID `drowned_harbor`, provider ID `drowned_harbor_authorities_v1`, and package kind/schema `tale` / `1`. None is registered by P0.21.

See [P0.21 Production Architecture Contract](docs/technical/Drowned_Harbor_Production_Architecture_and_Compilation_Contract_v1.md), [machine-readable contract](docs/preproduction/drowned_harbor_production_compilation_contract_v1.json), and [blocked implementation issue set](docs/preproduction/P0.21_Implementation_Issue_Set.md).

## Next development direction

1. **P0.20** — completed reconciliation and production decision.
2. **P0.21** — active production architecture and Tale-compilation contract.
3. **v0.2.0-alpha.1** — planned blocked production Tale scaffold.
4. **v0.2.0-alpha.2** — planned blocked complete end-to-end graybox route.
5. **v0.2.0-alpha.3** — planned blocked systems and replayability.
6. **v0.2.0-beta** — planned blocked production presentation and content integration.
7. **v0.2.0-rc** — planned blocked hardening and distribution readiness.

Only P0.21 is active. Every runtime stage requires separate owner authorization and a fresh governed issue. See [Post-P0.19 Production-Candidate Roadmap](docs/roadmap/Post_P0.19_Production_Candidate_Roadmap.md).

## Development routing

The Release Management chat owns live GitHub reconciliation, issue and release activation, architecture, exact-head review, CI diagnosis, bounded GitHub-native corrections, guarded merges, and post-merge verification.

Codex is not required for P0.21. It should be used after a separately authorized runtime issue genuinely requires substantial local multi-file implementation, Godot editor work, repeated local build/debug cycles, Windows-specific execution, filesystem exploration, or binary/asset handling. v0.2.0-alpha.1 is expected to be the first such stage.

No runtime release begins without:

- an explicit active issue;
- an exact protected-main baseline;
- one bounded branch and draft PR;
- declared paths and exclusions;
- exact validation expectations;
- independent Release Management review.

## What the finished game is aiming for

The target is a replayable digital horror-board-game platform built around multiple authored settings and rule variants.

The intended experience includes:

- multiple Tales with distinct boards, mysteries, threats, roles, factions, transformations, items, hazards, and endings;
- standalone Tales and linked Chronicle Campaigns;
- shorter Quick Fright sessions;
- cooperative, hidden-betrayal, one-versus-many, outbreak, mystery, rival-team, and survival structures;
- a Living Board that can reveal, flood, burn, collapse, rotate, split, or otherwise change;
- a signature Terror Turn where the board, objective, allegiance, or player form changes;
- meaningful defeat states through Restless roles;
- optional private companion devices that are never required;
- Spooky, Grim, and Gore & Dread presentation profiles with mechanically equivalent rules;
- an original modern storybook-horror look readable on a living-room television.

## The Underteller and the Director

**The Underteller** is the fictional host and interface voice. He introduces Tales, frames choices, acknowledges public consequences, recaps connected chapters, and delivers epilogues. He does not secretly decide the rules.

The **Director** is the underlying authored pacing system. It begins local, deterministic, and explainable—not as a cloud language model. It may adjust legal event weights, clues, scarcity, spawn timing, music, lighting, and hints within a Tale’s declared limits. It may not inspect unrevealed roles, private objectives, hidden targets, private messages, or pending private transformations.

## Design pillars

1. **Board game first** — choices and state remain understandable and reproducible.
2. **Horror is social** — tension comes from the group as well as the monsters.
3. **No player becomes irrelevant** — defeat changes participation rather than ending it.
4. **Every chapter tells a memorable story** — mechanics serve an authored arc.
5. **Readable on a living-room television** — silhouettes, symbols, text, and focus remain clear.
6. **Private devices are optional** — they enhance hidden information but are not required.
7. **Systems before content volume** — reusable foundations come before a large Tale catalog.
8. **Quality over speed** — major claims require the right automated and human evidence.

## Technical and production boundaries

- Godot **4.7.1-stable**, typed GDScript, Compatibility renderer.
- 960×540 logical world viewport with 16:9 output and scalable UI.
- Windows and Linux first.
- Native Godot authority owns gameplay in the current architecture.
- The production Tale catalog contains exactly one entry: Lantern House.
- Test-only synthetic and prototype content remains under export-excluded paths.
- The supported Companion development dependency graph is Wrangler 4.114.0 → Miniflare 4.20260722.0 → Sharp 0.35.2, with Workers Types 5.20260722.1.
- Production Cloudflare deployment, accounts, matchmaking, campaign persistence, full remote play, and security certification remain deferred.
- Issue #39 remains the authority for future human household and remote playtest evidence.

**Automation is not human evidence.** It establishes bounded deterministic behavior, privacy separation, package identity, export integrity, and deadlock resistance. It does not establish fun, tension, fairness, comprehension, physical-controller behavior, television readability, accessibility compliance, household networking, remote-device behavior, privacy certification, security certification, or production readiness.

## Repository map

- `game/` — Godot project and production runtime
- `game/tests/` — export-excluded tests, fixtures, and isolated prototype proofs
- `docs/gdd/` — canonical living Game Design Document
- `docs/tales/` — governed Tale design and authoring packages
- `docs/technical/` — architecture, contracts, tooling, and isolation rules
- `docs/preproduction/` — P0.x package records, schemas, and current status
- `docs/roadmap/` — historical and current roadmaps
- `docs/decisions/` — design and architecture decisions
- `docs/playtests/` — automated evidence and carefully classified human records
- `art/` and `audio/` — source and exports when approved
- `web/companion/` — accessible browser companion prototype
- `services/room-service/` — ephemeral Cloudflare-compatible room coordinator
- `tools/` — validators, generators, packaging tools, and regression suites

## Validation

GitHub Actions checks repository integrity, Godot import and tests, deterministic simulations, replay and privacy behavior, GDScript quality, Windows/Linux portable builds, Tale package/catalog/provider boundaries, Drowned Harbor prototype isolation and export exclusion, preproduction contracts, P0.21 architecture/status succession, and Companion service/browser behavior.

## Documentation and licensing

Markdown is canonical for Git history. Polished snapshots may be generated at meaningful milestones, but source-of-truth changes belong in the repository.

The repository is public, but no final reuse license has been selected. The intended direction is source-available and noncommercial rather than an OSI open-source license. See `LICENSE-DECISION.md`.
