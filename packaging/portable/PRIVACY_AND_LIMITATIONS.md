# Privacy and limitations

The native Godot executable is authoritative. The launcher and build-support surface do not download, update, transmit telemetry, or mutate gameplay. Optional companions remain non-authoritative; no phone is required.

Playtest reports are explicitly exported to `user://playtest_exports`. A tester can locate that local-only folder without exposing a concrete username:

- Windows: `%APPDATA%\Godot\app_userdata\Terror Turn\playtest_exports`
- Linux: `$XDG_DATA_HOME/godot/app_userdata/Terror Turn/playtest_exports`
- Linux default when `XDG_DATA_HOME` is unset: `~/.local/share/godot/app_userdata/Terror Turn/playtest_exports`

`Terror Turn` is the exact current Godot project-folder name and remains provisional. Schema-v2 reports contain bounded public/aggregate session evidence and omit unrevealed roles, objectives, private selections, room secrets, tokens, client/device identities, usernames, machine names, absolute paths, IP/network details, and report-host metadata.

`build_manifest.json` identifies the reviewed source, platform, packaged files, and deterministic content. It contains no username, machine name, absolute repository path, token, room secret, IP address, report contents, or device identity. Its timestamp is labeled non-deterministic metadata and is excluded from deterministic content identity.

The pilot evidence package may contain exactly one reviewed `PILOT_SESSION_RECORD.json`. Do not return raw reports, recordings, photographs, voices, biometrics, medical details, direct identities, exact ages, addresses, usernames, paths, tokens, room codes, IP/network details, or device IDs. Only reviewed report SHA-256 hashes may enter the record. Offline validation rejects unknown files and prohibited values; this repository provides no uploader, telemetry, cloud API, or AI-service intake.

No physical controller, phone, household Wi-Fi, television-distance, native-4K, assistive-technology, long-session, balance, fun, accessibility, privacy, security, or household-observation claim follows from this bundle, CI, automation, synthetic input, browser tests, or screenshots. Record work only after explicit voluntary human observation in a copied `PILOT_SESSION_RECORD.json`. The bundled record leaves every manual check `not_tested`, every route check `not_observed`, and all human declarations false.
