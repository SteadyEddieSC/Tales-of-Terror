# Companion Room Service Architecture and Local Run Guide

## Components

`services/room-service/src/room-coordinator.ts` is a deterministic, platform-neutral ephemeral coordinator used by unit tests. `worker.ts` wraps it in a Cloudflare Worker and one Durable Object per human join code. Durable Object storage holds a bounded, short-lived coordinator snapshot plus its inactivity alarm so platform hibernation cannot erase a room between requests. The snapshot can contain opaque capabilities and queued, already-filtered relay payloads until delivery, close, or expiry. It contains no gameplay authority, player profile, campaign, analytics identity, or long-term history and is deleted on close/expiry.

The service owns join-code collision retry, host and per-client resume capabilities, pending/connected membership, approved seat claims, relay ordering, bounded inbox/ack caches, rate limits, heartbeat, close, and expiry. It has no room-list endpoint and no gameplay imports. A service outage fails companions disconnected; a valid unexpired Durable Object snapshot may restore relay state without acquiring gameplay authority.

Defaults are eight clients/pending joins, 32 messages per queue, 32 cached acknowledgements, 8,192-byte bodies, 16 messages per 1,000 ms, a ten-minute inactivity deadline, a 30-second host-loss deadline, two-minute acknowledgement-cache retention, and bounded sanitized diagnostics. Tests inject a monotonic clock; production-like code reads elapsed service time, advances it monotonically, persists every relevant timestamp, and schedules the next alarm at the earlier host-loss or inactivity deadline. Client traffic updates ordinary activity but never the host timestamp. Close or expiry clears membership, capability strings, relay queues, and acknowledgement state.

The relay initially returns `relayAccepted: true` without implying gameplay success. When native Godot relays its acknowledgement or rejection, the Durable Object replaces the provisional cached receipt for that client/request ID. A duplicate then returns the authoritative cached result and is not drained into Godot again. Expired acknowledgement entries may leave the relay cache, but `CompanionBridge` and the native authorities retain their independent idempotency/immutable-response checks.

## Native host adapter

`game/src/companion/companion_room_service_host.gd` is a typed Godot node over the host HTTPS interface. It stores the opaque host capability only in a private field and Authorization headers. It polls pending membership/intents, maps approved seats to transient clients, calls `CompanionBridge` with snake-case internal envelopes, and publishes only codec-produced wire envelopes from bridge output. Membership messages are handled separately from gameplay intents. If HTTP is unavailable or malformed, the adapter reports a sanitized transport state and performs no gameplay mutation; local controller/shared-screen play continues.

## Capability flow

1. Host creates a room and receives the join code plus an opaque host capability over a no-store HTTPS response.
2. Browser uses only the join code and a random transient client ID to enter pending state.
3. Host drains a sanitized pending request and explicitly approves a stable seat through an Authorization header.
4. The service sends that client an opaque resume capability scoped to room/client/seat. The host response does not contain it, and no other client can drain that inbox.
5. Reconnect succeeds only after the prior socket disconnects and only for the exact tuple. Wrong seat, connected reuse, revoked, expired, missing, or tampered capability fails closed.

Capabilities use `crypto.randomUUID()`/platform randomness. This is not custom cryptography. They never appear in URLs, diagnostics, logs, or committed fixtures; tests use clearly synthetic factories.

## Local commands

From the repository root with Node 24.18.0 LTS:

```powershell
npm ci
npm run typecheck
npm run test:service
npm run dev:service
# With GODOT_BIN set to the pinned Godot 4.7 console executable:
npm run test:e2e:local
```

Wrangler listens on `http://127.0.0.1:8787` by default and uses local Durable Object emulation without Cloudflare credentials. Create with `POST /v1/rooms`, join with `POST /v1/rooms/join`, and perform host operations through `POST /v1/rooms/host` with `Authorization: Bearer …`. The browser socket is `/v1/rooms/{JOIN_CODE}/socket`; capability material is sent only in its first message.

`ALLOWED_ORIGINS` defaults to the local companion development origins. Browser requests from all other origins fail. Non-browser CLI calls may omit `Origin`; production configuration must set an explicit HTTPS origin and should be reviewed before deployment. There is no production deployment in v0.0.9.

`test:e2e:local` starts credential-free local Durable Object emulation, launches the native Godot host adapter, joins/resumes an exact synthetic client/seat over WebSocket, submits one prompt intent, and waits for the native authoritative acknowledgement to return to the client. It asserts one RulesSession history mutation and scans sanitized native output for hidden board/capability values.

## Logging and operations

Application code does not call `console.log` and diagnostics include only versions, room state/code, separate inactivity/host-loss ages, counts, claimed seat numerals, sequence/queue depth, truncated request display, result, and counters. The Godot host adapter likewise emits no request, capability, or payload logs. Do not enable request-body logging at an edge proxy. Wrangler telemetry is development tooling, not part of the product; CI disables it and no application analytics SDK exists.
