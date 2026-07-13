# Director Configuration and Candidate Schema

Director content is trusted, reviewed data with no callbacks or executable script fields. Stable IDs are lowercase snake case and never drive generic runtime branches.

## Profile example

```gdscript
{
  "id": "standard", "version": 1, "mode": "adaptive",
  "pacing_curve": [
    {"progress": 0, "act": "arrival", "low": 20, "high": 38},
    {"progress": 35, "act": "deepening", "low": 38, "high": 62}
  ],
  "metric_weights": {"progress": 1, "failure_pressure": 1},
  "normalization_bounds": {"progress": [0, 100]},
  "budgets": {"pressure": 65, "relief": 30, "clue": 24,
              "scarcity": 18, "ambient": 20, "intervention": 30},
  "global_cooldown": 0, "tag_cooldown": 1,
  "repetition_window": 4, "target_window": 5,
  "max_targets_per_window": 2, "recovery_window": 2,
  "min_spacing": 0, "max_spacing": 5,
  "volatility": 4, "max_chain": 3, "max_retries": 2,
  "pressure_window": 4, "max_pressure_per_window": 65,
  "allow_tags": [], "deny_tags": [], "reduced_volatility": false
}
```

All ten documented metrics require normalization bounds. Curves are strictly increasing and stay within 0–100. Budgets, cooldowns, spacing, windows, retry limits, and pressure caps are nonnegative and internally possible. Tags and tag affinities use the bounded vocabulary. Every profile must allow an authored no-op.

## Candidate example

```gdscript
{
  "id": "example_omen", "version": 1,
  "name": "Example Omen", "summary": "Friendly player text.",
  "category": "ambient", "tags": ["ambient", "nudge"],
  "base_weight": 8,
  "conditions": [{"type": "metric_at_least", "metric": "stalled_steps", "value": 40}],
  "metric_affinities": {"stalled_steps": 30},
  "target_scope": "none",
  "budget_kind": "ambient", "budget_cost": 1,
  "cooldown": 2, "repetition_window": 3,
  "pressure_impact": 0, "relief_impact": 0, "tension_impact": 6,
  "payload": {"type": "presentation", "cue": "example_omen",
              "message": "The lantern turns.", "speaker_key": "scenario_host",
              "reduced_motion_safe": true},
  "presentation": {"symbol": "≋", "pattern": "eastward lines", "tone": "watchful"}
}
```

Categories are pressure, relief, hint, board, event, ambient, and no-op. Target scopes are none, active-any, and active-negative. Conditions are always, metric bounds, approved rule flags, and hazard bounds. Payloads are queue-event, bounded rules effects, one validated board mutation, presentation, or no-op.

Validation rejects duplicate/malformed IDs, unknown tags/metrics/conditions, bad curves, negative limits, missing rules/board references, malformed payloads, and configurations without a legal fallback. Presentation supplies text plus symbol and pattern; color is optional reinforcement only.
