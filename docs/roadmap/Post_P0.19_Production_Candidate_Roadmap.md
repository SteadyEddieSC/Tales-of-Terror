# Post-P0.19 Drowned Harbor Production-Candidate Roadmap

**Version:** 1.4
**Status:** Alpha.3 developer-only runtime complete; protected-main reconciliation active
**Reconciled protected-main baseline:** `cad70c5c8f0db1de7d557aff242cc8fe3610361b`

## Current decision

P0.21, Alpha.1, P0.22, Alpha.2, P0.23, and `v0.2.0-alpha.3` are complete. Alpha.3 supplies developer-only systems and replayability authority; it does not make Drowned Harbor a normal production Tale.

Issue #111 is the sole active release. It reconciles the repository's current-state documentation from the actual Alpha.3 merge SHA. Issue #110 remains planning-only and blocked until issue #111 merges and protected `main` is reverified.

## Production boundary

- Normal playable version remains `v0.1.9`.
- Lantern House remains the sole normal/default Tale.
- Drowned Harbor Alpha.3 exists only behind explicit developer admission.
- Drowned Harbor remains absent from the normal Tale Library and ordinary Windows/Linux exports.
- Alpha.3 merged through issue #108 / PR #109 at `cad70c5c8f0db1de7d557aff242cc8fe3610361b`.
- Alpha.3 candidate source head was `08fdbe8b52a66fc44a98bdd27878554c5478aef1`.

## Governed sequence

- **P0.21 — Production Architecture:** completed, PR #99.
- **v0.2.0-alpha.1 — Production Tale Scaffold:** completed, PR #101.
- **P0.22 — Alpha.2 Route Contract:** completed, PR #103.
- **v0.2.0-alpha.2 — End-to-End Graybox:** completed, PR #105.
- **P0.23 — Alpha.3 Systems & Replayability Contract:** completed, issue #106 / PR #107.
- **v0.2.0-alpha.3 — Systems & Replayability:** completed developer-only runtime, issue #108 / PR #109.
- **Post-Alpha.3 status reconciliation:** active, issue #111.
- **DH-VBL-001 / issue #110 — Visual Baseline Registration & Board Production Conversion Brief 01:** `planned_blocked`; no branch, PR, source art, runtime art, or Codex task until explicit activation after issue #111.
- **v0.2.0-beta — Presentation & Content Integration:** `planned_blocked`.
- **v0.2.0-rc — Hardening & Distribution Readiness:** `planned_blocked`.

## Alpha.3 result

Alpha.3 governs Cooperative seats 1–8, Hidden Betrayer seats 3–8, and Outbreak seats 2–8; six roles; Living, Bellmarked, and Tidebound objectives; active continuation; 12 items; 12 cards; eight resources; 12 hazards; 19 encounters; rescue; bounded public-input Director variation; seven endings; snapshot v3 migration; and repeated-session replayability.

The Companion audit remediation uses reviewed exact npm overrides for PostCSS `8.5.23` and Undici `7.29.0`, while preserving Wrangler `4.114.0`, Workers Types `5.20260722.1`, Miniflare `4.20260722.0`, and Sharp `0.35.2`. The final Alpha.3 candidate passed every permanent exact-head workflow.

## Persistent invariants

Stable-seat identity, no-op rejection, four privacy classes, public-only Director inputs, explicit migration, bounded deterministic variation, authoring/runtime separation, developer-only admission, ordinary-export exclusion, human-evidence limits, issue #39, issue #7, and PR #32 remain unchanged.

Automation does not establish fun, balance, physical-controller behavior, television readability, accessibility compliance, privacy/security certification, production readiness, or shipping authorization.

## Immediate next action

1. Complete issue #111 on one exact ten-path candidate head.
2. Squash-merge it with an expected-head guard.
3. Reverify protected `main` from the resulting merge SHA.
4. Only then may Release Coordination activate issue #110 as a bounded documentation/schema/provenance planning release.

No source art, runtime art, Godot asset integration, or visual-candidate promotion is authorized by this roadmap.
