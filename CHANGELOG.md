# Changelog

## v0.1.9 - Automated Playthrough & Deadlock Lab

- Added an export-excluded deterministic virtual-player lab that completes the accepted Lantern House route across 1–8 stable seats, four seeds, and five legal strategy profiles.
- Added paired replay-equivalence checks plus bounded stale, duplicate, wrong-seat, idle, disconnect/reconnect, reset, rematch, and mid-prompt restoration probes.
- Added privacy-safe failure reproduction records containing only bounded public lifecycle, interaction, seed, strategy, and digest data.
- Registered the lab as a permanent fail-closed Godot workflow step and raised the enforced first-party GDScript inventory from 99 to 100 files.
- Preserved all gameplay, Tale, package/catalog, role/faction, Director, Companion, snapshot, report-schema, and human-playtest boundaries; issue #44 and issue #39 remain open.

## v0.1.8 - Controlled Reveal & Shared-Screen Privacy Hardening

- Added a deterministic controller-first privacy ceremony between public briefing and ordinary Lantern House play: neutral shield, authorized stable seat, allowlisted private reveal, safe close, and public continuation.
- Kept RoleSession as the only private-data and acknowledgement authority while the presentation-only PrivateRevealFlow owns only phase, queue position, authorized seat, and reveal revision.
- Added wrong-seat, duplicate, cancel, Help, disconnect/reconnect, reset/rematch, restoration, 1–8 seat, full-route, GUT, and recursive privacy-canary coverage.
- Preserved the exact one-Tale catalog/package identities, roles and balance, gameplay/Director RNG, snapshots and report schemas, no-phone route, and unchanged Companion graph.
- Issue #44 remains open: the inherited Companion dependency audit still reports GHSA-f88m-g3jw-g9cj; this game-only release does not deploy or publicly release Companion services.

## v0.1.7 - Player-Owned Interaction Pass

- Replaced remaining repeated-confirm and automatic Lantern House progression with explicit stable-seat interaction windows for threshold choices, council voting, card play, courage checks, Director acknowledgement, Restless action/pass, and stage continuation.
- Added privacy-safe shared-screen projections for eligible, committed, pending, and owning seats while preserving existing RulesSession, BoardState, Director, and RoleSession authority.
- Added wrong-seat, paused, duplicate, stale, pass, RNG-invariance, full-route, and 1–8 seat deterministic coverage plus permanent CI/toolchain registration.
- Preserved the exact one-Tale catalog/package identities, story, balance, snapshots, report schema, Companion graph, and no-phone route.
- Issue #44 remains open: the unchanged Companion dependency graph retains GHSA-f88m-g3jw-g9cj; this game-only release does not deploy or publicly release Companion services.

## v0.1.6 - Controller-First Tale Library & Selection UX

- Added a controller-first Tale Library between mode confirmation and the public briefing, with D-pad/left-stick/keyboard focus, confirm, back, Help, and protected-reset behavior.
- Sourced name, briefing, objective, and supported seats from the validated catalog and governed localization projection; production still contains only Lantern House.
- Added atomic fail-closed preparation, briefing-back restoration, bounded internal-build guidance, immutable active-session selection, and export-excluded two-entry focus/selection coverage.
- Preserved the exact Tale catalog/package identities and every gameplay, replay, RNG, snapshot, report, stable-seat, no-phone, Companion, and portable-build boundary.
- Issue #44 remains open: the unchanged Companion dependency graph retains GHSA-f88m-g3jw-g9cj with three High and zero Critical findings; this game-only release does not deploy or publicly release Companion services.

## v0.1.5 - Tale Catalog, Selection & Runtime Provider Boundary

- Added one closed `tale_catalog` schema-v1 production catalog containing only the exact accepted Lantern House package and governed display/provider/source identities.
- Added static reviewed provider construction and bounded pre-session stable-ID selection; the generic coordinator no longer names Lantern House classes or package paths.
- Added deterministic offline catalog identity/validation, complete negative diagnostics, and export-excluded synthetic two-entry selection/provider/package/atomic-failure fixtures.
- Preserved all Lantern House replay digests, stable IDs, saves, schema-v2 reports, snapshots, RNG, companions, no-phone behavior, reset/rematch, dependencies, tools, and provisional branding.

## v0.1.4 - Reusable Tale Package & Authoring Validator

- Routed the accepted Lantern House vertical slice through one closed, versioned `tale` schema-v1 package that references the existing authority data without semantic expansion.
- Added deterministic canonical SHA-256 identity, exact inventory/compatibility/source-ledger output, reviewed referenced-JSON hashes, and build/runtime provenance.
- Added an offline source-located validator and 20 synthetic negative cases covering every required unsafe, unresolved, incompatible, orphaned, nondeterministic, and unsupported authoring class.
- Added runtime identity allowlisting, atomic fail-closed rejection, a seven-case golden replay matrix, and exact preservation of the inherited 24-case seed/seat digests.
- Preserved stable IDs, saves, schema-v2 reports, 1–8 seats, fallback, events, roles/factions/afterlife, endings, reset/rematch, companions, no-phone play, dependencies, tools, and provisional branding.

## v0.1.3 - Pilot Framework & Candidate Build

- Bumped the single internal release source to v0.1.3 without changing gameplay, balance, content, authority, companions, dependencies, toolchains, or provisional branding.
- Added a consent-based pilot kit with exact artifact verification, controller-first/no-phone setup, voluntary stop language, privacy rules, observation/recovery sheets, questionnaire, report-hash guidance, and evidence-return instructions.
- Added exact versioned pilot-session and findings-register schemas with committed blank defaults: all manual checks remain `not_tested`, route fields remain `not_observed`, human declarations remain false, and the findings register contains zero findings.
- Added offline exact-file evidence validation, frozen-candidate matching, traversal/unknown/private-data rejection, evidence-class integrity, deterministic normalization with source-file SHA-256 provenance, and deterministic human-judgment finding IDs/sorting.
- Expanded the strict Windows/Linux bundle allowlists only for bounded blank pilot materials and schemas; raw reports, private evidence, source tests, caches, and unrelated development files remain excluded.
- Completed the framework release with automated/headless Windows and Linux candidate-build support. No human pilot or manual validation occurred: all manual checks remain `not_tested`, route fields remain `not_observed`, declarations remain false, and findings remain empty.
- Deferred the real household or remote-observed pilot and findings triage to issue #39. That issue requires a fresh candidate from the then-current protected `main`; v0.1.3 does not keep ordinary development waiting for player availability.

## v0.1.2 - Portable Playtest Build & Session Bundle

- Added checksum-pinned Godot 4.7.1 Windows and Linux export presets and CI-only portable archives with exact allowlist/denylist validation, deterministic runtime and bundle-content identities, and privacy-bounded versioned manifests.
- Added relative offline launch helpers, facilitator/session documents, a fail-closed manual hardware-validation record that defaults to `not_tested`, and direct/native plus launcher smoke coverage.
- Added a presentation-only Help page for bounded internal build/support identity, with integrated regression proof that it leaves gameplay authority, snapshots, public history, reports, RNG, and companion boundaries unchanged.

## v0.1.1 - Playtest Readiness & Guided Session UX

- Added controller-first lifecycle guidance and a high-contrast, paged help/accessibility surface covering controls, current objective, prompt/vote progress, stable-seat reconnect, no-phone reveal, optional companions, protected reset, ending, and report export.
- Added an exact version-2, bounded, local-only playtest report with privacy-filtered public/aggregate observations, separate completion/disposition semantics, explicit non-overwriting JSON/Markdown export through a replaceable writer, and a fixed `user://playtest_exports` destination.
- Added interruption, privacy-negative, export, no-network, report-ordering, no-phone, optional-companion, and deterministic-invariance regressions plus a facilitator checklist, questionnaire, technical/privacy guides, and review evidence.

## v0.1.0 - First Vertical Slice

- Added a strict version-1 Lantern House scenario manifest and typed native coordinator that composes existing seat, exploration, board, rules, Director, social-role, and optional companion authorities without duplicating their mutable state.
- Added the controller-first title, stable-seat lobby, mode confirmation, briefing, active tale, deterministic terminal result, privacy-safe ending, rematch, and return-to-title route while retaining engineering labs for diagnostics.
- Added atomic initialization and restore, coordinator snapshots, canonical deterministic digests, 1–8-seat fallback coverage, afterlife continuation, optional exactly-once companion integration, focused GUT coverage, and a bounded 24-run multi-seed simulation.

## v0.0.9.2 - GDScript Quality Gate Cleanup

- Canonically formatted the explicit 67-file first-party GDScript inventory with pinned `gdformat` 4.5.0, then resolved the inherited 1,235 lint findings with bounded typed, behavior-preserving corrections and one focused role-projection regression.
- Converted `gdlint` and `gdformat --check` from informational baselines to fail-closed zero-finding CI gates over the unchanged inventory/exclusions, retained inspectable quality artifacts, and hardened repository validation against masking, source rewriting, or inventory drift.
- Preserved gameplay, public method names and signatures, native authority, deterministic RNG/state transitions, companion behavior/privacy, renderer, viewport, visual design, assets, dependencies, export, and deployment behavior. v0.1.0 remains blocked pending independent acceptance.

## v0.0.9.1 - Toolchain & Test Infrastructure Hardening

- Upgraded local Windows and Linux CI validation to checksum-pinned official Godot 4.7.1-stable while preserving the Compatibility renderer, 960×540 logical viewport, typed GDScript, and native gameplay authority.
- Vendored GUT 9.7.1 with its licenses and provenance, added five focused typed smoke/protocol/atomicity/privacy tests, retained every standalone test and deterministic simulation, and added JUnit artifact upload with failure propagation.
- Selected `gdtoolkit==4.5.0` in `requirements-dev.in` and committed its complete Python 3.11.9 dependency graph with exact versions and distribution hashes. CI installs with `--require-hashes`, runs `pip check`, and publishes `pip freeze --all`; the large pre-existing lint/format baseline remains informational and blocks v0.1.0 pending separately bounded cleanup.
- Corrected repository whitespace validation to inspect committed pull-request and main-push ranges while exempting only vendored GUT, and published losslessly optimized 720p, 1080p, and virtual/off-screen 4K review captures in the repository.

## v0.0.9 - Companion Room Prototype

- Added a typed transport-neutral Godot companion bridge, filtered public/seat/faction views, bounded versioned protocol, fake and WebSocket transports, stable-seat claims/reconnect, exactly-once authority routing, sanitized diagnostics, and deterministic 1–8-client privacy/authority simulations.
- Added a strict TypeScript Cloudflare-compatible ephemeral room coordinator plus an accessible responsive browser companion for join, approval, privacy reveal/obscure, legal action, acknowledgement, reconnect, and leave/clear flows.
- Added the Companion Room Lab, ADR-0019, protocol/service/browser/threat-model guides, pinned lockfile and CI, v0.0.9 release notes, and explicit deferred physical-device/network/security checks.

## v0.0.8 - Roles, Factions & Afterlife

- Added scene-independent deterministic social-role authority, stable-seat secrets, isolated role RNG, validated declarative factions/forms/modes/objectives/actions/transitions, atomic cross-authority proposals, snapshots, and mixed outcomes.
- Added public/seat/faction/diagnostics privacy contracts, recursive leak evaluation, authorized Director aggregates, controlled private reveal, meaningful Restless/guardian/replacement paths, Social Horror Lab evidence stages, comprehensive tests, and 157 deterministic 1–8 player simulations.
- Added ADR-0018 plus social architecture, schema, privacy, outcome, simulation, GDD, and release documentation.

## v0.0.7 - Dread Director

- Added a local deterministic authored pacing Director with read-only telemetry, isolated RNG, explainable scoring, fairness/mercy/cooldown/pressure guardrails, proposal authority boundaries, snapshots, and bounded audit history.
- Added Lantern House struggling, cruising, and stalled demonstrations; friendly safe-frame presentation; paged raw diagnostics; multi-seed simulation; ADR-0017; and Director schema, telemetry, technical, simulation, and release documentation.

## v0.0.6 - Turn, Event & Card Engine

- Added deterministic authoritative round, prompt, event, check, vote, card, inventory, consequence, history, and snapshot systems.
- Added declarative Lantern House rules content, replaceable host hooks, shared-screen rules HUD/diagnostics, comprehensive tests, ADR-0016, and schema/technical/release documentation.

## v0.0.5 — Living Board Engine

- Added a validated authored board definition mapping the exploration room into five named spaces and five connectors.
- Added authoritative occupancy, reveal, hazard, feature, blocker, connector, revision, and mutation-history state.
- Added deterministic traversability, reachability, shortest-path, crossing, connectivity-impact, and simultaneous-arbitration queries.
- Added atomic living-board mutations and versioned JSON-compatible in-memory snapshot restoration.
- Added signal-driven board-debug presentation, expanded diagnostics, comprehensive regression tests, and pinned CI coverage.

## v0.0.4 — Shared Exploration Sandbox

- Added an authored collision-aware exploration room and one to eight seat-owned pawns.
- Added semantic per-device movement, two deterministic interactables, and reconnect-stable pawn ownership.
- Added reusable shared-camera framing with visible soft/hard separation policy.
- Added toggleable exploration diagnostics and comprehensive deterministic tests.
- Added pinned Godot 4.7 headless validation to pull-request CI.

## v0.0.3 — Visual Language & Asset Pipeline

- Replaced the engineering presentation with reusable storybook-horror theme resources and UI primitives.
- Added player identity through a color-vision-conscious palette, Roman numerals, and segmented stripe counts.
- Added status badges, focus and reconnect-warning treatments, a subtle diorama backdrop, and a fully visible input-transparent safe-area frame.
- Activated reviewed Git LFS patterns and documented normal Git, LFS, and GitHub Release boundaries.
- Added asset organization, naming, provenance, and automated policy validation.

## v0.0.2 — Input & Display Lab

- Added controller discovery and eight-seat assignment with stable reconnect reservations.
- Added semantic input actions and a keyboard development fallback.
- Added device, seat-state, and last-action diagnostics with protected reset.
- Added adjustable safe-area testing and documented 720p, 1080p, and 4K targets.
- Separated discovery, seat state, and presentation for later reuse.

## [Unreleased]

### Added
- Public repository foundation for the Terror Turn working-title direction.
- Canonical Markdown GDD and launch guide.
- Versioned v0.2 DOCX milestone exports in the downloadable foundation package.
- Godot 4.7 shell at a 960×540 logical viewport.
- Repository checks workflow, issue templates, security policy, and ADRs.

### Changed
- Replaced the previous working title with Terror Turn.
- Updated repository guidance for the existing public `SteadyEddieSC/Tales-of-Terror` repository.
- Deferred Git LFS activation until large source assets begin, targeted no later than v0.0.3.
