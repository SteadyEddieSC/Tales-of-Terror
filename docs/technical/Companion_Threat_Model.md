# Companion Prototype Threat Model and Known Limitations

## Assets and actors

Protected assets are seat-private roles, factions, objectives, actions, prompts, card/inventory references, opaque host/resume capabilities, and authoritative game integrity. Actors include the trusted native host, an honest or tampered browser, another seat, a network observer, the room-service operator, and an unauthenticated requester.

## Mitigated prototype threats

| Threat | Boundary |
|---|---|
| Browser attempts direct mutation | Protocol accepts only bounded prompt/role intents; Godot revalidates through public authorities. |
| Cross-seat disclosure or action | Explicit host claim plus exact client/seat resume scope; recursive view and error leak tests. |
| Replay/double input | Request-ID acknowledgement cache, monotonic ordering, authoritative revisions, and authority-level immutable prompt/use rules. |
| Stale or out-of-order work | Rejected before authority calls with a sanitized refresh response. |
| Wire schema confusion | Exact nine-field envelopes plus message-specific payload maps reject unknown, mixed snake/camel, ambiguous, or uncontrolled recursive conversion. |
| Malformed/oversized/flooded input | JSON, depth, collection, string, body, rate, queue, room, and client bounds. |
| Partial mutation/RNG drift | Bridge prevalidation and existing atomic `RulesSession`/`RoleSession`/`BoardState` boundaries; invalid-path snapshot/RNG tests. |
| Capability exposure | Distinct platform-random capabilities, no URL/query placement, no logs/diagnostics, no cross-client return, no committed real tokens. |
| Room enumeration/persistence | No listing endpoint, short expiry, no accounts/profiles/campaign history, destroy on close/expiry. |
| Host disappears while clients remain active | Persisted host timestamp and host-loss deadline are independent from ordinary client activity. |
| Hidden authored board room disclosure | Unrevealed spaces are omitted before labels, IDs, occupants, features, hazards, blockers, or identifying connectors are projected. |
| Coordinator loss | Companions fail disconnected; local native game continues and remains uncorrupted. |
| Shared-device shoulder surfing | Explicit gate, honest warning, quick obscure, DOM removal, and clear-local-data action. |

## Accepted limitations

The relay operator can observe already-filtered payloads and the short-lived Durable Object snapshot can temporarily hold capabilities and queued filtered payloads; there is no end-to-end encryption and no custom cryptography. Join codes are human-friendly routing handles, not passwords. A stolen live resume capability can impersonate that client/seat until revocation or expiry, though simultaneous reuse and wrong-seat use fail. The prototype does not provide production-grade abuse detection, DDoS protection, moderation, forensic logs, disaster recovery, uptime, key rotation, certificate/domain configuration, or formal penetration testing.

Cloudflare credentials and a live deployment are intentionally unnecessary. Local Worker/native/browser integration and deterministic elapsed-time tests are not a production penetration test. Physical-phone Wi-Fi behavior, mixed Android/iOS browsers, router/firewall/NAT variants, television-distance review, production security/privacy/legal review, and long-session observation remain deferred manual gates.
