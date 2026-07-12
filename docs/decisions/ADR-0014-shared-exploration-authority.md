# ADR-0014: Shared exploration ownership, camera, and interaction authority

- **Status:** Accepted
- **Date:** July 12, 2026

## Context

The first shared-world sandbox must support up to eight local pawns without binding reusable gameplay rules to transient controller IDs or presentation nodes. One shared camera must remain readable when players separate, and simultaneous interactions need a deterministic result.

## Decision

PawnRegistry maps stable seat numbers to persistent PawnState models. Device IDs are replaceable control bindings owned by the seat/input adapters; disconnecting reserves the model and pawn instead of transferring it. ExplorationPawn is a collision-aware runtime view of that model.

SharedCameraPolicy performs deterministic framing and separation calculations. SharedCameraCoordinator applies smoothing. Beyond the soft separation distance, outward movement receives resistance and an edge warning. Beyond the hard threshold, further outward movement is blocked and a regroup prompt is shown; inward movement is never resisted. Split screen is not introduced.

InteractionResolver chooses nearby focus deterministically. Requests targeting the same interactable in one physics tick resolve to the lowest seat number, while requests for different interactables may both succeed.

## Consequences

Pawn ownership survives device ID changes and can later accept companion identities. Camera math and interaction arbitration are headlessly testable. Extreme separation is visible and reversible rather than silently relocating a pawn. The temporary lowest-seat tie-breaker is predictable but may later be replaced by authored initiative or turn rules.
