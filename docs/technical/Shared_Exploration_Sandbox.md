# Shared Exploration Sandbox

## Responsibilities

- PlayerInputRouter: translates semantic movement/interact actions into per-device input state.
- PawnRegistry and PawnState: own seat-to-pawn identity, reconnect persistence, input vectors, speed, and deterministic bounds.
- ExplorationPawn: renders color, Roman numeral, and seat-count pattern while applying CharacterBody2D movement and collision.
- ExplorationRoom: owns the authored 1800×1000 walkable room, passage, obstacles, spawn points, and static collision.
- SharedCameraPolicy: calculates group framing, bounded zoom, and separation policy without scene dependencies.
- SharedCameraCoordinator: smoothly applies policy targets to one Camera2D.
- InteractionResolver and InteractionCoordinator: discover focus, queue requests, and arbitrate one winner per prop per physics tick.
- SandboxInteractable: implements the deterministic gate and clue-pedestal state changes.
- ExplorationDiagnostics: presents ownership, position, input, camera, focus, and reservation state behind a toggle.

## Movement and ownership

Each active seat produces one pawn. Presentation never chooses ownership from a device ID. The registry binds the seat's current device to its existing pawn; a reserved seat retains its pawn with input disabled. Reconnection updates the binding without moving or recreating the pawn.

Input vectors are normalized before applying a constant 210 world-unit-per-second speed. CharacterBody2D handles authored static collision, then room bounds clamp the pawn center as a final deterministic safety rule. Joining after launch uses the seat's indexed spawn point.

## Shared camera and extreme separation

The camera frames all pawn positions with 260×190 logical units of padding and clamps zoom from 0.60 to 1.35. Position and zoom approach targets exponentially so results are frame-rate independent. A future reduced-motion option can set policy targets immediately.

Maximum pair distance controls separation:

- Up to 620 units: normal.
- 620–820 units: visible edge warning; outward movement beyond the soft radius is reduced to 35%.
- Beyond 820 units: regroup warning; further outward movement is blocked while inward movement remains unrestricted.

This milestone never splits the screen or silently teleports a pawn.

## Interactions

The iron gate and clue pedestal expose the same focus and interaction contract. The closest enabled prop within 86 units receives focus. If several seats request the same prop in one physics tick, the lowest seat number wins. Different props resolve independently. Results are authored state toggles only—no cards, inventory, events, or turn economy.

## Bottom HUD safe-area policy

Interaction and status messages occupy a dedicated panel to the left of the protected-reset panel. Both regions are recalculated from the active 0–48 px safe margin, remain inset by another 10 logical pixels, and never overlap. Status text has a constrained width, wraps to at most two lines, clips to its panel, and uses an ellipsis when additional content cannot fit. Automated layout assertions cover the minimum, default, and maximum safe-frame settings; display scaling continues from the 960×540 logical viewport.

## Controls

- Move: left stick, D-pad, WASD, or arrow keys.
- Interact: controller A or keyboard E.
- Diagnostics: controller X or keyboard T.
- Join: controller A or keyboard J.
- Protected reset/return to title: hold controller Y or keyboard R for 1.5 seconds.
- Safe frame: controller LB/RB or keyboard -/+.
