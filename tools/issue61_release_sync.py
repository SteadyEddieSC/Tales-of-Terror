#!/usr/bin/env python3
"""Synchronize the bounded v0.1.8 internal release identity and records."""

from __future__ import annotations

from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
CURRENT = "v0.1.7"
NEXT = "v0.1.8"


def _path(relative: str) -> Path:
    return ROOT / relative


def _replace(relative: str, old: str, new: str, expected: int = 1) -> None:
    path = _path(relative)
    text = path.read_text(encoding="utf-8")
    actual = text.count(old)
    if actual != expected:
        raise RuntimeError(f"{relative}: expected {expected} marker(s), found {actual}: {old!r}")
    path.write_text(text.replace(old, new), encoding="utf-8")


def _replace_version_everywhere(relative: str) -> None:
    path = _path(relative)
    text = path.read_text(encoding="utf-8")
    if CURRENT not in text:
        raise RuntimeError(f"{relative}: missing current release marker {CURRENT}")
    path.write_text(text.replace(CURRENT, NEXT), encoding="utf-8")


def _create(relative: str, content: str) -> None:
    path = _path(relative)
    if path.exists():
        raise RuntimeError(f"{relative}: release record already exists")
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(content.rstrip() + "\n", encoding="utf-8")


def main() -> int:
    for relative in (
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
    ):
        _replace_version_everywhere(relative)

    portable_path = _path("docs/technical/Portable_Playtest_Bundles.md")
    portable = portable_path.read_text(encoding="utf-8")
    if portable.count(CURRENT) != 4:
        raise RuntimeError("Portable_Playtest_Bundles.md current release marker count drifted")
    portable = portable.replace(
        "v0.1.7 produces internal, portable Windows and Linux x86_64 "
        "player-owned-interaction candidates",
        "v0.1.8 produces internal, portable Windows and Linux x86_64 "
        "controlled-reveal and shared-screen privacy candidates",
    ).replace(CURRENT, NEXT)
    portable_path.write_text(portable, encoding="utf-8")

    readme_old = """3. Complete v0.1.7 with explicit stable-seat ownership for threshold choices, votes, card play, checks, Director acknowledgement, Restless action/pass, and stage continuation.
"""
    readme_new = """3. Complete v0.1.8 with a fail-closed, controller-first private reveal ceremony before ordinary Lantern House play.
"""
    _replace("README.md", readme_old, readme_new)
    _replace(
        "README.md",
        "The normal player route now begins at the title, accepts 1–8 stable seats, confirms the authored mode or safe cooperative fallback, opens the Tale Library, presents a public briefing, and runs Lantern House through explicit controller-owned interaction windows before a privacy-safe ending and clean rematch. The shared screen identifies eligible, committed, pending, and owning stable seats; A/Enter commits, B/Escape uses an authored pass where allowed, and X/H opens Help. Phones remain optional.",
        "The normal player route now begins at the title, accepts 1–8 stable seats, confirms the authored mode or safe cooperative fallback, opens the Tale Library, presents a public briefing, and completes a controller-owned private reveal ceremony before ordinary Lantern House play. The television remains neutral between seats, identifies only the authorized stable seat, opens only that seat's allowlisted RoleSession projection, clears private presentation before advancing, and then continues through explicit player-owned interaction windows to a privacy-safe ending and clean rematch. A/Enter opens or closes the authorized reveal, B/Escape cancels back to the shield, and X/H opens Help only after private content is cleared. Phones remain optional.",
    )
    _replace(
        "README.md",
        "v0.1.7 builds on the accepted v0.1.6 Tale Library by replacing remaining fixture-like automatic progression with stable-seat-owned threshold, vote, card, check, Director, afterlife, and continuation decisions. Invalid, wrong-seat, paused, stale, or duplicate input cannot advance the Tale or consume Director RNG. Production still contains only Lantern House. No human pilot, physical-controller, TV, or remote-device validation occurred and no manual pass is claimed; issue #39 remains deferred.",
        "v0.1.8 builds on the accepted v0.1.7 player-owned interaction route with a deterministic controlled-reveal queue for seat-private role information. Wrong-seat, stale, duplicate, cancel, Help, disconnect/reconnect, reset/rematch, and restored-session paths fail closed to a neutral shield without transferring authorization or exposing private role, faction, objective, action, target, provenance, or result data. Production still contains only Lantern House. No human pilot, physical-controller, television, viewing-distance, accessibility, household, or remote-device validation occurred and no manual pass is claimed; issue #39 remains deferred.",
    )

    changelog_entry = """## v0.1.8 - Controlled Reveal & Shared-Screen Privacy Hardening

- Added a deterministic controller-first privacy ceremony between public briefing and ordinary Lantern House play: neutral shield, authorized stable seat, allowlisted private reveal, safe close, and public continuation.
- Kept RoleSession as the only private-data and acknowledgement authority while the presentation-only PrivateRevealFlow owns only phase, queue position, authorized seat, and reveal revision.
- Added wrong-seat, duplicate, cancel, Help, disconnect/reconnect, reset/rematch, restoration, 1–8 seat, full-route, GUT, and recursive privacy-canary coverage.
- Preserved the exact one-Tale catalog/package identities, roles and balance, gameplay/Director RNG, snapshots and report schemas, no-phone route, and unchanged Companion graph.
- Issue #44 remains open: the inherited Companion dependency audit still reports GHSA-f88m-g3jw-g9cj; this game-only release does not deploy or publicly release Companion services.

"""
    _replace("CHANGELOG.md", "# Changelog\n\n", "# Changelog\n\n" + changelog_entry)

    gdd_append = """

## Controlled reveal and shared-screen privacy

v0.1.8 inserts a deterministic presentation-only reveal ceremony after the public briefing and before ordinary Tale interaction. The television starts and returns to a neutral shield, publicly names only the currently authorized stable seat, and accepts open/close input only from that seat. RoleSession remains the source of assignments, private projections, and acknowledgement; PrivateRevealFlow owns no role, faction, objective, action, rule, board, outcome, or RNG authority.

Private presentation is cleared before authorization advances, Help opens, a reveal is cancelled, the authorized seat disconnects, a session resets or rematches, the route returns to title, or a scene is torn down. Reconnect restores access only to the same stable seat and re-enters through the neutral shield. Restored sessions derive reveal completion from restored RoleSession acknowledgements without changing the snapshot schema. Public television state, history, reports, Help, and Director telemetry remain recursively free of role, faction, objective, action, target, result, and provenance canaries. This release hardens the one existing Lantern House route; it adds no Tale, social content, Director pacing, afterlife depth, or competing gameplay authority.
"""
    gdd_path = _path("docs/gdd/Terror_Turn_GDD.md")
    gdd = gdd_path.read_text(encoding="utf-8")
    if "## Controlled reveal and shared-screen privacy" in gdd:
        raise RuntimeError("GDD v0.1.8 section already exists")
    gdd_path.write_text(gdd.rstrip() + gdd_append + "\n", encoding="utf-8")

    toolchain_old = "v0.1.1 added nine reviewed first-party scripts—four presentation/report runtime files, two standalone suites, one focused GUT script, the memory-writer test seam, and a full-route capture fixture—raising the explicit inventory from 74 to 83 files. v0.1.2 adds the presentation-only internal build-identity reader and its standalone authority-invariance suite, raising the inventory to 85 files. v0.1.4 adds the Tale-package runtime boundary plus its runtime and replay-equivalence suites, raising the inventory to 88 files. v0.1.5 adds the catalog, provider registry, selection state, runtime suite, and export-excluded synthetic provider seam, raising the inventory to 93 files. v0.1.6 adds the scene-independent Tale Library flow model and standalone suite, raising the inventory to 95 files. v0.1.7 adds the scene-independent player-interaction flow model and standalone suite, raising the inventory to 97 files. `playtest_readiness_test.gd`, `playtest_main_route_test.gd`, `portable_build_identity_test.gd`, `tale_package_test.gd`, `tale_catalog_test.gd`, `tale_library_test.gd`, `player_owned_interaction_test.gd`, and `tale_replay_equivalence_test.gd` are fail-closed workflow steps. `tools/validate_playtest_readiness.py` verifies the report fixture schema, exact capture dimensions, full-route capture composition, approved user-data destination, required test surfaces, and absence of reporting network APIs or forbidden serialized identity fields. Both quality gates remain zero-finding over the complete 97-file inventory."
    toolchain_new = "v0.1.1 added nine reviewed first-party scripts—four presentation/report runtime files, two standalone suites, one focused GUT script, the memory-writer test seam, and a full-route capture fixture—raising the explicit inventory from 74 to 83 files. v0.1.2 adds the presentation-only internal build-identity reader and its standalone authority-invariance suite, raising the inventory to 85 files. v0.1.4 adds the Tale-package runtime boundary plus its runtime and replay-equivalence suites, raising the inventory to 88 files. v0.1.5 adds the catalog, provider registry, selection state, runtime suite, and export-excluded synthetic provider seam, raising the inventory to 93 files. v0.1.6 adds the scene-independent Tale Library flow model and standalone suite, raising the inventory to 95 files. v0.1.7 adds the scene-independent player-interaction flow model and standalone suite, raising the inventory to 97 files. v0.1.8 adds the presentation-only private-reveal flow and standalone privacy suite, raising the inventory to 99 files. `playtest_readiness_test.gd`, `playtest_main_route_test.gd`, `portable_build_identity_test.gd`, `tale_package_test.gd`, `tale_catalog_test.gd`, `tale_library_test.gd`, `player_owned_interaction_test.gd`, `private_reveal_flow_test.gd`, and `tale_replay_equivalence_test.gd` are fail-closed workflow steps. `tools/validate_playtest_readiness.py` verifies the report fixture schema, exact capture dimensions, full-route capture composition, approved user-data destination, required test surfaces, and absence of reporting network APIs or forbidden serialized identity fields. Both quality gates remain zero-finding over the complete 99-file inventory."
    _replace("docs/technical/Toolchain_and_Testing.md", toolchain_old, toolchain_new)

    repository_old = """          test -f docs/releases/v0.1.7-player-owned-interaction-pass.md
          test -f docs/playtests/v0.1.7-player-owned-interaction-evidence.md
"""
    repository_new = repository_old + """          test -f docs/releases/v0.1.8-controlled-reveal-shared-screen-privacy.md
          test -f docs/playtests/v0.1.8-controlled-reveal-evidence.md
"""
    _replace(".github/workflows/repository-checks.yml", repository_old, repository_new)

    _create(
        "docs/releases/v0.1.8-controlled-reveal-shared-screen-privacy.md",
        """# v0.1.8 — Controlled Reveal & Shared-Screen Privacy Hardening

## Release purpose

This release turns the existing seat-private RoleSession projections into an explicit controller-first reveal ceremony before ordinary Lantern House play. It reuses the accepted stable-seat, social, rules, board, Director, Tale package, catalog, snapshot, report, and presentation foundations.

## Player-facing change

After the public briefing, the shared television remains on a neutral shield until the identified stable seat confirms. Only that seat can open its allowlisted private role view. The same seat closes and acknowledges the view before the screen returns to neutral and advances deterministically to the next seat. Once all required acknowledgements complete, the existing player-owned interaction route begins. Phones remain optional.

## Authority and privacy boundary

`PrivateRevealFlow` owns presentation authorization only: phase, sorted stable-seat queue, current seat, and reveal revision. `RoleSession` remains the authority for assignments, private projection, and acknowledgement. Wrong-seat, unsupported, stale, duplicate, cancel, Help, disconnect, reconnect, reset, rematch, return, teardown, and restored-session paths fail closed without transferring authorization, consuming gameplay or Director RNG, or exposing private role, faction, objective, action, target, result, or provenance data.

## Compatibility

The release preserves the exact one-entry Tale catalog and Lantern House package identities, authored roles and balance, gameplay outcomes, snapshot and schema-v2 report contracts, replay equivalence, 1–8 stable seats, no-phone play, reset/rematch behavior, and unchanged Companion dependency graph. It adds no second Tale, Director pacing expansion, afterlife-depth expansion, social content, network authority, account, or cloud requirement.

## Validation boundary

Repository policy, zero-finding GDScript lint and formatting, typed Godot import, all inherited standalone suites, the controlled-reveal privacy suite, full controller route, snapshot restoration, deterministic simulations, local browser/service/native integration, GUT/JUnit, and exact-head Windows/Linux portable assembly are required before merge. No human, physical-controller, television, viewing-distance, accessibility, household, fun, balance, or privacy-certification result is claimed; issue #39 remains deferred.

Issue #44 remains open. Companion services are not deployed or publicly released, and this release does not suppress, weaken, or bypass the inherited dependency audit.""",
    )

    _create(
        "docs/playtests/v0.1.8-controlled-reveal-evidence.md",
        """# v0.1.8 Controlled Reveal Automated Evidence

## Classification

This record covers automated and headless implementation evidence only. It is not a human playtest report and contains no household, physical-controller, television, viewing-distance, accessibility, duration, fun, balance, privacy-certification, or remote-device observation.

## Evidence contract

The final exact source head, workflow run IDs, portable artifact IDs, and wrapper digests are recorded on PR #62 after release synchronization. Build manifests independently carry the exact source commit and release `v0.1.8`; this document intentionally avoids a self-referential commit field.

Required successful evidence includes repository checks, the complete Godot 4.7 workflow, controlled-reveal and recursive privacy-canary tests, snapshot restoration, the controller-driven full main route, replay and 1–8 seat simulations, local browser-to-native integration, GUT/JUnit, and Windows/Linux portable-bundle validation. The separate Companion workflow may retain only the documented issue #44 audit failure with no dependency, suppression, threshold, protocol, service, configuration, or deployment change.

## Preserved identities

- Production Tale ID: `lantern_house_vertical_slice`
- Display name: Lantern House
- Catalog SHA-256: `2b478fd0d11fa075c2050409193aa06e6b9ca4dcf6efd4e4c550a9f3a5ff9db6`
- Package SHA-256: `abb39d6bfbdf8d7de108379f08180c13efb99bbffa3e53f30eaaa8de7f459dee`

Issue #39 remains the only place for future human-session evidence.""",
    )

    changed = [
        ".github/workflows/portable-builds.yml",
        ".github/workflows/repository-checks.yml",
        "CHANGELOG.md",
        "README.md",
        "docs/gdd/Terror_Turn_GDD.md",
        "docs/playtests/v0.1.8-controlled-reveal-evidence.md",
        "docs/releases/v0.1.8-controlled-reveal-shared-screen-privacy.md",
        "docs/technical/Portable_Playtest_Bundles.md",
        "docs/technical/Toolchain_and_Testing.md",
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
    ]
    manifest = _path("artifacts/issue61-release-sync-files.txt")
    manifest.parent.mkdir(parents=True, exist_ok=True)
    manifest.write_text("\n".join(changed) + "\n", encoding="utf-8")
    print(f"Prepared {len(changed)} v0.1.8 release files")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
