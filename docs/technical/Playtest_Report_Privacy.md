# Playtest Report Privacy

## Exact allowlist

| Section | Permitted fields |
| --- | --- |
| Build/scenario | schema version, release, scenario ID/version |
| Session | deterministic seed, seat count, public mode, fallback flag, aggregate companion-used flag, explicit UTC start/end, completion reason, bounded post-ending disposition |
| Lifecycle | sequence, elapsed seconds, public lifecycle |
| Seats | sequence, elapsed seconds, stable seat number, join/disconnect/reconnect/leave category, controller/keyboard class |
| Recovery | sequence, elapsed seconds, pause/resume/aggregate companion-connected category |
| Waits | sequence, elapsed seconds, prompt/vote kind, eligible/submitted counts, completion flag |
| Rejections | sequence, elapsed seconds, bounded category only |
| Stages | public stage ID and elapsed seconds |
| Outcome | public terminal reason and SHA-256 authority/public-history digests |
| Optional feedback | local 0–5 rating and bounded notes only when deliberately entered |

Unknown schema keys reject. The observer selects these fields rather than recursively sanitizing arbitrary payloads. Planted private values in unrelated public-state dictionary branches are therefore omitted by construction.

## Explicit denylist

Reports never serialize unrevealed role, faction, objective, form, private selection, raw response, companion join code, token, capability, request body, room secret, browser storage, client identity, IP or network detail, raw input, OS username, machine name, absolute repository path, or controller/device identity. No report code imports or invokes network APIs. Reports are not telemetry and are not authoritative.

Tester notes are optional local input. Facilitators must not enter another player’s private reveal, contact information, device/network identifiers, or secrets. Delete or redact a report before sharing if free-form notes accidentally contain personal data.

## Storage and sharing

Production export remains fixed to `user://playtest_exports`. The UI and bundle documents resolve it with user-relative guidance, never a concrete host username or absolute build path:

- Windows: `%APPDATA%\Godot\app_userdata\Terror Turn\playtest_exports`
- Linux: `$XDG_DATA_HOME/godot/app_userdata/Terror Turn/playtest_exports`
- Linux default when `XDG_DATA_HOME` is unset: `~/.local/share/godot/app_userdata/Terror Turn/playtest_exports`

`Terror Turn` is the exact current `application/config/name` project folder and remains provisional. Nothing is uploaded automatically. A facilitator chooses whether to inspect or share the two files after the session. Automated fixtures contain synthetic values only.

## Pilot evidence intake

The v0.1.3 pilot record is separate from schema-v2 runtime reports. A facilitator may record reviewed report SHA-256 hashes but must not ingest or commit report content. Offline intake accepts exactly one `PILOT_SESSION_RECORD.json`, rejects unknown files, links, traversal, oversized input, direct identifiers, usernames, absolute/repository paths, secrets, tokens, room codes, IP/network details, device IDs, and ambiguous evidence classes, and retains only normalized bounded values plus the input-file SHA-256. Automated and synthetic evidence cannot be promoted to human/physical evidence.

The committed pilot record is intentionally blank: manual checks are `not_tested`, route fields are `not_observed`, counts are zero, strings/arrays are empty, and human declarations are false. The blank findings register contains no actual findings. Human evidence is reviewed before Stage 2 commits anything.

## Build manifest separation

The v0.1.3 portable `build_manifest.json` is a separate non-authoritative build record, not a playtest report. Its exact schema contains only release/source/target identity, reviewed engine/scenario constants, build-time classification, and bundle file sizes and SHA-256 values. It cannot contain report payloads or filenames, usernames, machine names, repository paths, tokens, room secrets, IP addresses, or device identities. The in-game support page similarly shows only bounded build identity and the user-relative platform location above. Neither manifest nor support presentation mutates or serializes gameplay authority.
