from __future__ import annotations

from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def read(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8")


def write(path: str, text: str) -> None:
    target = ROOT / path
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_text(text, encoding="utf-8")


def replace_once(path: str, old: str, new: str) -> None:
    text = read(path)
    if text.count(old) != 1:
        raise SystemExit(f"{path}: expected one release-sync marker, found {text.count(old)}")
    write(path, text.replace(old, new))


def main() -> int:
    version_files = [
        ".github/workflows/portable-builds.yml",
        "game/project.godot",
        "game/src/build/internal_build_identity.gd",
        "game/tests/fixtures/playtest_report_v2.json",
        "game/tests/fixtures/playtest_report_v2.md",
        "game/tests/portable_build_identity_test.gd",
        "packaging/portable/START_HERE.md",
        "packaging/portable/bundle_spec.json",
        "tools/portable_bundle.py",
        "tools/test_portable_bundle.py",
        "tools/validate_playtest_readiness.py",
        "docs/technical/Portable_Playtest_Bundles.md",
    ]
    for path in version_files:
        text = read(path)
        if "v0.1.6" not in text:
            raise SystemExit(f"{path}: missing v0.1.6 marker")
        write(path, text.replace("v0.1.6", "v0.1.7"))

    start = read("packaging/portable/START_HERE.md")
    start = start.replace(
        "Tale Library Candidate Build",
        "Player-Owned Interaction Candidate Build",
    )
    start = start.replace(
        "Connect controllers before starting. Press A to claim a stable seat; an owned controller presses A again to confirm. One to eight seats are supported. Enter is the keyboard development fallback and Space can confirm. Press X/H for Help. Phones are optional: the native Godot host remains authoritative and the complete session can be played without phones.",
        "Connect controllers before starting. Press A to claim a stable seat; an owned controller presses A again to confirm. One to eight seats are supported. During Lantern House, the shared screen identifies the eligible or owning stable seat for each threshold choice, vote, card play, check, Director acknowledgement, Restless action, and stage continuation. Enter is the keyboard development fallback and Space can confirm. Press X/H for Help. Phones are optional: the native Godot host remains authoritative and the complete session can be played without phones.",
    )
    write("packaging/portable/START_HERE.md", start)

    portable = read("docs/technical/Portable_Playtest_Bundles.md")
    portable = portable.replace(
        "internal, portable Windows and Linux x86_64 Tale-Library candidates",
        "internal, portable Windows and Linux x86_64 player-owned-interaction candidates",
    )
    write("docs/technical/Portable_Playtest_Bundles.md", portable)

    changelog = read("CHANGELOG.md")
    heading = "# Changelog\n\n"
    if changelog.count(heading) != 1 or "## v0.1.7 - Player-Owned Interaction Pass" in changelog:
        raise SystemExit("CHANGELOG.md release marker drifted")
    entry = """## v0.1.7 - Player-Owned Interaction Pass

- Replaced remaining repeated-confirm and automatic Lantern House progression with explicit stable-seat interaction windows for threshold choices, council voting, card play, courage checks, Director acknowledgement, Restless action/pass, and stage continuation.
- Added privacy-safe shared-screen projections for eligible, committed, pending, and owning seats while preserving existing RulesSession, BoardState, Director, and RoleSession authority.
- Added wrong-seat, paused, duplicate, stale, pass, RNG-invariance, full-route, and 1–8 seat deterministic coverage plus permanent CI/toolchain registration.
- Preserved the exact one-Tale catalog/package identities, story, balance, snapshots, report schema, Companion graph, and no-phone route.
- Issue #44 remains open: the unchanged Companion dependency graph retains GHSA-f88m-g3jw-g9cj; this game-only release does not deploy or publicly release Companion services.

"""
    write("CHANGELOG.md", changelog.replace(heading, heading + entry))

    replace_once(
        "README.md",
        "3. Complete v0.1.6 with a controller-first Tale Library that selects the exact Lantern House package through the reviewed catalog and provider boundaries.",
        "3. Complete v0.1.7 with explicit stable-seat ownership for threshold choices, votes, card play, checks, Director acknowledgement, Restless action/pass, and stage continuation.",
    )
    replace_once(
        "README.md",
        "The normal player route now begins at the title, accepts 1–8 stable seats, confirms the authored mode or safe cooperative fallback, opens the Tale Library, presents a public briefing, runs the selected Tale, publishes a privacy-safe ending, and supports a clean rematch. D-pad or left stick changes Library focus; keyboard arrows remain a development fallback; A/Enter confirms; B/Escape returns; and X/H opens Help. Returning from the briefing restores the focused and selected Tale, stable seats, controller ownership, and mode. Phones remain optional.",
        "The normal player route now begins at the title, accepts 1–8 stable seats, confirms the authored mode or safe cooperative fallback, opens the Tale Library, presents a public briefing, and runs Lantern House through explicit controller-owned interaction windows before a privacy-safe ending and clean rematch. The shared screen identifies eligible, committed, pending, and owning stable seats; A/Enter commits, B/Escape uses an authored pass where allowed, and X/H opens Help. Phones remain optional.",
    )
    replace_once(
        "README.md",
        "v0.1.6 exposes the accepted v0.1.5 catalog/provider architecture through a provenance-free player route without changing the catalog or Tale package identities. Invalid catalog, localization, provider, package, or selection input remains on the Library and preserves prior setup state. Production still contains only Lantern House. No human pilot, physical-controller, TV, or remote-device validation occurred and no manual pass is claimed; issue #39 remains deferred.",
        "v0.1.7 builds on the accepted v0.1.6 Tale Library by replacing remaining fixture-like automatic progression with stable-seat-owned threshold, vote, card, check, Director, afterlife, and continuation decisions. Invalid, wrong-seat, paused, stale, or duplicate input cannot advance the Tale or consume Director RNG. Production still contains only Lantern House. No human pilot, physical-controller, TV, or remote-device validation occurred and no manual pass is claimed; issue #39 remains deferred.",
    )

    gdd = read("docs/gdd/Terror_Turn_GDD.md")
    anchor = "Once the active Tale starts, selection is immutable. Production continues to contain only Lantern House.\n"
    if gdd.count(anchor) != 1 or "## Player-owned interaction pass" in gdd:
        raise SystemExit("GDD player-owned section marker drifted")
    section = """

## Player-owned interaction pass

v0.1.7 converts the remaining integration-fixture operations into explicit stable-seat controller windows. Threshold and council responses remain RulesSession work; card play belongs to the card owner; the legal seat attempts the courage check; any eligible active seat may acknowledge the bounded Director window; the actual Restless seat acts or passes; and an active seat explicitly continues each authored stage.

The shared-screen projection exposes only public interaction kind, instruction, controls, eligible seats, committed seats, pending seats, owner seat, public option labels, and whether pass is authored. Wrong-seat, disconnected, paused, stale, duplicate, and late input cannot mutate authority. Invalid presentation input consumes no Director RNG. This pass changes how players own the existing verbs; it does not add story, balance, cards, events, roles, factions, endings, a second Tale, or a competing gameplay authority.
"""
    write("docs/gdd/Terror_Turn_GDD.md", gdd.replace(anchor, anchor + section))

    toolchain = read("docs/technical/Toolchain_and_Testing.md")
    old = "v0.1.6 adds the scene-independent Tale Library flow model and standalone suite, raising the inventory to 95 files. `playtest_readiness_test.gd`, `playtest_main_route_test.gd`, `portable_build_identity_test.gd`, `tale_package_test.gd`, `tale_catalog_test.gd`, `tale_library_test.gd`, and `tale_replay_equivalence_test.gd` are fail-closed workflow steps. `tools/validate_playtest_readiness.py` verifies the report fixture schema, exact capture dimensions, full-route capture composition, approved user-data destination, required test surfaces, and absence of reporting network APIs or forbidden serialized identity fields. Both quality gates remain zero-finding over the complete 95-file inventory."
    new = "v0.1.6 adds the scene-independent Tale Library flow model and standalone suite, raising the inventory to 95 files. v0.1.7 adds the scene-independent player-interaction flow model and standalone suite, raising the inventory to 97 files. `playtest_readiness_test.gd`, `playtest_main_route_test.gd`, `portable_build_identity_test.gd`, `tale_package_test.gd`, `tale_catalog_test.gd`, `tale_library_test.gd`, `player_owned_interaction_test.gd`, and `tale_replay_equivalence_test.gd` are fail-closed workflow steps. `tools/validate_playtest_readiness.py` verifies the report fixture schema, exact capture dimensions, full-route capture composition, approved user-data destination, required test surfaces, and absence of reporting network APIs or forbidden serialized identity fields. Both quality gates remain zero-finding over the complete 97-file inventory."
    if toolchain.count(old) != 1:
        raise SystemExit("Toolchain inventory marker drifted")
    write("docs/technical/Toolchain_and_Testing.md", toolchain.replace(old, new))

    checks_path = ".github/workflows/repository-checks.yml"
    checks = read(checks_path)
    checks_marker = "          test -f docs/playtests/v0.1.6-tale-library-evidence.md\n"
    checks_new = checks_marker + "          test -f docs/releases/v0.1.7-player-owned-interaction-pass.md\n          test -f docs/playtests/v0.1.7-player-owned-interaction-evidence.md\n"
    if checks.count(checks_marker) != 1 or "v0.1.7-player-owned-interaction-pass.md" in checks:
        raise SystemExit("repository-checks release marker drifted")
    write(checks_path, checks.replace(checks_marker, checks_new))

    write(
        "docs/releases/v0.1.7-player-owned-interaction-pass.md",
        """# v0.1.7 — Player-Owned Interaction Pass

## Release purpose

This release turns the accepted Lantern House vertical slice from a technically complete integration route into an explicitly player-owned controller route. It reuses all existing rules, board, Director, social, Tale package, catalog, provider, snapshot, report, and presentation authorities.

## Player-facing change

The shared screen now presents bounded interaction windows for threshold choices, council votes, card play, courage checks, Director acknowledgement, Restless action or pass, and stage continuation. Each window identifies the eligible, committed, pending, or owning stable seats and the available public controls. One input event can produce at most one authoritative commit.

## Authority and privacy boundary

`PlayerInteractionFlow` derives presentation and routing state from existing authorities. RulesSession still owns prompt and vote responses; card/check/Director/role operations still execute through the accepted coordinator and authorities. Wrong-seat, paused, disconnected, stale, duplicate, and late inputs fail without authority mutation. Invalid acknowledgement consumes no Director RNG. Public interaction projections exclude private objectives, provider/package provenance, source paths, hashes, and report contents.

## Compatibility

The release preserves the exact one-entry Tale catalog and Lantern House package identities, authored story and balance, cards and events, roles/factions/afterlife content, snapshots, schema-v2 reports, deterministic replay, 1–8 stable seats, no-phone play, rematch/reset, and the unchanged Companion graph.

## Validation boundary

Repository policy, zero-finding GDScript lint and formatting, typed Godot import, all inherited standalone suites, the player-owned interaction suite, full controller route, deterministic simulations, local browser/service/native integration, GUT/JUnit, and exact-head Windows/Linux portable assembly are required before merge. No human, physical-controller, television, accessibility, household, fun, balance, or privacy-certification result is claimed; issue #39 remains deferred.

Issue #44 remains open. Companion services are not deployed or publicly released, and this release does not suppress or weaken the inherited dependency audit.
""",
    )
    write(
        "docs/playtests/v0.1.7-player-owned-interaction-evidence.md",
        """# v0.1.7 Player-Owned Interaction Automated Evidence

## Classification

This record covers automated and headless implementation evidence only. It is not a human playtest report and contains no household, physical-controller, television, accessibility, duration, fun, balance, privacy-certification, or remote-device observation.

## Evidence contract

The final exact source head, workflow run IDs, portable artifact IDs, and wrapper digests are recorded on PR #60 after release synchronization. Build manifests independently carry the exact source commit and release `v0.1.7`; this document intentionally avoids a self-referential commit field.

Required successful evidence includes repository checks, the complete Godot 4.7 workflow, the player-owned interaction suite, the controller-driven full main route, replay and 1–8 seat simulations, local browser-to-native integration, GUT/JUnit, and Windows/Linux portable-bundle validation. The separate Companion workflow may retain only the documented issue #44 audit failure with no dependency, suppression, threshold, protocol, service, configuration, or deployment change.

## Preserved identities

- Production Tale ID: `lantern_house_vertical_slice`
- Display name: Lantern House
- Catalog SHA-256: `2b478fd0d11fa075c2050409193aa06e6b9ca4dcf6efd4e4c550a9f3a5ff9db6`
- Package SHA-256: `abb39d6bfbdf8d7de108379f08180c13efb99bbffa3e53f30eaaa8de7f459dee`

Issue #39 remains the only place for future human-session evidence.
""",
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
