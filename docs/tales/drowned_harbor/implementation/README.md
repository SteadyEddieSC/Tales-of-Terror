# Drowned Harbor Implementation Planning

This directory contains governance for a possible future isolated Drowned Harbor prototype.

It does **not** contain a runtime Tale package, scene, script, resource, provider, catalog entry, imported asset, localization package, input map, Companion endpoint, or playable export.

## Current status

- Tale status: `design_only`
- Decision: conditional authorization in principle
- Execution: blocked pending explicit user reopening
- Parent issue: #79
- Child implementation issues: #80–#86
- Production Tale: `lantern_house_vertical_slice`
- Production catalog change authorized: no
- Runtime changes in P0.12: no
- Human evidence claimed: no

## Authoritative files

- `docs/technical/Prototype_Authorization_and_Isolation_Contract_v1.md`
- `docs/preproduction/prototype_authorization_schema_v1.json`
- `docs/tales/drowned_harbor/implementation/drowned_harbor_prototype_authorization_v1.json`
- `docs/preproduction/P0.12_Implementation_Issue_Set.md`
- `docs/preproduction/P0.12_Release_Summary.md`

## Unlock rule

No child issue may begin until P0.12 is merged, the user explicitly reopens local/Codex implementation work, a clean branch is created from current protected `main`, the exact child issue is intentionally unblocked, and production/catalog/export boundaries are reverified.

Issue #39 remains the authority for human playtesting. Issue #44 remains the authority for the Companion dependency vulnerability and may not be suppressed or reinterpreted.
