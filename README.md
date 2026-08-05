# Terror Turn *(working title)*

A controller-first, 1–8 player digital horror board-game adventure about surviving living storybook Tales, navigating shifting alliances, and staying meaningfully involved even after defeat.

> **Naming status:** `Terror Turn` and `The Underteller` remain provisional pending the legal and common-law review tracked by issue #7. The repository remains `SteadyEddieSC/Tales-of-Terror` until that gate is resolved.

## Current project status

This repository contains a functional **internal vertical slice**, a completed isolated future-Tale prototype program, a developer-only Drowned Harbor Alpha.3 runtime, and completed metadata-only Drowned Harbor visual, presentation, and UX-planning authorities. It is not a finished game, public demo, commercial release, deployed online service, or content-complete campaign.

- **Normal playable version:** `v0.1.9`
- **Sole production/default Tale:** `lantern_house_vertical_slice` — Lantern House
- **Status-reconciliation baseline:** `22b43893b7726e5c5bea1078aced1cf11e08049f`
- **Latest completed runtime release:** `v0.2.0-alpha.3` — issue #108 / PR #109
- **Completed visual baseline release:** `DH-VBL-001` — issue #110 / PR #113
- **Completed High Water presentation registration:** `DH-PRESENT-REG-001` / `DH-PRESENT-001` — issue #114 / PR #115
- **Completed presentation-family registration:** `DH-PRESENT-REG-002` / `DH-PRESENT-FAMILY-001` — issue #118 / PR #119
- **Completed UX advisory registration:** `DH-UX-REG-001` / `DH-UX-001` — issue #120 / PR #124
- **Current status reconciliation:** issue #125; documentation and governance only
- **Next release:** unselected and not authorized; blocked on rights/provenance evidence and an explicit activation decision
- **Human-evidence issue #39:** deferred and still authoritative
- **Naming issue #7:** open
- **Unrelated Dependabot PR #32:** not part of feature releases

Lantern House remains the sole normal/default Tale. Drowned Harbor remains developer-only and is not ordinarily playable. No visual image, archive, editable source, production art, runtime art, UX implementation, or rights resolution was admitted by the completed planning releases.

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

Reusable production foundations include:

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

The P0.1–P0.19 program established the design package and isolated high-risk prototype proofs. P0.21 established production architecture; Alpha.1 created a production scaffold; P0.22 and Alpha.2 created the complete end-to-end graybox route; P0.23 established the systems/replayability contract; Alpha.3 implemented the developer-only systems runtime; and the completed visual, presentation-family, and UX advisory releases registered metadata-only planning authority.

Alpha.3 merged through issue #108 / PR #109 at protected-main SHA `cad70c5c8f0db1de7d557aff242cc8fe3610361b`. Its candidate source head was `08fdbe8b52a66fc44a98bdd27878554c5478aef1`.

Alpha.3 includes:

- Cooperative play for seats 1–8;
- Hidden Betrayer for seats 3–8 with deterministic Cooperative fallback below three seats;
- Outbreak for seats 2–8 with Tidebound conversion only after High Water;
- six Living roles;
- six Living, five Bellmarked, and four Tidebound objective families;
- Bell-Witness, Lifeboat Survivor, Lighthouse Guardian, and Drowned Guide continuation forms;
- 12 items, 12 cards, eight resources, 12 hazards, 19 encounters, and seven endings;
- version-3 package, scenario, provider, and snapshot authority;
- explicit snapshot-v2 to snapshot-v3 migration or fail-closed restore;
- stable-seat reconnect and surrogate continuity;
- public/aggregate-only Director inputs and deterministic anti-repeat selection;
- a minimum 126-run repeated-session matrix;
- permanent ordinary-export exclusion.

The completed planning authorities add:

- `DH-VBL-001` — recognized preproduction visual baseline;
- `DH-CB-002` — truthful external candidate register with unresolved source facts preserved;
- `DH-VCB-001` — board-production conversion authority and shared-board-master requirements;
- `DH-PRESENT-001` — accepted external High Water presentation-hook storyboard reference;
- `DH-PRESENT-002` and `DH-PRESENT-003` — qualified Last Light and ending/epilogue storyboard references;
- `DH-PRESENT-FAMILY-001` — presentation-family consistency assessment with conversion readiness `not_ready`;
- `DH-UX-001` — accepted external shared-screen UX advisory with required corrections;
- exact Tide, connector, ownership, privacy, layout-hypothesis, provenance, and evidence boundaries;
- no visual or UX candidate creation or promotion;
- no image or archive in Git history and no public GitHub Release asset authorization.

`DH-UX-001` establishes planning direction for six layout modes, 1–8 stable-seat continuity, focus/preview/confirmation/authority-owned commit semantics, public-only transcript and replay, neutral private shielding, stage-by-stage UX flows, and issue #39 evidence plans. Its coordinates, tile sizes, drawer dimensions, type sizes, prompts, and microcopy remain advisory hypotheses rather than implementation or evidence.

Drowned Harbor remains:

- developer-only and explicitly admitted;
- unregistered in the normal Tale catalog and central provider registry;
- absent from the normal Tale Library and startup/fallback paths;
- excluded from ordinary Windows and Linux exports;
- without final visual assets, production presentation, human playtest approval, or shipping authorization.

### Drowned Harbor premise

At an impossible low tide, a drowned coastal town rises from black tidal mud. Travelers cross a broken causeway toward a Bellhouse, Salt Market, lifeboat shed, flooded archive, and distant lighthouse. The town’s leaders once wrecked ships and used a ledger-and-bell ritual to erase the harbor from memory, but one missing name left the ritual incomplete. As the sea returns, the group must recover the truth, decide whom to trust, survive the **High Water Terror Turn**, and choose whether the harbor is sealed, released, raised, abandoned, or remembered.

Its authored stages are:

1. **Low Tide Arrival**
2. **Bellhouse Ledger**
3. **Lighthouse Council**
4. **High Water**
5. **Last Light**

## Story mode: Tales

A **Tale** is a self-contained authored horror adventure with its own location, board, stages, encounters, roles, social structure, transformation rules, ending logic, dialogue, visual language, sound direction, and accessibility presentation. A Tale may support standalone, Chronicle, Quick Fright, cooperative, betrayal, hunted, outbreak, mystery, rival-team, or survival structures. Unsupported seat counts or social layouts must use an authored safe fallback rather than producing a broken session.

## Development sequence

1. **P0.20 — Post-Prototype Reconciliation:** completed.
2. **P0.21 — Production Architecture & Tale Compilation:** completed, PR #99.
3. **v0.2.0-alpha.1 — Production Tale Scaffold:** completed, PR #101.
4. **P0.22 — Alpha.2 Route Contract:** completed, PR #103.
5. **v0.2.0-alpha.2 — End-to-End Graybox:** completed, PR #105.
6. **P0.23 — Alpha.3 Systems & Replayability Contract:** completed, issue #106 / PR #107.
7. **v0.2.0-alpha.3 — Systems & Replayability:** completed developer-only runtime, issue #108 / PR #109.
8. **Post-Alpha.3 status reconciliation:** completed, issue #111 / PR #112.
9. **DH-VBL-001 — Visual Baseline Registration & Board Production Conversion Brief 01:** completed metadata-only planning release, issue #110 / PR #113.
10. **DH-PRESENT-REG-001 — High Water Presentation Study Metadata Registration:** completed metadata-only planning release, issue #114 / PR #115.
11. **Post-DH-PRESENT-001 status reconciliation:** completed, issue #116 / PR #117.
12. **DH-PRESENT-REG-002 — Last Light, Ending & Presentation-Family Registration:** completed metadata-only planning release, issue #118 / PR #119.
13. **DH-UX-REG-001 — Shared-Screen UX Advisory Registration:** completed metadata-only planning release, issue #120 / PR #124.
14. **Post-DH-UX-001 status reconciliation:** issue #125; documentation and governance only.
15. **Next bounded release:** unselected; rights/provenance evidence and explicit activation are required.
16. **v0.2.0-beta — Presentation & Content Integration:** future and blocked.
17. **v0.2.0-rc — Hardening & Distribution Readiness:** future and blocked.

The completed planning releases do not authorize source art, runtime art, Godot asset integration, UX implementation, candidate promotion, public distribution, rights resolution, or substantial Codex implementation. The accepted UX advisory remains planning-only.

## Development routing

Release Coordination owns live GitHub reconciliation, issue and release activation, architecture, exact-head review, CI diagnosis, bounded GitHub-native corrections, guarded merges, and post-merge verification.

Codex should be used only after a separately authorized release genuinely requires substantial local multi-file implementation, Godot editor work, repeated local build/debug cycles, Windows-specific execution, filesystem exploration, or binary/asset handling.

No implementation release begins without:

- an explicit active issue;
- an exact protected-main baseline;
- one bounded branch and draft PR;
- declared paths and exclusions;
- exact validation expectations;
- independent Release Coordination review.

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
- Test-only synthetic, prototype, and developer-only Drowned Harbor content remains export-excluded.
- The Companion development graph retains Wrangler `4.114.0`, Workers Types `5.20260722.1`, Miniflare `4.20260722.0`, and Sharp `0.35.2`.
- Reviewed exact npm overrides pin PostCSS `8.5.23` and Undici `7.29.0`; inherited validators fail closed on any override or lock drift.
- Production Cloudflare deployment, accounts, matchmaking, campaign persistence, full remote play, and security certification remain deferred.
- Issue #39 remains the authority for future human household and remote playtest evidence.

**Automation is not human evidence.** It establishes bounded deterministic behavior, privacy separation, package identity, export integrity, dependency audit state, and deadlock resistance. It does not establish fun, tension, fairness, comprehension, physical-controller behavior, television readability, accessibility compliance, household networking, remote-device behavior, privacy certification, security certification, production readiness, or shipping authorization.

## Repository map

- `game/` — Godot project and production runtime
- `game/tests/` — export-excluded tests, fixtures, prototypes, and developer-only proofs
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

GitHub Actions check repository integrity, Godot import and tests, deterministic simulations, replay and privacy behavior, GDScript quality, Windows/Linux portable builds, Tale package/catalog/provider boundaries, Drowned Harbor isolation and export exclusion, Alpha.1–3 contracts, inherited mutation suites, visual/presentation/UX-planning metadata boundaries, Companion audit/typecheck/tests/build/smoke, real local relay integration, and clean generated-output boundaries.

## Documentation and licensing

Markdown is canonical for Git history. Polished snapshots may be generated at meaningful milestones, but source-of-truth changes belong in the repository.

The repository is public, but no final reuse license has been selected. The intended direction is source-available and noncommercial rather than an OSI open-source license. See `LICENSE-DECISION.md`.
