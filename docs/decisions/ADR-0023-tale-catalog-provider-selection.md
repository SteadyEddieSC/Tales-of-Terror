# ADR-0023: Closed Tale catalog, provider registry, and stable-ID selection

**Status:** Accepted for v0.1.5

## Context

The v0.1.4 package proves one reusable Tale envelope, but the coordinator still selected its package path and directly constructed Lantern House content classes. Adding another reviewed Tale at that seam would require generic runtime edits and risk partial initialization or stable-ID branching.

## Decision

Introduce one versioned `tale_catalog` schema-v1 repository contract and one static `TaleProviderRegistry`. The catalog binds stable IDs to exact package, display, provider, and source identities. The registry—not JSON—owns reviewed constructors. `VerticalSliceCoordinator` selects a catalog entry by stable ID and commits session authorities only after catalog, provider, package, manifest, content, mode, and session candidates all validate.

Catalog/package provenance remains presentation and build evidence, not gameplay state. Production contains only Lantern House. Synthetic multi-entry proof remains in export-excluded tests.

## Consequences

- Future reviewed Tales can use the same catalog/selection/coordinator seam without arbitrary execution or Tale-ID branches.
- Invalid selection retains the prior valid selection and authority state atomically.
- A catalog edit alone cannot authorize new content; a separate design/content review and static provider registration remain mandatory.
- The accepted Lantern House route, digests, saves, reports, RNG, companions, reset, rematch, and replay results remain unchanged.
