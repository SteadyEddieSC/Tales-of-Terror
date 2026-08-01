#!/usr/bin/env python3
"""Mutation tests for the export-excluded P0.18 High Water proof."""

from __future__ import annotations

import copy
from pathlib import Path
from typing import Callable

from validate_drowned_harbor_high_water_transformation import (
    ADAPTER_PATH,
    CATALOG_PATH,
    EXPORT_PRESETS_PATH,
    ISOLATION_TEST_PATH,
    LANTERN_PACKAGE_PATH,
    MANIFEST_PATH,
    PACKAGE_JSON_PATH,
    PACKAGE_LOCK_PATH,
    PROJECT_PATH,
    PROVIDER_PATH,
    README_PATH,
    SCENE_PATH,
    SCHEMA_PATH,
    SHELL_PATH,
    SUMMARY_PATH,
    TECHNICAL_PATH,
    TEST_PATH,
    UID_SIDECAR_PATHS,
    WORKFLOW_PATH,
    HighWaterValidationError,
    fixture_by_id,
    read_json,
    validate_documentation_text,
    validate_fixture_package,
    validate_godot_sources_text,
    validate_manifest_and_production_boundary,
    validate_uid_sidecar_contents,
    validate_workflow_text,
    tracked_uid_contents,
)

ROOT = Path(".")
Mutation = Callable[[], None]


def expect_failure(name: str, mutation: Mutation) -> None:
    try:
        mutation()
    except HighWaterValidationError:
        return
    raise AssertionError(f"mutation did not fail closed: {name}")


def fixture_mutation(mutate: Callable[[dict, dict], None]) -> None:
    package = copy.deepcopy(
        read_json(
            ROOT
            / "game/tests/drowned_harbor_dev_only/"
            "state_projection_fixtures_v1.json"
        )
    )
    schema = copy.deepcopy(read_json(ROOT / SCHEMA_PATH))
    mutate(package, schema)
    validate_fixture_package(package, schema)


def source_mutation(relative: Path, old: str, new: str) -> None:
    sources = {
        ADAPTER_PATH: (ROOT / ADAPTER_PATH).read_text(encoding="utf-8"),
        SHELL_PATH: (ROOT / SHELL_PATH).read_text(encoding="utf-8"),
        TEST_PATH: (ROOT / TEST_PATH).read_text(encoding="utf-8"),
        ISOLATION_TEST_PATH: (ROOT / ISOLATION_TEST_PATH).read_text(
            encoding="utf-8"
        ),
        SCENE_PATH: (ROOT / SCENE_PATH).read_text(encoding="utf-8"),
    }
    if old not in sources[relative]:
        raise AssertionError(f"mutation source not found in {relative}: {old}")
    sources[relative] = sources[relative].replace(old, new, 1)
    validate_godot_sources_text(
        sources[ADAPTER_PATH],
        sources[SHELL_PATH],
        sources[TEST_PATH],
        sources[ISOLATION_TEST_PATH],
        sources[SCENE_PATH],
    )


def boundary_mutation(
    mutate: Callable[[dict, dict, dict, str, str, str, dict, dict], None],
) -> None:
    manifest = copy.deepcopy(read_json(ROOT / MANIFEST_PATH))
    catalog = copy.deepcopy(read_json(ROOT / CATALOG_PATH))
    lantern = copy.deepcopy(read_json(ROOT / LANTERN_PACKAGE_PATH))
    provider = (ROOT / PROVIDER_PATH).read_text(encoding="utf-8")
    presets = (ROOT / EXPORT_PRESETS_PATH).read_text(encoding="utf-8")
    project = (ROOT / PROJECT_PATH).read_text(encoding="utf-8")
    package_json = copy.deepcopy(read_json(ROOT / PACKAGE_JSON_PATH))
    package_lock = copy.deepcopy(read_json(ROOT / PACKAGE_LOCK_PATH))
    values = [
        manifest,
        catalog,
        lantern,
        provider,
        presets,
        project,
        package_json,
        package_lock,
    ]
    mutate(*values)
    validate_manifest_and_production_boundary(*values)


def workflow_mutation(old: str, new: str) -> None:
    workflow = (ROOT / WORKFLOW_PATH).read_text(encoding="utf-8")
    if old not in workflow:
        raise AssertionError(f"workflow mutation source not found: {old}")
    validate_workflow_text(workflow.replace(old, new, 1))


def boundary_text_mutation(relative: Path, old: str, new: str) -> None:
    manifest = copy.deepcopy(read_json(ROOT / MANIFEST_PATH))
    catalog = copy.deepcopy(read_json(ROOT / CATALOG_PATH))
    lantern = copy.deepcopy(read_json(ROOT / LANTERN_PACKAGE_PATH))
    texts = {
        PROVIDER_PATH: (ROOT / PROVIDER_PATH).read_text(encoding="utf-8"),
        EXPORT_PRESETS_PATH: (ROOT / EXPORT_PRESETS_PATH).read_text(encoding="utf-8"),
        PROJECT_PATH: (ROOT / PROJECT_PATH).read_text(encoding="utf-8"),
    }
    if old not in texts[relative]:
        raise AssertionError(f"boundary mutation source not found in {relative}: {old}")
    texts[relative] = texts[relative].replace(old, new, 1)
    validate_manifest_and_production_boundary(
        manifest,
        catalog,
        lantern,
        texts[PROVIDER_PATH],
        texts[EXPORT_PRESETS_PATH],
        texts[PROJECT_PATH],
        copy.deepcopy(read_json(ROOT / PACKAGE_JSON_PATH)),
        copy.deepcopy(read_json(ROOT / PACKAGE_LOCK_PATH)),
    )


def documentation_mutation(old: str, new: str) -> None:
    technical = (ROOT / TECHNICAL_PATH).read_text(encoding="utf-8")
    summary = (ROOT / SUMMARY_PATH).read_text(encoding="utf-8")
    readme = (ROOT / README_PATH).read_text(encoding="utf-8")
    if old not in summary:
        raise AssertionError(f"documentation mutation source not found: {old}")
    validate_documentation_text(technical, summary.replace(old, new, 1), readme)


def uid_mutation(mutate: Callable[[dict[Path, str]], None]) -> None:
    tracked = tracked_uid_contents(ROOT)
    contents = {path: tracked[path] for path in UID_SIDECAR_PATHS}
    mutate(contents)
    mutated_tracked = tracked.copy()
    mutated_tracked.update(contents)
    validate_uid_sidecar_contents(contents, mutated_tracked)


def high_water_fixture(package: dict) -> dict:
    return fixture_by_id(package, "DH-FIX-004")


def main() -> int:
    package = read_json(
        ROOT
        / "game/tests/drowned_harbor_dev_only/state_projection_fixtures_v1.json"
    )
    validate_fixture_package(package, read_json(ROOT / SCHEMA_PATH))
    validate_godot_sources_text(
        (ROOT / ADAPTER_PATH).read_text(encoding="utf-8"),
        (ROOT / SHELL_PATH).read_text(encoding="utf-8"),
        (ROOT / TEST_PATH).read_text(encoding="utf-8"),
        (ROOT / ISOLATION_TEST_PATH).read_text(encoding="utf-8"),
        (ROOT / SCENE_PATH).read_text(encoding="utf-8"),
    )

    mutations: list[tuple[str, Mutation]] = [
        (
            "overlength UID payload",
            lambda: uid_mutation(
                lambda contents: contents.__setitem__(
                    UID_SIDECAR_PATHS[0], "uid://dhhighwateradp1\n"
                )
            ),
        ),
        (
            "duplicate UID between new sidecars",
            lambda: uid_mutation(
                lambda contents: contents.__setitem__(
                    UID_SIDECAR_PATHS[1], contents[UID_SIDECAR_PATHS[0]]
                )
            ),
        ),
        (
            "invalid canonical UID character",
            lambda: uid_mutation(
                lambda contents: contents.__setitem__(
                    UID_SIDECAR_PATHS[0], "uid://c5s0l3fkk44zw\n"
                )
            ),
        ),
        (
            "missing UID prefix",
            lambda: uid_mutation(
                lambda contents: contents.__setitem__(
                    UID_SIDECAR_PATHS[0], "c5s0l3fkk448w\n"
                )
            ),
        ),
        (
            "empty UID file",
            lambda: uid_mutation(
                lambda contents: contents.__setitem__(UID_SIDECAR_PATHS[0], "")
            ),
        ),
        (
            "skip generates different result bytes",
            lambda: source_mutation(
                SHELL_PATH,
                '_settle_persistent_summary("semantic_skip")',
                '_committed_result["routes"] = {}\n\t_settle_persistent_summary("semantic_skip")',
            ),
        ),
        (
            "skip changes result revision",
            lambda: source_mutation(
                SHELL_PATH,
                '_settle_persistent_summary("semantic_skip")',
                '_committed_result["result_revision"] = 43\n\t_settle_persistent_summary("semantic_skip")',
            ),
        ),
        (
            "skip consumes RNG",
            lambda: source_mutation(
                SHELL_PATH,
                '_settle_persistent_summary("semantic_skip")',
                '_committed_result["rng_cursor"] = 13\n\t_settle_persistent_summary("semantic_skip")',
            ),
        ),
        (
            "presentation chooses authoritative result",
            lambda: source_mutation(
                SHELL_PATH,
                "\t_presentation_step += 1",
                "\t_committed_result = {}\n\t_presentation_step += 1",
            ),
        ),
        (
            "second transformation commit",
            lambda: source_mutation(
                SHELL_PATH,
                "\t_commit_count += 1",
                "\t_commit_count += 1\n\t_commit_count += 1",
            ),
        ),
        (
            "second public event",
            lambda: source_mutation(
                SHELL_PATH,
                "\t_public_event_count += 1",
                "\t_public_event_count += 1\n\t_public_event_count += 1",
            ),
        ),
        (
            "duplicate history accumulation",
            lambda: source_mutation(
                SHELL_PATH,
                "\t_public_history.append(event.duplicate(true))",
                "\t_public_history.append(event.duplicate(true))\n\t_public_history.append(event.duplicate(true))",
            ),
        ),
        (
            "duplicate transcript accumulation",
            lambda: source_mutation(
                SHELL_PATH,
                '_public_transcript.append(str(summary_entry.get("summary", "")))',
                '_public_transcript.append(str(summary_entry.get("summary", "")))\n\t\t_public_transcript.append(str(summary_entry.get("summary", "")))',
            ),
        ),
        (
            "duplicate replay accumulation",
            lambda: source_mutation(
                SHELL_PATH,
                "_public_replay.append(summary_entry.duplicate(true))",
                "_public_replay.append(summary_entry.duplicate(true))\n\t\t_public_replay.append(summary_entry.duplicate(true))",
            ),
        ),
        (
            "duplicate mirror accumulation",
            lambda: source_mutation(
                SHELL_PATH,
                "\t_mirrored_output.append(summary_entry.duplicate(true))",
                "\t_mirrored_output.append(summary_entry.duplicate(true))\n\t_mirrored_output.append(summary_entry.duplicate(true))",
            ),
        ),
        (
            "missing public event",
            lambda: source_mutation(
                SHELL_PATH,
                "\t_public_event_count += 1",
                "\tpass # public event omitted",
            ),
        ),
        (
            "missing public history",
            lambda: source_mutation(
                SHELL_PATH,
                "\t_public_history.append(event.duplicate(true))",
                "\tpass # public history omitted",
            ),
        ),
        (
            "stale revision accepted",
            lambda: source_mutation(
                ADAPTER_PATH,
                'return _rejected("stale_source_revision"',
                'return _rejected("stale_revision_accepted"',
            ),
        ),
        (
            "unauthorized actor accepted",
            lambda: source_mutation(
                ADAPTER_PATH,
                'return _rejected("unauthorized_actor"',
                'return _rejected("actor_accepted"',
            ),
        ),
        (
            "stable-seat replacement",
            lambda: fixture_mutation(
                lambda p, _s: high_water_fixture(p).__setitem__(
                    "stable_seat_identity_after", "seat_05"
                )
            ),
        ),
        (
            "skip-specific seat relocation",
            lambda: source_mutation(
                SHELL_PATH,
                '_settle_persistent_summary("semantic_skip")',
                '_committed_result["seat_positions"] = {"seat_04": "archive"}\n\t_settle_persistent_summary("semantic_skip")',
            ),
        ),
        (
            "private marker enters public projection",
            lambda: fixture_mutation(
                lambda p, _s: high_water_fixture(p)["projection_map"]["public"].__setitem__(
                    "latent_form", "private.latent_form"
                )
            ),
        ),
        (
            "private marker enters transcript",
            lambda: source_mutation(
                SHELL_PATH,
                '_public_transcript.append(str(summary_entry.get("summary", "")))',
                '_public_transcript.append("PRIVATE_TIDEBOUND_PENDING")',
            ),
        ),
        (
            "private marker enters replay",
            lambda: source_mutation(
                SHELL_PATH,
                "_public_replay.append(summary_entry.duplicate(true))",
                '_public_replay.append({"summary": "PRIVATE_CARRY_NAME_TO_LIGHTHOUSE"})',
            ),
        ),
        (
            "interruption rolls back committed result",
            lambda: source_mutation(
                SHELL_PATH,
                'append("caption_or_voice_interrupted_after_commit")',
                'append("caption_or_voice_interrupted_after_commit")\n\t_committed_result.clear()',
            ),
        ),
        (
            "post-commit recovery recomputes",
            lambda: source_mutation(
                SHELL_PATH,
                (
                    "func recover_projection(\n"
                    "\trequest: Dictionary = "
                    "DrownedHarborHighWaterFixtureAdapter.authorized_request(),\n"
                    ") -> Dictionary:\n"
                    "\tif not _committed_result.is_empty():\n"
                    "\t\treturn reproject_existing_result()"
                ),
                (
                    "func recover_projection(\n"
                    "\trequest: Dictionary = "
                    "DrownedHarborHighWaterFixtureAdapter.authorized_request(),\n"
                    ") -> Dictionary:\n"
                    "\tif not _committed_result.is_empty():\n"
                    "\t\treturn _adapter.load_and_prepare(request)"
                ),
            ),
        ),
        (
            "control returns before persistent summary",
            lambda: source_mutation(
                SHELL_PATH,
                "return _summary_available and _summary_acknowledged and _mode == SurfaceMode.TRANSFORMED_BOARD",
                "return true # summary bypassed",
            ),
        ),
        (
            "gameplay action mutates during presentation",
            lambda: source_mutation(
                SHELL_PATH,
                'return _reject("gameplay_mutation_blocked"',
                '_commit_count += 1\n\t\treturn _reject("gameplay_mutation_blocked"',
            ),
        ),
        (
            "transformed-board action commitment enabled",
            lambda: source_mutation(
                SHELL_PATH,
                'return _reject(\n\t\t"read_only_boundary"',
                'return {"accepted": true, "committed": true} # read_only_boundary',
            ),
        ),
        (
            "High Water production visibility",
            lambda: boundary_mutation(
                lambda m, _c, _l, _p, _e, _g, _j, _k: m.__setitem__(
                    "normal_tale_library_visible", True
                )
            ),
        ),
        (
            "High Water export inclusion",
            lambda: boundary_text_mutation(
                EXPORT_PRESETS_PATH,
                "tests/*",
                "tests/legacy_only/*",
            ),
        ),
        (
            "High Water scene points to production",
            lambda: source_mutation(
                SCENE_PATH,
                "res://tests/drowned_harbor_dev_only/high_water_transformation_shell.gd",
                "res://src/main/main.gd",
            ),
        ),
        (
            "event identity omits event key",
            lambda: source_mutation(
                ADAPTER_PATH,
                "[FIXTURE_ID, SOURCE_REVISION, RESULT_REVISION, EVENT_KEY]",
                "[FIXTURE_ID, SOURCE_REVISION, RESULT_REVISION, RNG_CURSOR]",
            ),
        ),
        (
            "event key drift",
            lambda: fixture_mutation(
                lambda p, _s: high_water_fixture(p)["expected_events"][0].__setitem__(
                    "event_key", "high_water_second_event"
                )
            ),
        ),
        (
            "RNG cursor changes",
            lambda: fixture_mutation(
                lambda p, _s: high_water_fixture(p).__setitem__(
                    "rng_cursor_after", 13
                )
            ),
        ),
        (
            "private sentinel removed",
            lambda: fixture_mutation(
                lambda p, _s: high_water_fixture(p)["source_state"]["private"].pop(
                    "director_target"
                )
            ),
        ),
        (
            "mechanism balance value invented",
            lambda: fixture_mutation(
                lambda p, _s: high_water_fixture(p)["source_state"]["public"].__setitem__(
                    "public_mechanism_changes", ["lighthouse_power_plus_3"]
                )
            ),
        ),
        (
            "Council direction presented as canon",
            lambda: fixture_mutation(
                lambda p, _s: high_water_fixture(p)["source_state"]["public"].__setitem__(
                    "council_direction", "save_the_bellhouse_canon"
                )
            ),
        ),
        (
            "fixture schema expands to eight",
            lambda: fixture_mutation(
                lambda _p, s: s["properties"]["fixtures"].__setitem__(
                    "maxItems", 8
                )
            ),
        ),
        (
            "production catalog registration",
            lambda: boundary_mutation(
                lambda _m, c, _l, _p, _e, _g, _j, _k: c["entries"].append(
                    {"tale_id": "drowned_harbor"}
                )
            ),
        ),
        (
            "production provider registration",
            lambda: boundary_text_mutation(
                PROVIDER_PATH,
                "extends RefCounted",
                "extends RefCounted\n# drowned_harbor provider",
            ),
        ),
        (
            "dependency pin drift",
            lambda: boundary_mutation(
                lambda _m, _c, _l, _p, _e, _g, j, _k: j[
                    "devDependencies"
                ].__setitem__("wrangler", "4.115.0")
            ),
        ),
        (
            "manifest issue progression drift",
            lambda: boundary_mutation(
                lambda m, _c, _l, _p, _e, _g, _j, _k: m.__setitem__(
                    "future_work_issues", [85, 86]
                )
            ),
        ),
        (
            "human evidence claim",
            lambda: boundary_mutation(
                lambda m, _c, _l, _p, _e, _g, _j, _k: m.__setitem__(
                    "human_evidence_claimed", True
                )
            ),
        ),
        (
            "workflow path boundary weakened",
            lambda: workflow_mutation(
                "'game/tests/drowned_harbor_dev_only/high_water_fixture_adapter.gd'",
                "'game/tests/drowned_harbor_dev_only/*.gd'",
            ),
        ),
        (
            "workflow action pin drift",
            lambda: workflow_mutation(
                "actions/checkout@9c091bb21b7c1c1d1991bb908d89e4e9dddfe3e0",
                "actions/checkout@main",
            ),
        ),
        (
            "documentation certification claim",
            lambda: documentation_mutation(
                "Validation is automated/headless.",
                "Validation is automated/headless. Privacy certified.",
            ),
        ),
        (
            "documentation predeclares mutation result",
            lambda: documentation_mutation(
                "this document does not predeclare a passing count.",
                "mutation results: 42/42 passed.",
            ),
        ),
    ]

    for name, mutation in mutations:
        expect_failure(name, mutation)
    print(f"Validated {len(mutations)} P0.18 fail-closed mutation cases")
    return 0
if __name__ == "__main__":
    raise SystemExit(main())
