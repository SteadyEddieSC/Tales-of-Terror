#!/usr/bin/env python3
"""Offline fail-closed validation for the Drowned Harbor alpha.1 scaffold."""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import re
import struct
import subprocess
import sys
from pathlib import Path
from typing import Any, Iterable

ROOT = Path(__file__).resolve().parents[1]
BASELINE = "4efdd76efdf2aa34823dae5d3624a3dca3f0a349"
BRANCH = "feature/v0.2.0-alpha.1-drowned-harbor-scaffold"
PACKAGE_DIGEST = "17e5ed3b651424f4e292239d1525808637babb7f91fb5134d018c644290b692f"
SCENARIO_DIGEST = "d7cb1934f119bd2d94c514a8a509758115b894a79dc57e02fa8bda322bdd2168"
LOCALIZATION_DIGEST = "c19bdaed5ad7b4e5169fcfeeb632b8c8b39acf7a5edf39bf23374186de886fa3"
CATALOG_DIGEST = "2b478fd0d11fa075c2050409193aa06e6b9ca4dcf6efd4e4c550a9f3a5ff9db6"
LANTERN_DIGEST = "abb39d6bfbdf8d7de108379f08180c13efb99bbffa3e53f30eaaa8de7f459dee"
PROVIDER_ID = "drowned_harbor_authorities_v1"
TALE_ID = "drowned_harbor"
PACKAGE_PATH = Path("game/data/tales/drowned_harbor/tale_package_v1.json")
SCENARIO_PATH = Path("game/data/scenarios/drowned_harbor_scaffold_v1.json")
LOCALIZATION_PATH = Path("game/data/tales/drowned_harbor/localization_en.json")
SOURCE_ROOT = Path("game/src/tales/drowned_harbor")
TEST_ROOT = Path("game/tests/drowned_harbor_production_scaffold")
WORKFLOW_PATH = Path(".github/workflows/v020-alpha1-production-tale-scaffold.yml")
UID_PATTERN = re.compile(r"uid://[a-y0-8]{1,13}")
PRIVACY_CLASSES = [
    "public",
    "controlled_reveal_private",
    "seat_private",
    "faction_private",
]

PROTECTED_HASHES = {
    "game/data/tales/tale_catalog_v1.json": "d328972d27fb7809737ef3da7dee7482bf6e3ad5ca25a0353616364b4950ca27",
    "game/src/session/tale_provider_registry.gd": "90f07605d63e4d931bd267cfb4d161003be7e8beee1911b88bd87425b5247c31",
    "game/src/session/tale_catalog.gd": "016c4384fdc999daffb6fad12aea8bf1ce84ea484f161b555d06e12ae5e42205",
    "game/src/session/tale_selection_state.gd": "d49f51560b5df94d503c0a724b54db9953614762fd9e0b1151d72c27e99dc57b",
    "game/src/session/vertical_slice_coordinator.gd": "0c7dc9cb5d5d201f623ed81028c1e366b047f5225015d29cb3d4eb91d704fc75",
    "game/src/main/main.gd": "26ec2f53c0c5eaa110b80025bc5068b8e551fd64964dda463391144060031db6",
}

REQUIRED_SOURCE_FILES = {
    "drowned_harbor_board_definition.gd",
    "drowned_harbor_developer_admission_gate.gd",
    "drowned_harbor_director_content.gd",
    "drowned_harbor_rules_content.gd",
    "drowned_harbor_scaffold_session.gd",
    "drowned_harbor_scoped_provider.gd",
    "drowned_harbor_social_content.gd",
}

AUTHORIZED_EXACT = {
    ".github/workflows/v020-alpha1-production-tale-scaffold.yml",
    "game/export_presets.cfg",
    "game/project.godot",
    "tools/validate_drowned_harbor_production_scaffold.py",
    "tools/test_validate_drowned_harbor_production_scaffold.py",
    "tools/validate_drowned_harbor_prototype_isolation.py",
    "tools/validate_drowned_harbor_bellhouse_recovery.py",
    "tools/portable_bundle.py",
    "game/tests/drowned_harbor_prototype_isolation_test.gd",
    "README.md",
    "CHANGELOG.md",
    "docs/releases/v0.2.0-alpha.1-production-tale-scaffold.md",
    "docs/playtests/v0.2.0-alpha.1-production-tale-scaffold-evidence.md",
    "docs/preproduction/post_prototype_status_v1.json",
    "docs/preproduction/P0.21_Implementation_Issue_Set.md",
    "docs/roadmap/Post_P0.19_Production_Candidate_Roadmap.md",
}
AUTHORIZED_PREFIXES = (
    "game/data/tales/drowned_harbor/",
    "game/src/tales/drowned_harbor/",
    "game/tests/drowned_harbor_production_scaffold/",
)
FORBIDDEN_EXPORT_PATH_PARTS = (
    "data/scenarios/drowned_harbor_scaffold_v1.json",
    "data/tales/drowned_harbor/",
    "src/tales/drowned_harbor/",
    "tests/drowned_harbor_production_scaffold/",
)
FORBIDDEN_EXPORT_MARKERS = (
    b"drowned_harbor",
    b"drowned_harbor_authorities_v1",
    b"drowned_harbor_placeholder_en_v1",
    b"drowned_harbor_scaffold_v1",
    b"acknowledge_scaffold_exit",
)


class ValidationError(RuntimeError):
    pass


def require(condition: bool, message: str) -> None:
    if not condition:
        raise ValidationError(message)


def sha256_file(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def canonical_digest(value: Any) -> str:
    payload = json.dumps(value, sort_keys=True, separators=(",", ":"), ensure_ascii=False)
    return hashlib.sha256(payload.encode("utf-8")).hexdigest()


def load_json(root: Path, relative: Path) -> dict[str, Any]:
    path = root / relative
    require(path.is_file(), f"missing JSON authority: {relative.as_posix()}")
    try:
        value = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, UnicodeError, json.JSONDecodeError) as exc:
        raise ValidationError(f"malformed JSON authority {relative.as_posix()}: {exc}") from exc
    require(isinstance(value, dict), f"JSON root must be an object: {relative.as_posix()}")
    return value


def exact_keys(value: dict[str, Any], expected: Iterable[str], label: str) -> None:
    expected_set = set(expected)
    require(set(value) == expected_set, f"{label} fields changed: {sorted(value)}")


def validate_package(root: Path) -> tuple[dict[str, Any], dict[str, Any], dict[str, Any]]:
    package = load_json(root, PACKAGE_PATH)
    scenario = load_json(root, SCENARIO_PATH)
    localization = load_json(root, LOCALIZATION_PATH)
    exact_keys(
        package,
        [
            "package_kind", "schema_version", "tale_id", "package_version", "provider",
            "display", "compatibility", "content", "stage_graph", "fallbacks", "privacy",
            "localization", "inventory", "persistence", "source_ledger", "identity_policy",
        ],
        "package",
    )
    require(package["package_kind"] == "tale", "package kind changed")
    require(package["schema_version"] == 1, "package schema changed")
    require(package["tale_id"] == TALE_ID, "Tale ID changed")
    require(package["package_version"] == 1, "package version changed")
    require(canonical_digest(package) == PACKAGE_DIGEST, "canonical package identity changed")
    require(sha256_file(root / SCENARIO_PATH) == SCENARIO_DIGEST, "scenario digest changed")
    require(
        sha256_file(root / LOCALIZATION_PATH) == LOCALIZATION_DIGEST,
        "localization digest changed",
    )
    provider = package["provider"]
    exact_keys(
        provider,
        [
            "provider_id", "provider_version", "board_reference", "rules_reference",
            "director_reference", "social_reference",
        ],
        "provider",
    )
    require(provider == {
        "provider_id": PROVIDER_ID,
        "provider_version": 1,
        "board_reference": "drowned_harbor_scaffold_board",
        "rules_reference": "drowned_harbor_scaffold_rules",
        "director_reference": "drowned_harbor_scaffold_director",
        "social_reference": "drowned_harbor_scaffold_social",
    }, "provider declaration changed")
    compatibility = package["compatibility"]
    exact_keys(
        compatibility,
        [
            "engine", "minimum_seats", "maximum_seats", "supported_modes",
            "admission_policy", "unknown_field_policy", "deterministic",
        ],
        "compatibility",
    )
    require(compatibility == {
        "engine": "godot_4_7_1",
        "minimum_seats": 1,
        "maximum_seats": 8,
        "supported_modes": ["scaffold_only"],
        "admission_policy": "developer_only_explicit_launch",
        "unknown_field_policy": "reject",
        "deterministic": True,
    }, "compatibility changed")
    content = package["content"]
    exact_keys(
        content,
        [
            "scenario_path", "scenario_id", "scenario_sha256", "board_reference",
            "rules_reference", "director_reference", "social_reference",
        ],
        "content",
    )
    require(content["scenario_path"] == "res://data/scenarios/drowned_harbor_scaffold_v1.json", "scenario path changed")
    require(content["scenario_id"] == "drowned_harbor_scaffold_v1", "scenario ID changed")
    require(content["scenario_sha256"] == SCENARIO_DIGEST, "scenario binding changed")
    require(package["privacy"]["classes"] == PRIVACY_CLASSES, "privacy classes changed")
    require(package["privacy"]["private_content_implemented"] is False, "private content was enabled")
    require(package["privacy"]["director_input_policy"] == "public_or_authorized_aggregate_only", "Director privacy boundary changed")
    require(package["persistence"] == {
        "snapshot_version": 1,
        "identity_selection": "validate_tale_and_package_before_state",
        "migration_policy": "exact_version_or_fail_closed",
        "exactly_once_policy": "persist_processed_request_and_event_ids",
        "rng_policy": "named_authority_owned_stream",
        "best_effort_restore": False,
    }, "persistence contract changed")
    require(package["stage_graph"] == {
        "entry_stage": "scaffold_entry",
        "terminal_stage": "scaffold_terminal",
        "stage_order": ["scaffold_entry"],
        "allowed_intents": ["acknowledge_scaffold_exit"],
    }, "one-stage graph changed")
    require(package["localization"]["catalog_id"] == "drowned_harbor_placeholder_en_v1", "localization ID changed")
    require(package["localization"]["catalog_sha256"] == LOCALIZATION_DIGEST, "localization binding changed")
    validate_scenario(scenario)
    validate_localization(localization)
    validate_source_ledger(package["source_ledger"])
    validate_no_executable_data(package)
    return package, scenario, localization


def validate_scenario(scenario: dict[str, Any]) -> None:
    exact_keys(
        scenario,
        [
            "scenario_kind", "schema_version", "scenario_id", "scenario_version", "tale_id",
            "authority_references", "stages", "terminal_behavior", "determinism", "privacy",
            "identity_policy",
        ],
        "scenario",
    )
    require(scenario["scenario_kind"] == "drowned_harbor_production_scaffold", "scenario kind changed")
    require(scenario["scenario_id"] == "drowned_harbor_scaffold_v1", "scenario identity changed")
    require(scenario["schema_version"] == 1 and scenario["scenario_version"] == 1, "scenario version changed")
    require(scenario["tale_id"] == TALE_ID, "scenario Tale binding changed")
    require(scenario["stages"] == [{
        "id": "scaffold_entry",
        "operations": ["acknowledge_scaffold_exit"],
        "terminal_on_completion": True,
    }], "scenario must retain exactly one scaffold stage")
    require(scenario["terminal_behavior"] == {
        "stage_id": "scaffold_terminal",
        "result": "return_to_normal_default",
        "cleanup": "clear_all_drowned_harbor_scaffold_authorities",
    }, "terminal cleanup changed")
    require(scenario["privacy"]["classes"] == PRIVACY_CLASSES, "scenario privacy classes changed")
    require(scenario["privacy"]["director_inputs"] == "public_or_authorized_aggregate_only", "scenario Director boundary changed")
    require(scenario["determinism"]["rng_stream"] == "drowned_harbor_scaffold_authority", "named RNG changed")
    require(scenario["determinism"]["wall_clock_dependency"] is False, "wall clock dependency enabled")


def validate_localization(localization: dict[str, Any]) -> None:
    exact_keys(
        localization,
        ["catalog_kind", "schema_version", "catalog_id", "locale", "status", "entries"],
        "localization",
    )
    require(localization["catalog_kind"] == "governed_placeholder_localization", "localization kind changed")
    require(localization["catalog_id"] == "drowned_harbor_placeholder_en_v1", "localization identity changed")
    require(localization["status"] == "temporary_internal_placeholder", "placeholder status changed")
    expected_keys = {
        "tale.drowned_harbor.scaffold.briefing",
        "tale.drowned_harbor.scaffold.display_name",
        "tale.drowned_harbor.scaffold.exit",
        "tale.drowned_harbor.scaffold.objective",
    }
    require(set(localization["entries"]) == expected_keys, "governed localization keys changed")
    require(all(isinstance(value, str) and value for value in localization["entries"].values()), "placeholder localization is incomplete")


def validate_source_ledger(ledger: Any) -> None:
    require(isinstance(ledger, list) and len(ledger) == 7, "source ledger must contain seven records")
    roles = [record.get("role") for record in ledger if isinstance(record, dict)]
    require(roles == [
        "board_authority", "director_content", "localization_catalog", "rules_content",
        "scenario_manifest", "scoped_provider", "social_content",
    ], "source ledger order or roles changed")
    for record in ledger:
        exact_keys(record, ["role", "path", "reference"], "source ledger record")
        path = record["path"]
        require(isinstance(path, str) and not path.startswith(("/", "res://", "http://", "https://")), "ledger path is not repository-relative")
        require(".." not in Path(path).parts, "ledger path escapes repository")


def validate_no_executable_data(value: Any, path: str = "#") -> None:
    forbidden_keys = {
        "class", "class_name", "script", "script_path", "callback", "expression", "url",
        "credential", "credentials", "telemetry", "remote_content", "executable",
    }
    if isinstance(value, dict):
        for key, nested in value.items():
            require(key not in forbidden_keys, f"executable or remote data key at {path}/{key}")
            validate_no_executable_data(nested, f"{path}/{key}")
    elif isinstance(value, list):
        for index, nested in enumerate(value):
            validate_no_executable_data(nested, f"{path}/{index}")
    elif isinstance(value, str):
        require(not value.startswith(("http://", "https://")), f"remote URL at {path}")
        require("game/tests/drowned_harbor_dev_only" not in value, f"prototype fixture dependency at {path}")
        require("docs/tales/drowned_harbor/authoring" not in value, f"authoring runtime dependency at {path}")


def validate_native_sources(root: Path) -> None:
    require((root / SOURCE_ROOT).is_dir(), "missing Drowned Harbor native source root")
    scripts = {path.name for path in (root / SOURCE_ROOT).glob("*.gd")}
    require(scripts == REQUIRED_SOURCE_FILES, f"native scaffold source inventory changed: {sorted(scripts)}")
    combined = "\n".join((root / SOURCE_ROOT / name).read_text(encoding="utf-8") for name in sorted(scripts))
    for forbidden in (
        "docs/tales/drowned_harbor/authoring",
        "drowned_harbor_dev_only",
        "res://tests/",
        "Tidebound",
        "Low Tide",
        "Bellhouse",
        "High Water",
        "Last Light",
    ):
        require(forbidden not in combined, f"native scaffold includes forbidden runtime/content term: {forbidden}")
    obligations = {
        "drowned_harbor_scoped_provider.gd": [
            "class_name DrownedHarborScopedProvider", "EXPECTED_PACKAGE_DIGEST",
            "if not _complete_content(content):", "incomplete_candidate", "private_director_input",
        ],
        "drowned_harbor_developer_admission_gate.gd": [
            "developer_only_explicit_launch", "_provider.build_candidate()", "var pending :=",
            "_session = pending", "_session = null", "exit_to_normal_default", "rollback", "rematch",
        ],
        "drowned_harbor_scaffold_session.gd": [
            "RNG_STREAM_NAME", "processed_request_ids", "processed_event_ids",
            "duplicate_request", "duplicate_event", "stale_revision", "wrong_stable_seat",
            "malformed_request", "_snapshot_identity_rejection", "unsupported_snapshot_version",
            "assert(to_snapshot() == before)",
        ],
        "drowned_harbor_director_content.gd": [
            "PUBLIC_INPUT_KEYS", "authorized_input_keys", "accepts_input",
        ],
        "drowned_harbor_social_content.gd": [
            "controlled_reveal_private", "seat_private", "faction_private",
        ],
    }
    for name, needles in obligations.items():
        source = (root / SOURCE_ROOT / name).read_text(encoding="utf-8")
        for needle in needles:
            require(needle in source, f"{name} is missing source obligation: {needle}")
    session_source = (root / SOURCE_ROOT / "drowned_harbor_scaffold_session.gd").read_text(encoding="utf-8")
    require("best_effort_field" not in session_source, "runtime implements best-effort restoration")
    director_source = (root / SOURCE_ROOT / "drowned_harbor_director_content.gd").read_text(encoding="utf-8")
    require(all(term not in director_source for term in ("private_objective", "hidden_target", "private_terms")), "Director source accepts private terms")


def validate_test_source(root: Path) -> None:
    test_path = root / TEST_ROOT / "drowned_harbor_production_scaffold_test.gd"
    require(test_path.is_file(), "missing focused Godot scaffold test")
    source = test_path.read_text(encoding="utf-8")
    for needle in (
        "complete native candidate validates", "partial candidate rejects",
        "repeated initialization is byte-equivalent", "stale_revision", "wrong_stable_seat",
        "malformed_request", "duplicate remains rejected after restore",
        "identity rejects before malformed fields", "best-effort field matching rejects",
        "rematch rebuilds through provider", "central registry excludes Drowned Harbor",
        "_test_canonical_uids", "round-trips through Godot ResourceUID",
        "DROWNED_HARBOR_PRODUCTION_SCAFFOLD_EVIDENCE:",
    ):
        require(needle in source, f"focused Godot coverage missing: {needle}")


def validate_uids(root: Path) -> None:
    new_scripts = sorted((root / SOURCE_ROOT).glob("*.gd")) + sorted((root / TEST_ROOT).glob("*.gd"))
    require(len(new_scripts) == 8, "expected seven native scripts and one focused test")
    new_uids: list[str] = []
    for script in new_scripts:
        uid_path = script.with_suffix(script.suffix + ".uid")
        require(uid_path.is_file(), f"missing canonical UID sidecar: {uid_path.relative_to(root)}")
        raw = uid_path.read_bytes()
        require(raw.endswith(b"\n") and raw.count(b"\n") == 1, f"UID sidecar must contain one line: {uid_path.relative_to(root)}")
        text = raw.decode("ascii").strip()
        require(UID_PATTERN.fullmatch(text) is not None, f"noncanonical Godot UID: {uid_path.relative_to(root)}")
        new_uids.append(text)
    require(len(set(new_uids)) == len(new_uids), "new Godot UIDs are not unique")
    repository_uids: dict[str, list[Path]] = {}
    for uid_path in (root / "game").rglob("*.gd.uid"):
        value = uid_path.read_text(encoding="ascii").strip()
        repository_uids.setdefault(value, []).append(uid_path)
    duplicates = {value: paths for value, paths in repository_uids.items() if len(paths) > 1}
    require(not duplicates, "repository contains duplicate GDScript UIDs")


def validate_protected_boundaries(root: Path) -> None:
    for relative, digest in PROTECTED_HASHES.items():
        require(sha256_file(root / relative) == digest, f"protected production file changed: {relative}")
    catalog = load_json(root, Path("game/data/tales/tale_catalog_v1.json"))
    require(canonical_digest(catalog) == CATALOG_DIGEST, "normal catalog identity changed")
    require(catalog["default_tale_id"] == "lantern_house_vertical_slice", "normal default Tale changed")
    require(len(catalog["entries"]) == 1, "normal catalog no longer contains exactly one Tale")
    require(catalog["entries"][0]["tale_id"] == "lantern_house_vertical_slice", "normal catalog contains Drowned Harbor")
    require(catalog["entries"][0]["package_sha256"] == LANTERN_DIGEST, "Lantern House package identity changed")
    registry = (root / "game/src/session/tale_provider_registry.gd").read_text(encoding="utf-8")
    require(PROVIDER_ID not in registry and TALE_ID not in registry, "central provider registry contains Drowned Harbor")
    for relative in (
        "game/src/session/tale_catalog.gd", "game/src/session/tale_selection_state.gd",
        "game/src/session/vertical_slice_coordinator.gd", "game/src/main/main.gd",
    ):
        source = (root / relative).read_text(encoding="utf-8")
        require(TALE_ID not in source and PROVIDER_ID not in source, f"normal navigation references Drowned Harbor: {relative}")


def validate_export_policy(root: Path) -> None:
    source = (root / "game/export_presets.cfg").read_text(encoding="utf-8")
    expected = (
        "data/scenarios/drowned_harbor_scaffold_v1.json,"
        "data/tales/drowned_harbor/*,src/tales/drowned_harbor/*"
    )
    require(source.count(expected) == 2, "both ordinary export presets must exclude alpha.1 data and source")
    require(source.count("tests/*") == 2, "both ordinary export presets must exclude tests")
    require(source.count('name="Internal Windows x86_64"') == 1, "Windows preset identity changed")
    require(source.count('name="Internal Linux x86_64"') == 1, "Linux preset identity changed")


def validate_workflow(root: Path) -> None:
    path = root / WORKFLOW_PATH
    require(path.is_file(), "missing alpha.1 workflow")
    source = path.read_text(encoding="utf-8")
    for needle in (
        "name: v0.2.0-alpha.1 Drowned Harbor production Tale scaffold",
        "actions/checkout@9c091bb21b7c1c1d1991bb908d89e4e9dddfe3e0",
        "actions/setup-python@ece7cb06caefa5fff74198d8649806c4678c61a1",
        "actions/upload-artifact@043fb46d1a93c77aae656e7c1c64a875d1fc6a0a",
        "python-version: 3.11.9",
        "--require-hashes --requirement requirements-dev.txt",
        "4ccdab7a48eeccbe8819a2fc1f6262f8d72065d98601bcb3743fcbd7ebd39f373758a788ee3293a05ec5b2c48538266c437404312e372225cd2df273945a2de9",
        "run_check scaffold-validator python tools/validate_drowned_harbor_production_scaffold.py",
        "run_check scaffold-mutations python tools/test_validate_drowned_harbor_production_scaffold.py",
        "drowned_harbor_production_scaffold_test.gd",
        '--export-pack "Internal Windows x86_64"',
        '--export-pack "Internal Linux x86_64"',
        "export-inventory --platform windows",
        "export-inventory --platform linux",
        "p020-alpha1-drowned-harbor-scaffold-evidence",
        "git diff --exit-code",
    ):
        require(needle in source, f"alpha.1 workflow missing obligation: {needle}")
    require("feature/v0.2.0-alpha.1-drowned-harbor-scaffold" in source, "workflow branch boundary changed")


def validate_documentation(root: Path) -> None:
    release = root / "docs/releases/v0.2.0-alpha.1-production-tale-scaffold.md"
    evidence = root / "docs/playtests/v0.2.0-alpha.1-production-tale-scaffold-evidence.md"
    require(release.is_file() and evidence.is_file(), "missing alpha.1 release/evidence documentation")
    combined = release.read_text(encoding="utf-8") + "\n" + evidence.read_text(encoding="utf-8")
    for needle in (
        BASELINE, BRANCH, "issue #100", PROVIDER_ID, PACKAGE_DIGEST, SCENARIO_DIGEST,
        LOCALIZATION_DIGEST, "developer-only", "Lantern House", "Issue #39", "Issue #7",
        "machine evidence", "not production readiness",
    ):
        require(needle in combined, f"documentation missing evidence boundary: {needle}")
    forbidden_claims = (
        "accessibility certified", "privacy certified", "security certified", "production ready",
        "public release ready", "human playtest passed", "balance validated", "fun validated",
    )
    lowered = combined.lower()
    for claim in forbidden_claims:
        require(claim not in lowered, f"documentation makes forbidden claim: {claim}")


def _run_git(root: Path, *args: str) -> str:
    completed = subprocess.run(
        ["git", *args], cwd=root, text=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
        check=False, encoding="utf-8",
    )
    require(completed.returncode == 0, f"git {' '.join(args)} failed: {completed.stderr.strip()}")
    return completed.stdout.strip()


def _authorized_path(path: str) -> bool:
    return path == SCENARIO_PATH.as_posix() or path in AUTHORIZED_EXACT or path.startswith(AUTHORIZED_PREFIXES)


def validate_git_boundary(root: Path) -> None:
    require(_run_git(root, "rev-parse", "origin/main") == BASELINE, "protected origin/main changed")
    branch = os.environ.get("GITHUB_HEAD_REF") or _run_git(root, "branch", "--show-current")
    require(branch == BRANCH, f"wrong release branch: {branch}")
    require(_run_git(root, "merge-base", "HEAD", BASELINE) == BASELINE, "release branch does not start at baseline")
    changed = set(filter(None, _run_git(root, "diff", "--name-only", BASELINE).splitlines()))
    changed.update(filter(None, _run_git(root, "ls-files", "--others", "--exclude-standard").splitlines()))
    unauthorized = sorted(path for path in changed if not _authorized_path(path))
    require(not unauthorized, f"unauthorized changed paths: {unauthorized}")


def pck_inventory(path: Path) -> list[str]:
    data = path.read_bytes()
    require(len(data) >= 112 and data[:4] == b"GDPC", "not a Godot PCK v4 archive")
    pack_format, engine_major = struct.unpack_from("<II", data, 4)
    require(pack_format == 4 and engine_major == 4, "unsupported Godot PCK format")
    directory_offset = struct.unpack_from("<Q", data, 32)[0]
    require(112 <= directory_offset <= len(data) - 4, "invalid PCK directory offset")
    cursor = directory_offset
    file_count = struct.unpack_from("<I", data, cursor)[0]
    cursor += 4
    require(0 < file_count < 100_000, "invalid PCK file count")
    paths: list[str] = []
    for _ in range(file_count):
        require(cursor + 4 <= len(data), "truncated PCK directory")
        path_length = struct.unpack_from("<I", data, cursor)[0]
        cursor += 4
        require(1 <= path_length <= 16_384 and cursor + path_length <= len(data), "invalid PCK path length")
        encoded = data[cursor : cursor + path_length]
        cursor += (path_length + 3) & ~3
        try:
            resource_path = encoded.rstrip(b"\x00").decode("utf-8")
        except UnicodeDecodeError as exc:
            raise ValidationError("PCK path is not UTF-8") from exc
        require(resource_path and ".." not in Path(resource_path).parts, "unsafe PCK path")
        require(cursor + 36 <= len(data), "truncated PCK record")
        cursor += 8 + 8 + 16 + 4
        paths.append(resource_path.replace("\\", "/"))
    require(len(paths) == len(set(paths)), "PCK inventory contains duplicate paths")
    return paths


def validate_export_inventory(platform: str, pck: Path, export_log: Path, source_sha: str) -> dict[str, Any]:
    require(platform in {"windows", "linux"}, "unsupported export platform")
    require(re.fullmatch(r"[0-9a-f]{40}", source_sha) is not None, "invalid source SHA")
    require(pck.is_file() and export_log.is_file(), "missing actual export evidence")
    inventory = pck_inventory(pck)
    lowered_paths = [path.lower() for path in inventory]
    path_hits = sorted(
        path for path in lowered_paths if any(part in path for part in FORBIDDEN_EXPORT_PATH_PARTS)
    )
    raw = pck.read_bytes()
    log_bytes = export_log.read_bytes()
    marker_hits = [index for index, marker in enumerate(FORBIDDEN_EXPORT_MARKERS, 1) if marker in raw or marker in log_bytes]
    require(not path_hits, f"Drowned Harbor alpha.1 path leaked into {platform} PCK")
    require(not marker_hits, f"Drowned Harbor alpha.1 identity leaked into {platform} export")
    return {
        "accepted": True,
        "classification": "automated_internal_machine_evidence",
        "human_evidence_claimed": False,
        "platform": platform,
        "source_sha": source_sha,
        "pck_file_count": len(inventory),
        "pck_size": pck.stat().st_size,
        "pck_sha256": sha256_file(pck),
        "export_log_sha256": sha256_file(export_log),
        "inventory_digest": hashlib.sha256("\n".join(sorted(inventory)).encode()).hexdigest(),
        "forbidden_path_hit_count": 0,
        "forbidden_marker_hit_count": 0,
    }


def validate_static(root: Path = ROOT, *, git_boundary: bool = True) -> dict[str, Any]:
    package, _, _ = validate_package(root)
    validate_native_sources(root)
    validate_test_source(root)
    validate_uids(root)
    validate_protected_boundaries(root)
    validate_export_policy(root)
    validate_workflow(root)
    validate_documentation(root)
    if git_boundary:
        validate_git_boundary(root)
    return {
        "accepted": True,
        "package_digest": canonical_digest(package),
        "scenario_digest": SCENARIO_DIGEST,
        "localization_digest": LOCALIZATION_DIGEST,
        "provider_id": PROVIDER_ID,
        "human_evidence_claimed": False,
    }


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser()
    subparsers = parser.add_subparsers(dest="command")
    export = subparsers.add_parser("export-inventory")
    export.add_argument("--platform", required=True, choices=("windows", "linux"))
    export.add_argument("--pck", required=True, type=Path)
    export.add_argument("--export-log", required=True, type=Path)
    export.add_argument("--source-sha", required=True)
    export.add_argument("--output", type=Path)
    return parser


def main(argv: list[str] | None = None) -> int:
    args = build_parser().parse_args(argv)
    try:
        if args.command == "export-inventory":
            result = validate_export_inventory(args.platform, args.pck, args.export_log, args.source_sha)
        else:
            result = validate_static()
    except ValidationError as exc:
        print(f"Drowned Harbor alpha.1 validation failed: {exc}", file=sys.stderr)
        return 1
    payload = json.dumps(result, sort_keys=True, separators=(",", ":"))
    if args.command == "export-inventory" and args.output is not None:
        args.output.parent.mkdir(parents=True, exist_ok=True)
        args.output.write_text(payload + "\n", encoding="utf-8")
    print(payload)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
