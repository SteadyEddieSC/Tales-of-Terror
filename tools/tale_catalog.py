#!/usr/bin/env python3
"""Validate repository-authored Tale catalogs without network or generated output."""

from __future__ import annotations

import argparse
import hashlib
import json
import re
import sys
from dataclasses import dataclass
from pathlib import Path, PurePosixPath
from typing import Any

import tale_package


ROOT = Path(__file__).resolve().parents[1]
DEFAULT_CATALOG = ROOT / "game/data/tales/tale_catalog_v1.json"
PRODUCTION_DIGEST = "2b478fd0d11fa075c2050409193aa06e6b9ca4dcf6efd4e4c550a9f3a5ff9db6"
ROOT_KEYS = {
    "catalog_kind",
    "schema_version",
    "catalog_version",
    "default_tale_id",
    "entries",
    "source_ledger",
    "compatibility",
    "identity_policy",
}
ENTRY_KEYS = {
    "tale_id",
    "package_path",
    "package_kind",
    "package_schema_version",
    "package_version",
    "package_sha256",
    "display",
    "provider",
}
DISPLAY_KEYS = {
    "catalog_path",
    "catalog_sha256",
    "display_key",
    "briefing_key",
    "objective_key",
}
PROVIDER_KEYS = {
    "provider_id",
    "provider_version",
    "board_reference",
    "rules_reference",
    "director_reference",
    "social_reference",
}
LEDGER_KEYS = {"tale_id", "role", "path", "reference"}
LEDGER_ROLES = {"governed_display", "provider_registry", "tale_package"}
COMPATIBILITY_KEYS = {
    "engine",
    "minimum_seats",
    "maximum_seats",
    "package_kind",
    "package_schema_version",
    "unknown_field_policy",
    "provider_policy",
}
IDENTITY_KEYS = {"algorithm", "canonicalization", "non_authoritative_metadata_excluded"}
PROVIDER_SPECS: dict[str, dict[str, Any]] = {
    "lantern_house_authorities_v1": {
        "provider_id": "lantern_house_authorities_v1",
        "provider_version": 1,
        "board_reference": "lantern_house",
        "rules_reference": "lantern_house_rules_sandbox",
        "director_reference": "lantern_house_director",
        "social_reference": "lantern_house_social_lab",
    }
}
STABLE_ID = re.compile(r"^[a-z][a-z0-9_]*$")
SHA256 = re.compile(r"^[0-9a-f]{64}$")
WINDOWS_ABSOLUTE = re.compile(r"^[A-Za-z]:[\\/]")
NETWORK_URL = re.compile(r"^(?:https?|wss?)://", re.IGNORECASE)
SECRET_KEY = re.compile(
    r"(?:api[_-]?key|authorization|credential|password|private[_-]?key|secret|token)$",
    re.IGNORECASE,
)
RUNTIME_KEY = re.compile(
    r"(?:class|class_name|eval|evaluate|executable|reflection|script|script_path)$",
    re.IGNORECASE,
)
PROHIBITED_PARTS = {
    ".evidence",
    ".git",
    ".godot",
    "builds",
    "cache",
    "dist",
    "node_modules",
    "output",
    "test-results",
}


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


def catalog_digest(value: Any) -> str:
    return hashlib.sha256(canonical_bytes(value)).hexdigest()


def _add(items: list[Diagnostic], code: str, path: str, message: str) -> None:
    items.append(Diagnostic(code, path, message))


def _exact_keys(
    value: Any,
    expected: set[str],
    path: str,
    items: list[Diagnostic],
) -> bool:
    if not isinstance(value, dict):
        _add(items, "missing_required_field", path, "expected an object")
        return False
    for key in sorted(expected - set(value)):
        _add(
            items,
            "missing_required_field",
            f"{path}/{key}",
            f"required field '{key}' is missing",
        )
    for key in sorted(set(value) - expected):
        _add(
            items,
            "unsupported_catalog_schema",
            f"{path}/{key}",
            f"unknown catalog field '{key}' is rejected",
        )
    return set(value) == expected


def _resource_path(
    value: Any,
    path: str,
    items: list[Diagnostic],
    *,
    allow_test_fixtures: bool,
    allow_script_source: bool = False,
) -> Path | None:
    if not isinstance(value, str) or not value:
        _add(items, "unresolved_catalog_reference", path, "repository path is required")
        return None
    if NETWORK_URL.match(value):
        _add(items, "network_url", path, "network catalog references are prohibited")
        return None
    if (
        WINDOWS_ABSOLUTE.match(value)
        or value.startswith("/")
        or value.startswith("~")
        or value.startswith("/home/")
        or value.startswith("/Users/")
    ):
        _add(items, "prohibited_catalog_path", path, "absolute or private paths are prohibited")
        return None
    if value.startswith("res://"):
        resolved = ROOT / "game" / value.removeprefix("res://")
    elif value.startswith("game/"):
        resolved = ROOT / value
    else:
        _add(
            items,
            "prohibited_catalog_path",
            path,
            "path must use res:// or game/ repository-relative form",
        )
        return None
    normalized = value.removeprefix("res://").replace("\\", "/")
    parts = {part.lower() for part in PurePosixPath(normalized).parts}
    if parts & PROHIBITED_PARTS or ("tests" in parts and not allow_test_fixtures):
        _add(
            items,
            "prohibited_catalog_path",
            path,
            "test, generated, cache, private-evidence, and build paths are prohibited",
        )
    if not allow_script_source and resolved.suffix.lower() in {".gd", ".cs", ".exe", ".sh"}:
        _add(
            items,
            "prohibited_runtime_reference",
            path,
            "catalog data cannot name scripts, classes, or executables",
        )
    if not resolved.is_file():
        _add(items, "unresolved_catalog_reference", path, "repository source does not resolve")
        return None
    return resolved


def _validate_safety(value: Any, path: str, items: list[Diagnostic]) -> None:
    if isinstance(value, dict):
        for key, child in value.items():
            child_path = f"{path}/{key}"
            if SECRET_KEY.search(str(key)):
                _add(items, "secret", child_path, "secret-bearing catalog fields are prohibited")
            if RUNTIME_KEY.search(str(key)):
                _add(
                    items,
                    "prohibited_runtime_reference",
                    child_path,
                    "script, class, reflection, executable, and evaluation fields are prohibited",
                )
            _validate_safety(child, child_path, items)
    elif isinstance(value, list):
        for index, child in enumerate(value):
            _validate_safety(child, f"{path}/{index}", items)
    elif isinstance(value, str) and NETWORK_URL.match(value):
        _add(items, "network_url", path, "network URLs are prohibited")


def _load_json(path: Path, json_path: str, items: list[Diagnostic]) -> dict[str, Any]:
    try:
        value = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError):
        _add(items, "unresolved_catalog_reference", json_path, "referenced JSON is malformed")
        return {}
    if not isinstance(value, dict):
        _add(items, "unresolved_catalog_reference", json_path, "referenced JSON must be an object")
        return {}
    return value


def _validate_compatibility(catalog: dict[str, Any], items: list[Diagnostic]) -> None:
    value = catalog.get("compatibility")
    if not _exact_keys(value, COMPATIBILITY_KEYS, "/compatibility", items):
        return
    expected = {
        "engine": "godot_4_7",
        "minimum_seats": 1,
        "maximum_seats": 8,
        "package_kind": "tale",
        "package_schema_version": 1,
        "unknown_field_policy": "reject",
        "provider_policy": "static_repository_reviewed_allowlist",
    }
    if value != expected:
        _add(
            items,
            "unsupported_catalog_schema",
            "/compatibility",
            "catalog compatibility must preserve the reviewed Godot 4.7, 1-8 seat, closed-provider policy",
        )


def _validate_identity_policy(catalog: dict[str, Any], items: list[Diagnostic]) -> None:
    value = catalog.get("identity_policy")
    if not _exact_keys(value, IDENTITY_KEYS, "/identity_policy", items):
        return
    if value != {
        "algorithm": "sha256",
        "canonicalization": "utf8_json_sorted_object_keys_compact_arrays_preserved",
        "non_authoritative_metadata_excluded": [],
    }:
        _add(
            items,
            "unstable_catalog_identity",
            "/identity_policy",
            "catalog identity must use the reviewed canonical SHA-256 policy",
        )


def _validate_display(
    entry: dict[str, Any],
    package: dict[str, Any],
    path: str,
    items: list[Diagnostic],
    allow_test_fixtures: bool,
) -> None:
    display = entry.get("display")
    if not _exact_keys(display, DISPLAY_KEYS, f"{path}/display", items):
        return
    assert isinstance(display, dict)
    resolved = _resource_path(
        display.get("catalog_path"),
        f"{path}/display/catalog_path",
        items,
        allow_test_fixtures=allow_test_fixtures,
    )
    if resolved is None:
        return
    if hashlib.sha256(resolved.read_bytes()).hexdigest() != display.get("catalog_sha256"):
        _add(
            items,
            "unresolved_catalog_display",
            f"{path}/display/catalog_sha256",
            "governed display catalog hash does not match",
        )
    values = _load_json(resolved, f"{path}/display/catalog_path", items)
    for key_name in ("display_key", "briefing_key", "objective_key"):
        key = display.get(key_name)
        if not isinstance(key, str) or not isinstance(values.get(key), str) or not values[key]:
            _add(
                items,
                "unresolved_catalog_display",
                f"{path}/display/{key_name}",
                f"governed display key '{key}' does not resolve",
            )
    package_display = package.get("localization", {})
    expected_pairs = {
        "catalog_path": "catalog",
        "catalog_sha256": "catalog_sha256",
        "display_key": "display_key",
        "briefing_key": "briefing_key",
        "objective_key": "objective_key",
    }
    for entry_key, package_key in expected_pairs.items():
        if display.get(entry_key) != package_display.get(package_key):
            _add(
                items,
                "unresolved_catalog_display",
                f"{path}/display/{entry_key}",
                f"display reference does not match package localization '{package_key}'",
            )


def _validate_provider(
    entry: dict[str, Any],
    package: dict[str, Any],
    manifest: dict[str, Any],
    path: str,
    items: list[Diagnostic],
    provider_specs: dict[str, dict[str, Any]],
) -> None:
    provider = entry.get("provider")
    if not _exact_keys(provider, PROVIDER_KEYS, f"{path}/provider", items):
        return
    assert isinstance(provider, dict)
    provider_id = provider.get("provider_id")
    spec = provider_specs.get(provider_id)
    if spec is None:
        _add(
            items,
            "unknown_provider",
            f"{path}/provider/provider_id",
            "provider is not in the reviewed static allowlist",
        )
        return
    if provider != spec:
        _add(
            items,
            "provider_reference_mismatch",
            f"{path}/provider",
            "provider declaration does not match the reviewed registry",
        )
    package_content = package.get("content", {})
    for key in (
        "board_reference",
        "rules_reference",
        "director_reference",
        "social_reference",
    ):
        if provider.get(key) != package_content.get(key) or provider.get(key) != manifest.get(key):
            _add(
                items,
                "provider_reference_mismatch",
                f"{path}/provider/{key}",
                "provider reference must match the package and scenario manifest",
            )


def _validate_entries(
    catalog: dict[str, Any],
    items: list[Diagnostic],
    *,
    allow_test_fixtures: bool,
    provider_specs: dict[str, dict[str, Any]],
) -> tuple[list[str], dict[str, dict[str, Any]]]:
    entries = catalog.get("entries")
    if not isinstance(entries, list) or not entries:
        _add(items, "missing_required_field", "/entries", "catalog requires at least one entry")
        return [], {}
    ids: list[str] = []
    context: dict[str, dict[str, Any]] = {}
    for index, value in enumerate(entries):
        path = f"/entries/{index}"
        if not _exact_keys(value, ENTRY_KEYS, path, items):
            continue
        assert isinstance(value, dict)
        tale_id = value.get("tale_id")
        if not isinstance(tale_id, str) or not STABLE_ID.fullmatch(tale_id):
            _add(items, "unstable_catalog_identity", f"{path}/tale_id", "Tale ID is unstable")
            continue
        if tale_id in ids:
            _add(items, "duplicate_tale_id", f"{path}/tale_id", "Tale IDs must be unique")
        ids.append(tale_id)
        package_path = _resource_path(
            value.get("package_path"),
            f"{path}/package_path",
            items,
            allow_test_fixtures=allow_test_fixtures,
        )
        if package_path is None:
            continue
        package = _load_json(package_path, f"{path}/package_path", items)
        if not package:
            continue
        for diagnostic in tale_package.validate(package):
            _add(
                items,
                "package_rejected",
                f"{path}/package_path{diagnostic.path}",
                diagnostic.message,
            )
        actual_digest = tale_package.package_digest(package)
        expected_digest = value.get("package_sha256")
        if not isinstance(expected_digest, str) or not SHA256.fullmatch(expected_digest):
            _add(
                items,
                "unstable_catalog_identity",
                f"{path}/package_sha256",
                "expected package SHA-256 must be lowercase hexadecimal",
            )
        elif actual_digest != expected_digest:
            _add(
                items,
                "package_identity_mismatch",
                f"{path}/package_sha256",
                "referenced package does not match the reviewed SHA-256",
            )
        comparisons = (
            ("package_kind", "package_kind", "package_kind_mismatch"),
            ("package_schema_version", "schema_version", "package_schema_mismatch"),
            ("package_version", "package_version", "package_version_mismatch"),
        )
        for entry_key, package_key, code in comparisons:
            if value.get(entry_key) != package.get(package_key):
                _add(items, code, f"{path}/{entry_key}", f"entry does not match package {package_key}")
        if tale_id != package.get("tale_id"):
            _add(
                items,
                "entry_tale_id_mismatch",
                f"{path}/tale_id",
                "entry Tale ID does not match the referenced package",
            )
        content = package.get("content", {})
        manifest_path = tale_package._resource_path(content.get("scenario_manifest", ""))
        manifest = (
            _load_json(manifest_path, f"{path}/package_path/content/scenario_manifest", items)
            if manifest_path is not None and manifest_path.is_file()
            else {}
        )
        _validate_display(value, package, path, items, allow_test_fixtures)
        _validate_provider(value, package, manifest, path, items, provider_specs)
        context[tale_id] = {
            "entry": value,
            "package": package,
            "package_path": package_path,
            "package_sha256": actual_digest,
        }
    if ids != sorted(ids):
        _add(items, "unstable_catalog_ordering", "/entries", "entries must be sorted by Tale ID")
    default = catalog.get("default_tale_id")
    if not isinstance(default, str) or ids.count(default) != 1:
        _add(
            items,
            "invalid_default_tale",
            "/default_tale_id",
            "default Tale ID must resolve exactly once",
        )
    return ids, context


def _validate_ledger(
    catalog: dict[str, Any],
    ids: list[str],
    context: dict[str, dict[str, Any]],
    items: list[Diagnostic],
    *,
    allow_test_fixtures: bool,
) -> None:
    ledger = catalog.get("source_ledger")
    if not isinstance(ledger, list) or not ledger:
        _add(items, "incomplete_source_ledger", "/source_ledger", "source ledger is required")
        return
    seen: set[tuple[str, str]] = set()
    ordering: list[tuple[str, str, str]] = []
    for index, value in enumerate(ledger):
        path = f"/source_ledger/{index}"
        if not _exact_keys(value, LEDGER_KEYS, path, items):
            continue
        assert isinstance(value, dict)
        tale_id, role, source = value.get("tale_id"), value.get("role"), value.get("path")
        if tale_id not in ids or role not in LEDGER_ROLES:
            _add(items, "incomplete_source_ledger", path, "ledger Tale ID or role is not consumed")
            continue
        key = (tale_id, role)
        if key in seen:
            _add(items, "duplicate_source_role", path, "ledger Tale roles must be unique")
        seen.add(key)
        ordering.append((tale_id, role, source if isinstance(source, str) else ""))
        resolved = _resource_path(
            source,
            f"{path}/path",
            items,
            allow_test_fixtures=allow_test_fixtures,
            allow_script_source=role == "provider_registry",
        )
        entry_context = context.get(tale_id, {})
        entry = entry_context.get("entry", {})
        expected: tuple[Any, Any] | None = None
        if role == "tale_package":
            expected = (entry.get("package_path", "").replace("res://", "game/"), entry.get("package_sha256"))
        elif role == "governed_display":
            display = entry.get("display", {})
            expected = (display.get("catalog_path", "").replace("res://", "game/"), display.get("catalog_sha256"))
        elif role == "provider_registry":
            expected = (
                "game/src/session/tale_provider_registry.gd",
                entry.get("provider", {}).get("provider_id"),
            )
        if expected is not None and (source, value.get("reference")) != expected:
            _add(
                items,
                "incomplete_source_ledger",
                path,
                "ledger path/reference does not match the catalog entry",
            )
        if resolved is not None and not isinstance(value.get("reference"), str):
            _add(items, "incomplete_source_ledger", f"{path}/reference", "reference is required")
    if ordering != sorted(ordering):
        _add(
            items,
            "unstable_catalog_ordering",
            "/source_ledger",
            "source ledger must be sorted by Tale ID, role, and path",
        )
    for tale_id in ids:
        for role in LEDGER_ROLES:
            if (tale_id, role) not in seen:
                _add(
                    items,
                    "incomplete_source_ledger",
                    "/source_ledger",
                    f"Tale '{tale_id}' is missing source role '{role}'",
                )


def validate(
    catalog: Any,
    *,
    expected_digest: str | None = None,
    allow_test_fixtures: bool = False,
    provider_specs: dict[str, dict[str, Any]] | None = None,
) -> list[Diagnostic]:
    items: list[Diagnostic] = []
    if not isinstance(catalog, dict):
        return [Diagnostic("unsupported_catalog_schema", "/", "catalog root must be an object")]
    _validate_safety(catalog, "", items)
    if not _exact_keys(catalog, ROOT_KEYS, "", items):
        return sorted(set(items))
    if (
        catalog.get("catalog_kind") != "tale_catalog"
        or catalog.get("schema_version") != 1
        or catalog.get("catalog_version") != 1
    ):
        _add(
            items,
            "unsupported_catalog_schema",
            "/catalog_kind",
            "catalog kind/schema/version must be tale_catalog/1/1",
        )
    if expected_digest is not None and catalog_digest(catalog) != expected_digest:
        _add(
            items,
            "unstable_catalog_identity",
            "/",
            "catalog canonical SHA-256 does not match the reviewed identity",
        )
    _validate_compatibility(catalog, items)
    _validate_identity_policy(catalog, items)
    ids, context = _validate_entries(
        catalog,
        items,
        allow_test_fixtures=allow_test_fixtures,
        provider_specs=provider_specs or PROVIDER_SPECS,
    )
    _validate_ledger(
        catalog,
        ids,
        context,
        items,
        allow_test_fixtures=allow_test_fixtures,
    )
    return sorted(set(items))


def validate_file(
    path: Path = DEFAULT_CATALOG,
    *,
    expected_digest: str | None = PRODUCTION_DIGEST,
) -> tuple[dict[str, Any], list[Diagnostic]]:
    try:
        value = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError):
        return {}, [Diagnostic("unsupported_catalog_schema", "/", "catalog file is unreadable")]
    return value, validate(value, expected_digest=expected_digest)


def summary(catalog: dict[str, Any]) -> dict[str, Any]:
    entries = catalog.get("entries", [])
    return {
        "accepted": True,
        "catalog_kind": catalog.get("catalog_kind"),
        "schema_version": catalog.get("schema_version"),
        "catalog_version": catalog.get("catalog_version"),
        "sha256": catalog_digest(catalog),
        "default_tale_id": catalog.get("default_tale_id"),
        "inventory": [
            {
                "tale_id": entry.get("tale_id"),
                "package_sha256": entry.get("package_sha256"),
                "provider_id": entry.get("provider", {}).get("provider_id"),
                "provider_version": entry.get("provider", {}).get("provider_version"),
            }
            for entry in entries
            if isinstance(entry, dict)
        ],
        "source_ledger": catalog.get("source_ledger", []),
        "compatibility": catalog.get("compatibility", {}),
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("command", choices=("validate", "identity"), nargs="?", default="validate")
    parser.add_argument("path", nargs="?", type=Path, default=DEFAULT_CATALOG)
    args = parser.parse_args()
    catalog, diagnostics = validate_file(args.path)
    if diagnostics:
        print(
            json.dumps(
                {"accepted": False, "diagnostics": [item.as_dict() for item in diagnostics]},
                indent=2,
            )
        )
        return 1
    result = summary(catalog)
    if args.command == "identity":
        result = {"accepted": True, "sha256": result["sha256"]}
    print(json.dumps(result, indent=2, sort_keys=True))
    return 0


if __name__ == "__main__":
    sys.exit(main())
