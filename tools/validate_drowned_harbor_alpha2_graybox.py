#!/usr/bin/env python3
"""Validate the governed Drowned Harbor alpha.2 end-to-end graybox."""

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

ROOT = Path(".")
BASELINE = "da86c0aa74bc0442862c97e3c371f6b714da4d0a"
BRANCH = "feature/v0.2.0-alpha.2-end-to-end-graybox"
PACKAGE_PATH = Path("game/data/tales/drowned_harbor/tale_package_v2.json")
SCENARIO_PATH = Path("game/data/scenarios/drowned_harbor_graybox_v2.json")
LOCALIZATION_PATH = Path("game/data/tales/drowned_harbor/localization_graybox_en_v2.json")
SOURCE_ROOT = Path("game/src/tales/drowned_harbor/alpha2")
GATE_PATH = Path("game/src/tales/drowned_harbor/drowned_harbor_developer_admission_gate.gd")
TEST_PATH = Path("game/tests/drowned_harbor_alpha2_graybox/drowned_harbor_alpha2_graybox_test.gd")
WORKFLOW_PATH = Path(".github/workflows/v020-alpha2-end-to-end-graybox.yml")
RELEASE_PATH = Path("docs/releases/v0.2.0-alpha.2-end-to-end-graybox.md")
EVIDENCE_PATH = Path("docs/playtests/v0.2.0-alpha.2-end-to-end-graybox-evidence.md")
EXPORT_PRESETS_PATH = Path("game/export_presets.cfg")
PORTABLE_PATH = Path("tools/portable_bundle.py")
CATALOG_PATH = Path("game/data/tales/tale_catalog_v1.json")
REGISTRY_PATH = Path("game/src/session/tale_provider_registry.gd")
PROJECT_PATH = Path("game/project.godot")
PACKAGE_DIGEST = "ee9e2f21b23f2b8f7ac8c8be1520c6ebcb679807a5f0dbd0d23825824b2f90b7"
SCENARIO_DIGEST = "5927dba92238512fdc74b10387ea7378f00d74a462445749d6493a512b7d7a0d"
LOCALIZATION_DIGEST = "137919b02a572fc1c844521c38633bf27ad49bcb9d1fe8a83147db2210d1a227"
CATALOG_DIGEST = "2b478fd0d11fa075c2050409193aa06e6b9ca4dcf6efd4e4c550a9f3a5ff9db6"
LANTERN_DIGEST = "abb39d6bfbdf8d7de108379f08180c13efb99bbffa3e53f30eaaa8de7f459dee"
STAGES = [
    "low_tide_arrival_v1",
    "bellhouse_ledger_v1",
    "lighthouse_council_v1",
    "high_water_v1",
    "last_light_v1",
    "ending_resolution_v1",
    "epilogue_attribution_v1",
    "rematch_title_cleanup_v1",
]
TRANSITIONS = [
    "transition_low_tide_to_bellhouse",
    "transition_bellhouse_to_council",
    "transition_council_to_high_water",
    "transition_high_water_to_last_light",
    "transition_last_light_to_ending",
    "transition_ending_to_epilogue",
    "transition_epilogue_to_cleanup",
]
PRIVACY_CLASSES = ["public", "controlled_reveal_private", "seat_private", "faction_private"]
RNG_STREAMS = [
    "drowned_harbor_route_authority",
    "drowned_harbor_board_authority",
    "drowned_harbor_social_authority",
    "drowned_harbor_director_authority",
]
DIRECTOR_INPUTS = [
    "authoritative_revision",
    "connected_seat_count",
    "stage_id",
    "public_progress",
    "public_pressure",
    "public_recovery_count",
]
EXPECTED_ALPHA2_SOURCES = {
    "drowned_harbor_alpha2_board_authority.gd",
    "drowned_harbor_alpha2_board_definition.gd",
    "drowned_harbor_alpha2_director_content.gd",
    "drowned_harbor_alpha2_role_authority.gd",
    "drowned_harbor_alpha2_rules_authority.gd",
    "drowned_harbor_alpha2_scoped_provider.gd",
    "drowned_harbor_alpha2_session.gd",
}
AUTHORIZED_EXACT = {
    ".github/workflows/v020-alpha1-production-tale-scaffold.yml",
    ".github/workflows/v020-alpha2-end-to-end-graybox.yml",
    "CHANGELOG.md",
    "docs/playtests/v0.2.0-alpha.2-end-to-end-graybox-evidence.md",
    "docs/releases/v0.2.0-alpha.2-end-to-end-graybox.md",
    "game/data/scenarios/drowned_harbor_graybox_v2.json",
    "game/export_presets.cfg",
    "tools/portable_bundle.py",
    "tools/test_validate_drowned_harbor_alpha2_graybox.py",
    "tools/validate_drowned_harbor_alpha2_graybox.py",
    "tools/validate_drowned_harbor_production_scaffold.py",
}
AUTHORIZED_PREFIXES = (
    "game/data/tales/drowned_harbor/",
    "game/src/tales/drowned_harbor/",
    "game/tests/drowned_harbor_alpha2_graybox/",
)
FORBIDDEN_EXPORT_PATH_PARTS = (
    "data/scenarios/drowned_harbor_graybox_v2.json",
    "data/tales/drowned_harbor/",
    "src/tales/drowned_harbor/",
    "tests/drowned_harbor_alpha2_graybox/",
)
FORBIDDEN_EXPORT_MARKERS = (
    b"drowned_harbor_graybox_v2",
    b"drowned_harbor_alpha2",
    b"council_commitment_id",
    b"high_water_transformation_id",
    b"PRIVATE_ALPHA2_",
)


class Alpha2ValidationError(RuntimeError):
    """Raised when a governed alpha.2 assertion fails."""


def require(condition: bool, message: str) -> None:
    if not condition:
        raise Alpha2ValidationError(message)


def read_json(path: Path) -> dict[str, Any]:
    try:
        value = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        raise Alpha2ValidationError(f"invalid or missing JSON: {path}: {exc}") from exc
    require(isinstance(value, dict), f"JSON root must be an object: {path}")
    return value


def canonical_digest(value: Any) -> str:
    payload = json.dumps(value, ensure_ascii=False, sort_keys=True, separators=(",", ":"))
    return hashlib.sha256(payload.encode("utf-8")).hexdigest()


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def strings(value: Any) -> Iterable[str]:
    if isinstance(value, dict):
        for key, nested in value.items():
            yield str(key)
            yield from strings(nested)
    elif isinstance(value, list):
        for nested in value:
            yield from strings(nested)
    elif isinstance(value, str):
        yield value


def validate_package_data(
    package: dict[str, Any], scenario: dict[str, Any], localization: dict[str, Any]
) -> None:
    require(canonical_digest(package) == PACKAGE_DIGEST, "package v2 canonical identity drifted")
    require(package.get("package_kind") == "tale", "package kind drifted")
    require(package.get("schema_version") == 1, "package schema drifted")
    require(package.get("tale_id") == "drowned_harbor", "Tale identity drifted")
    require(package.get("package_version") == 2, "package target version must be 2")
    provider = package.get("provider", {})
    require(
        provider
        == {
            "provider_id": "drowned_harbor_authorities_v1",
            "provider_version": 2,
            "board_reference": "drowned_harbor_graybox_board_v2",
            "rules_reference": "drowned_harbor_graybox_rules_v2",
            "director_reference": "drowned_harbor_graybox_director_v2",
            "social_reference": "drowned_harbor_graybox_social_v2",
        },
        "scoped provider v2 identity drifted",
    )
    require(package.get("stage_graph", {}).get("stage_order") == STAGES, "package stage order drifted")
    require(
        package.get("stage_graph", {}).get("transition_order") == TRANSITIONS,
        "package transition order drifted",
    )
    require(package.get("privacy", {}).get("classes") == PRIVACY_CLASSES, "privacy classes drifted")
    persistence = package.get("persistence", {})
    require(persistence.get("snapshot_version") == 2, "snapshot target must be v2")
    require(
        persistence.get("migration_policy")
        == "explicit_alpha1_snapshot_v1_to_alpha2_snapshot_v2_or_fail_closed",
        "migration policy weakened",
    )
    require(persistence.get("best_effort_restore") is False, "best-effort restore is prohibited")
    require(sha256_bytes_for_json_source(scenario) == SCENARIO_DIGEST, "scenario raw identity drifted")
    require(scenario.get("scenario_version") == 2, "scenario target version must be 2")
    require(scenario.get("stage_order") == STAGES, "scenario stage order drifted")
    transition_ids = [item.get("id") for item in scenario.get("transitions", [])]
    require(transition_ids == TRANSITIONS, "scenario transition graph drifted")
    for index, transition in enumerate(scenario.get("transitions", [])):
        require(transition.get("from") == STAGES[index], "transition source drifted")
        require(transition.get("to") == STAGES[index + 1], "transition target drifted")
    require(
        scenario.get("transitions", [])[2].get("exactly_once_identity") == "council_commitment_id",
        "Council exactly-once identity missing",
    )
    require(
        scenario.get("transitions", [])[3].get("exactly_once_identity")
        == "high_water_transformation_id",
        "High Water exactly-once identity missing",
    )
    determinism = scenario.get("determinism", {})
    require(determinism.get("rng_streams") == RNG_STREAMS, "named RNG stream inventory drifted")
    require(determinism.get("maximum_accepted_actions") == 96, "safe-route action bound drifted")
    require(
        determinism.get("maximum_rejections_before_diagnostic") == 8,
        "deadlock diagnostic bound drifted",
    )
    require(scenario.get("privacy", {}).get("classes") == PRIVACY_CLASSES, "scenario privacy drifted")
    require(
        scenario.get("privacy", {}).get("director_input_allowlist") == DIRECTOR_INPUTS,
        "Director public input allowlist drifted",
    )
    require(scenario.get("admission", {}).get("normal_catalog_registered") is False, "catalog enabled")
    require(scenario.get("admission", {}).get("normal_provider_registered") is False, "provider enabled")
    require(scenario.get("admission", {}).get("ordinary_export_authorized") is False, "export enabled")
    require(sha256_bytes_for_json_source(localization) == LOCALIZATION_DIGEST, "localization raw identity drifted")
    require(localization.get("catalog_version") == 2, "localization target version must be 2")
    require(
        localization.get("status") == "temporary_internal_placeholder",
        "localization is not governed placeholder text",
    )
    entries = localization.get("entries", {})
    require(isinstance(entries, dict) and len(entries) >= 14, "localization inventory incomplete")
    for stage in STAGES:
        require(f"stage.{stage}" in entries, f"stage localization missing: {stage}")
    executable_fields = {"script", "class", "callback", "expression", "url", "credential"}
    require(not executable_fields.intersection(strings(scenario)), "scenario contains executable field")
    require(not executable_fields.intersection(strings(package)), "package contains executable field")


def sha256_bytes_for_json_source(value: dict[str, Any]) -> str:
    if value.get("scenario_id") == "drowned_harbor_graybox_v2":
        return sha256_file(SCENARIO_PATH)
    if value.get("catalog_id") == "drowned_harbor_graybox_en_v2":
        return sha256_file(LOCALIZATION_PATH)
    return ""


def validate_sources(source_texts: dict[str, str], gate: str, test: str) -> None:
    require(set(source_texts) == EXPECTED_ALPHA2_SOURCES, "alpha.2 native source inventory drifted")
    combined = "\n".join(source_texts[name] for name in sorted(source_texts))
    obligations = {
        "drowned_harbor_alpha2_board_authority.gd": (
            "class_name DrownedHarborAlpha2BoardAuthority",
            "var _state := BoardState.new(_definition)",
            "apply_high_water_atomic",
            "HIGH_WATER_MUTATIONS",
            "shortest_path",
        ),
        "drowned_harbor_alpha2_rules_authority.gd": (
            "class_name DrownedHarborAlpha2RulesAuthority",
            "STAGE_ORDER",
            "TRANSITION_ORDER",
            "council_commitment_id",
            "high_water_transformation_id",
            "accepted_action_count",
        ),
        "drowned_harbor_alpha2_role_authority.gd": (
            "class_name DrownedHarborAlpha2RoleAuthority",
            "PRIVACY_CLASSES",
            "seat_private_view",
            "resolve_epilogue",
        ),
        "drowned_harbor_alpha2_session.gd": (
            "class_name DrownedHarborAlpha2Session",
            "validate_snapshot",
            '"processed_request_ids": _processed_request_ids.duplicate()',
            '"processed_event_ids": _processed_event_ids.duplicate()',
            "simulate_projection_failure",
            "func reproject_committed_result(identity_kind: String) -> Dictionary:",
            "bounded_progress_watchdog",
            "disconnect_seat",
            "assign_surrogate_control",
            "reconnect_seat",
            "signal public_event_committed(event: Dictionary)",
        ),
        "drowned_harbor_alpha2_scoped_provider.gd": (
            "class_name DrownedHarborAlpha2ScopedProvider",
            "ee9e2f21b23f2b8f7ac8c8be1520c6e",
            "bcb679807a5f0dbd0d23825824b2f90b7",
            "5927dba92238512fdc74b10387ea7378",
            "f00d74a462445749d6493a512b7d7a0d",
            "137919b02a572fc1c844521c38633bf2",
            "7ad49bcb9d1fe8a83147db2210d1a227",
        ),
    }
    for name, phrases in obligations.items():
        for phrase in phrases:
            require(phrase in source_texts[name], f"{name} missing governed seam: {phrase}")
    require(combined.count("_council_commitment_id = _identity(") == 1, "Council commit path duplicated")
    require(combined.count("_high_water_transformation_id = _identity(") == 1, "High Water commit path duplicated")
    for prohibited in ("Time.get_", "DateTime", "Timer.new", "HTTPRequest", "WebSocket", "docs/", "drowned_harbor_dev_only"):
        require(prohibited not in combined, f"runtime contains prohibited dependency: {prohibited}")
    require("admit_alpha2" in gate and "restore_alpha2" in gate, "developer gate lacks alpha.2 admission")
    require("migrate_alpha1_snapshot_to_alpha2" in gate, "explicit snapshot migration missing")
    require(
        "package_version" in gate and "!= 2" in gate,
        "version-2 admission is not closed",
    )
    test_phrases = (
        "_test_deterministic_safe_routes_for_seats_one_through_eight",
        "for seat_count: int in range(1, 9):",
        "_test_no_op_rejections_and_deadlock_diagnostic",
        "_test_stage_boundary_restore_and_replay_equivalence",
        "_test_disconnect_surrogate_and_reconnect_continuity",
        "_test_interruption_projection_recovery_and_exactly_once",
        "_test_alpha1_snapshot_migration_and_fail_closed_rejection",
        "_test_rematch_rollback_and_title_cleanup",
        "signal_count == 8",
        "transition_count == 7",
        '"PRIVATE_" not in _canonical(first.final_projection)',
    )
    for phrase in test_phrases:
        require(phrase in test, f"focused Godot matrix missing: {phrase}")


def validate_uid_inventory(root: Path = ROOT) -> None:
    targets = [root / SOURCE_ROOT / f"{name}.uid" for name in EXPECTED_ALPHA2_SOURCES]
    targets.append(root / TEST_PATH.with_suffix(".gd.uid"))
    all_values: dict[str, Path] = {}
    for path in (root / "game").rglob("*.gd.uid"):
        value = path.read_text(encoding="utf-8").strip()
        require(re.fullmatch(r"uid://[a-z0-9]{11,13}", value) is not None, f"invalid UID: {path}")
        require(value not in all_values, f"duplicate UID: {path} and {all_values.get(value)}")
        all_values[value] = path
    for path in targets:
        require(path.is_file(), f"alpha.2 UID missing: {path}")


def validate_production_boundaries(
    catalog: dict[str, Any], registry: str, project: str, lantern: dict[str, Any]
) -> None:
    require(canonical_digest(catalog) == CATALOG_DIGEST, "production Tale catalog identity changed")
    require(canonical_digest(lantern) == LANTERN_DIGEST, "Lantern House package identity changed")
    require(catalog.get("default_tale_id") == "lantern_house_vertical_slice", "normal default changed")
    require(len(catalog.get("entries", [])) == 1, "normal Tale catalog size changed")
    require("drowned_harbor" not in json.dumps(catalog).lower(), "Drowned Harbor entered normal catalog")
    require("drowned_harbor" not in registry.lower(), "Drowned Harbor entered central provider registry")
    require('run/main_scene="res://src/main/Main.tscn"' in project, "normal startup scene changed")
    require('config/features=PackedStringArray("4.7", "GL Compatibility")' in project, "Godot feature marker changed")


def validate_export_policy(presets: str, portable: str) -> None:
    exact = (
        'exclude_filter=".gutconfig.json,tests/*,addons/*,'
        'src/exploration/ExplorationShowcase.tscn,'
        'src/exploration/exploration_showcase.gd,'
        'data/scenarios/drowned_harbor_scaffold_v1.json,'
        'data/tales/drowned_harbor/*,src/tales/drowned_harbor/*,'
        'data/scenarios/drowned_harbor_graybox_v2.json"'
    )
    require(presets.count(exact) == 2, "both ordinary exports must use extended exact exclusion")
    require("drowned_harbor_graybox_v2.json" in portable, "portable policy lacks alpha.2 scenario exclusion")
    require("exact_exclude_filter" in portable, "portable exact-filter enforcement missing")


def validate_workflow(workflow: str) -> None:
    phrases = (
        "name: v0.2.0-alpha.2 Drowned Harbor end-to-end graybox",
        "feature/v0.2.0-alpha.2-end-to-end-graybox",
        "Enforce alpha.2 protected-base path boundary",
        "validate_drowned_harbor_alpha2_graybox.py",
        "run_check alpha2-mutations python tools/test_validate_drowned_harbor_alpha2_graybox.py",
        "drowned_harbor_alpha2_graybox_test.gd",
        "Godot_v4.7.1-stable",
        "gdformat --check",
        "gdlint",
        "typed-import",
        "main-smoke",
        "gut",
        "export-inventory --platform windows",
        "export-inventory --platform linux",
        "p020-alpha2-drowned-harbor-graybox-evidence",
        "Prove source tree remains clean",
    )
    for phrase in phrases:
        require(phrase in workflow, f"alpha.2 workflow missing: {phrase}")
    require("actions/checkout@9c091bb21b7c1c1d1991bb908d89e4e9dddfe3e0" in workflow, "checkout pin changed")
    require("actions/setup-python@ece7cb06caefa5fff74198d8649806c4678c61a1" in workflow, "Python pin changed")
    require("actions/upload-artifact@043fb46d1a93c77aae656e7c1c64a875d1fc6a0a" in workflow, "artifact pin changed")


def validate_documentation(release: str, evidence: str, changelog: str) -> None:
    combined = "\n".join((release, evidence, changelog)).lower()
    for phrase in (
        "v0.2.0-alpha.2",
        "issue #104",
        "developer-only",
        "eight stages",
        "seven transitions",
        "snapshot v2",
        "alpha.1",
        "council_commitment_id",
        "high_water_transformation_id",
        "windows",
        "linux",
        "automation is machine evidence",
        "issue #39",
    ):
        require(phrase in combined, f"alpha.2 documentation missing: {phrase}")
    for claim in (
        "human playtesting passed",
        "privacy certified",
        "security certified",
        "accessibility certified",
        "physical-controller validated",
        "television readability validated",
        "production ready",
        "public release authorized",
        "fun validated",
        "balance validated",
    ):
        require(claim not in combined, f"unsupported evidence claim found: {claim}")


def _run_git(root: Path, *args: str) -> str:
    return subprocess.check_output(["git", *args], cwd=root, text=True).strip()


def _authorized_path(path: str) -> bool:
    return path in AUTHORIZED_EXACT or path.startswith(AUTHORIZED_PREFIXES)


def validate_git_boundary(root: Path = ROOT) -> None:
    require(_run_git(root, "rev-parse", "origin/main") == BASELINE, "protected origin/main changed")
    branch = os.environ.get("GITHUB_HEAD_REF") or _run_git(root, "branch", "--show-current")
    require(branch == BRANCH, f"wrong alpha.2 branch: {branch}")
    require(_run_git(root, "merge-base", "HEAD", BASELINE) == BASELINE, "branch baseline changed")
    changed = set(filter(None, _run_git(root, "diff", "--name-only", BASELINE).splitlines()))
    changed.update(filter(None, _run_git(root, "ls-files", "--others", "--exclude-standard").splitlines()))
    unauthorized = sorted(path for path in changed if not _authorized_path(path))
    require(not unauthorized, f"unauthorized alpha.2 paths: {unauthorized}")


def pck_inventory(path: Path) -> list[str]:
    data = path.read_bytes()
    require(len(data) >= 112 and data[:4] == b"GDPC", "not a Godot PCK v4 archive")
    pack_format, engine_major = struct.unpack_from("<II", data, 4)
    require(pack_format == 4 and engine_major == 4, "unsupported PCK format")
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
        require(1 <= path_length <= 16_384 and cursor + path_length <= len(data), "invalid PCK path")
        encoded = data[cursor : cursor + path_length]
        cursor += (path_length + 3) & ~3
        try:
            resource_path = encoded.rstrip(b"\x00").decode("utf-8")
        except UnicodeDecodeError as exc:
            raise Alpha2ValidationError("PCK path is not UTF-8") from exc
        require(resource_path and ".." not in Path(resource_path).parts, "unsafe PCK path")
        require(cursor + 36 <= len(data), "truncated PCK record")
        cursor += 36
        paths.append(resource_path.replace("\\", "/"))
    require(len(paths) == len(set(paths)), "PCK inventory contains duplicate paths")
    return paths


def validate_export_inventory(
    platform: str, pck: Path, export_log: Path, source_sha: str
) -> dict[str, Any]:
    require(platform in {"windows", "linux"}, "unsupported export platform")
    require(re.fullmatch(r"[0-9a-f]{40}", source_sha) is not None, "invalid source SHA")
    require(pck.is_file() and export_log.is_file(), "missing actual export evidence")
    inventory = pck_inventory(pck)
    lowered = [item.lower() for item in inventory]
    path_hits = [item for item in lowered if any(part in item for part in FORBIDDEN_EXPORT_PATH_PARTS)]
    raw = pck.read_bytes()
    log = export_log.read_bytes()
    marker_hits = [marker.decode() for marker in FORBIDDEN_EXPORT_MARKERS if marker in raw or marker in log]
    require(not path_hits, f"alpha.2 path leaked into {platform} export: {path_hits}")
    require(not marker_hits, f"alpha.2 identity leaked into {platform} export: {marker_hits}")
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
    package = read_json(root / PACKAGE_PATH)
    scenario = read_json(root / SCENARIO_PATH)
    localization = read_json(root / LOCALIZATION_PATH)
    validate_package_data(package, scenario, localization)
    source_texts = {
        path.name: path.read_text(encoding="utf-8")
        for path in sorted((root / SOURCE_ROOT).glob("*.gd"))
    }
    validate_sources(
        source_texts,
        (root / GATE_PATH).read_text(encoding="utf-8"),
        (root / TEST_PATH).read_text(encoding="utf-8"),
    )
    validate_uid_inventory(root)
    validate_production_boundaries(
        read_json(root / CATALOG_PATH),
        (root / REGISTRY_PATH).read_text(encoding="utf-8"),
        (root / PROJECT_PATH).read_text(encoding="utf-8"),
        read_json(root / "game/data/tales/lantern_house/tale_package_v1.json"),
    )
    validate_export_policy(
        (root / EXPORT_PRESETS_PATH).read_text(encoding="utf-8"),
        (root / PORTABLE_PATH).read_text(encoding="utf-8"),
    )
    validate_workflow((root / WORKFLOW_PATH).read_text(encoding="utf-8"))
    validate_documentation(
        (root / RELEASE_PATH).read_text(encoding="utf-8"),
        (root / EVIDENCE_PATH).read_text(encoding="utf-8"),
        (root / "CHANGELOG.md").read_text(encoding="utf-8"),
    )
    if git_boundary:
        validate_git_boundary(root)
    return {
        "accepted": True,
        "package_digest": PACKAGE_DIGEST,
        "scenario_digest": SCENARIO_DIGEST,
        "localization_digest": LOCALIZATION_DIGEST,
        "stage_count": len(STAGES),
        "transition_count": len(TRANSITIONS),
        "supported_seat_counts": list(range(1, 9)),
        "snapshot_version": 2,
        "human_evidence_claimed": False,
    }


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser()
    parser.add_argument("--skip-git-boundary", action="store_true")
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
            result = validate_static(git_boundary=not args.skip_git_boundary)
    except (Alpha2ValidationError, OSError, subprocess.CalledProcessError) as exc:
        print(f"Drowned Harbor alpha.2 validation failed: {exc}", file=sys.stderr)
        return 1
    payload = json.dumps(result, sort_keys=True, separators=(",", ":"))
    if args.command == "export-inventory" and args.output is not None:
        args.output.parent.mkdir(parents=True, exist_ok=True)
        args.output.write_text(payload + "\n", encoding="utf-8")
    print(payload)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
