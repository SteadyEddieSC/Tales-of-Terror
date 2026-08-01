# Post-P0.19 Drowned Harbor Production-Candidate Roadmap

**Version:** 1.1
**Status:** P0.21 planning stage active; no runtime successor issue activated
**Reconciled protected-main baseline:** `58f6f4e4ece9bbdd5932216c87aacc064e48e05a`
**Working title status:** Terror Turn and The Underteller remain provisional pending issue #7

## 1. Decision

The P0.13–P0.19 isolated-prototype program and P0.20 reconciliation are complete. Further test-only shells would provide diminishing value compared with integrating the proven contracts into a real Tale.

The governed direction is a staged **v0.2.0 Drowned Harbor production-candidate stream**. P0.21 is the sole active planning release and defines the architecture and compilation boundary. It does not create production authority, register Drowned Harbor, expose it in the normal Tale Library, include it in ordinary exports, activate a runtime issue, or authorize Codex implementation.

## 2. Current baseline

### Production application

- Playable internal version: v0.1.9.
- Sole production/default Tale: `lantern_house_vertical_slice`.
- Controller-first 1–8 stable-seat local route.
- Deterministic gameplay authority, Director, roles/factions, Restless participation, private-information boundaries, optional local Companion prototype, and Windows/Linux internal exports.

### Drowned Harbor prototype

Drowned Harbor has governed design and media direction plus seven deterministic fixtures and four focused feature families:

- Low Tide presentation;
- Bellhouse decision and invalid-action recovery;
- controlled-private bargain and inherited-state handoff;
- High Water transformation and transformed-board presentation.

P0.19 added aggregate automation and export exclusion. Drowned Harbor remains test-only, production-unregistered, absent from the normal Tale Library, and excluded from ordinary exports.

### P0.21 planning authority

P0.21 defines:

- design-reference-to-production output mapping;
- ownership boundaries for stage state, reducer/event authority, private projection, Director inputs, RNG, and presentation;
- future package/provider/catalog identities without registering them;
- developer-only explicit admission rules;
- save, restore, migration, replay, exactly-once, reset, and rematch rules;
- asset, localization, provenance, fallback, rollback, and removal rules;
- blocked implementation issue definitions for later stages.

The machine-readable contract remains planning-only and is not a runtime input.

### Open gates

- Issue #7: professional naming clearance before public title commitment.
- Issue #39: deferred human household/remote evidence.
- PR #32: unrelated Dependabot action updates, outside this roadmap.

Issue #44 is complete and must not be described as open or intentionally red.

## 3. Routing policy

### Release Management chat

Use Release Management for:

- live GitHub reconciliation;
- issue and release activation;
- architecture and acceptance-criteria drafting;
- exact-head PR review;
- workflow and artifact diagnosis;
- bounded GitHub-native corrections;
- guarded squash merge and post-merge reconciliation.

### Codex

Use Codex only after a separately authorized issue requires substantial local work such as:

- production Godot scene/script implementation;
- broad multi-file runtime changes;
- repeated local Godot import, build, and debugging cycles;
- Windows-specific execution;
- asset import or binary handling;
- filesystem exploration unavailable through GitHub.

Codex must never activate, merge, or close the release. It returns a draft PR and exact candidate head to Release Management.

## 4. Governed release sequence

Only P0.21 is active. Every later stage is `planned_blocked`, has no GitHub issue, and requires separate authorization.

### P0.21 — Production Architecture & Tale-Compilation Contract

**State:** active planning
**Type:** documentation, schemas, validators, implementation issue definitions
**Owner:** Release Management; Codex not required

Deliver:

- authoritative mapping from authoring-reference data to production Tale package/runtime structures;
- ownership boundaries for stage state, reducer/event authority, private projection, Director inputs, RNG, and presentation;
- production package identity and versioning rules;
- hidden internal registration strategy that does not expose an incomplete Tale in the normal library;
- save, restore, migration, replay, and exactly-once rules;
- asset, localization, provenance, fallback, rollback, and removal rules;
- bounded blocked definitions for alpha.1 through release candidate;
- fail-closed machine contract, validators, and mutation tests.

Exit: implementation-ready contract and inactive stage definitions. No production registration.

### v0.2.0-alpha.1 — Production Tale Scaffold

**State:** planned blocked
**GitHub issue:** none
**Type:** runtime implementation
**Recommended owner:** Codex for implementation, Release Management for governance

Deliver:

- production Drowned Harbor package skeleton;
- static provider implementation behind a developer-only explicit gate;
- production stage graph and state identities;
- reducer/event scaffolding;
- save/restore and migration envelope;
- deterministic package/provider/admission tests;
- rollback/removal path;
- no test-fixture authority in the production path.

Exit: runtime can enter and leave the hidden Drowned Harbor scaffold through production architecture while Lantern House remains the normal default.

### v0.2.0-alpha.2 — End-to-End Graybox

**State:** planned blocked
**GitHub issue:** none

Deliver one complete placeholder-art route:

1. Low Tide Arrival;
2. Bellhouse Ledger;
3. Lighthouse Council;
4. High Water;
5. Last Light;
6. ending and epilogue;
7. rematch/title cleanup.

Include production movement, stage transitions, Council decision authority, transformation, ending resolution, failure recovery, save/restore, and replay equivalence.

Exit: a deterministic session can finish without Drowned Harbor test fixtures or prototype shells.

### v0.2.0-alpha.3 — Systems & Replayability

**State:** planned blocked
**GitHub issue:** none

Deliver:

- roles and private objectives;
- Bellmarked and Tidebound paths;
- factions, betrayal, and reveal logic;
- items, cards, events, hazards, and rescue;
- Restless forms and continued participation;
- Director pressure and recovery;
- 1–8-seat authored fallbacks;
- multiple endings and mixed attribution;
- save/restore, reconnect, replay, and repeated-session matrices.

Exit: content-complete graybox with meaningful route and outcome variation.

### v0.2.0-beta — Presentation & Content Integration

**State:** planned blocked
**GitHub issue:** none

Deliver:

- production shared-screen UI and controller glyphs;
- board camera and landmark readability;
- approved environment, character, item, card, icon, and transformation assets;
- animation and transition effects;
- SFX, adaptive music, and Underteller narration strategy;
- captions, transcript, persistent text, reduced-motion, and pseudolocalization;
- screenshot baselines and text-overflow checks across target resolutions;
- asset provenance and attribution completeness.

Exit: feature-complete internal beta with replaceable temporary media clearly labeled.

### v0.2.0-rc — Hardening & Distribution Readiness

**State:** planned blocked
**GitHub issue:** none

Deliver:

- clean install, upgrade, migration, reset, rollback, and uninstall behavior;
- deterministic regression, performance, memory, and long-session automation;
- dependency and security audit;
- privacy and Companion deployment decision;
- Windows/Linux packaging and launcher validation;
- license, third-party notices, and asset attribution;
- naming/storefront gate status;
- release notes, support matrix, known limitations, and rollback plan.

Exit: exact candidate suitable for a separate public-demo or internal-release decision. This roadmap itself makes no public-release claim.

## 5. Companion recommendation

Keep the Companion optional and local-network-oriented through the next production milestones. Do not add accounts, matchmaking, cloud persistence, analytics, or public deployment merely to support Drowned Harbor alpha work.

A later separate decision may choose:

- local-only optional Companion;
- supported remote room service;
- no Companion for the first public release.

## 6. Production invariants until separately changed

- Lantern House remains the sole normal production/default Tale.
- Drowned Harbor remains hidden or unregistered until a bounded release explicitly changes that state.
- Test fixtures and prototype shells never become production authority by path reuse.
- Authoring references are compilation inputs, never runtime inputs.
- Private devices remain optional.
- Stable-seat identity survives disconnect, reconnect, control-source change, transformation, defeat, and continuation.
- Shared output never exposes private terms or desirability hints.
- Rejected actions remain state-and-RNG no-ops.
- Save migration is explicit and versioned or fails closed.
- Automation is not human evidence and is not accessibility, privacy/security certification, fun, fairness, balance, television-readability, or production-readiness evidence.
- Issue #39 remains the human-evidence authority.
- Issue #7 remains the public-branding gate.

## 7. Immediate next action

Complete P0.21 on one exact candidate head and merge only after independent Release Management review and all applicable workflows pass.

After P0.21 merges, the project owner may separately authorize **v0.2.0-alpha.1 — Production Tale Scaffold**. No runtime Codex prompt is created until that separate authorization.
