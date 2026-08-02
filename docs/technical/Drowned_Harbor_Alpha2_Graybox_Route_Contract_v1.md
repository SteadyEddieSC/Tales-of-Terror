# Drowned Harbor Alpha.2 Graybox Route Contract v1

**Release:** P0.22  
**Issue:** #102  
**Protected-main baseline:** `85b77d5216472afdb4abb7598917d5052eed180a`  
**Status:** Active planning contract; no alpha.2 runtime authority

## 1. Purpose

This contract defines the complete deterministic production route required for
`v0.2.0-alpha.2 — End-to-End Graybox` before substantial Godot implementation
begins. It turns the broad stage list into a closed route, ownership, persistence,
privacy, recovery, and validation contract.

P0.22 is planning only. It creates no gameplay runtime, scene, Tale package,
provider registration, catalog entry, normal Tale Library item, ordinary export,
asset, or public release. The machine-readable authority is
`docs/preproduction/drowned_harbor_alpha2_graybox_route_contract_v1.json`; its
schema is closed and fail-closed.

## 2. Starting authority

P0.22 starts from merged `v0.2.0-alpha.1` at
`85b77d5216472afdb4abb7598917d5052eed180a`.

Alpha.1 already proves:

- Tale ID `drowned_harbor`;
- scoped provider `drowned_harbor_authorities_v1`;
- package kind/schema `tale` / `1`;
- developer-only explicit admission;
- complete-candidate validation before authority commit;
- identity-first snapshot restore;
- named RNG ownership and exactly-once identity;
- state-and-RNG no-op rejection;
- cleanup to Lantern House;
- normal catalog/provider/navigation isolation;
- ordinary Windows/Linux export exclusion.

P0.22 does not change those runtime identities. It specifies the future version-2
graybox route and migration expectations.

## 3. Governed route

The route is linear, bounded, reachable, and terminal:

1. `low_tide_arrival_v1`
2. `bellhouse_ledger_v1`
3. `lighthouse_council_v1`
4. `high_water_v1`
5. `last_light_v1`
6. `ending_resolution_v1`
7. `epilogue_attribution_v1`
8. `rematch_title_cleanup_v1`

No stage may be skipped, entered from an undeclared predecessor, or left through
an undeclared transition. Every accepted transition creates a deterministic save
checkpoint. The final cleanup stage is terminal and has no outgoing transition.

## 4. Stage contracts

### Low Tide Arrival — `low_tide_arrival_v1`

- **Authority owner:** `rules_session`
- **Entry preconditions:** `validated_alpha2_package`, `active_stable_seats_1_to_8`, `board_at_causeway_entry`
- **Allowed intents:** `move_to_landmark`, `confirm_low_tide_arrival`
- **Target scopes:** `board_connector`, `public_stage`
- **Reducer outputs:** `pawn_positions`, `visited_landmarks`, `arrival_complete`
- **Events:** `low_tide_arrival_completed`
- **Save boundaries:** `stage_entry`, `after_each_accepted_movement`, `stage_complete`
- **Interruption:** `restore_current_stable_seat_and_pending_public_prompt`
- **Privacy projection:** `public_only`
- **Cleanup:** `retain_route_state_until_terminal_cleanup`
- **Bound:** at most `24` accepted actions.

### Bellhouse Ledger — `bellhouse_ledger_v1`

- **Authority owner:** `rules_session`
- **Entry preconditions:** `arrival_complete`, `bellhouse_reachable`
- **Allowed intents:** `inspect_ledger`, `commit_bellhouse_choice`, `recover_bellhouse_choice`
- **Target scopes:** `bellhouse_ledger`, `public_choice`
- **Reducer outputs:** `ledger_inspected`, `bellhouse_choice`, `recovery_state`
- **Events:** `bellhouse_choice_committed`, `bellhouse_recovery_applied`
- **Save boundaries:** `stage_entry`, `after_ledger_inspection`, `after_choice_commit`, `stage_complete`
- **Interruption:** `restore_committed_choice_or_reopen_uncommitted_prompt`
- **Privacy projection:** `public_with_empty_private_scaffold`
- **Cleanup:** `retain_choice_and_recovery_history_until_terminal_cleanup`
- **Bound:** at most `12` accepted actions.

### Lighthouse Council — `lighthouse_council_v1`

- **Authority owner:** `rules_session`
- **Entry preconditions:** `bellhouse_choice_committed`, `council_reachable`
- **Allowed intents:** `submit_council_commitment`, `resolve_council_commitment`
- **Target scopes:** `stable_seat`, `council_resolution`
- **Reducer outputs:** `seat_commitments`, `council_result`, `council_commitment_id`
- **Events:** `council_commitment_recorded`, `council_resolved`
- **Save boundaries:** `stage_entry`, `after_each_commitment`, `after_council_resolution`, `stage_complete`
- **Interruption:** `preserve_stable_seat_commitments_and_pending_eligible_seats`
- **Privacy projection:** `public_commitment_status_without_private_terms`
- **Cleanup:** `persist_exactly_once_commitment_identity_through_terminal_cleanup`
- **Bound:** at most `18` accepted actions.

### High Water — `high_water_v1`

- **Authority owner:** `rules_session`
- **Entry preconditions:** `council_resolved`, `high_water_not_applied`
- **Allowed intents:** `acknowledge_high_water`, `apply_high_water_transformation`
- **Target scopes:** `public_stage`, `board_state`, `stable_seat_forms`
- **Reducer outputs:** `tide_state`, `connector_mutations`, `transformed_forms`, `high_water_transformation_id`
- **Events:** `high_water_acknowledged`, `high_water_transformation_applied`
- **Save boundaries:** `stage_entry`, `before_transformation`, `after_transformation`, `stage_complete`
- **Interruption:** `resume_before_or_after_atomic_transformation_never_mid_commit`
- **Privacy projection:** `public_consequences_with_authorized_private_form_projection`
- **Cleanup:** `retain_transformation_identity_and resulting_state_until_terminal_cleanup`
- **Bound:** at most `8` accepted actions.

### Last Light — `last_light_v1`

- **Authority owner:** `rules_session`
- **Entry preconditions:** `high_water_applied`, `last_light_route_available`
- **Allowed intents:** `move_to_last_light_route`, `commit_last_light_action`, `resolve_last_light`
- **Target scopes:** `board_connector`, `public_stage`, `stable_seat`
- **Reducer outputs:** `last_light_positions`, `last_light_commitments`, `last_light_result`
- **Events:** `last_light_action_committed`, `last_light_resolved`
- **Save boundaries:** `stage_entry`, `after_each_accepted_movement`, `after_each_commitment`, `stage_complete`
- **Interruption:** `restore_positions_commitments_and_pending_public_prompt`
- **Privacy projection:** `public_route_status_without_hidden_desirability`
- **Cleanup:** `retain_last_light_result_until_attribution_complete`
- **Bound:** at most `24` accepted actions.

### Ending Resolution — `ending_resolution_v1`

- **Authority owner:** `rules_session`
- **Entry preconditions:** `last_light_resolved`, `ending_not_resolved`
- **Allowed intents:** `resolve_ending`
- **Target scopes:** `authoritative_session`
- **Reducer outputs:** `ending_id`, `ending_result`, `public_consequences`
- **Events:** `ending_resolved`
- **Save boundaries:** `stage_entry`, `after_ending_resolution`, `stage_complete`
- **Interruption:** `restore_resolved_ending_or_reopen_single_resolution_intent`
- **Privacy projection:** `public_ending_without_unrevealed_attribution_terms`
- **Cleanup:** `retain_ending_result_until_epilogue_acknowledged`
- **Bound:** at most `2` accepted actions.

### Epilogue Attribution — `epilogue_attribution_v1`

- **Authority owner:** `role_session`
- **Entry preconditions:** `ending_resolved`, `attribution_inputs_complete`
- **Allowed intents:** `resolve_epilogue_attribution`, `acknowledge_epilogue`
- **Target scopes:** `stable_seat`, `public_epilogue`
- **Reducer outputs:** `seat_attributions`, `public_epilogue`, `epilogue_acknowledged`
- **Events:** `epilogue_attribution_resolved`, `epilogue_acknowledged`
- **Save boundaries:** `stage_entry`, `after_attribution_resolution`, `after_epilogue_acknowledgement`, `stage_complete`
- **Interruption:** `preserve_private_attribution_authority_and_public_acknowledgement_state`
- **Privacy projection:** `authorized_seat_or_faction_terms_plus_public_epilogue`
- **Cleanup:** `retain_attribution_only_until terminal_cleanup_commit`
- **Bound:** at most `10` accepted actions.

### Rematch and Title Cleanup — `rematch_title_cleanup_v1`

- **Authority owner:** `session_coordinator`
- **Entry preconditions:** `epilogue_acknowledged`, `terminal_cleanup_not_committed`
- **Allowed intents:** `request_rematch`, `return_to_title`
- **Target scopes:** `scoped_session`
- **Reducer outputs:** `cleanup_complete`, `next_destination`
- **Events:** `drowned_harbor_session_cleared`
- **Save boundaries:** `stage_entry`, `before_cleanup`, `after_cleanup_terminal`
- **Interruption:** `repeat_idempotent_cleanup_until_no_scoped_authority_remains`
- **Privacy projection:** `public_cleanup_status_only`
- **Cleanup:** `clear_all_drowned_harbor_authorities_and_return_to_validated_destination`
- **Bound:** at most `2` accepted actions.

## 5. Transition and exactly-once rules

Seven transitions connect the eight stages. Each transition requires the source
stage to be complete and the target preconditions to validate before authority
changes.

Two identities are especially protected:

- `council_commitment_id` owns the resolved Lighthouse Council decision;
- `high_water_transformation_id` owns the atomic High Water transformation.

Both identities persist through save/restore and remain duplicate no-ops after
reload, reconnect, retry, or replay. High Water may restore before or after the
atomic transformation, never in a partially transformed state.

## 6. Movement, decisions, and recovery

`BoardState` owns production movement, spaces, connectors, pawn positions, tide
mutations, and route reachability. `RulesSession` owns legal intents, stage
progression, Bellhouse choice/recovery, Council commitment, High Water
transformation, Last Light resolution, and ending resolution.

Bellhouse recovery must distinguish:

- invalid input, which is a state-and-RNG no-op;
- an uncommitted interrupted prompt, which may be reopened;
- a committed choice, which must restore exactly;
- a declared recovery action, which must be bounded and publicly recorded.

The deterministic safe route uses cooperative public choices only. Alpha.2 does
not implement the content-complete role, faction, betrayal, item, hazard, or
multiple-ending systems reserved for alpha.3.

## 7. Stable seats and 1–8-seat fallback

Every seat count from 1 through 8 has one declared cooperative safe route with the
same stage order. Action ownership uses the lowest connected eligible stable seat,
then advances deterministically. Disconnect or control-source replacement never
changes the stable seat's state. Surrogate control is presentation/input routing,
not a new gameplay owner.

Every safe-route run is bounded to 96 accepted actions. Eight consecutive
rejections without progress require an actionable diagnostic; they may not
silently loop. Automated completion must prove no deadlock for all eight seat
counts.

## 8. Persistence, migration, and replay

Alpha.2 targets:

- package version `2`;
- scenario version `2`;
- snapshot version `2`.

Restore validates Tale, package kind/schema/version, provider, and snapshot
version before interpreting stage state. The only planned migration is an
explicit alpha.1 scaffold snapshot-v1 to alpha.2 snapshot-v2 migration. Any
unsupported or malformed identity fails closed without partial authority or
fallback to another Tale.

Every stage entry and accepted stage transition is a checkpoint. Processed request
and event identities persist. Equal authoritative inputs, named-stream states,
seeds, and snapshots must produce replay-equivalent state, public history,
ending, attribution, and cleanup.

## 9. Privacy and Director boundary

The only privacy classes remain:

- `public`;
- `controlled_reveal_private`;
- `seat_private`;
- `faction_private`.

`RoleSession` owns private and controlled-reveal projections. Shared output may
show only public consequences and bounded progress. It may never reveal private
objectives, hidden targets, private terms, unrevealed factions, pending private
transformations, private ending attribution, or desirability hints.

The Director receives only the closed public/aggregate allowlist in the
machine-readable contract. It never receives private terms and never owns stage
progression, transformations, endings, or attribution.

## 10. Compilation and traceability

Design authoring references and prototype proofs may guide implementation, but
they remain non-runtime inputs. Alpha.2 must create separately reviewed native
outputs for:

- scenario/stage graph version 2;
- Tale package version 2;
- governed placeholder localization;
- board, rules, Director, social/private, session, and scoped-provider authority;
- focused alpha.2 tests and release evidence.

No runtime code may load `docs/tales/drowned_harbor/authoring/` or
`game/tests/drowned_harbor_dev_only/`. Data may not select arbitrary classes,
scripts, callbacks, expressions, remote content, URLs, credentials, telemetry,
or executable fragments.

## 11. Admission and export boundary

Drowned Harbor remains reachable only through the exact developer-only gate.
Lantern House remains the sole normal/default Tale. Alpha.2 may not modify the
normal Tale catalog, central provider registry, Tale Library, title/setup
navigation, or fallback selection.

All alpha.2 scenario, package, localization, native source, and focused-test paths
remain excluded from ordinary Windows and Linux exports. The implementation
release must inspect actual produced PCK inventories and scan for both paths and
closed identity markers.

## 12. Rollback and cleanup

Failure before candidate commit leaves no alpha.2 authority. Failure during
restore preserves the prior snapshot and returns an actionable rejection.
Rematch rebuilds through the validated package/provider path. Return-to-title
clears all Drowned Harbor session, private, RNG, processed-identity, board, and
presentation-scoped state before the normal destination is selected.

Rollback may remove version-2 alpha.2 outputs and retain the alpha.1 scaffold, or
reject version-2 saves fail-closed. It may not rewrite them as Lantern House or
silently downgrade state.

## 13. Implementation routing

The inactive implementation definition is
`docs/preproduction/P0.22_Alpha2_Implementation_Issue.md`.

After P0.22 merges, the project owner may separately authorize alpha.2. That
implementation is expected to use Codex at **Very High** effort because it
requires broad typed Godot changes, repeated import/test/export cycles, and
stage-boundary debugging. Release Management still owns scope amendments,
exact-head review, promotion, merge, closure, and successor activation.

## 14. Evidence boundary

Automation is not human evidence.

P0.22 makes no claim of playable alpha.2 runtime, physical-controller validation,
television readability, accessibility certification, privacy/security
certification, fun, pacing, fairness, balance, final assets, production
readiness, or public-release authorization. Issue #39 remains the human-evidence
authority and issue #7 remains the naming gate.
