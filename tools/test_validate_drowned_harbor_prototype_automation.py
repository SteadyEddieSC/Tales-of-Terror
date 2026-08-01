#!/usr/bin/env python3
"""Fail-closed mutations for P0.19 prototype automation and export exclusion."""

from __future__ import annotations

import copy
import json
import tempfile
from pathlib import Path
from typing import Callable

from validate_drowned_harbor_prototype_automation import (
    CATALOG_PATH,
    EXPECTED_COMPONENTS,
    EXPECTED_ENTRY_POINTS,
    EXPORT_PRESETS_PATH,
    FIXTURE_PATH,
    GODOT_WORKFLOW_PATH,
    LANTERN_PATH,
    MANIFEST_PATH,
    PORTABLE_WORKFLOW_PATH,
    PROFILE_PATH,
    PROJECT_PATH,
    PROVIDER_PATH,
    README_PATH,
    SUMMARY_PATH,
    TECHNICAL_PATH,
    TEST_PATH,
    UID_PATH,
    WORKFLOW_PATH,
    ISOLATION_TEST_PATH,
    AutomationValidationError,
    read_json,
    sha256_file,
    validate_documentation,
    validate_godot_source,
    validate_manifest,
    validate_production_boundary,
    validate_profile,
    validate_uid_contents,
    validate_workflows,
    verify_bundle_export,
    verify_native_export,
)

ROOT = Path(".")
Mutation = Callable[[], None]
SOURCE_SHA = "1" * 40


def expect_failure(name: str, mutation: Mutation) -> None:
    try:
        mutation()
    except AutomationValidationError:
        return
    raise AssertionError(f"mutation did not fail closed: {name}")


def profile_mutation(change: Callable[[dict], None]) -> None:
    value = copy.deepcopy(read_json(ROOT / PROFILE_PATH))
    change(value)
    validate_profile(value)


def manifest_mutation(change: Callable[[dict], None]) -> None:
    value = copy.deepcopy(read_json(ROOT / MANIFEST_PATH))
    change(value)
    validate_manifest(value)


def production_mutation(
    change: Callable[[dict, dict, dict, str, str, str], None]
) -> None:
    profile = copy.deepcopy(read_json(ROOT / PROFILE_PATH))
    catalog = copy.deepcopy(read_json(ROOT / CATALOG_PATH))
    lantern = copy.deepcopy(read_json(ROOT / LANTERN_PATH))
    provider = (ROOT / PROVIDER_PATH).read_text(encoding="utf-8")
    project = (ROOT / PROJECT_PATH).read_text(encoding="utf-8")
    presets = (ROOT / EXPORT_PRESETS_PATH).read_text(encoding="utf-8")
    values = [profile, catalog, lantern, provider, project, presets]
    change(*values)
    validate_production_boundary(*values)


def workflow_mutation(target: Path, old: str, new: str) -> None:
    values = {
        WORKFLOW_PATH: (ROOT / WORKFLOW_PATH).read_text(encoding="utf-8"),
        GODOT_WORKFLOW_PATH: (ROOT / GODOT_WORKFLOW_PATH).read_text(encoding="utf-8"),
        PORTABLE_WORKFLOW_PATH: (ROOT / PORTABLE_WORKFLOW_PATH).read_text(encoding="utf-8"),
    }
    if old not in values[target]:
        raise AssertionError(f"workflow mutation source missing: {target}: {old}")
    values[target] = values[target].replace(old, new)
    validate_workflows(
        values[WORKFLOW_PATH],
        values[GODOT_WORKFLOW_PATH],
        values[PORTABLE_WORKFLOW_PATH],
    )


def godot_source_mutation(old: str, new: str) -> None:
    source = (ROOT / TEST_PATH).read_text(encoding="utf-8")
    if old not in source:
        raise AssertionError(f"Godot source mutation target missing: {old}")
    source = source.replace(old, new, 1)
    isolation = (ROOT / ISOLATION_TEST_PATH).read_text(encoding="utf-8")
    validate_godot_source(source, isolation)


def documentation_mutation(old: str, new: str) -> None:
    values = {
        TECHNICAL_PATH: (ROOT / TECHNICAL_PATH).read_text(encoding="utf-8"),
        SUMMARY_PATH: (ROOT / SUMMARY_PATH).read_text(encoding="utf-8"),
        README_PATH: (ROOT / README_PATH).read_text(encoding="utf-8"),
    }
    if old not in values[TECHNICAL_PATH]:
        raise AssertionError(f"documentation mutation source missing: {old}")
    values[TECHNICAL_PATH] = values[TECHNICAL_PATH].replace(old, new, 1)
    validate_documentation(
        values[TECHNICAL_PATH], values[SUMMARY_PATH], values[README_PATH]
    )


def uid_mutation(content: str, duplicate: bool = False) -> None:
    contents = {
        path.relative_to(ROOT): path.read_text(encoding="utf-8")
        for path in (ROOT / "game").rglob("*.gd.uid")
    }
    contents[UID_PATH] = content
    if duplicate:
        other = next(path for path in contents if path != UID_PATH)
        contents[other] = content
    validate_uid_contents(content, contents)


def fake_native(
    native_bytes: bytes = b"SAFE_P019_NATIVE",
    log_bytes: bytes = b"SAFE EXPORT LOG",
    source_sha: str = SOURCE_SHA,
    platform: str = "windows",
    preset: str = "Internal Windows x86_64",
) -> None:
    with tempfile.TemporaryDirectory() as temporary:
        root = Path(temporary)
        native = root / "native.bin"
        log = root / "export.log"
        native.write_bytes(native_bytes)
        log.write_bytes(log_bytes)
        verify_native_export(
            ROOT, platform, source_sha, preset, native, log, root / "evidence.json"
        )


def fake_bundle(
    relative_file: str = "lantern_house_internal.exe",
    file_bytes: bytes = b"SAFE_P019_BUNDLE",
    manifest_source_sha: str = SOURCE_SHA,
    manifest_platform: str = "windows",
) -> None:
    with tempfile.TemporaryDirectory() as temporary:
        temp = Path(temporary)
        native = temp / "native.bin"
        log = temp / "export.log"
        bundle = temp / "bundle"
        native.write_bytes(b"SAFE_P019_NATIVE")
        log.write_bytes(b"SAFE EXPORT LOG")
        target = bundle / relative_file
        target.parent.mkdir(parents=True)
        target.write_bytes(file_bytes)
        manifest = {
            "source_commit": manifest_source_sha,
            "platform": manifest_platform,
            "tale_catalog": {
                "sha256": "2b478fd0d11fa075c2050409193aa06e6b9ca4dcf6efd4e4c550a9f3a5ff9db6"
            },
            "tale_package": {
                "sha256": "abb39d6bfbdf8d7de108379f08180c13efb99bbffa3e53f30eaaa8de7f459dee"
            },
        }
        (bundle / "build_manifest.json").write_text(
            json.dumps(manifest, sort_keys=True) + "\n", encoding="utf-8"
        )
        verify_bundle_export(
            ROOT,
            "windows",
            SOURCE_SHA,
            "Internal Windows x86_64",
            native,
            log,
            bundle,
            temp / "bundle-evidence.json",
        )


def main() -> int:
    profile = read_json(ROOT / PROFILE_PATH)
    validate_profile(profile)
    validate_manifest(read_json(ROOT / MANIFEST_PATH))
    mutations: list[tuple[str, Mutation]] = [
        ("missing implemented family", lambda: profile_mutation(lambda p: p["feature_families"].pop())),
        ("duplicate implemented family", lambda: profile_mutation(lambda p: p["feature_families"].append(copy.deepcopy(p["feature_families"][0])))),
        ("wrong fixture mapping", lambda: profile_mutation(lambda p: p["feature_families"][0].__setitem__("fixtures", ["DH-FIX-002"]))),
        ("DH-FIX-005 treated as runtime", lambda: profile_mutation(lambda p: p["projection_only_fixtures"][0].__setitem__("runtime_shell", True))),
        ("missing projection-only fixture", lambda: profile_mutation(lambda p: p.__setitem__("projection_only_fixtures", []))),
        ("missing deterministic repetition", lambda: profile_mutation(lambda p: p["determinism"].__setitem__("repetitions_per_sequence", 1))),
        ("lowered bounded-step requirement", lambda: profile_mutation(lambda p: p["determinism"].__setitem__("max_steps_per_case", 8))),
        ("omitted stale revision case", lambda: profile_mutation(lambda p: p["coverage"].__setitem__("stale_revision", False))),
        ("omitted wrong authority case", lambda: profile_mutation(lambda p: p["coverage"].__setitem__("wrong_authority", False))),
        ("omitted wrong seat case", lambda: profile_mutation(lambda p: p["coverage"].__setitem__("wrong_stable_seat", False))),
        ("omitted replay case", lambda: profile_mutation(lambda p: p["coverage"].__setitem__("replay", False))),
        ("omitted skip equivalence", lambda: profile_mutation(lambda p: p["coverage"].__setitem__("high_water_full_skip_equivalence", False))),
        ("omitted disconnect case", lambda: profile_mutation(lambda p: p["coverage"].__setitem__("controlled_private_disconnect", False))),
        ("omitted recovery case", lambda: profile_mutation(lambda p: p["coverage"].__setitem__("high_water_recovery", False))),
        ("omitted deadlock case", lambda: profile_mutation(lambda p: p["coverage"].__setitem__("bounded_no_deadlock", False))),
        ("human evidence claim enabled", lambda: profile_mutation(lambda p: p["classification"].__setitem__("human_playtest_evidence", True))),
        ("production registration enabled", lambda: manifest_mutation(lambda m: m.__setitem__("production_catalog_registered", True))),
        ("playable export enabled", lambda: manifest_mutation(lambda m: m.__setitem__("playable_export_authorized", True))),
        ("runtime authority enabled", lambda: manifest_mutation(lambda m: m.__setitem__("runtime_authority_created", True))),
        ("wrong completed issue inventory", lambda: manifest_mutation(lambda m: m.__setitem__("completed_work_issues", [80, 81, 82, 83, 84, 85]))),
        ("nonempty future issue inventory", lambda: manifest_mutation(lambda m: m.__setitem__("future_work_issues", [87]))),
        ("missing aggregate entry point", lambda: manifest_mutation(lambda m: m["allowed_entry_points"].remove(EXPECTED_ENTRY_POINTS[4]))),
        ("added runtime component", lambda: manifest_mutation(lambda m: m["prototype_components"].append("res://tests/drowned_harbor_dev_only/automation_runtime.gd"))),
        ("missing automation profile registration", lambda: manifest_mutation(lambda m: m.__setitem__("automation_profiles", []))),
        ("wrong catalog digest", lambda: profile_mutation(lambda p: p["production_boundary"].__setitem__("catalog_sha256", "0" * 64))),
        ("wrong Lantern House digest", lambda: profile_mutation(lambda p: p["production_boundary"].__setitem__("lantern_house_package_sha256", "0" * 64))),
        ("production catalog mutated", lambda: production_mutation(lambda _p, c, _l, _r, _j, _e: c["entries"].append({"tale_id": "drowned_harbor"}))),
        ("missing general Godot workflow step", lambda: workflow_mutation(GODOT_WORKFLOW_PATH, "res://tests/drowned_harbor_prototype_automation_test.gd", "res://tests/removed_automation_test.gd")),
        ("missing portable export verification", lambda: workflow_mutation(PORTABLE_WORKFLOW_PATH, "native-export", "native-check-removed")),
        ("missing P0.19 workflow command", lambda: workflow_mutation(WORKFLOW_PATH, "python tools/validate_drowned_harbor_prototype_automation.py", "python -m removed_validator")),
        ("weakened exact-path boundary", lambda: workflow_mutation(WORKFLOW_PATH, "'game/tests/drowned_harbor_prototype_automation_test.gd'", "'game/tests/*.gd'")),
        ("export log containing test path", lambda: fake_native(log_bytes=b"Storing File: res://tests/hidden.gd")),
        ("native bytes containing forbidden marker", lambda: fake_native(native_bytes=b"SAFE DH-FIX-001 UNSAFE")),
        ("bundle inventory containing prototype file", lambda: fake_bundle(relative_file="tests/drowned_harbor.gd")),
        ("bundle bytes containing private marker", lambda: fake_bundle(file_bytes=b"PRIVATE_FIND_MISSING_NAME")),
        ("source SHA mismatch", lambda: fake_bundle(manifest_source_sha="2" * 40)),
        ("wrong platform identity", lambda: fake_bundle(manifest_platform="linux")),
        ("missing evidence status", lambda: workflow_mutation(PORTABLE_WORKFLOW_PATH, "p019-windows-native.status", "removed-windows-native.status")),
        ("malformed new UID", lambda: uid_mutation("uid://not-canonical-z\n")),
        ("duplicate new UID", lambda: uid_mutation((ROOT / UID_PATH).read_text(encoding="utf-8"), True)),
        (
            "omitted aggregate unknown-intent case",
            lambda: godot_source_mutation(
                'unknown_request["intent"] = "unknown_fixture_intent"',
                'unknown_request["intent"] = "project_low_tide_public_action"',
            ),
        ),
        (
            "omitted aggregate malformed-request case",
            lambda: godot_source_mutation(
                'malformed_request.erase("intent")',
                'malformed_request["intent"] = malformed_request.get("intent", "")',
            ),
        ),
        ("documentation human evidence claim", lambda: documentation_mutation("Machine evidence boundary", "Machine evidence boundary\n\nHuman validated.")),
        ("documentation certification claim", lambda: documentation_mutation("Machine evidence boundary", "Machine evidence boundary\n\nPrivacy certified.")),
    ]
    for name, mutation in mutations:
        expect_failure(name, mutation)
    print(f"Validated {len(mutations)} P0.19 fail-closed mutation cases")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
