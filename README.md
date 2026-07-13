# Terror Turn (working title)

A controller-first, 1–8 player digital horror board-game adventure with shared-screen play, shifting alliances, meaningful afterlife roles, an adaptive Underteller/Director, and optional browser companion devices.

> **Repository note:** The repository remains `SteadyEddieSC/Tales-of-Terror` until the working title receives a careful trademark, storefront, domain, and common-law review. An informal search is not legal clearance.

## Current priorities

1. Preserve the Godot 4.7 controller/display, visual, exploration, Living Board, rules, Director, and social-role foundations.
2. Prove cooperative, betrayal, Horror, Changed, Restless, reconnect, and mixed-outcome play before production content volume.
3. Keep private views transport-neutral and authority-safe for the later companion prototype.
4. Add Cloudflare companion rooms only after the local gameplay and privacy contracts remain stable.

## Foundation decisions

- Godot 4.7 stable, typed GDScript, Compatibility renderer.
- 960×540 logical world viewport, 16:9 output, scalable high-resolution UI.
- Windows and Linux first; Batocera validation through Linux builds.
- Shared camera by default; split screen only for specific modes or mini-games.
- Native Godot host remains authoritative in early online-capable releases.
- No normal-length mode leaves eliminated players inactive.

## Repository map

- `game/` — Godot project
- `docs/gdd/` — canonical living Game Design Document
- `docs/technical/` — project setup and architecture
- `docs/decisions/` — design/architecture decision records
- `art/` and `audio/` — source and exports
- `web/companion/` — future browser companion UI
- `services/room-service/` — future Cloudflare room coordinator

## Documentation rule

Markdown is canonical for Git history. Polished DOCX snapshots are generated at meaningful milestones and retained in the starter package or tagged release artifacts. The long-term choice between Git LFS and Release attachments is recorded before v0.0.3.

## License status

The repository is public, but no final reuse license has been selected. The intended direction is source-available and noncommercial rather than an OSI open-source license. See `LICENSE-DECISION.md`.
