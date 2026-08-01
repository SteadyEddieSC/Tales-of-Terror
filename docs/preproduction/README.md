# Preproduction and Production-Planning Index

**Status:** Internal design, prototype, and planning material
**Current package:** P0.21 — Production Architecture & Tale-Compilation Contract
**Protected-main baseline reconciled:** `58f6f4e4ece9bbdd5932216c87aacc064e48e05a`

## Current authorities

- [Current post-prototype status](post_prototype_status_v1.json)
- [P0.21 machine-readable compilation contract](drowned_harbor_production_compilation_contract_v1.json)
- [P0.21 closed contract schema](drowned_harbor_production_compilation_contract_schema_v1.json)
- [P0.21 production architecture contract](../technical/Drowned_Harbor_Production_Architecture_and_Compilation_Contract_v1.md)
- [P0.21 blocked implementation issue set](P0.21_Implementation_Issue_Set.md)
- [Post-P0.19 Production-Candidate Roadmap](../roadmap/Post_P0.19_Production_Candidate_Roadmap.md)
- [P0.21 Release Summary](P0.21_Release_Summary.md)
- [Drowned Harbor Design Bible](../tales/drowned_harbor/Drowned_Harbor_Design_Bible.md)
- [Seat Continuity and Multiplayer Admission Contract](../design/Seat_Continuity_and_Admission.md)
- [AI Media Production and Provenance Guide](../assets/AI_Media_Production_Guide.md)

## Historical authorities

- `preproduction_package_index_v1.json` is the frozen P0.1–P0.7 package contract created for P0.8. It is historical and remains byte-unchanged.
- [Post-v0.1.9 Preproduction Roadmap](../roadmap/Post_v0.1.9_Preproduction_Roadmap.md) is superseded as the active roadmap but retained as a historical planning record.
- P0.1–P0.20 release summaries remain the authoritative package-by-package history.
- [P0.20 Release Summary](P0.20_Release_Summary.md) records the completed reconciliation and decision pack.

## Completed package stream

- **P0.1–P0.8:** narrative, continuity, dialogue, visual, audio, music, voice, accessibility, package indexing, and cross-media traceability.
- **P0.9–P0.12:** Tale-authoring schema, shared-screen storyboards, interaction-state traceability, and isolated-prototype authorization.
- **P0.13–P0.16:** prototype isolation, deterministic fixtures, Low Tide shell, and Bellhouse/recovery.
- **P0.17–P0.19:** controlled-private shielding, High Water transformation, aggregate automation, and ordinary-export exclusion.
- **P0.20:** post-prototype reconciliation and production-candidate roadmap.

P0.19 completed issues #80–#86 and authorized no successor implementation issue. P0.20 merged through PR #97 at `58f6f4e4ece9bbdd5932216c87aacc064e48e05a`.

## Current P0.21 boundary

P0.21 defines how the design-only Drowned Harbor authoring package may later map into separately reviewed production authorities. The authoring reference remains a compilation input and never a runtime input.

P0.21 reserves future planning identities for `drowned_harbor` and `drowned_harbor_authorities_v1`, but creates no production package, provider registration, catalog entry, save schema, reducer, event, RNG stream, normal-library item, or ordinary export.

The later stages from v0.2.0-alpha.1 through release candidate are defined as `planned_blocked`, have no GitHub issue, and are not active.

## Current production boundary

Lantern House remains the sole production/default Tale. Drowned Harbor remains development-only, test-isolated, explicit-test-script-only, production-unregistered, absent from the normal Tale Library, and excluded from ordinary Windows/Linux exports.

Issue #44 is complete. Issue #39 remains the human-evidence authority. Issue #7 remains the naming gate. PR #32 remains unrelated.

## Routing

Release Management handles repository reconciliation, architecture, schemas, roadmap work, issue/PR governance, CI review, and bounded GitHub-native changes.

Codex is not required for P0.21. It is expected for substantial local Godot implementation only after a separately authorized v0.2.0-alpha.1 issue.

Automation is not human evidence.
