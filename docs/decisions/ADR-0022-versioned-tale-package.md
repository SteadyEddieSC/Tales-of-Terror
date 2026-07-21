# ADR-0022: Versioned repository-authored Tale package

**Status:** Accepted for v0.1.4

## Context

Lantern House already has validated board, rules, Director, social, and vertical-slice data, but the accepted scenario manifest alone is not a reusable package boundary with deterministic inventory, source traceability, governed text, or an offline authoring gate.

## Decision

Wrap the existing accepted inputs in one closed `tale` schema-v1 JSON envelope. The envelope references rather than replaces existing authority data, declares graph/compatibility/fallback/privacy/inventory/source contracts, and receives a canonical SHA-256 identity. The offline Python validator provides source-located diagnostics and the typed Godot runtime accepts only the reviewed allowlisted identity, verifies referenced JSON hashes, reuses existing validators, and compares instantiated inventory before authority construction.

Package provenance stays outside gameplay snapshots, reports, RNG, and authority decisions. Future supported identities require review and an explicit runtime allowlist update. Unknown fields, remote content, generated scripts, arbitrary evaluation, and untrusted packages fail closed.

## Consequences

- Lantern House proves one reusable package path without adding a second Tale or changing gameplay.
- Authoring mistakes reject deterministically before runtime mutation.
- Identity, inventory, compatibility, and source ledger reproduce offline and travel in build evidence.
- This is a repository authoring contract, not a public modding or backwards-compatibility promise.
