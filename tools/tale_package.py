#!/usr/bin/env python3
"""Validate repository-authored Tale packages without network access."""

from __future__ import annotations

import argparse
import hashlib
import json
import re
import sys
from dataclasses import dataclass
from pathlib import Path, PurePosixPath
from typing import Any


ROOT = Path(__file__).resolve().parents[1]
DEFAULT_PACKAGE = ROOT / "game/data/tales/lantern_house/tale_package_v1.json"
PACKAGE_KEYS = {
    "package_kind",
    "schema_version",
    "tale_id",
    "package_version",
    "display",
    "compatibility",
    "content",
    "stage_graph",
    "fallbacks",
    "privacy",
    "localization",
    "inventory",
    "social_compatibility",
    "source_ledger",
    "identity_policy",
}
INVENTORY_KEYS = {
    "actions",
    "cards",
    "connectors",
    "director_candidates",
    "director_profiles",
    "events",
    "factions",
    "items",
    "modes",
    "objectives",
    "roles",
    "spaces",
    "stages",
    "transitions",
}
CONTENT_KEYS = {
    "scenario_manifest",
    "scenario_sha256",
    "board_reference",
    "rules_reference",
    "director_reference",
    "social_reference",
}
EXPECTED_LEDGER_ROLES = {
    "scenario_manifest",
    "localization_catalog",
    "board_authority",
    "director_content",
    "rules_content",
    "social_content",
}
VALID_PRIVACY = {"public", "controlled_reveal_private", "seat_private", "faction_private"}
GENERATED_PARTS = {
    ".evidence",
    ".git",
    ".godot",
    "builds",
    "dist",
    "node_modules",
    "output",
    "test-results",
}
SECRET_KEYS = re.compile(
    r"(?:api[_-]?key|authorization|credential|password|private[_-]?key|room[_-]?secret|token)$",
    re.IGNORECASE,
)
NETWORK_URL = re.compile(r"^(?:https?|wss?)://", re.IGNORECASE)
WINDOWS_ABSOLUTE = re.compile(r"^[A-Za-z]:[\\/]")
STABLE_ID = re.compile(r"^[a-z][a-z0-9_]*$")


@dataclass(frozen=True, order=True)
class Diagnostic:
    code: str
    path: str
    message: str

    def as_dict(self) -> dict[str, str]:
        return {"code": self.code, "path": self.path, "message": self.message}


def canonical_bytes(value: Any) -> bytes:
    return json.dumps(
        value, ensure_ascii=True, separators=(",", ":"), sort_keys=True
    ).encode("utf-8")


def package_digest(value: Any) -> str:
    return hashlib.sha256(canonical_bytes(value)).hexdigest()


def _resource_path(value: str) -> Path | None:
    if value.startswith("res://"):
        return ROOT / "game" / value.removeprefix("res://")
    if WINDOWS_ABSOLUTE.match(value) or value.startswith("/") or value.startswith("~"):
        return None
    return ROOT / PurePosixPath(value)


def _add(
    diagnostics: list[Diagnostic], code: str, path: str, message: str
) -> None:
    diagnostics.append(Diagnostic(code, path, message))


def _exact_keys(
    value: Any,
    expected: set[str],
    path: str,
    diagnostics: list[Diagnostic],
) -> bool:
    if not isinstance(value, dict):
        _add(diagnostics, "missing_required_field", path, "expected an object")
        return False
    for key in sorted(expected - set(value)):
        _add(
            diagnostics,
            "missing_required_field",
            f"{path}/{key}",
            f"required field '{key}' is missing",
        )
    for key in sorted(set(value) - expected):
        _add(
            diagnostics,
            "unsupported_schema",
            f"{path}/{key}",
            f"unknown field '{key}' is rejected by schema v1",
        )
    return set(value) == expected


def _stable_id(value: Any) -> bool:
    return isinstance(value, str) and bool(STABLE_ID.fullmatch(value))


def _validate_safety(value: Any, path: str, diagnostics: list[Diagnostic]) -> None:
    if isinstance(value, dict):
        for key, child in value.items():
            child_path = f"{path}/{key}"
            if SECRET_KEYS.search(str(key)):
                _add(diagnostics, "secret", child_path, "secret-bearing fields are prohibited")
            _validate_safety(child, child_path, diagnostics)
        return
    if isinstance(value, list):
        for index, child in enumerate(value):
            _validate_safety(child, f"{path}/{index}", diagnostics)
        return
    if not isinstance(value, str):
        return
    if NETWORK_URL.match(value):
        _add(diagnostics, "network_url", path, "network URLs are prohibited")
    if WINDOWS_ABSOLUTE.match(value) or value.startswith("/home/") or value.startswith("/Users/"):
        _add(diagnostics, "prohibited_path", path, "absolute or private paths are prohibited")
    normalized = value.removeprefix("res://")
    parts = {part.lower() for part in PurePosixPath(normalized.replace("\\", "/")).parts}
    if parts & GENERATED_PARTS:
        _add(
            diagnostics,
            "generated_reference",
            path,
            "generated, private-evidence, cache, or build paths are prohibited",
        )


def _validate_inventory(package: dict[str, Any], diagnostics: list[Diagnostic]) -> None:
    inventory = package.get("inventory")
    if not _exact_keys(inventory, INVENTORY_KEYS, "/inventory", diagnostics):
        return
    assert isinstance(inventory, dict)
    for category in sorted(INVENTORY_KEYS):
        values = inventory.get(category)
        path = f"/inventory/{category}"
        if not isinstance(values, list) or not values:
            _add(diagnostics, "missing_required_field", path, "inventory category must be non-empty")
            continue
        if any(not _stable_id(item) for item in values):
            _add(diagnostics, "unstable_identity", path, "inventory IDs must be stable lowercase IDs")
        if len(values) != len(set(values)):
            _add(diagnostics, "duplicate_id", path, "inventory IDs must be unique")
        if values != sorted(values):
            _add(diagnostics, "unstable_ordering", path, "inventory IDs must be sorted")


def _validate_content(package: dict[str, Any], diagnostics: list[Diagnostic]) -> dict[str, Any]:
    content = package.get("content")
    if not _exact_keys(content, CONTENT_KEYS, "/content", diagnostics):
        return {}
    assert isinstance(content, dict)
    manifest_path = content.get("scenario_manifest")
    resolved = _resource_path(manifest_path) if isinstance(manifest_path, str) else None
    if resolved is None or not resolved.is_file():
        _add(
            diagnostics,
            "unresolved_reference",
            "/content/scenario_manifest",
            "scenario manifest does not resolve to a repository file",
        )
        return {}
    if hashlib.sha256(resolved.read_bytes()).hexdigest() != content.get("scenario_sha256"):
        _add(
            diagnostics,
            "unresolved_reference",
            "/content/scenario_sha256",
            "scenario manifest hash does not match the reviewed source",
        )
    try:
        manifest = json.loads(resolved.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError):
        _add(
            diagnostics,
            "unresolved_reference",
            "/content/scenario_manifest",
            "scenario manifest is unreadable or malformed",
        )
        return {}
    reference_pairs = (
        ("board_reference", "board_reference"),
        ("rules_reference", "rules_reference"),
        ("director_reference", "director_reference"),
        ("social_reference", "social_reference"),
    )
    for package_key, manifest_key in reference_pairs:
        if content.get(package_key) != manifest.get(manifest_key):
            _add(
                diagnostics,
                "unresolved_reference",
                f"/content/{package_key}",
                f"reference does not match scenario manifest '{manifest_key}'",
            )
    if package.get("tale_id") != manifest.get("scenario_id"):
        _add(
            diagnostics,
            "unresolved_reference",
            "/tale_id",
            "Tale ID does not match the scenario stable ID",
        )
    seats = manifest.get("supported_seats", {})
    compatibility = package.get("compatibility", {})
    if (
        not isinstance(compatibility, dict)
        or compatibility.get("minimum_seats") != seats.get("minimum")
        or compatibility.get("maximum_seats") != seats.get("maximum")
        or seats != {"minimum": 1, "maximum": 8}
    ):
        _add(
            diagnostics,
            "unsupported_player_count",
            "/compatibility",
            "the accepted package must support exactly 1 through 8 stable seats",
        )
    manifest_stage_ids = [stage.get("id") for stage in manifest.get("stages", []) if isinstance(stage, dict)]
    inventory = package.get("inventory", {})
    if isinstance(inventory, dict) and sorted(manifest_stage_ids) != inventory.get("stages"):
        _add(
            diagnostics,
            "unresolved_reference",
            "/inventory/stages",
            "stage inventory does not match the scenario manifest",
        )
    return manifest


def _validate_stage_graph(
    package: dict[str, Any], manifest: dict[str, Any], diagnostics: list[Diagnostic]
) -> None:
    graph = package.get("stage_graph")
    expected = {"entry_stage", "required_terminal_stage", "stage_order", "transitions"}
    if not _exact_keys(graph, expected, "/stage_graph", diagnostics):
        return
    assert isinstance(graph, dict)
    stages = graph.get("stage_order")
    if not isinstance(stages, list) or not stages or len(stages) != len(set(stages)):
        _add(diagnostics, "duplicate_id", "/stage_graph/stage_order", "stage IDs must be unique")
        return
    manifest_order = [stage.get("id") for stage in manifest.get("stages", []) if isinstance(stage, dict)]
    if manifest and stages != manifest_order:
        _add(
            diagnostics,
            "invalid_transition",
            "/stage_graph/stage_order",
            "stage order must match the accepted authored manifest order",
        )
    entry = graph.get("entry_stage")
    terminal = graph.get("required_terminal_stage")
    if entry not in stages or terminal not in stages:
        _add(
            diagnostics,
            "invalid_transition",
            "/stage_graph",
            "entry and terminal stages must resolve",
        )
        return
    transitions = graph.get("transitions")
    if not isinstance(transitions, list):
        _add(diagnostics, "invalid_transition", "/stage_graph/transitions", "transitions must be an array")
        return
    normalized: list[tuple[str, str]] = []
    adjacency: dict[str, set[str]] = {stage: set() for stage in stages}
    for index, transition in enumerate(transitions):
        path = f"/stage_graph/transitions/{index}"
        if not isinstance(transition, dict) or set(transition) != {"from", "to"}:
            _add(diagnostics, "invalid_transition", path, "transition must contain only from/to")
            continue
        source, target = transition.get("from"), transition.get("to")
        if source not in adjacency or target not in adjacency:
            _add(diagnostics, "invalid_transition", path, "transition references an unknown stage")
            continue
        normalized.append((source, target))
        adjacency[source].add(target)
    if normalized != sorted(normalized):
        _add(
            diagnostics,
            "unstable_ordering",
            "/stage_graph/transitions",
            "transitions must be sorted by from/to",
        )
    reachable = {entry}
    pending = [entry]
    while pending:
        source = pending.pop(0)
        for target in sorted(adjacency[source]):
            if target not in reachable:
                reachable.add(target)
                pending.append(target)
    missing = [stage for stage in stages if stage not in reachable]
    if missing or terminal not in reachable:
        _add(
            diagnostics,
            "unreachable_stage",
            "/stage_graph",
            f"required stages are unreachable: {', '.join(missing or [str(terminal)])}",
        )


def _validate_fallbacks_and_social(package: dict[str, Any], diagnostics: list[Diagnostic]) -> None:
    fallbacks = package.get("fallbacks")
    required = {
        "cooperative_mode",
        "no_phone",
        "optional_companion_unavailable",
        "unsupported_optional_feature",
    }
    if not _exact_keys(fallbacks, required, "/fallbacks", diagnostics):
        _add(
            diagnostics,
            "missing_fallback",
            "/fallbacks",
            "cooperative, no-phone, optional-companion, and unsupported-feature fallbacks are required",
        )
    elif any(not isinstance(fallbacks.get(key), str) or not fallbacks[key] for key in required):
        _add(diagnostics, "missing_fallback", "/fallbacks", "fallback declarations must be non-empty")
    social = package.get("social_compatibility")
    expected = {"afterlife_required", "afterlife_roles", "factions", "roles"}
    if not _exact_keys(social, expected, "/social_compatibility", diagnostics):
        return
    assert isinstance(social, dict)
    inventory = package.get("inventory", {})
    roles = social.get("roles")
    factions = social.get("factions")
    afterlife = social.get("afterlife_roles")
    valid = (
        social.get("afterlife_required") is True
        and isinstance(roles, list)
        and isinstance(factions, list)
        and isinstance(afterlife, list)
        and bool(afterlife)
        and roles == inventory.get("roles")
        and factions == inventory.get("factions")
        and set(afterlife) <= set(roles)
        and roles == sorted(roles)
        and factions == sorted(factions)
        and afterlife == sorted(afterlife)
    )
    if not valid:
        _add(
            diagnostics,
            "incompatible_social_declaration",
            "/social_compatibility",
            "role, faction, and required afterlife declarations are incompatible with inventory",
        )


def _validate_privacy_and_localization(
    package: dict[str, Any], manifest: dict[str, Any], diagnostics: list[Diagnostic]
) -> None:
    privacy = package.get("privacy")
    if not isinstance(privacy, list) or not privacy:
        _add(diagnostics, "invalid_privacy", "/privacy", "privacy classifications are required")
    else:
        keys: list[str] = []
        for index, record in enumerate(privacy):
            path = f"/privacy/{index}"
            if not isinstance(record, dict) or set(record) != {"classification", "key"}:
                _add(diagnostics, "invalid_privacy", path, "privacy record must contain key/classification")
                continue
            keys.append(record.get("key", ""))
            if record.get("classification") not in VALID_PRIVACY:
                _add(diagnostics, "invalid_privacy", path, "unsupported privacy classification")
        if keys != sorted(keys) or len(keys) != len(set(keys)):
            _add(diagnostics, "unstable_ordering", "/privacy", "privacy keys must be sorted and unique")
    localization = package.get("localization")
    expected = {
        "catalog",
        "catalog_sha256",
        "briefing_key",
        "display_key",
        "narration_keys",
        "objective_key",
    }
    if not _exact_keys(localization, expected, "/localization", diagnostics):
        return
    assert isinstance(localization, dict)
    catalog_path = _resource_path(localization.get("catalog", ""))
    if catalog_path is None or not catalog_path.is_file():
        _add(diagnostics, "unresolved_localization", "/localization/catalog", "catalog does not resolve")
        return
    if hashlib.sha256(catalog_path.read_bytes()).hexdigest() != localization.get("catalog_sha256"):
        _add(
            diagnostics,
            "unresolved_localization",
            "/localization/catalog_sha256",
            "localization catalog hash does not match the reviewed source",
        )
    try:
        catalog = json.loads(catalog_path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError):
        _add(diagnostics, "unresolved_localization", "/localization/catalog", "catalog is malformed")
        return
    keys = [
        localization.get("briefing_key"),
        localization.get("display_key"),
        localization.get("objective_key"),
        *localization.get("narration_keys", []),
    ]
    for key in keys:
        if not isinstance(key, str) or not isinstance(catalog.get(key), str) or not catalog[key]:
            _add(
                diagnostics,
                "unresolved_localization",
                "/localization",
                f"governed key '{key}' does not resolve",
            )
    if set(catalog) - set(keys):
        _add(
            diagnostics,
            "orphaned_record",
            "/localization/catalog",
            "catalog contains ungoverned orphaned records",
        )
    if manifest:
        expected_text = {
            localization.get("briefing_key"): manifest.get("briefing"),
            localization.get("objective_key"): manifest.get("public_objective"),
        }
        for key, text in expected_text.items():
            if catalog.get(key) != text:
                _add(
                    diagnostics,
                    "unresolved_localization",
                    "/localization",
                    f"governed key '{key}' changes accepted player-visible text",
                )
        stage_titles = {stage.get("title") for stage in manifest.get("stages", []) if isinstance(stage, dict)}
        narrated = {catalog.get(key) for key in localization.get("narration_keys", [])}
        if narrated != stage_titles:
            _add(
                diagnostics,
                "unresolved_localization",
                "/localization/narration_keys",
                "narration keys must preserve every accepted stage title",
            )


def _validate_ledger(package: dict[str, Any], diagnostics: list[Diagnostic]) -> None:
    ledger = package.get("source_ledger")
    if not isinstance(ledger, list) or not ledger:
        _add(diagnostics, "missing_required_field", "/source_ledger", "source ledger is required")
        return
    paths: list[str] = []
    roles: list[str] = []
    for index, record in enumerate(ledger):
        path = f"/source_ledger/{index}"
        if not isinstance(record, dict) or set(record) != {"path", "reference", "role"}:
            _add(diagnostics, "orphaned_record", path, "ledger record must contain path/reference/role")
            continue
        source = record.get("path")
        paths.append(source if isinstance(source, str) else "")
        roles.append(record.get("role", ""))
        resolved = _resource_path(source) if isinstance(source, str) else None
        if resolved is None or not resolved.is_file():
            _add(diagnostics, "unresolved_reference", f"{path}/path", "ledger source does not resolve")
        if record.get("role") not in EXPECTED_LEDGER_ROLES:
            _add(diagnostics, "orphaned_record", f"{path}/role", "ledger role is not consumed")
    if paths != sorted(paths) or len(paths) != len(set(paths)):
        _add(diagnostics, "unstable_ordering", "/source_ledger", "ledger paths must be sorted and unique")
    if set(roles) != EXPECTED_LEDGER_ROLES:
        _add(diagnostics, "orphaned_record", "/source_ledger", "ledger roles must be complete and unique")


def validate(package: Any) -> list[Diagnostic]:
    diagnostics: list[Diagnostic] = []
    if not isinstance(package, dict):
        return [Diagnostic("unsupported_schema", "/", "package root must be an object")]
    _exact_keys(package, PACKAGE_KEYS, "", diagnostics)
    if package.get("package_kind") != "tale":
        _add(diagnostics, "unsupported_schema", "/package_kind", "package kind must be 'tale'")
    if package.get("schema_version") != 1:
        _add(diagnostics, "unsupported_schema", "/schema_version", "only Tale schema v1 is supported")
    if not _stable_id(package.get("tale_id")) or package.get("package_version") != 1:
        _add(diagnostics, "unstable_identity", "/tale_id", "stable Tale ID and package version 1 are required")
    display = package.get("display")
    if _exact_keys(
        display,
        {"display_key", "tone_profile", "content_profile"},
        "/display",
        diagnostics,
    ) and any(not _stable_id(display.get(key)) for key in ("tone_profile", "content_profile")):
        _add(diagnostics, "unstable_identity", "/display", "display profiles must use stable IDs")
    compatibility = package.get("compatibility")
    compatibility_keys = {
        "engine",
        "minimum_seats",
        "maximum_seats",
        "supported_modes",
        "unknown_field_policy",
        "runtime_policy",
    }
    if _exact_keys(compatibility, compatibility_keys, "/compatibility", diagnostics):
        modes = compatibility.get("supported_modes")
        if (
            compatibility.get("engine") != "godot_4_7"
            or compatibility.get("unknown_field_policy") != "reject"
            or compatibility.get("runtime_policy")
            != "repository_authored_allowlisted_identity_only"
            or not isinstance(modes, list)
            or any(not _stable_id(mode) for mode in modes)
            or modes != sorted(modes)
            or len(modes) != len(set(modes))
        ):
            _add(
                diagnostics,
                "unstable_identity",
                "/compatibility",
                "compatibility policy or ordering is unsupported",
            )
    identity = package.get("identity_policy")
    _exact_keys(
        identity,
        {"algorithm", "canonicalization", "non_authoritative_metadata_excluded"},
        "/identity_policy",
        diagnostics,
    )
    if identity != {
        "algorithm": "sha256",
        "canonicalization": "utf8_json_sorted_object_keys_compact_arrays_preserved",
        "non_authoritative_metadata_excluded": [],
    }:
        _add(
            diagnostics,
            "unstable_identity",
            "/identity_policy",
            "identity policy must use the exact canonical SHA-256 contract",
        )
    _validate_safety(package, "", diagnostics)
    _validate_inventory(package, diagnostics)
    manifest = _validate_content(package, diagnostics)
    _validate_stage_graph(package, manifest, diagnostics)
    _validate_fallbacks_and_social(package, diagnostics)
    _validate_privacy_and_localization(package, manifest, diagnostics)
    _validate_ledger(package, diagnostics)
    return sorted(set(diagnostics))


def validate_file(path: Path) -> tuple[dict[str, Any], list[Diagnostic]]:
    try:
        package = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        return {}, [Diagnostic("unsupported_schema", "/", f"package is unreadable or malformed: {exc}")]
    return package if isinstance(package, dict) else {}, validate(package)


def summary(package: dict[str, Any]) -> dict[str, Any]:
    inventory = package.get("inventory", {})
    return {
        "accepted": True,
        "package_kind": package["package_kind"],
        "schema_version": package["schema_version"],
        "tale_id": package["tale_id"],
        "package_version": package["package_version"],
        "sha256": package_digest(package),
        "inventory": {key: len(inventory[key]) for key in sorted(inventory)},
        "source_ledger": package["source_ledger"],
        "compatibility": package["compatibility"],
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("command", choices=("validate", "identity"))
    parser.add_argument("package", nargs="?", type=Path, default=DEFAULT_PACKAGE)
    args = parser.parse_args()
    package, diagnostics = validate_file(args.package.resolve())
    if diagnostics:
        print(json.dumps({"accepted": False, "diagnostics": [item.as_dict() for item in diagnostics]}, indent=2))
        return 1
    result = summary(package)
    if args.command == "identity":
        result = {"accepted": True, "sha256": result["sha256"]}
    print(json.dumps(result, indent=2, sort_keys=True))
    return 0


if __name__ == "__main__":
    sys.exit(main())
