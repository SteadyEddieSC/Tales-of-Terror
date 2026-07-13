# ADR-0019: Companion room authority, filtered views, and ephemeral capabilities

- **Status:** Accepted
- **Date:** July 13, 2026

## Context

Optional browser companions need stable-seat private information and low-frequency input without becoming a second game runtime, moving secrets into diagnostics, or letting a replaceable relay own rules. Browser processes and network connections are transient; existing gameplay ownership belongs to stable seats. A lost or malicious client must not partially apply work, consume gameplay randomness, or impair local controller play.

## Decision

Native Godot remains the only gameplay authority. The scene-independent `CompanionBridge` consumes explicit public projections from `SeatManager`, `BoardState`, `RulesSession`, `DirectorRuntime`, and `RoleSession`; it never forwards their snapshots, RNG state, raw audits, spoiler diagnostics, or mutable internal dictionaries. It regenerates public, seat-private, and authored faction-private payloads on demand. Accepted prompt and role-action intents cross existing `RulesSession` or `RoleSession` public methods; board effects continue through `BoardState`. The bridge never directly mutates board, rules, role, Director, pawn, controller, or seat state.

The version-1 protocol is bounded, ordered, and replay-safe. Unknown versions/types, malformed or oversized JSON, unauthorized/wrong-seat claims, stale authoritative revisions, out-of-order sequences, and duplicate request IDs fail closed. A bounded acknowledgement cache makes accepted request IDs idempotent. Invalid network work changes only sanitized transport rejection counters/history and consumes no gameplay RNG.

The Cloudflare-compatible Worker/Durable Object owns only ephemeral communication: human join code, opaque host/resume capabilities, membership, pending claims, connection state, relay queues, sequence/ack cache, heartbeat, limits, and short expiry. A bounded room snapshot is kept in Durable Object storage so hibernation cannot silently drop a live room; it may temporarily contain capabilities and queued, already-filtered relay payloads, and is deleted on host close or expiry. The service does not parse game rules or persist player profiles/campaigns. Join codes are not capabilities. Capabilities use platform randomness and deployed transport uses platform TLS; no custom cryptography is introduced. Coordinator unavailability may disconnect companions but cannot corrupt the native game.

A browser join creates only a pending transient client. The host explicitly maps it to one existing stable seat. A valid resume capability is scoped to that room/client/seat and is delivered only over the client channel. It cannot claim another seat, survive revocation/expiry, or transfer a controller reservation. One gameplay seat may have its existing local controller plus one approved companion input surface. Existing authority revision, immutable prompt response, and request-ID checks deterministically reject duplicated local/companion submissions.

The browser stores only room code, room ID, transient client ID, approved seat number, and opaque resume capability. Private gameplay payloads remain in memory, are absent from URLs/history, are inserted into the DOM only after the privacy gate, and are removed when obscured, disconnected, expired, revoked, or cleared. TLS protects transport, but the prototype is not end-to-end encrypted against the room-service operator.

## Consequences

Local shared-screen/controller play remains independent of companion availability. A deterministic fake transport is the primary integration harness; the WebSocket/Worker path is replaceable. The prototype has no accounts, matchmaking, room enumeration, chat, voice, camera, biometrics, fingerprinting, analytics, advertising, campaign persistence, service worker, push notification, or production deployment requirement. Production security certification, abuse review, longer reliability work, and physical-device/network validation remain future gates.
