# Director Simulation and Evaluation

Run the focused suites from the repository root:

```powershell
Godot_v4.7-stable_win64_console.exe --headless --path game --script res://tests/dread_director_test.gd
Godot_v4.7-stable_win64_console.exe --headless --path game --script res://tests/director_simulation_test.gd
```

The simulation runs 90 short sequences: ten seeds × three authored adaptive profiles × struggling, cruising, and stalled trajectories. Each sequence replays identical inputs, applies decisions through the authority adapter, advances several bounded decisions, and checks RNG isolation, nonmutation during evaluation, appropriate trajectory response, nonnegative budgets, per-seat targeting caps, bounded history, audit completeness, and safe no-op under exhausted budgets.

The unit suite additionally covers malformed profiles/candidates, telemetry validation, score arithmetic, eligibility reasons, mercy, cooldowns, downstream atomicity, presentation-only cues, fixed/off modes, safe frames, snapshot replay, and the literal candidate-ID branch guard. CI runs both suites after all v0.0.2–v0.0.6 regressions.

The v0.0.8 social suites additionally compare Director telemetry and decisions across different unrevealed secret assignments, then prove that only an authored public reveal changes allowlisted social aggregates.

This harness is an engineering regression and comparative pacing tool. Its fixtures are controlled, short, and not evidence of final balance, production content variety, long-session emotional pacing, or accessibility comfort. Physical-controller play, television viewing distance, reduced-motion preference integration, and longer balance sessions remain manual checks.
