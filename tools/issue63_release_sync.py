#!/usr/bin/env python3
"""Prepare the bounded v0.1.9 release-identity and evidence synchronization."""

from __future__ import annotations

from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
CURRENT = "v0.1.8"
NEXT = "v0.1.9"

RELEASE_FILES = [
    "CHANGELOG.md",
    "README.md",
    "docs/gdd/Terror_Turn_GDD.md",
    "docs/playtests/v0.1.9-automated-playthrough-evidence.md",
    "docs/releases/v0.1.9-automated-playthrough-deadlock-lab.md",
    "docs/technical/Portable_Playtest_Bundles.md",
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


def _path(relative: str) -> Path:
    return ROOT / relative


def _replace_once(relative: str, old: str, new: str) -> None:
    path = _path(relative)
    text = path.read_text(encoding="utf-8")
    if text.count(old) != 1:
        raise RuntimeError(f"{relative} expected one guarded marker: {old!r}")
    path.write_text(text.replace(old, new), encoding="utf-8")


def _replace_version_everywhere(relative: str) -> None:
    path = _path(relative)
    text = path.read_text(encoding="utf-8")
    count = text.count(CURRENT)
    if count < 1:
        raise RuntimeError(f"{relative} has no {CURRENT} release marker")
    if NEXT in text:
        raise RuntimeError(f"{relative} already contains {NEXT}")
    path.write_text(text.replace(CURRENT, NEXT), encoding="utf-8")


def _prepend_changelog() -> None:
    path = _path("CHANGELOG.md")
    text = path.read_text(encoding="utf-8")
    marker = "# Changelog\n\n"
    if not text.startswith(marker) or "## v0.1.9 - Automated Playthrough & Deadlock Lab" in text:
        raise RuntimeError("CHANGELOG.md release insertion marker drifted")
    section = """## v0.1.9 - Automated Playthrough & Deadlock Lab

- Added an export-excluded deterministic virtual-player lab that completes the accepted Lantern House route across 1–8 stable seats, four seeds, and five legal strategy profiles.
- Added paired replay-equivalence checks plus bounded stale, duplicate, wrong-seat, idle, disconnect/reconnect, reset, rematch, and mid-prompt restoration probes.
- Added privacy-safe failure reproduction records containing only bounded public lifecycle, interaction, seed, strategy, and digest data.
- Registered the lab as a permanent fail-closed Godot workflow step and raised the enforced first-party GDScript inventory from 99 to 100 files.
- Preserved all gameplay, Tale, package/catalog, role/faction, Director, Companion, snapshot, report-schema, and human-playtest boundaries; issue #44 and issue #39 remain open.

"""
    path.write_text(marker + section + text[len(marker) :], encoding="utf-8")


def _update_readme() -> None:
    _replace_once(
        "README.md",
        "3. Complete v0.1.8 with a fail-closed, controller-first private reveal ceremony before ordinary Lantern House play.",
        "3. Complete v0.1.9 with a deterministic automated playthrough and deadlock lab that repeatedly proves the accepted Lantern House route across supported seat counts.",
    )
    _replace_once(
        "README.md",
        "The normal player route now begins at the title, accepts 1–8 stable seats, confirms the authored mode or safe cooperative fallback, opens the Tale Library, presents a public briefing, and completes a controller-owned private reveal ceremony before ordinary Lantern House play. The television remains neutral between seats, identifies only the authorized stable seat, opens only that seat's allowlisted RoleSession projection, clears private presentation before advancing, and then continues through explicit player-owned interaction windows to a privacy-safe ending and clean rematch. A/Enter opens or closes the authorized reveal, B/Escape cancels back to the shield, and X/H opens Help only after private content is cleared. Phones remain optional.",
        "The normal player route remains title, 1–8 stable-seat lobby, authored mode or safe cooperative fallback, Tale Library, public briefing, controller-owned private reveal ceremony, explicit player-owned Lantern House interactions, privacy-safe ending, and clean rematch. The television remains neutral between private reveals, authorization stays with one stable seat at a time, and phones remain optional. v0.1.9 adds no player-facing rules or story; it adds an export-excluded virtual-player lab that repeatedly exercises this accepted route.",
    )
    _replace_once(
        "README.md",
        "v0.1.8 builds on the accepted v0.1.7 player-owned interaction route with a deterministic controlled-reveal queue for seat-private role information. Wrong-seat, stale, duplicate, cancel, Help, disconnect/reconnect, reset/rematch, and restored-session paths fail closed to a neutral shield without transferring authorization or exposing private role, faction, objective, action, target, provenance, or result data. Production still contains only Lantern House. No human pilot, physical-controller, television, viewing-distance, accessibility, household, or remote-device validation occurred and no manual pass is claimed; issue #39 remains deferred.",
        "v0.1.9 runs the accepted route through deterministic virtual-seat strategies across 1–8 seats and four seeds, with paired replay checks and bounded wrong-seat, stale, duplicate, idle, disconnect/reconnect, reset, rematch, and restoration probes. The validated matrix is automated mechanical evidence only: it does not establish fun, tension, fairness, comprehension, balance, physical-controller behavior, television readability, accessibility, household networking, remote-device behavior, or privacy certification. Production still contains only Lantern House, and issue #39 remains deferred.",
    )


def _append_gdd() -> None:
    path = _path("docs/gdd/Terror_Turn_GDD.md")
    text = path.read_text(encoding="utf-8").rstrip()
    heading = "## Automated playthrough and deadlock lab"
    if heading in text:
        raise RuntimeError("GDD already contains v0.1.9 automated lab section")
    section = """

## Automated playthrough and deadlock lab

v0.1.9 adds an export-excluded deterministic virtual-player lab around the accepted Lantern House route. It completes controlled reveals and existing player-owned interaction windows across 1–8 stable seats, four fixed seeds, and cooperative, cautious, risk-seeking, alternating-legal, and delayed-reconnect profiles. Each normal configuration is run twice and compared by terminal reason, authority digest, public-history digest, and bounded step count.

The lab also probes wrong-seat, stale, duplicate, idle, disconnect/reconnect, protected-reset, rematch, and mid-prompt restoration behavior. A run must terminate inside the authored step bound or emit a bounded privacy-safe reproduction record containing only seed, seat count, strategy, public lifecycle/stage/operation/interaction identifiers, reason, and authority/public-history digests. The lab adds no gameplay authority, Tale content, balance decision, telemetry, player profile, or production runtime surface. Its passing matrix is mechanical evidence only and cannot replace human evaluation of fun, tension, fairness, comprehension, accessibility, television readability, or physical controls.
"""
    path.write_text(text + section, encoding="utf-8")


def _update_portable_document() -> None:
    path = _path("docs/technical/Portable_Playtest_Bundles.md")
    text = path.read_text(encoding="utf-8")
    old = (
        "v0.1.8 produces internal, portable Windows and Linux x86_64 "
        "controlled-reveal and shared-screen privacy candidates"
    )
    new = (
        "v0.1.9 produces internal, portable Windows and Linux x86_64 "
        "automated-playthrough and deadlock-lab candidates"
    )
    if text.count(old) != 1:
        raise RuntimeError("Portable_Playtest_Bundles.md release description drifted")
    text = text.replace(old, new)
    if text.count(CURRENT) != 2:
        raise RuntimeError("Portable_Playtest_Bundles.md current release marker count drifted")
    path.write_text(text.replace(CURRENT, NEXT), encoding="utf-8")


def _write_release_records() -> None:
    release = """# v0.1.9 — Automated Playthrough & Deadlock Lab

## Release purpose

This release adds an export-excluded deterministic virtual-player lab that repeatedly completes the accepted Lantern House route before a human playtest can be scheduled. It targets mechanical deadlocks, ownership errors, stale or duplicate mutation, reconnect transfer, replay divergence, and reset/rematch/restoration contamination.

## Automated matrix

The committed lab covers all supported 1–8 stable-seat counts, four fixed seeds (`1`, `17`, `4706`, and `65521`), and five deterministic legal profiles: cooperative, cautious, risk-seeking, alternating, and delayed reconnect. Every normal configuration runs twice for replay comparison, producing 320 completed normal runs. Additional 1-, 4-, and 8-seat cases cover rematch, protected reset, and mid-prompt snapshot restoration.

## Failure contract

Every run is bounded by an explicit reveal and active-Tale step budget. A failure emits one reproduction record containing only seed, seat count, strategy, bounded step, lifecycle, stage and operation indexes, public interaction ID and kind, bounded reason, authority digest, and public-history digest. Private roles, factions, objectives, actions, targets, device identity, room secrets, report contents, source paths, and package/catalog provenance are excluded.

## Preserved authority and content

The lab invokes the accepted controlled-reveal, RulesSession, RoleSession, BoardState, DirectorRuntime, coordinator, reset, rematch, and snapshot boundaries. It introduces no gameplay authority and changes no runtime source, story, balance, cards, events, roles, factions, objectives, outcomes, Director pacing, afterlife behavior, Tale package, catalog, provider, localization, snapshot schema, or report schema. Production still contains only Lantern House.

## Validation boundary

Repository policy, zero-finding first-party lint and formatting, typed Godot import, the complete inherited Godot/GUT/browser-native suite, the permanent automated lab, and exact-head Windows/Linux portable bundles must pass before merge. The separate Companion workflow may retain only the documented issue #44 dependency-audit failure. This automated evidence does not establish human fun, tension, fairness, comprehension, balance, physical-controller behavior, television readability, accessibility, household behavior, remote-device behavior, or privacy certification; issue #39 remains deferred.
"""
    evidence = """# v0.1.9 Automated Playthrough Evidence

## Classification

This is automated, deterministic, headless mechanical evidence. It is not a human playtest report and contains no household, physical-controller, television, viewing-distance, accessibility, fun, tension, fairness, comprehension, balance, privacy-certification, or remote-device observation.

## Matrix contract

The automated playthrough lab executes:

- stable-seat counts 1 through 8;
- seeds `1`, `17`, `4706`, and `65521`;
- cooperative, cautious, risk-seeking, alternating, and delayed-reconnect profiles;
- two runs per normal configuration for terminal reason, authority digest, public-history digest, and step-count equivalence;
- selected 1-, 4-, and 8-seat rematch, protected-reset, and mid-prompt restoration cases.

That is 160 normal configurations and 320 paired normal runs, plus nine lifecycle probes. A passing exact-head run means this bounded matrix reached valid terminal/reset/rematch/restoration states without emitting a reproduction failure. It does not prove that no defect exists outside the matrix.

## Reproduction and privacy contract

Failures are fail-closed and emit only bounded public reproduction fields: seed, seat count, strategy, step, lifecycle, stage index, operation index, interaction ID, interaction kind, reason, authority digest, and public-history digest. Private role/faction/objective/action/target data, device identity, room secrets, report contents, source paths, and package/catalog provenance are forbidden.

## Preserved identities

- Production Tale ID: `lantern_house_vertical_slice`
- Display name: Lantern House
- Catalog SHA-256: `2b478fd0d11fa075c2050409193aa06e6b9ca4dcf6efd4e4c550a9f3a5ff9db6`
- Package SHA-256: `abb39d6bfbdf8d7de108379f08180c13efb99bbffa3e53f30eaaa8de7f459dee`

The final exact source head, workflow run IDs, portable artifact IDs, and artifact digests are recorded on PR #64 after release synchronization. Issue #39 remains the only location for future human-session evidence. Issue #44 remains the unchanged Companion dependency-audit boundary.
"""
    release_path = _path("docs/releases/v0.1.9-automated-playthrough-deadlock-lab.md")
    evidence_path = _path("docs/playtests/v0.1.9-automated-playthrough-evidence.md")
    if release_path.exists() or evidence_path.exists():
        raise RuntimeError("v0.1.9 release records already exist")
    release_path.write_text(release, encoding="utf-8")
    evidence_path.write_text(evidence, encoding="utf-8")


def main() -> int:
    for relative in (
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

    _prepend_changelog()
    _update_readme()
    _append_gdd()
    _update_portable_document()
    _write_release_records()

    for relative in RELEASE_FILES:
        path = _path(relative)
        if not path.is_file():
            raise RuntimeError(f"missing prepared release file: {relative}")
        if relative not in {"CHANGELOG.md", "docs/gdd/Terror_Turn_GDD.md"}:
            text = path.read_text(encoding="utf-8")
            if CURRENT in text:
                raise RuntimeError(f"stale current-release marker remains in {relative}")
    print("Prepared bounded v0.1.9 release synchronization")
    for relative in RELEASE_FILES:
        print(relative)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
