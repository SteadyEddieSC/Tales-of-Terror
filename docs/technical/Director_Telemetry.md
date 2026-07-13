# Director Telemetry Dictionary

Telemetry is a short-lived read-only snapshot derived from local `RulesSession` and `BoardState`. Missing required fields fail validation; optional future signals use a neutral documented default. Values are JSON-compatible and never contain device IDs, controller identities, accounts, network addresses, voice, camera, biometric, or long-term cross-session data.

| Field | Unit/range | Source and missing behavior |
|---|---:|---|
| `round` | integer ≥ 1 | Rules round; invalid if missing |
| `phase` | stable rules phase | Current phase; invalid if missing |
| `progress` | 0–100 | Bounded round/phase plus authored objective counter |
| `failure_pressure` | 0–100 | Recent failure/partial results in last four checks; zero with no checks |
| `resource_pressure` | 0–100 | Inverse bounded sum of hope, resolve, hands, and inventory; empty resources mean high pressure |
| `hazard_pressure` | 0–100 | Bounded count of authoritative hazards and blockers; zero with none |
| `group_spread` | 0–100 | Number of occupied authored spaces beyond one; zero when occupancy is unavailable |
| `stalled_steps` | 0–100 | Authored deterministic `objective_stall_steps`; never wall-clock time |
| `prompt_latency` | 0–100 | Authored deterministic `prompt_latency_steps`; never wall-clock time |
| `pass_frequency` | 0–100 percent | Current passed seats divided by connected participating seats |
| `participation_imbalance` | 0–100 | Bounded span of recent accepted seat actions |
| `rejected_actions` | 0–100 | Authored deterministic rejected-action counter; zero when absent |
| `objective_progress` | 0–10 | Authored objective counter used in progress calculation |
| `recent_check_outcomes` | string list | Bounded accepted check history; empty when none |
| `recent_intervention_tags` | tag list | Tags copied from recent authored effect sources; empty when none |
| `active_seats` | seat-number list | Connected participating seats |
| `disconnected_seats` | seat-number list | Reserved participating seats; never negative targets |
| `reserved_seat_count` | 0–8 | Size of disconnected list |
| `future_balance_signal` | 0–100 | Neutral 50 plus bounded revealed-only social imbalance; unrevealed assignments cannot change it |
| `social_signals` | allowlisted integer map | Public/revealed or aggregate values copied from `RoleSession`; empty before social authority is supplied |

The snapshot is diagnostic state, so stable internal IDs may appear there. Player presentation resolves authored friendly names and hides these metrics.

Social signal keys are limited to revealed faction count, public hostility, defeated count, Restless count, public conversion pressure, revealed imbalance, social-choice pressure, and afterlife-support availability. Role/form/faction/objective IDs, private targets/messages, and planned transitions are never present.
