# Social Content Schema

All social content is trusted, reviewable data. It contains no callbacks, script paths, expressions, or unbounded recursion. Stable IDs are lowercase snake case; generic runtime and presentation resolve behavior through validated fields and tags.

## Definition families

- **Faction:** identity/version, friendly label, symbol, pattern, membership policy, seat bounds, relationship dispositions, shared objectives, transition references, future communication permission, result group, presentation metadata, and Director-signal policy.
- **Role/form:** friendly/private identity, safe public cover, starting/allowed factions, player bounds, reveal policy, objectives, actions, transitions, tags/incompatibilities, lifecycle, afterlife mapping/delay, epilogue metadata, and future private-view metadata.
- **Objective:** scope, visibility, bounded authoritative conditions, deterministic priority, result category, partial conditions, end reveal, and epilogue tags.
- **Action:** visibility, lifecycle/phase eligibility, target scope/count, use/per-round/cooldown limits, tags, and bounded proposals.
- **Transition:** source forms, target form, trigger, visibility, explicit chain bound, state patch, optional downstream effects, and public presentation.
- **Mode:** supported counts, fixed/random assignment, pools, required/forbidden combinations, fallback, objectives, privacy/terminal/afterlife policy, Director allowlist, and retry/chain/inactivity limits.

## Bounded vocabularies

Objective conditions are always, rules flag, rules counter threshold, board feature, faction count, seat lifecycle state, or action-used checks. Action proposals are rules effects, one board mutation, a social transition, or a presentation payload. Existing `RulesContent` validates downstream effect vocabulary.

Visibility is one of public, seat-private, faction-private, or diagnostics. Lifecycle values are active, transformed, defeated, afterlife, replacement, or escaped. Target scopes are none, self, other, any, or same-faction other.

## Validation failures

Validation rejects duplicate/malformed IDs, unknown references, malformed symbols/patterns, hidden roles without a public cover, illegal factions, unsupported player counts, bad assignment pools, impossible target/use bounds, arbitrary proposal types, missing objectives/actions, unknown forms, unbounded transition cycles, invalid communication/Director policies, and afterlife forms that can become indefinitely passive.

Example role/form:

```gdscript
{
  "id": "example_form", "version": 1,
  "label": "Friendly Form", "symbol": "F", "pattern": "crossed lines",
  "starting_faction": "example_faction", "allowed_factions": ["example_faction"],
  "reveal_policy": "hidden",
  "public_cover": {"label": "Unknown", "symbol": "?", "pattern": "closed hatch"},
  "objective_refs": ["example_objective"], "action_refs": ["example_action"],
  "transition_refs": ["example_reveal"], "afterlife_mapping": "example_defeat",
  "maximum_inactive_transition_delay": 1
}
```
