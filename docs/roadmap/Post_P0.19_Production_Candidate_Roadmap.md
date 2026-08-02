# Post-P0.19 Drowned Harbor Production-Candidate Roadmap

**Version:** 1.2
**Status:** P0.22 alpha.2 planning active; alpha.2 runtime blocked
**Reconciled protected-main baseline:** `85b77d5216472afdb4abb7598917d5052eed180a`
**Working title status:** Terror Turn and The Underteller remain provisional pending issue #7

## 1. Current decision

The isolated prototype stream, P0.20 reconciliation, P0.21 production
architecture, and `v0.2.0-alpha.1` developer-only production scaffold are
complete.

P0.22 is the sole active release. It defines the exact end-to-end graybox route,
closed machine contract, validation, and inactive alpha.2 implementation issue.
It creates no gameplay runtime and does not activate alpha.2.

## 2. Current production boundary

- Playable internal version: `v0.1.9`.
- Sole normal/default Tale: `lantern_house_vertical_slice`.
- Drowned Harbor alpha.1 exists only behind explicit developer admission.
- Drowned Harbor is absent from the normal Tale Library and ordinary exports.
- Alpha.1 merge: issue #100 / PR #101 /
  `85b77d5216472afdb4abb7598917d5052eed180a`.
- P0.21 architecture merge: issue #98 / PR #99 /
  `4efdd76efdf2aa34823dae5d3624a3dca3f0a349`.

## 3. Routing policy

Release Management owns planning contracts, schemas, validators, workflows,
status succession, issue activation, exact-head review, promotion, merge, and
closure.

Codex is used only when substantial local Godot implementation, repeated
import/test/export cycles, Windows-specific execution, filesystem-heavy work, or
asset handling is required. Codex must never activate, mark ready, merge, close,
or create a successor release.

## 4. Governed release sequence

### P0.21 — Production Architecture & Tale-Compilation Contract

**State:** completed
**Issue/PR:** #98 / #99
**Merge:** `4efdd76efdf2aa34823dae5d3624a3dca3f0a349`

Defines authority ownership, compilation boundaries, package/provider admission,
persistence, privacy, export isolation, and blocked implementation stages.

### v0.2.0-alpha.1 — Production Tale Scaffold

**State:** completed internal runtime scaffold
**Issue/PR:** #100 / #101
**Merge:** `85b77d5216472afdb4abb7598917d5052eed180a`

Provides the native developer-only scaffold, version-1 package/scenario/snapshot,
fail-closed restore and exactly-once behavior, cleanup, and ordinary-export
exclusion. It is not normally playable.

### P0.22 — Alpha.2 Graybox Route Contract & Implementation Plan

**State:** active planning
**Issue:** #102
**Owner:** Release Management; Codex not required

Delivers:

- exact eight-stage route and seven transitions;
- movement, Bellhouse, Council, High Water, Last Light, ending, epilogue, and
  cleanup authority rules;
- save/restore/migration/replay requirements at every boundary;
- exactly-once Council and High Water identities;
- 1–8-seat bounded safe routes and deadlock requirements;
- privacy and public-only Director input boundaries;
- closed contract/schema, validator, mutations, and workflow;
- inactive implementation-ready alpha.2 issue definition.

Exit: one exact candidate head passes independent review. No runtime issue is
activated by P0.22.

### v0.2.0-alpha.2 — End-to-End Graybox

**State:** `planned_blocked`
**GitHub issue:** none
**Recommended owner:** Codex at Very High effort after separate authorization

Implement one complete placeholder-art route:

1. Low Tide Arrival;
2. Bellhouse Ledger;
3. Lighthouse Council;
4. High Water;
5. Last Light;
6. ending resolution;
7. epilogue attribution;
8. rematch/title cleanup.

Exit: deterministic completion for seats 1–8 without runtime dependence on
authoring references or prototype fixtures.

### v0.2.0-alpha.3 — Systems & Replayability

**State:** `planned_blocked`

Add roles, private objectives, Bellmarked/Tidebound paths, factions, betrayal,
items, events, hazards, rescue, Restless continuation, Director variation,
multiple endings, reconnect/replay matrices, and repeated-session coverage.

### v0.2.0-beta — Presentation & Content Integration

**State:** `planned_blocked`

Add reviewed shared-screen UI, controller glyphs, board camera, production media,
animation, SFX/music/narration strategy, localization, captions, persistent text,
reduced motion, screenshots, overflow checks, and asset provenance.

### v0.2.0-rc — Hardening & Distribution Readiness

**State:** `planned_blocked`

Complete install/upgrade/migration/reset/rollback/uninstall, performance and
long-session automation, dependency/security review, Companion decision,
packaging, licensing, attribution, naming/storefront gates, support matrix,
release notes, and the issue #39 evidence decision.

## 5. Production invariants

- Lantern House remains the sole normal/default Tale.
- Drowned Harbor remains developer-only until separately promoted.
- Authoring references and prototype fixtures are never runtime inputs.
- Stable-seat identity survives disconnect, surrogate control, return,
  transformation, defeat, and continuation.
- Shared output never exposes private terms or desirability hints.
- Director inputs are public or explicitly authorized aggregates only.
- Rejected actions remain state-and-RNG no-ops.
- Save migration is explicit and versioned or fails closed.
- Ordinary exports exclude Drowned Harbor until separately authorized.
- Companion remains optional and local-development-oriented.
- Automation is not human evidence or certification.
- Issue #39 remains the human-evidence authority.
- Issue #7 remains the naming gate.
- PR #32 remains unrelated.

## 6. Immediate next action

Complete P0.22 on one exact candidate head. After merge, the owner may separately
authorize `v0.2.0-alpha.2 — Drowned Harbor End-to-End Graybox`. No alpha.2 GitHub issue, branch, or Codex prompt is created by this roadmap.
