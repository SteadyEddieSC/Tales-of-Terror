# Lantern House v0.1.3 Pilot-ready Internal Playtest

This extracted folder is an internal evaluation build. The working title is provisional; this is not a public demo or storefront release.

## Launch

- Windows: double-click `launch.cmd`, or launch `lantern_house_internal.exe` directly.
- Linux: run `./launch.sh`, or run `./lantern_house_internal.x86_64` directly.

The helper is optional. It uses only files beside it, performs no download, requires no administrator access, and returns a clear error if the native executable is missing.

## Play

Connect controllers before starting. Press A to claim a stable seat; an owned controller presses A again to confirm. One to eight seats are supported. Enter is the keyboard development fallback and Space can confirm. Press X/H for Help. Phones are optional: the native Godot host remains authoritative and the complete session can be played without phones.

## Reports and facilitation

At the ending, open Help, move to the Playtest Report page, and press A/Enter. JSON and Markdown are stored only in the exported build's local Godot user-data folder:

- Windows: `%APPDATA%\Godot\app_userdata\Terror Turn\playtest_exports`
- Linux: `$XDG_DATA_HOME/godot/app_userdata/Terror Turn/playtest_exports`
- Linux default when `XDG_DATA_HOME` is unset: `~/.local/share/godot/app_userdata/Terror Turn/playtest_exports`

`Terror Turn` is the exact current Godot project-folder name and remains a provisional working title. These user-relative forms do not reveal a tester or build-host username. Before observing a session, open `FACILITATOR_GUIDE.md`, `OBSERVATION_SHEET.md`, `POST_SESSION_QUESTIONNAIRE.md`, and `PRIVACY_AND_LIMITATIONS.md`. `PILOT_SESSION_RECORD.json` and `FINDINGS_REGISTER.json` are intentionally blank; no human pilot or manual pass is pre-populated.

For launch/runtime support, open Help -> Build & Support and report the visible release, short build ID, platform, architecture, build classification, and exact error. Do not send report contents, room secrets, player identities, network details, or device information.
