# First Vertical Slice

## Lifecycle

`VerticalSliceCoordinator` validates transitions across title, lobby, confirmation, briefing, active stages, terminal resolution, and ending. Confirm advances the player-facing route; cancel at the ending returns to title. During active play, the exploration sandbox reuses the coordinator-owned board, rules, Director, role, companion, and pawn references rather than constructing competing authorities.

The five authored stages are Threshold, Council, Reckoning, Afterlife, and Ending. They demonstrate event chaining and a public prompt, archive reveal and public vote, card/inventory/check/Director flow, defeated-to-Restless continuation, and mixed public outcome resolution.

## Atomicity and replay

Initialization validates manifest/content/reference/seat combinations into candidate authorities before commit. A player stage creates one private stage-start checkpoint before its first operation. That checkpoint remains unchanged across prompt and vote waits and contains the stable-seat roster, pawn registry, board, rules, Director, roles, stage/operation indices, ordered stage history, and coordinator-owned Director decision/application evidence. Success appends one stage-history entry and clears the checkpoint. Any later rejection restores the entire checkpoint, clears the transaction, and leaves no prompt, vote, card, board, Director, role, pawn, or progression residue. The automated fixture path uses the same transaction machinery.

Snapshot schema version 2 has an exact top-level key set. In addition to the existing seat, board, rules, Director, and role snapshots, it includes `PawnRegistry` snapshot version 1, Director application evidence, and any active stage transaction. Pawn rows contain only stable seat number, device association, identity, connection state, bounded world position, bounded input vector, and nearby interactable ID. They never contain nodes, input objects, browser identity, tokens, capabilities, or companion-private payloads.

`PawnRegistry.restore_snapshot()` validates exact keys, unique seats/devices, seat/device/identity/connection consistency, finite movement vectors, room bounds and walls, roster equality, and duplicate/unknown pawns before replacing its private registry. Coordinator restore also requires BoardState occupancy and the board copy embedded in RulesSession to agree with positions and with each other.

Coordinator restore accepts only coherent lifecycle/progression combinations. Pre-session states have no session authorities and use stage `-1`, operation `0`, no pause, no history, and no transaction. Boot/title requires every seat to be unassigned; lobby may contain a validated stable-seat roster; confirmation requires a non-empty roster. Seat rows permit only stable unassigned, active, or reserved states with unique identities and active devices. Briefing has initialized authorities but no completed stages. Active snapshots require a bounded current stage/operation, exactly one ordered history row per completed authored stage, and a transaction iff execution is suspended after operation zero. Terminal and ending snapshots require every authored stage, operation zero, terminal rules state, and Director evidence. Pause is active-tale-only. Every nested authority is restored into detached candidates before the current session is touched.

Rematch and restore are two-phase replacements. Candidate manifest/content and all candidate authorities are built and validated while the current ending or open-room session remains intact. After validation succeeds, the old companion room is closed and its claims, pending clients, acknowledgement cache, sequence/history, join code, and transport state are discarded; only then are clean candidate authorities committed. Rematch retains the authored stable-seat roster and returns to briefing. Candidate failure changes neither lifecycle nor any authority or room state.

Canonical JSON key ordering produces SHA-256 authority and public-history digests. The bounded simulation runs seeds 4706, 9017, and 22031 for every supported seat count and compares two independent executions per fixture.

## Manifest references and mode policy

Manifest version 1 uses exact schemas for supported seats, terminal, ending, rematch, companion, and deterministic fixture policies. The five stage IDs and their entry/completion conditions are ordered and fixed for this bounded slice. Event/card/prompt/vote references resolve through `LanternHouseRulesContent`; check IDs and effect bundles use small explicit registries. Role selectors must identify authored roles whose referenced transition trigger or action tag is compatible.

Only the manifest's default and fallback modes are selectable. The default is used whenever its player-count policy supports the roster. Its declared fallback must match the manifest fallback and may be selected only for a player count unsupported by the default. Other valid `SocialContent` modes are deliberately unavailable to this release and reject before authority construction.

## Input and diagnostics

Controllers remain primary; keyboard actions mirror join, confirm, cancel, movement, interaction, and diagnostics. The normal route requires no mouse or companion. The diagnostics action exposes the previous input/display lab outside active play and the inherited exploration/board/rules/Director/social diagnostics during the tale.

## Companion boundary

`CompanionBridge` is optional. Room creation, host-approved stable-seat claims, reconnect, filtered projections, revision checks, request IDs, and exactly-once acknowledgements are unchanged. Closing or omitting the room cannot block native play.
