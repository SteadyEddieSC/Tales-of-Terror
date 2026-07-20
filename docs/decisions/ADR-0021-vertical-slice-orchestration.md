# ADR-0021: Vertical-slice orchestration

**Status:** Accepted for v0.1.0

## Context

The reviewed input, exploration, board, rules, Director, social-role, and companion foundations previously appeared as separate engineering labs. The first vertical slice needs one lifecycle without creating a second gameplay authority or allowing scenario data to execute arbitrary code.

## Decision

Use a versioned validated JSON scenario manifest and one typed native `VerticalSliceCoordinator`. The coordinator owns one session-scoped reference to each existing authority, advances an explicit high-level lifecycle, and routes a small allowlist of bounded operations through public authority methods. It does not write internal authority fields, infer secrets, or give the companion relay authority.

Initialization constructs and validates candidate content and authorities before commit. Stage execution snapshots all authorities and restores them if any bounded operation rejects. Coordinator snapshots embed the existing authority snapshots plus lifecycle, manifest identity, stable-seat snapshot, stage index, and deterministic evidence history. Restore validates through candidate authorities before commit.

The lifecycle is `boot_title → lobby → confirmation → briefing → active_tale → terminal → ending`. Rematch retains the stable-seat roster but reconstructs every session authority. Return to title also clears seat bindings. The engineering labs remain available through the diagnostics action.

## Consequences

- Native Godot remains the sole gameplay authority.
- Scenario content is inspectable, bounded, deterministic, and free of script references.
- Same seed and ordered inputs can be replayed and compared with canonical SHA-256 digests.
- New authorities must expose validated public orchestration or snapshot methods before a future manifest may compose them.
- Campaign saves, cloud authority, production deployment, and arbitrary scenario scripting remain out of scope.
