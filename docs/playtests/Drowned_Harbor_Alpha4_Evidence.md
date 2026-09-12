# Drowned Harbor Alpha.4 implementation evidence

Recorded 2026-09-12 for issue #161. This is automated and agent-reviewed developer
evidence, not a human playtest, accessibility certification or production admission.

## Executed checks

- Official Godot 4.7.1-stable, Compatibility renderer, logical 960×540.
- Alpha.4 session suite: 1,772 checks. All 21 supported seat/mode combinations,
  deterministic repeats and replay, malformed content/save rejection, four
  different player-selected endings with the same seed, explicit Outbreak
  refusal/binding, failed-bundle rollback and post-defeat participation.
- Alpha.4 input/save suite: stable ownership, simultaneous command ordering,
  held-button suppression, unowned input rejection, reservation/reclaim races,
  exact typed disk serialization, corruption recovery and unsupported versions.
- Rendered frontend: full keyboard-driven route at 1, 4 and 8 seats, nested
  overlays, private text destruction, inventory pages, save/title/continue,
  ending and rematch. Two virtual controllers exercise actual Godot button events
  after simulated discovery, including a saved disconnected owner and second-seat
  reclaim. No physical controllers are represented by those virtual devices.
- Native Alpha.2 regression: 236 checks; Alpha.3 regression: 590 checks over 126
  repeated mode/seat/seed runs. Their fixture content coverage is not a claim that
  every old fixture has a selectable Alpha.4 player action.
- GUT: 23 tests and 150 assertions passed.
- Complete headless quality runner: all 29 standalone suites plus GUT passed,
  including 335 Lantern House deterministic runs and 160 replay configurations.
- First-party GDScript: lint and formatting checks pass for 151 files.
- Repository policy, provenance, catalog/package, privacy, toolchain, portable
  bundle, pilot templates, historical boundary and quality-validator checks pass
  in isolation. The new demo packager has three tests covering stale staging,
  exact archive membership and preservation of prior artifacts on incomplete export.
- Companion TypeScript and 10 browser tests pass. Twenty service unit tests pass;
  six worker integration cases do not run because local worker startup reaches
  the existing 60-second hook timeout. Companion source and lockfile are unchanged.
  The GitHub Actions Companion protocol/service/browser job passes on the draft PR,
  including its worker integration environment.
- `npm audit --audit-level=moderate`: zero reported vulnerabilities.

The complete headless command surface remains `python quality/run_quality.py godot
--godot <official executable>`; it includes the Alpha.4 suites and rejects runtime
GDScript errors even when the engine process returns zero.

One full headless frontend run reported four ObjectDB instances and two resources
still in use at process shutdown. A focused verbose rerun completed without that
warning; the rendered frontend and exported Windows smoke also exited cleanly.
This intermittent test-teardown warning is not claimed to be resolved.

## Visual review

The source scene rendered through Intel UHD Graphics 630 / OpenGL 3.3. The agent
inspected title, eight-seat lobby and board, large text, private role and allegiance
pages, public crew status, inventory, controller reclaim, Bellhouse and results.
Review found and fixed overflowing private copy, long action detail, crowded lobby
labels and overlay return paths. Public sound cues have text captions; cue playback
is suppressed during private handoffs.

Local images are generated under `game/test-results/alpha4-screenshots`. Private
images contain game secrets and must not be republished as public evidence.
Logs are local under `builds/alpha4-*.log`; those paths are intentionally untracked.

## Developer artifacts

`tools/build_drowned_harbor_demo.py` validates the official engine version and
export-template SHA-512, creates a fresh staging project, and packages exactly the
executable, player guide, Godot license and build identity. Output ZIPs and their
SHA-256 values are recorded in `builds/alpha4/build_manifest.json`. Each identity
records the source commit and whether any source changes were uncommitted.

The executable accepts `-- --demo-smoke` for an offline native scene/content/art/
audio admission check. Both Windows and Linux demo ZIPs were exported from clean
committed source, and the actual Windows executable passed that smoke check.
Linux export creation does not establish Linux runtime or
physical display evidence on this Windows workstation.

## Remaining evidence and content limits

Human fun/balance review, physical 1–8-controller sessions, television viewing
distance, Linux execution and independent art review are pending. The demo uses
six landmarks, three playable card effects, collected equipment and bounded social
transitions. Dedicated role abilities, a new Companion bridge, recorded Underteller
speech and proof of ordinary-player routes to all seven authored endings remain
future work. The broad Alpha.3 fixture counts must not be used as Alpha.4 completion
counts. The current private account evaluates the six living objectives; broader
faction and Tidebound objective evaluation remains partial.
