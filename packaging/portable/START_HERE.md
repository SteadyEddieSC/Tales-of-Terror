# Lantern House v0.1.2 Internal Playtest

This extracted folder is an internal evaluation build. The working title is provisional; this is not a public demo or storefront release.

## Launch

- Windows: double-click `launch.cmd`, or launch `lantern_house_internal.exe` directly.
- Linux: run `./launch.sh`, or run `./lantern_house_internal.x86_64` directly.

The helper is optional. It uses only files beside it, performs no download, requires no administrator access, and returns a clear error if the native executable is missing.

## Play

Connect controllers before starting. Press A to claim a stable seat; an owned controller presses A again to confirm. One to eight seats are supported. Enter is the keyboard development fallback and Space can confirm. Press X/H for Help. Phones are optional: the native Godot host remains authoritative and the complete session can be played without phones.

## Reports and facilitation

At the ending, open Help, move to the Playtest Report page, and press A/Enter. JSON and Markdown are stored only in Godot's local user-data `playtest_exports` folder. Open `FACILITATOR_GUIDE.md`, `POST_SESSION_QUESTIONNAIRE.md`, and `PRIVACY_AND_LIMITATIONS.md` before observing a session.

For launch/runtime support, open Help → Build & Support and report the visible release, short build ID, platform, and exact error. Do not send report contents, room secrets, player identities, network details, or device information.
