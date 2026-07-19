# Ephemeral Companion Room Service

Cloudflare-compatible v0.0.9 Worker/Durable Object relay. It owns only ephemeral join, claim, resume, ordering, bounded queue/acknowledgement, heartbeat, and expiry state; Native Godot owns all gameplay.

Run from the repository root:

```powershell
npm ci
npm run test:service
npm run dev:service
```

No Cloudflare account or credentials are required for local emulation. See [Companion_Room_Service.md](../../docs/technical/Companion_Room_Service.md), [Companion_Protocol.md](../../docs/technical/Companion_Protocol.md), and [Companion_Threat_Model.md](../../docs/technical/Companion_Threat_Model.md).
