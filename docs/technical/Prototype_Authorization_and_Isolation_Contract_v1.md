# Prototype Authorization and Isolation Contract v1

## Purpose

This contract governs whether preproduction material may advance into a bounded runtime prototype without being mistaken for a production Tale, release candidate, public promise, or substitute for human validation.

P0.12 applies this contract to Drowned Harbor. It does not implement Drowned Harbor.

## Current decision

Drowned Harbor receives **conditional authorization in principle for a future isolated prototype**, while **runtime execution remains blocked**.

The conditional authorization becomes executable only after every unlock gate in the machine-readable decision is satisfied. Until then, planning, documentation, GitHub issues, validators, schemas, and workflow checks are permitted; runtime scenes, scripts, resources, packages, providers, input maps, Companion endpoints, imported production assets, and playable exports are prohibited.

## Required isolation

A future prototype must remain outside the production Tale inventory and normal Tale-selection path.

The following production authorities must remain unchanged unless a later, separately reviewed production-authorization release explicitly changes them:

- `game/data/tales/tale_catalog_v1.json`;
- the default Tale identity;
- the reviewed provider registry and provider set;
- the production package digest and source ledger;
- normal Tale Library presentation;
- production export and portable-bundle contents.

Lantern House remains the sole production Tale. Drowned Harbor may not appear as locked content, coming-soon content, selectable content, store content, marketing content, or an implicit release promise.

## Development-only identity

Any future prototype identity must be unmistakably synthetic and development-only. It must:

1. require an explicit development-only entry path;
2. fail closed when that entry path or required fixture is absent;
3. remain unavailable to normal production startup and Tale selection;
4. avoid production Tale IDs, package IDs, provider IDs, display keys, and catalog records;
5. remain excluded from ordinary production and portable exports;
6. contain no credentials, URLs, telemetry, upload path, or external service dependency;
7. preserve exact source and result revisions for deterministic evidence.

## Authorized future slice

After unlock, the first isolated prototype is limited to the following responsibilities:

- a dev-only isolation boundary;
- deterministic synthetic source-state and projection fixtures;
- Low-Tide shared-screen shell for `DH-UI-003` / `DH-IS-003`;
- Bellhouse decision and invalid-action recovery for `DH-UI-004`, `DH-IS-004`, `DH-UI-019`, and `DH-IS-019`;
- controlled-private neutral shield and handoff proof for `DH-UI-007`, `DH-IS-007`, `DH-UI-016`, and `DH-IS-016`;
- deterministic High Water transition and transformed-board proof for `DH-UI-008`, `DH-IS-008`, `DH-UI-009`, and `DH-IS-009`;
- automated privacy, replay, deadlock, catalog-integrity, and export-exclusion evidence.

The slice is a technical and interaction proof. It is not a complete Tale, vertical slice, playtest build, production package, or content-complete demonstration.

## Stable-seat and privacy requirements

Every future prototype path must preserve the stable seat rather than creating a replacement character, bot character, fresh seat, healing, reroll, restored inventory, objective reset, or spectator demotion.

Public projections may contain only authoritative public state. Controlled-private data must:

1. enter only after the neutral shared shield commits;
2. be delivered only to the authorized private surface abstraction;
3. remain absent from public display, public audio, captions, transcript, replay, diagnostics, mirroring, seat summaries, and public history;
4. clear before shared projection, authority transfer, or public audio resumes;
5. commit nothing when the private surface is unavailable, disconnected, stale, expired, or unauthorized.

No privacy or security certification is implied by automated checks.

## Determinism and recovery

Authoritative prototype actions must validate actor authority, source revision, legal action, route or target, and confirmation state before mutation.

Committed actions must:

- reduce deterministically;
- emit the governed event key exactly once where the P0.11 trace requires it;
- produce idempotent public and private reprojections;
- preserve source and result revision identity;
- avoid raw account or controller identity in player-facing output.

Rejected actions must mutate no authoritative state, consume no RNG, leak no private state, reset no stable seat, and return focus to the preserved legal decision or a deterministic recovery destination.

## Presentation requirements

The prototype must preserve the P0.10 storyboard obligations for layout regions, privacy surface, confirmation pattern, captions, persistent text, transcript exclusion, stable-seat identity, and focus restoration.

Placeholder presentation must follow the original-first and visual-language policies. Dark and dreary presentation is permitted; a continuous muddy brown, gray, or low-value wash that collapses timber, mud, slate, water, canvas, brass, clothing, and interface into one range is not.

Placeholder art, audio, or generated material receives no production approval through prototype use.

## Evidence boundary

Automated checks may establish deterministic behavior, schema conformance, privacy exclusions, catalog integrity, export exclusion, replay equivalence, and deadlock resistance.

They do not establish:

- physical-controller behavior;
- television readability;
- accessibility compliance or suitability;
- privacy or security certification;
- household or remote playtest results;
- fun, pacing, tension, fairness, balance, comprehension, or emotional impact.

Issue #39 remains the authority for human playtesting. Issue #44 remains the authority for the Companion dependency vulnerability and may not be suppressed, waived, or reinterpreted by prototype work.

## Unlock gates

Runtime execution remains blocked until all of the following are true:

1. P0.12 is merged to protected `main`.
2. The user explicitly reopens local/Codex implementation work.
3. The implementation branch begins from the then-current protected-main SHA.
4. The exact issue being implemented remains open and blocked status is intentionally removed or superseded.
5. Production catalog, provider, package, default Tale, and normal Tale Library boundaries remain unchanged.
6. Required automated checks are defined before merge.
7. No unresolved change attempts to suppress issue #44 or claim issue #39 evidence.

## Promotion boundary

A future isolated prototype does not authorize production promotion. Production authorization requires a separate release that explicitly reviews:

- Tale package and provider identity;
- production catalog and Tale Library changes;
- production assets and licenses;
- localization and final narrative packaging;
- input, controller, display, privacy, accessibility, performance, and save compatibility;
- human playtest evidence;
- release, legal-name, storefront, and marketing readiness.
