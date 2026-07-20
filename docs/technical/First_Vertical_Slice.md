# First Vertical Slice

## Lifecycle

`VerticalSliceCoordinator` validates transitions across title, lobby, confirmation, briefing, active stages, terminal resolution, and ending. Confirm advances the player-facing route; cancel at the ending returns to title. During active play, the exploration sandbox reuses the coordinator-owned board, rules, Director, role, companion, and pawn references rather than constructing competing authorities.

The five authored stages are Threshold, Council, Reckoning, Afterlife, and Ending. They demonstrate event chaining and a public prompt, archive reveal and public vote, card/inventory/check/Director flow, defeated-to-Restless continuation, and mixed public outcome resolution.

## Atomicity and replay

Initialization validates manifest/content/reference/seat combinations into candidate authorities before commit. Each stage records BoardState, RulesSession, DirectorRuntime, and RoleSession snapshots before execution and restores all four if an operation rejects. Snapshot restore first builds a complete candidate coordinator, validates every nested snapshot, then commits. Malformed input leaves the existing coordinator unchanged.

Canonical JSON key ordering produces SHA-256 authority and public-history digests. The bounded simulation runs seeds 4706, 9017, and 22031 for every supported seat count and compares two independent executions per fixture.

## Input and diagnostics

Controllers remain primary; keyboard actions mirror join, confirm, cancel, movement, interaction, and diagnostics. The normal route requires no mouse or companion. The diagnostics action exposes the previous input/display lab outside active play and the inherited exploration/board/rules/Director/social diagnostics during the tale.

## Companion boundary

`CompanionBridge` is optional. Room creation, host-approved stable-seat claims, reconnect, filtered projections, revision checks, request IDs, and exactly-once acknowledgements are unchanged. Closing or omitting the room cannot block native play.
