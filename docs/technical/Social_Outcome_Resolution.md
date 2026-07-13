# Social Objective and Outcome Resolution

Objectives are declarative, deterministic queries over approved `RulesSession`, `BoardState`, and `RoleSession` state. Evaluation is side-effect free. Each evaluation records complete, partial, result category, priority, visibility, end-reveal policy, and epilogue tags.

Supported scopes are shared scenario, faction, individual, and afterlife. Result categories include victory, defeat, escaped, changed, restless, partial, and unresolved. A seat may evaluate several compatible or conflicting objectives; the authored terminal policy selects the highest-priority completed result while retaining every objective breakdown. Faction summaries aggregate per-seat results without imposing a single-winner assumption.

`resolve_outcomes` first evaluates the complete proposal, then asks `RulesSession.complete` to accept the mode's authored result key. Only after acceptance does `RoleSession` store/audit the resolved outcome and increment revision. Repeating resolution returns the same outcome idempotently without another rules or role mutation.

The Lantern House mixed fixture demonstrates a successful private individual objective, multiple Changed results, a Restless result, per-faction summaries, partial-capable conditions, and end-of-game objective disclosure. This is format/authority evidence, not final balance.
