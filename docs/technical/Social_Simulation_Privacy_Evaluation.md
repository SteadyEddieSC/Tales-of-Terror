# Social Simulation and Privacy Evaluation

Run from the repository root:

```powershell
Godot_v4.7-stable_win64_console.exe --headless --path game --script res://tests/role_session_test.gd
Godot_v4.7-stable_win64_console.exe --headless --path game --script res://tests/social_simulation_test.gd
```

The unit suite covers schema failures, deterministic/fixed assignment, RNG isolation, fallback, stable-seat reconnect, all four view contracts, recursive leak checks, Director blindness, reveal/Horror/Changed/cure/defeat/Restless/guardian/replacement/escape paths, action authorization/bounds, downstream atomicity, mixed outcomes, snapshots, HUD/private-reveal behavior, safe frames, paging, and literal-ID branch guards.

The simulation runs 157 deterministic sequences across five seeds. Cooperative and afterlife paths cover every count from one through eight; hidden Betrayer and Outbreak cover every supported count from three through eight; Hunted covers two, four, and eight; and separate sequences cover mixed results, invalid requests, fallback, and malformed snapshot restore.

Invariants include replay equality, no role/core/Director RNG drift, no secret leakage, stable reconnect ownership, bounded transition/action history, meaningful afterlife action availability, atomic downstream rejection, multi-winner outcomes, safe fallback, and full audit presence.

The harness is regression evidence, not proof of final social balance, deception quality, long-session fun, television legibility, physical-controller comfort, or simultaneous privacy. Those remain manual or future companion checks.
