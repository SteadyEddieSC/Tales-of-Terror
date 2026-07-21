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

Production export is fixed to `user://playtest_exports`. The UI shows only relative user-data paths, not the host username or absolute path. Nothing is uploaded automatically. A facilitator chooses whether to inspect or share the two files after the session. Automated fixtures contain synthetic values only.
