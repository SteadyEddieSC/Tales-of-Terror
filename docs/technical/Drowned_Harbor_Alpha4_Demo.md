# Drowned Harbor Alpha.4 playable demo

Launch the exported demo executable, or open `game/project.godot` in official
Godot 4.7.1-stable and run `game/src/tales/drowned_harbor/alpha4/DemoMain.tscn`.
The ordinary project main scene remains Lantern House. Logical size remains
960×540 with the Compatibility renderer.

The route is title → local crew → mode/seed → introduction → controlled private
hands → Low Tide → Bellhouse → Council → High Water → flooded exploration →
Last Light → ending → epilogue → results → rematch/title. All regular advancement
uses displayed player choices. A saved Tale resumes through the pause/reclaim menu.

The private handoff has separate role/objective and allegiance/account pages.
Pause includes public witness status and three inventory pages for supplies,
cards and observed threats. Only voluntarily declared allegiances appear publicly.
Nested help/settings/pause navigation returns through the original private shield.
Restored seats are offered controller reclaim when their turn arrives, and a
keyboard reclaim cancels a pending controller claim for that seat.

See `packaging/drowned_harbor_demo/START_HERE.md` for player controls and limits.
The local save and settings are in Godot's user-data directory for the project.
Source runs and exported demos use distinct application names/user directories.

## Implementation

- `demo_content.gd`: authored choices, resource/counter effects, cards, objective
  conditions, route operation bundles, Director effects and seven ending policies.
- `demo_session.gd`: versioned native authority adapter and candidate replay/restore.
- `demo_input.gd`: semantic input, controller discovery, stable-seat ownership,
  deterministic input batches and explicit reconnect/reclaim.
- `demo_save_store.gd`: bounded typed local file transport, checksum and backup.
- `demo_main.gd`, `demo_screen_view.gd`, `demo_board_view.gd`: menus, controlled
  private handoff, public board, tide/movement animation and accessibility settings.
- `demo_narrative.gd`, `demo_audio.gd`: localizable text and public-only sound routing.

The developer export tool stages only `src`, `assets`, `data`, project settings and
its generated identity. It uses official checksum-verified export templates and
records the source commit and whether the source was dirty. It creates separate
Windows/Linux ZIPs and a SHA-256 build manifest under `builds/alpha4`.

```text
python tools/build_drowned_harbor_demo.py --godot <official-console-executable> \
  --templates-archive <Godot_v4.7.1-stable_export_templates.tpz> \
  --checksums <official-SHA512-SUMS.txt>
```

## Verification

The Alpha.4 standalone suites test choice-dependent endings with the same seed,
all supported seat/mode combinations, deterministic replay, malformed restore,
explicit Outbreak refusal/conversion, post-defeat actions, ownership, corruption
and backup recovery. The frontend suite injects actual keyboard events through
the input adapter, navigating the scene at one, four and eight seats.
It also exercises nested overlays and two simulated controllers through actual
Godot button events. Device discovery metadata is simulated; this is not physical
controller evidence. See `docs/playtests/Drowned_Harbor_Alpha4_Evidence.md`.

```text
godot --headless --path game --script res://tests/drowned_harbor_alpha4/demo_session_test.gd
godot --headless --path game --script res://tests/drowned_harbor_alpha4/demo_frontend_test.gd
godot --headless --path game --script res://tests/drowned_harbor_alpha4_input_save_test.gd
godot --path game --resolution 960x540 --script res://tests/drowned_harbor_alpha4/demo_frontend_test.gd -- --capture
```

Captures are export-excluded under `game/test-results/alpha4-screenshots`.
Private captures contain game secrets and must not be treated as public reports.
The shared quality runner also fails on GDScript runtime errors even if Godot
returns process status zero.

## Current limits

Six public landmarks stand in for the full town. Items currently communicate
collection and ownership; the new selectable card actions supply the active
equipment effects. The existing Alpha.3 social authority bounds the demo to one
Tidebound conversion and one defeat transition per Tale. Broader dynamic social
play and dedicated role abilities remain future work. Endings are player-dependent;
not all seven authored outcomes have a demonstrated ordinary-player route yet.

Speech is generation-ready text, not recorded voice. Music/ambience consists of
original synthesized beds and cues. This demo has no phone/remote control bridge.
Save migration from older prototype models is explicitly unsupported. Manual
controller, television, accessibility and target Linux hardware evidence remains pending.
