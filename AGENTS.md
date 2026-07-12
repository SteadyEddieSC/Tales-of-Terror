# Repository guidance

## Scope

These instructions apply to the entire repository.

## Project conventions

- Target Godot 4.7 with standard, typed GDScript and the Compatibility renderer.
- Preserve the 960×540 logical viewport unless an ADR explicitly changes it.
- Keep device discovery, player/seat state, and UI presentation in separate components.
- Prefer semantic input actions over device-specific input checks in presentation code.
- Support controller-first shared-screen play; keyboard input is a development fallback.
- Keep canonical design and technical documentation in Markdown under `docs/`.
- Record lasting architecture decisions in a numbered ADR.
- Do not add large binary art or audio without following the repository's Git LFS decision.

## Validation

- Run Godot headless project validation when a compatible executable is available.
- Run the checks represented in `.github/workflows/repository-checks.yml` before publishing.
- Record tests that require physical controllers, television viewing distance, or specific displays.

## Git workflow

- Work on a dedicated branch; do not commit feature work directly to `main`.
- Keep commits focused and link pull requests to their GitHub issue.
