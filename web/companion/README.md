# Browser Companion Prototype

Accessible responsive v0.0.9 presentation/input surface. It joins a host room, waits for explicit stable-seat approval, gates private content, submits bounded intents, resumes the same seat, and clears ephemeral local data. It is not a browser game runtime.

Run from the repository root:

```powershell
npm ci
npm run test:browser
npm run dev:browser
```

The local room service defaults to `http://127.0.0.1:8787`. See [Browser_Companion_UX_Privacy.md](../../docs/technical/Browser_Companion_UX_Privacy.md) and [Companion_Protocol.md](../../docs/technical/Companion_Protocol.md).
