# Repository guidance

## Scope

These instructions apply to the entire repository.

## Project conventions

- Target official Godot 4.7.1-stable with standard, typed GDScript and the Compatibility renderer. The project feature marker remains the Godot 4.7 family marker.
- Preserve the 960×540 logical viewport unless an ADR explicitly changes it.
- Keep device discovery, player/seat state, and UI presentation in separate components.
- Prefer semantic input actions over device-specific input checks in presentation code.
- Support controller-first shared-screen play; keyboard input is a development fallback.
- Keep canonical design and technical documentation in Markdown under `docs/`.
- Record lasting architecture decisions in a numbered ADR.
- Do not add large binary art or audio without following the repository's Git LFS decision.
- Put editable masters under art/source or audio/source, derived runtime assets under game/assets, and provenance in art/provenance.json.
- Use lowercase snake_case names with an asset role suffix such as _panel, _icon, _texture, _loop, or _voice.
- Never commit an asset whose source, license, generator, or derivation is unknown.
- Keep exploration ownership and deterministic rules in testable models; device IDs belong in input/ownership adapters, not pawn presentation.
- Resolve simultaneous shared-world interactions deterministically and document the arbitration rule.
- Treat authored board definitions as immutable inputs; authoritative BoardState mutations and queries must remain scene-independent and testable.
- Keep board presentation signal-driven. Future turns, cards, Director logic, networking, and companion clients may request or replicate changes but must not mutate board state directly.
- Keep authored rules content declarative and validated; generic rules and presentation paths must never branch on stable event or card IDs.
- Treat `RulesSession` as the scene-independent authority for phases, prompts, seeded randomness, events, card zones, inventory, votes, consequences, and ordered rules history.
- Validate complete consequence bundles before committing them; board effects must request mutations from `BoardState`.
- Keep Director profiles and candidates declarative and validated; generic Director runtime and presentation paths must never branch on stable candidate IDs.
- Derive Director telemetry read-only from authoritative local state, and keep the salted Director RNG isolated from rules/deck/check RNG.
- Treat Director output as proposals only; rules and board work must cross public `RulesSession` and `BoardState` validation boundaries before Director state records acceptance.
- Treat `RoleSession` as the scene-independent authority for stable-seat roles/forms, factions, reveal/lifecycle state, private objectives/actions, bounded social resources, transitions, outcomes, role RNG, and social audit history.
- Keep role assignment RNG isolated from RulesSession and Director streams; invalid social content, plans, transitions, and actions must consume no role RNG.
- Generate public, seat-private, faction-private, and spoiler-diagnostics social views independently; public histories, errors, host payloads, and Director signals must never expose unrevealed social data.
- Keep generic social runtime and presentation free of literal role, faction, form, objective, and fixture ID branches; authored social work must cross public RulesSession and BoardState proposal boundaries.
- Keep native Godot as the only gameplay authority; companion services relay ephemeral communication and browsers submit bounded intents through public authority methods.
- Keep companion public, stable-seat private, authored faction-private, and sanitized diagnostics projections explicit and independently generated; never forward authoritative snapshots, RNG, raw audits, capabilities, or another seat's secrets.
- Keep transient browser/client identity separate from stable-seat ownership. Companion claims require host approval, reconnect is scoped to the same room/client/seat, and invalid network work must consume no gameplay RNG or partially mutate gameplay.
- Preserve standalone SceneTree regression tests and deterministic simulations alongside focused GUT tests; adopt GUT incrementally rather than rewriting proven harnesses.
- Pin third-party addons and development tools to reviewed releases, retain their licenses and provenance, and exclude vendored code from first-party lint and formatting checks.
- Run `gdlint` and `gdformat --check` against first-party GDScript only. CI must never auto-format source, and repository-wide formatting belongs in a separately bounded change.

## Validation

- Run Godot headless project validation when a compatible executable is available.
- Run the checks represented in `.github/workflows/repository-checks.yml` before publishing.
- Run python tools/validate_assets.py and git lfs track when asset rules change.
- Record tests that require physical controllers, television viewing distance, or specific displays.

## Git workflow

- Work on a dedicated branch; do not commit feature work directly to `main`.
- Keep commits focused and link pull requests to their GitHub issue.
