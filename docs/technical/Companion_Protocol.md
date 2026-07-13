# Companion Protocol v1

## Purpose and trust boundary

Protocol v1 carries already-filtered views from the authoritative native Godot host and bounded player intents in the opposite direction. The room service may order, limit, cache acknowledgements, and relay envelopes. It never evaluates a choice, role action, card, board mutation, outcome, or Director proposal.

JSON field names are lower camel case on the TypeScript/browser wire. The GDScript bridge uses equivalent snake-case envelope keys internally and accepts camel-case intent payloads at its transport boundary. Transport adapters perform the explicit conversion; no gameplay authority depends on JSON naming.

## Envelope

Every envelope contains:

| Field | Bound and meaning |
|---|---|
| `protocolVersion` | Integer `1`; other versions reject as `unsupported_version`. |
| `roomId` | Opaque lowercase stable ID, 1–64 characters. |
| `messageType` | One value from the bounded vocabulary below. |
| `serverSequence` | Nonnegative, monotonically assigned per room by the relay. |
| `authoritativeRevision` | Current monotonic aggregate of Godot rules, board, role, and Director revisions. |
| `requestId` | Client-generated lowercase replay key, 1–64 characters. |
| `seatClaim` | `0` for public/host work or the host-approved stable seat `1–8`. |
| `payload` | JSON object bounded to 8 nesting levels, 64 items per collection, and 256 characters per string. |
| `acknowledgement` | Empty, `accepted`, or a bounded rejection code. |

UTF-8 messages are at most 8,192 bytes. Unknown fields may be ignored only after the complete bounded envelope validates. Malformed JSON never reaches the bridge. Protocol/runtime paths do not branch on scenario, event, card, role, faction, form, objective, or action IDs.

## Message vocabulary

- Room lifecycle: `room_created`, `room_closed`, `room_expired`, `host_heartbeat`.
- Membership: `client_joined`, `client_left`, `seat_claim_requested`, `seat_claim_approved`, `seat_claim_rejected`, `reconnect_resume`.
- Filtered views: `public_view_update`, `seat_private_view_update`, `faction_private_view_update`.
- Intents: `prompt_choice_submit`, `role_action_submit`, `private_reveal_ack`.
- Result: `acknowledgement`, `rejection`.

Rejection codes are `stale`, `duplicate`, `unauthorized`, `malformed`, `rate_limited`, `unsupported_version`, `unsupported_type`, `expired`, `room_full`, `wrong_seat`, `revoked`, `host_missing`, and `body_too_large`. Errors do not echo submitted secret values or authorization material.

## Intent payloads

`prompt_choice_submit` carries only `optionIds` and the current `promptRevision`. `role_action_submit` carries only `actionId` and a bounded stable-seat `targets` array. The bridge supplies the approved actor seat rather than trusting a payload actor. Godot then revalidates phase, prompt/action identity, target scope, connection, uses, cooldown, downstream effects, and the aggregate authoritative revision.

Duplicate request IDs return the cached acknowledgement without another authority call. A stale revision returns the current revision and a refresh requirement but no private data. Out-of-order positive server sequences reject before gameplay. Accepted results include the resulting authoritative revision and `appliedOnce: true`.

## Local and deployed transport

`ws://127.0.0.1` and `ws://localhost` are permitted only for labeled local development. Deployed transport requires `wss://`/HTTPS using platform TLS. Host/resume capabilities are exchanged in headers or the first WebSocket authentication message, never query strings. The initial socket URL may contain the human join code for Durable Object routing. The prototype is not end-to-end encrypted against the relay operator.
