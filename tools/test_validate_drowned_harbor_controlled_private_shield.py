#!/usr/bin/env python3
"""Mutation tests for the export-excluded P0.17 controlled-private proof."""

from __future__ import annotations

import copy
from pathlib import Path
from typing import Callable

from validate_drowned_harbor_controlled_private_shield import (
    ADAPTER_PATH,
    EXPORT_PRESETS_PATH,
    MANIFEST_PATH,
    PACKAGE_JSON_PATH,
    PACKAGE_LOCK_PATH,
    PROVIDER_PATH,
    README_PATH,
    SCHEMA_PATH,
    SHELL_PATH,
    SUMMARY_PATH,
    SURFACE_PATH,
    TECHNICAL_PATH,
    TEST_PATH,
    ControlledPrivateValidationError,
    read_json,
    validate_documentation_text,
    validate_fixture_package,
    validate_godot_sources_text,
    validate_manifest_and_production_boundary,
)

ROOT = Path(".")
Mutation = Callable[[], None]


def expect_failure(name: str, mutation: Mutation) -> None:
    try:
        mutation()
    except ControlledPrivateValidationError:
        return
    raise AssertionError(f"mutation did not fail closed: {name}")


def fixture_mutation(mutate: Callable[[dict], None]) -> None:
    package = copy.deepcopy(read_json(ROOT / "game/tests/drowned_harbor_dev_only/state_projection_fixtures_v1.json"))
    schema = copy.deepcopy(read_json(ROOT / SCHEMA_PATH))
    mutate(package)
    validate_fixture_package(package, schema)


def source_mutation(
    relative: Path,
    old: str,
    new: str,
) -> None:
    sources = {
        ADAPTER_PATH: (ROOT / ADAPTER_PATH).read_text(encoding="utf-8"),
        SURFACE_PATH: (ROOT / SURFACE_PATH).read_text(encoding="utf-8"),
        SHELL_PATH: (ROOT / SHELL_PATH).read_text(encoding="utf-8"),
        TEST_PATH: (ROOT / TEST_PATH).read_text(encoding="utf-8"),
    }
    if old not in sources[relative]:
        raise AssertionError(f"mutation source text not found in {relative}: {old}")
    sources[relative] = sources[relative].replace(old, new, 1)
    validate_godot_sources_text(
        sources[ADAPTER_PATH],
        sources[SURFACE_PATH],
        sources[SHELL_PATH],
        sources[TEST_PATH],
    )


def boundary_mutation(
    mutate: Callable[[dict, dict, str, str, dict, dict], None],
) -> None:
    manifest = copy.deepcopy(read_json(ROOT / MANIFEST_PATH))
    catalog = copy.deepcopy(read_json(ROOT / "game/data/tales/tale_catalog_v1.json"))
    provider = (ROOT / PROVIDER_PATH).read_text(encoding="utf-8")
    presets = (ROOT / EXPORT_PRESETS_PATH).read_text(encoding="utf-8")
    package_json = copy.deepcopy(read_json(ROOT / PACKAGE_JSON_PATH))
    package_lock = copy.deepcopy(read_json(ROOT / PACKAGE_LOCK_PATH))
    values = [manifest, catalog, provider, presets, package_json, package_lock]
    mutate(*values)
    validate_manifest_and_production_boundary(*values)


def documentation_mutation(old: str, new: str) -> None:
    technical = (ROOT / TECHNICAL_PATH).read_text(encoding="utf-8")
    summary = (ROOT / SUMMARY_PATH).read_text(encoding="utf-8")
    readme = (ROOT / README_PATH).read_text(encoding="utf-8")
    if old not in summary:
        raise AssertionError(f"documentation mutation source not found: {old}")
    validate_documentation_text(technical, summary.replace(old, new, 1), readme)


def fixture_by_id(package: dict, fixture_id: str) -> dict:
    return next(value for value in package["fixtures"] if value["fixture_id"] == fixture_id)


def main() -> int:
    package = read_json(ROOT / "game/tests/drowned_harbor_dev_only/state_projection_fixtures_v1.json")
    validate_fixture_package(package, read_json(ROOT / SCHEMA_PATH))
    validate_godot_sources_text(
        (ROOT / ADAPTER_PATH).read_text(encoding="utf-8"),
        (ROOT / SURFACE_PATH).read_text(encoding="utf-8"),
        (ROOT / SHELL_PATH).read_text(encoding="utf-8"),
        (ROOT / TEST_PATH).read_text(encoding="utf-8"),
    )

    validate_manifest_and_production_boundary(
        read_json(ROOT / MANIFEST_PATH),
        read_json(ROOT / "game/data/tales/tale_catalog_v1.json"),
        (ROOT / PROVIDER_PATH).read_text(encoding="utf-8"),
        (ROOT / EXPORT_PRESETS_PATH).read_text(encoding="utf-8"),
        read_json(ROOT / PACKAGE_JSON_PATH),
        read_json(ROOT / PACKAGE_LOCK_PATH),
    )

    mutations: list[tuple[str, Mutation]] = [
        ("missing DH-FIX-007", lambda: fixture_mutation(lambda p: p["fixtures"].pop())),
        (
            "duplicate fixture ID",
            lambda: fixture_mutation(
                lambda p: p["fixtures"][-1].__setitem__("fixture_id", "DH-FIX-006")
            ),
        ),
        (
            "wrong UI binding",
            lambda: fixture_mutation(
                lambda p: fixture_by_id(p, "DH-FIX-007").__setitem__("storyboard_id", "DH-UI-015")
            ),
        ),
        (
            "wrong interaction binding",
            lambda: fixture_mutation(
                lambda p: fixture_by_id(p, "DH-FIX-007").__setitem__("trace_id", "DH-IS-015")
            ),
        ),
        (
            "public path reads private state",
            lambda: fixture_mutation(
                lambda p: fixture_by_id(p, "DH-FIX-007")["projection_map"]["public"].__setitem__(
                    "objective", "private.objective"
                )
            ),
        ),
        (
            "private event enters public history",
            lambda: fixture_mutation(
                lambda p: fixture_by_id(p, "DH-FIX-003")["expected_events"][0].__setitem__(
                    "classification", "public"
                )
            ),
        ),
        (
            "non-neutral shield",
            lambda: source_mutation(
                SHELL_PATH,
                'const NEUTRAL_SHIELD_TEXT: String = "PRIVATE REVIEW IN PROGRESS"',
                'const NEUTRAL_SHIELD_TEXT: String = "SEAT 3 BARGAIN REVIEW"',
            ),
        ),
        (
            "default confirm focus",
            lambda: source_mutation(
                SURFACE_PATH,
                '"private_surface_identity",',
                '"confirm_private_bargain",',
            ),
        ),
        (
            "timeout acceptance",
            lambda: source_mutation(
                SURFACE_PATH,
                "func acknowledge(request: Dictionary) -> Dictionary:",
                "func timeout_accept() -> void:\n\tpass\n\n\nfunc acknowledge(request: Dictionary) -> Dictionary:",
            ),
        ),
        (
            "wall-clock authority",
            lambda: source_mutation(
                ADAPTER_PATH,
                "func load_and_project(request: Dictionary, path: String = FIXTURE_PATH) -> Dictionary:",
                "func wall_clock_authority() -> int:\n\treturn Time.get_ticks_msec()\n\n\nfunc load_and_project(request: Dictionary, path: String = FIXTURE_PATH) -> Dictionary:",
            ),
        ),
        (
            "wrong stable-seat acceptance",
            lambda: source_mutation(ADAPTER_PATH, 'return _rejected("wrong_stable_seat"', 'return _rejected("accepted"'),
        ),
        (
            "stale revision acceptance",
            lambda: source_mutation(ADAPTER_PATH, 'return _rejected("stale_source_revision"', 'return _rejected("accepted"'),
        ),
        (
            "duplicate commit",
            lambda: source_mutation(SHELL_PATH, "_commit_count += 1", "_commit_count += 1\n\t_commit_count += 1"),
        ),
        (
            "Refuse focus routed to acknowledgement",
            lambda: source_mutation(
                SHELL_PATH,
                "result = refuse_private_bargain()",
                "result = request_acknowledgement()",
            ),
        ),
        (
            "Refuse creates a bargain commit",
            lambda: source_mutation(
                SHELL_PATH,
                "\t_clear_private_application_state()",
                "\t_commit_count += 1\n\t_clear_private_application_state()",
            ),
        ),
        (
            "lifetime-global commit gating",
            lambda: source_mutation(
                SHELL_PATH,
                "\t_pending_public_result = {",
                (
                    "\tif _commit_count != 0:\n"
                    '\t\treturn _reject_pending_action("duplicate_acknowledgement")\n'
                    "\t_pending_public_result = {"
                ),
            ),
        ),
        (
            "lifetime-global public-event suppression",
            lambda: source_mutation(
                SHELL_PATH,
                "if not _committed_public_event_identities.has(event_identity):",
                "if _public_event_count == 0:",
            ),
        ),
        (
            "duplicate identity not checked",
            lambda: source_mutation(
                SHELL_PATH,
                "_committed_private_event_identities.has(private_event_identity)",
                "false # duplicate identity ignored",
            ),
        ),
        (
            "distinct handoff incorrectly treated as duplicate",
            lambda: source_mutation(
                SHELL_PATH,
                "_committed_private_event_identities.has(private_event_identity)",
                "_committed_private_event_identities.has(private_event_key)",
            ),
        ),
        (
            "private surface cleared before duplicate validation",
            lambda: source_mutation(
                SHELL_PATH,
                "\tvar acknowledged: Dictionary = _private_surface.acknowledge(request)",
                (
                    "\t_private_surface.clear_private_state()\n"
                    "\tvar acknowledged: Dictionary = _private_surface.acknowledge(request)"
                ),
            ),
        ),
        (
            "second public event omitted",
            lambda: source_mutation(
                SHELL_PATH,
                "prototype_public_event_emitted.emit(event.duplicate(true))",
                "pass # second public event omitted",
            ),
        ),
        (
            "second history entry omitted",
            lambda: source_mutation(
                SHELL_PATH,
                "_public_history.append(event.duplicate(true))",
                "pass # second history entry omitted",
            ),
        ),
        (
            "RESTORING Cancel clears pending result",
            lambda: source_mutation(
                SHELL_PATH,
                "func cancel_or_defer() -> Dictionary:\n",
                (
                    "func cancel_or_defer() -> Dictionary:\n"
                    "\tif _mode == SurfaceMode.RESTORING:\n"
                    "\t\t_pending_public_result.clear()\n"
                ),
            ),
        ),
        (
            "RECOVERY Cancel clears pending result",
            lambda: source_mutation(
                SHELL_PATH,
                "func cancel_or_defer() -> Dictionary:\n",
                (
                    "func cancel_or_defer() -> Dictionary:\n"
                    "\tif _mode == SurfaceMode.RECOVERY:\n"
                    "\t\t_pending_public_result.clear()\n"
                ),
            ),
        ),
        (
            "post-commit shield advertises Cancel",
            lambda: source_mutation(
                SHELL_PATH,
                'controller_prompts = "RESTORATION PENDING  |  X / H: HELP"',
                'controller_prompts = "B / ESC: CANCEL  |  X / H: HELP"',
            ),
        ),
        (
            "pending interruption moves to neutral shield",
            lambda: source_mutation(
                SHELL_PATH,
                (
                    "\t\t_mode = SurfaceMode.RECOVERY\n"
                    "\t\t_status = NEUTRAL_SHIELD_TEXT\n"
                    "\t\t_lifecycle_audit.append(\"post_commit_interruption_recovery_preserved\")"
                ),
                (
                    "\t\t_mode = SurfaceMode.NEUTRAL_SHIELD\n"
                    "\t\t_status = NEUTRAL_SHIELD_TEXT\n"
                    "\t\t_lifecycle_audit.append(\"post_commit_interruption_recovery_preserved\")"
                ),
            ),
        ),
        (
            "pending interruption clears result",
            lambda: source_mutation(
                SHELL_PATH,
                "func interrupt_presentation() -> Dictionary:\n",
                (
                    "func interrupt_presentation() -> Dictionary:\n"
                    "\tif not _pending_public_result.is_empty():\n"
                    "\t\t_pending_public_result.clear()\n"
                ),
            ),
        ),
        (
            "pending disconnect is restricted to RESTORING",
            lambda: source_mutation(
                SHELL_PATH,
                "func handle_disconnect() -> Dictionary:\n"
                "\tif not _pending_public_result.is_empty():",
                "func handle_disconnect() -> Dictionary:\n"
                "\tif _mode == SurfaceMode.RESTORING:",
            ),
        ),
        (
            "pending disconnect moves to neutral shield",
            lambda: source_mutation(
                SHELL_PATH,
                "\t\t_mode = SurfaceMode.RECOVERY\n"
                "\t\t_status = NEUTRAL_SHIELD_TEXT\n"
                "\t\t_lifecycle_audit.append(\"post_commit_disconnect_recovery_preserved\")",
                "\t\t_mode = SurfaceMode.NEUTRAL_SHIELD\n"
                "\t\t_status = NEUTRAL_SHIELD_TEXT\n"
                "\t\t_lifecycle_audit.append(\"post_commit_disconnect_recovery_preserved\")",
            ),
        ),
        (
            "pending disconnect clears result",
            lambda: source_mutation(
                SHELL_PATH,
                "func handle_disconnect() -> Dictionary:\n",
                "func handle_disconnect() -> Dictionary:\n\t_pending_public_result.clear()\n",
            ),
        ),
        (
            "pending disconnect full clear permits a new handoff",
            lambda: source_mutation(
                SHELL_PATH,
                "func handle_disconnect() -> Dictionary:\n"
                "\tif not _pending_public_result.is_empty():\n"
                "\t\t_clear_private_state_preserving_public_result()",
                "func handle_disconnect() -> Dictionary:\n"
                "\tif not _pending_public_result.is_empty():\n"
                "\t\t_clear_private_application_state()",
            ),
        ),
        (
            "pending disconnect creates a second private commit",
            lambda: source_mutation(
                SHELL_PATH,
                'append("post_commit_disconnect_recovery_preserved")',
                'append("post_commit_disconnect_recovery_preserved")\n'
                "\t\t_commit_count += 1",
            ),
        ),
        (
            "pending disconnect emits a public event early",
            lambda: source_mutation(
                SHELL_PATH,
                'append("post_commit_disconnect_recovery_preserved")',
                'append("post_commit_disconnect_recovery_preserved")\n'
                "\t\tprototype_public_event_emitted.emit({})",
            ),
        ),
        (
            "post-interruption restoration impossible",
            lambda: source_mutation(
                SHELL_PATH,
                "if _mode not in [SurfaceMode.RESTORING, SurfaceMode.RECOVERY]:",
                "if _mode != SurfaceMode.RESTORING:",
            ),
        ),
        (
            "new handoff allowed before pending restoration",
            lambda: source_mutation(
                SHELL_PATH,
                "or not _pending_public_result.is_empty()",
                "or false # pending restoration ignored",
            ),
        ),
        (
            "post-commit Cancel creates second private commit",
            lambda: source_mutation(
                SHELL_PATH,
                'append("post_commit_cancel_rejected_restoration_preserved")',
                (
                    'append("post_commit_cancel_rejected_restoration_preserved")\n'
                    "\t\t_commit_count += 1"
                ),
            ),
        ),
        (
            "post-control or disconnect restoration omits public history entry",
            lambda: source_mutation(
                SHELL_PATH,
                "_public_history.append(event.duplicate(true))",
                "pass # post-control history omitted",
            ),
        ),
        (
            "post-control restoration duplicates public event",
            lambda: source_mutation(
                SHELL_PATH,
                "prototype_public_event_emitted.emit(event.duplicate(true))",
                (
                    "prototype_public_event_emitted.emit(event.duplicate(true))\n"
                    "\t\tprototype_public_event_emitted.emit(event.duplicate(true))"
                ),
            ),
        ),
        (
            "missing payload clearing",
            lambda: source_mutation(SURFACE_PATH, "\t_private_payload.clear()", "\tpass # payload retained"),
        ),
        (
            "private payload retained across handoffs",
            lambda: source_mutation(
                SHELL_PATH,
                "not _private_surface.is_cleared()",
                "false # retained payload accepted",
            ),
        ),
        (
            "healing mutation",
            lambda: source_mutation(SHELL_PATH, "func restore_public(", "func heal_seat() -> void:\n\tpass\n\n\nfunc restore_public("),
        ),
        (
            "reroll mutation",
            lambda: source_mutation(SHELL_PATH, "func restore_public(", "func reroll() -> void:\n\tpass\n\n\nfunc restore_public("),
        ),
        (
            "inventory restoration",
            lambda: source_mutation(SHELL_PATH, "func restore_public(", "func restore_inventory() -> void:\n\tpass\n\n\nfunc restore_public("),
        ),
        (
            "objective reset",
            lambda: source_mutation(SHELL_PATH, "func restore_public(", "func reset_objective() -> void:\n\tpass\n\n\nfunc restore_public("),
        ),
        (
            "missing approved overrides",
            lambda: boundary_mutation(
                lambda _m, _c, _p, _e, j, _l: j.pop("overrides", None)
            ),
        ),
        (
            "approved PostCSS override drift",
            lambda: boundary_mutation(
                lambda _m, _c, _p, _e, j, _l: j["overrides"].__setitem__(
                    "postcss", "8.5.22"
                )
            ),
        ),
        (
            "extra override key",
            lambda: boundary_mutation(
                lambda _m, _c, _p, _e, j, _l: j["overrides"].__setitem__(
                    "sharp", "0.35.2"
                )
            ),
        ),
        (
            "resolutions field introduced",
            lambda: boundary_mutation(
                lambda _m, _c, _p, _e, j, _l: j.__setitem__(
                    "resolutions", {"undici": "7.29.0"}
                )
            ),
        ),
        (
            "locked PostCSS remediation drift",
            lambda: boundary_mutation(
                lambda _m, _c, _p, _e, _j, lock: lock["packages"][
                    "node_modules/postcss"
                ].__setitem__("version", "8.5.22")
            ),
        ),
        (
            "locked Undici remediation drift",
            lambda: boundary_mutation(
                lambda _m, _c, _p, _e, _j, lock: lock["packages"][
                    "node_modules/undici"
                ].__setitem__("version", "7.28.0")
            ),
        ),
        (
            "direct Sharp dev dependency",
            lambda: boundary_mutation(
                lambda _m, _c, _p, _e, j, _l: j["devDependencies"].__setitem__(
                    "sharp", "0.35.2"
                )
            ),
        ),
        (
            "production registration",
            lambda: boundary_mutation(
                lambda _m, catalog, _p, _e, _j, _l: catalog["entries"].append(
                    {"tale_id": "drowned_harbor_dev_only"}
                )
            ),
        ),
        (
            "export inclusion",
            lambda: boundary_mutation(
                lambda _m, _c, _p, _e, _j, _l: _m.__setitem__("playable_export_authorized", True)
            ),
        ),
        (
            "human evidence claim",
            lambda: boundary_mutation(
                lambda m, _c, _p, _e, _j, _l: m.__setitem__("human_evidence_claimed", True)
            ),
        ),
        (
            "certification claim",
            lambda: documentation_mutation(
                "Validation is automated/headless.",
                "Validation is automated/headless. Privacy certified.",
            ),
        ),
    ]
    for name, mutation in mutations:
        expect_failure(name, mutation)
    print(f"Validated {len(mutations)} P0.17 fail-closed mutation cases")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
