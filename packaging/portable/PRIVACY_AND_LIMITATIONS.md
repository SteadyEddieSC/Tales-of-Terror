# Privacy and limitations

The native Godot executable is authoritative. The launcher and build-support surface do not download, update, transmit telemetry, or mutate gameplay. Optional companions remain non-authoritative; no phone is required.

Playtest reports are explicitly exported to the local Godot user-data `playtest_exports` folder. Schema-v2 reports contain bounded public/aggregate session evidence and omit unrevealed roles, objectives, private selections, room secrets, tokens, client/device identities, usernames, machine names, absolute paths, IP/network details, and report-host metadata.

`build_manifest.json` identifies the reviewed source, platform, packaged files, and deterministic content. It contains no username, machine name, absolute repository path, token, room secret, IP address, report contents, or device identity. Its timestamp is labeled non-deterministic metadata and is excluded from deterministic content identity.

No physical controller, phone, household Wi-Fi, television-distance, native-4K, assistive-technology, long-session, balance, or household-observation claim follows from this bundle, CI, automation, synthetic input, browser tests, or screenshots. Record such work only through explicit human entry in `MANUAL_VALIDATION_RECORD.json`.
