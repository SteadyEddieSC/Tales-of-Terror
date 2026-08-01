# Post-P0.19 Drowned Harbor Production-Candidate Roadmap

**Version:** 1.0
**Status:** Planning authority; no successor implementation issue activated
**Reconciled protected-main baseline:** `836716b6857323f36abcc4728ee05e01d31cd843`
**Working title status:** Terror Turn and The Underteller remain provisional pending issue #7

## 1. Decision

The P0.13–P0.19 isolated-prototype program is complete. Further test-only shells would provide diminishing value compared with integrating the proven contracts into a real Tale.

The recommended direction is a staged **v0.2.0 Drowned Harbor production-candidate stream**, beginning with a bounded architecture and compilation contract. This roadmap authorizes planning only. It does not activate P0.21, create production authority, register Drowned Harbor, or authorize Codex implementation.

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

P0.19 adds aggregate automation and export exclusion. Drowned Harbor remains test-only, production-unregistered, absent from the normal Tale Library, and excluded from ordinary exports.

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

## 4. Planned release sequence

No stage below is active merely because it appears in this roadmap.

### P0.21 — Production Architecture & Tale-Compilation Contract

**Type:** documentation, schemas, validators, implementation issue set
**Recommended owner:** Release Management; Codex not expected

Deliver:

- authoritative mapping from authoring-reference data to production Tale package/runtime structures;
- ownership boundaries for stage state, reducer/event authority, private projection, Director inputs, and presentation;
- production package identity and versioning rules;
- hidden internal registration strategy that does not expose an incomplete Tale in the normal library;
- save, restore, migration, replay, and exactly-once rules;
- asset, localization, and provenance compilation rules;
- bounded child issues for alpha.1 through release candidate;
- explicit rollback and removal path.

Exit: implementation-ready contract and separately blocked runtime issues. No production registration.

### v0.2.0-alpha.1 — Production Tale Scaffold

**Type:** runtime implementation
**Recommended owner:** Codex for implementation, Release Management for governance

Deliver:

- production Drowned Harbor package skeleton;
- provider implementation behind an internal development gate;
- production stage graph and state identities;
- reducer/event scaffolding;
- save/restore and migration envelope;
- deterministic package/catalog/provider tests;
- no test-fixture authority in the production path.

Exit: runtime can enter and leave the hidden Drowned Harbor scaffold through production architecture while Lantern House remains the normal default.

### v0.2.0-alpha.2 — End-to-End Graybox

Deliver one complete placeholder-art route:

1. Low Tide Arrival;
2. Bellhouse Ledger;
3. Lighthouse Council;
4. High Water;
5. Last Light;
6. ending and epilogue;
7. rematch/title cleanup.

Include production movement, stage transitions, Council decision authority, transformation, ending resolution, and failure recovery.

Exit: a deterministic session can finish without Drowned Harbor test fixtures or prototype shells.

### v0.2.0-alpha.3 — Systems & Replayability

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

### v0.2.0 Release Candidate — Hardening & Distribution Readiness

Deliver:

- clean install, upgrade, migration, reset, and uninstall behavior;
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
- Private devices remain optional.
- Stable-seat identity survives disconnect, reconnect, control-source change, transformation, defeat, and continuation.
- Shared output never exposes private terms or desirability hints.
- Automation is not human, accessibility, privacy/security certification, fun, fairness, balance, television-readability, or production-readiness evidence.
- Issue #39 remains the human-evidence authority.
- Issue #7 remains the public-branding gate.

## 7. Immediate next action

Complete P0.20 and review it on one exact candidate head. After P0.20 merges, the project owner may separately authorize **P0.21 — Production Architecture & Tale-Compilation Contract**.

No runtime Codex prompt is needed during P0.20. Codex becomes appropriate at v0.2.0-alpha.1 or earlier only when P0.21 identifies a genuinely local implementation task.
