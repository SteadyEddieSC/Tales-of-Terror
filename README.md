# Terror Turn (working title)

A controller-first, 1–8 player digital horror board-game adventure with shared-screen play, shifting alliances, meaningful afterlife roles, an adaptive Underteller/Director, and optional browser companion devices.

> **Repository note:** The repository remains `SteadyEddieSC/Tales-of-Terror` until the working title receives a careful trademark, storefront, domain, and common-law review. An informal search is not legal clearance.

## Current priorities

1. Preserve the Godot 4.7.1 controller/display, visual, exploration, Living Board, rules, Director, social-role, and companion authority foundations.
2. Run every legacy regression and deterministic simulation plus the focused GUT 9.7.1 boundary suite under the pinned engine patch.
3. Freeze one v0.1.3 Windows/Linux pilot candidate with verified Godot 4.7.1 export templates, exact artifact identity, bounded facilitator materials, and blank human evidence.
4. Keep pilot intake and findings triage offline, exact-schema, privacy-rejecting, deterministic, and unable to promote automated evidence into human or physical claims.
5. Keep stable-seat privacy and exactly-once intent boundaries regression-tested through the fake transport, local Worker emulation, browser lab, and native-authority E2E.
6. Defer production Cloudflare deployment, accounts, matchmaking, persistence, full remote play, and security certification until their own reviewed gates.

The normal player route now begins at the title, accepts 1–8 stable seats, confirms the authored mode or safe cooperative fallback, presents a public briefing, runs the Lantern House tale, publishes a privacy-safe ending, and supports a clean rematch. Unowned controller A/keyboard Enter claims a seat without double-advancing; a later owned A/Enter or Space confirms the roster. Contextual guidance identifies stage and waiting progress, X/H opens controller-accessible help, and a finalized report can be explicitly exported as local JSON and Markdown. The v0.1.3 Help surface shows bounded internal build/support identity without entering gameplay snapshots, reports, or authority digests. Controllers are primary, keyboard remains a development fallback, and phones remain optional. Stage 1 prepares the pilot only; no human session or manual pass is claimed.

## Foundation decisions

- Official Godot 4.7.1-stable, typed GDScript, Compatibility renderer.
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
- `web/companion/` — accessible browser companion prototype
- `services/room-service/` — ephemeral Cloudflare-compatible room coordinator
- `game/addons/gut/` — vendored GUT 9.7.1 framework, excluded from first-party style checks
- `requirements-dev.in` — reviewed direct GDScript Toolkit selection
- `requirements-dev.txt` — fully resolved, exact, hash-locked Python development environment

## Validation layers

GitHub Actions keeps the established `Godot 4.7 headless validation`, companion, and foundation check identities. The Godot job verifies the official Linux archive checksum, enforces zero-finding first-party `gdlint` and `gdformat --check` gates, runs all standalone tests and simulations, runs the focused GUT suite, and uploads quality evidence plus GUT JUnit output. A separate portable-build job verifies the official Godot 4.7.1 export-template checksum, exports and smokes Linux, validates both platform bundles, and uploads internal Windows/Linux archives without committing binaries. See `docs/technical/Toolchain_and_Testing.md` for equivalent Windows commands.

## Documentation rule

Markdown is canonical for Git history. Polished DOCX snapshots are generated at meaningful milestones and retained in the starter package or tagged release artifacts. The long-term choice between Git LFS and Release attachments is recorded before v0.0.3.

## License status

The repository is public, but no final reuse license has been selected. The intended direction is source-available and noncommercial rather than an OSI open-source license. See `LICENSE-DECISION.md`.
