# Companion Protocol v1

## Purpose and trust boundary

Protocol v1 carries already-filtered views from the authoritative native Godot host and bounded player intents in the opposite direction. The room service may order, limit, cache acknowledgements, and relay envelopes. It never evaluates a choice, role action, card, board mutation, outcome, or Director proposal.

JSON field names are lower camel case on the TypeScript/browser/service wire. GDScript uses snake-case protocol keys internally. `CompanionWireCodec` is the single bidirectional transport-boundary conversion: all nine envelope fields are mapped explicitly, and only protocol-owned payload fields are mapped by message type. Rules, social, Director, and authored presentation dictionaries inside their declared projection containers remain opaque; the codec never recursively renames arbitrary authored content. No gameplay authority depends on JSON naming.

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

UTF-8 messages are at most 8,192 bytes. Every envelope has exactly the nine fields above. Unknown, duplicated-by-alias, snake/camel mixed, ambiguous, malformed, or oversized envelopes fail closed before the bridge. JSON numeric envelope fields and protocol-owned numeric intent fields are accepted only when they are nonnegative exact integers, then normalized to typed GDScript integers. Protocol/runtime paths do not branch on scenario, event, card, role, faction, form, objective, or action IDs.

## Message vocabulary

- Room lifecycle: `room_created`, `room_closed`, `room_expired`, `host_heartbeat`.
- Membership: `client_joined`, `client_left`, `seat_claim_requested`, `seat_claim_approved`, `seat_claim_rejected`, `reconnect_resume`.
- Filtered views: `public_view_update`, `seat_private_view_update`, `faction_private_view_update`.
- Intents: `prompt_choice_submit`, `role_action_submit`, `private_reveal_ack`.
- Result: `acknowledgement`, `rejection`.

Rejection codes are `stale`, `duplicate`, `unauthorized`, `malformed`, `rate_limited`, `unsupported_version`, `unsupported_type`, `expired`, `room_full`, `wrong_seat`, `revoked`, `host_missing`, and `body_too_large`. Errors do not echo submitted secret values or authorization material.

## Intent payloads

`prompt_choice_submit` carries only `optionIds` and the current `promptRevision`. `role_action_submit` carries only `actionId` and a bounded stable-seat `targets` array. The bridge supplies the approved actor seat rather than trusting a payload actor. Godot then revalidates phase, prompt/action identity, target scope, connection, uses, cooldown, downstream effects, and the aggregate authoritative revision.

The GDScript equivalents are exactly `option_ids`/`prompt_revision` and `action_id`/`targets`. Mixed names and extra intent keys reject as `malformed`. Lifecycle, membership, acknowledgement, and rejection payloads likewise have bounded allowlists. View payload conversion is limited to declared companion projection structure such as view metadata, seat identity, legal actions, faction members, and board counts; nested authority/authored values are copied without key rewriting.

Duplicate request IDs return the cached acknowledgement without another authority call. A stale revision returns the current revision and a refresh requirement but no private data. Out-of-order positive server sequences reject before gameplay. Accepted results include the resulting authoritative revision and `appliedOnce: true`.

`game/tests/fixtures/companion_protocol_v1.json` is consumed by both runtimes. TypeScript proves its produced wire envelope equals the fixture; Godot parses it to the exact internal contract. Godot proves its produced acknowledgement equals the TypeScript-validated wire fixture, round-trips it, and rejects malformed/mixed-schema fixture cases.

## Local and deployed transport

`ws://127.0.0.1` and `ws://localhost` are permitted only for labeled local development. Deployed transport requires `wss://`/HTTPS using platform TLS. Host/resume capabilities are exchanged in headers or the first WebSocket authentication message, never query strings. The initial socket URL may contain the human join code for Durable Object routing. The prototype is not end-to-end encrypted against the relay operator.
