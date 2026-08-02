#!/usr/bin/env python3
"""Fail-closed mutations for the Drowned Harbor alpha.1 validator."""

from __future__ import annotations

import json
import shutil
import struct
import tempfile
from pathlib import Path
from typing import Callable

import validate_drowned_harbor_production_scaffold as validator

ROOT = Path(__file__).resolve().parents[1]

COPY_PATHS = [
    validator.PACKAGE_PATH,
    validator.SCENARIO_PATH,
    validator.LOCALIZATION_PATH,
    validator.SOURCE_ROOT,
    validator.TEST_ROOT,
    validator.WORKFLOW_PATH,
    Path("game/export_presets.cfg"),
    Path("game/data/tales/tale_catalog_v1.json"),
    Path("game/src/session/tale_provider_registry.gd"),
    Path("game/src/session/tale_catalog.gd"),
    Path("game/src/session/tale_selection_state.gd"),
    Path("game/src/session/vertical_slice_coordinator.gd"),
    Path("game/src/main/main.gd"),
    Path("docs/releases/v0.2.0-alpha.1-production-tale-scaffold.md"),
    Path("docs/playtests/v0.2.0-alpha.1-production-tale-scaffold-evidence.md"),
]


def copy_fixture(destination: Path) -> None:
    for relative in COPY_PATHS:
        source = ROOT / relative
        target = destination / relative
        target.parent.mkdir(parents=True, exist_ok=True)
        if source.is_dir():
            shutil.copytree(source, target)
        else:
            shutil.copy2(source, target)


def replace(path: Path, old: str, new: str) -> None:
    source = path.read_text(encoding="utf-8")
    if old not in source:
        raise AssertionError(f"mutation target not found: {old}")
    path.write_text(source.replace(old, new, 1), encoding="utf-8")


def mutate_json(path: Path, mutation: Callable[[dict], None]) -> None:
    value = json.loads(path.read_text(encoding="utf-8"))
    mutation(value)
    path.write_text(json.dumps(value, indent=2) + "\n", encoding="utf-8")


def expect_static_failure(name: str, mutation: Callable[[Path], None]) -> None:
    with tempfile.TemporaryDirectory(prefix="alpha1-mutation-") as temporary:
        root = Path(temporary)
        copy_fixture(root)
        mutation(root)
        try:
            validator.validate_static(root, git_boundary=False)
        except validator.ValidationError:
            print(f"PASS mutation: {name}")
            return
        raise AssertionError(f"validator accepted mutation: {name}")


def write_synthetic_pck(path: Path, resource_paths: list[str], marker: bytes = b"") -> None:
    header = bytearray(112)
    header[:4] = b"GDPC"
    struct.pack_into("<IIII", header, 4, 4, 4, 7, 1)
    struct.pack_into("<I", header, 20, 0)
    struct.pack_into("<Q", header, 24, 112)
    struct.pack_into("<Q", header, 32, 112)
    directory = bytearray(struct.pack("<I", len(resource_paths)))
    for resource_path in resource_paths:
        encoded = resource_path.encode("utf-8") + b"\0"
        directory += struct.pack("<I", len(encoded))
        directory += encoded
        directory += b"\0" * ((-len(encoded)) % 4)
        directory += struct.pack("<QQ", 0, 0) + b"\0" * 16 + struct.pack("<I", 0)
    path.write_bytes(bytes(header + directory) + marker)


def expect_export_failure(name: str, paths: list[str], marker: bytes = b"") -> None:
    with tempfile.TemporaryDirectory(prefix="alpha1-export-mutation-") as temporary:
        root = Path(temporary)
        pck = root / "export.pck"
        log = root / "export.log"
        write_synthetic_pck(pck, paths, marker)
        log.write_text("Godot export completed\n", encoding="utf-8")
        try:
            validator.validate_export_inventory("windows", pck, log, validator.BASELINE)
        except validator.ValidationError:
            print(f"PASS mutation: {name}")
            return
        raise AssertionError(f"export validator accepted mutation: {name}")


def main() -> int:
    mutations: list[tuple[str, Callable[[Path], None]]] = [
        ("wrong Tale identity", lambda root: mutate_json(root / validator.PACKAGE_PATH, lambda value: value.__setitem__("tale_id", "other_tale"))),
        ("wrong provider identity", lambda root: mutate_json(root / validator.PACKAGE_PATH, lambda value: value["provider"].__setitem__("provider_id", "dynamic_provider"))),
        ("wrong scenario identity", lambda root: mutate_json(root / validator.SCENARIO_PATH, lambda value: value.__setitem__("scenario_id", "unknown_scenario"))),
        ("wrong localization identity", lambda root: mutate_json(root / validator.LOCALIZATION_PATH, lambda value: value.__setitem__("catalog_id", "unknown_catalog"))),
        ("unknown package field", lambda root: mutate_json(root / validator.PACKAGE_PATH, lambda value: value.__setitem__("unknown", True))),
        ("authoring reference used at runtime", lambda root: mutate_json(root / validator.PACKAGE_PATH, lambda value: value["source_ledger"][0].__setitem__("path", "docs/tales/drowned_harbor/authoring/reference.json"))),
        ("prototype fixture used at runtime", lambda root: replace(root / validator.SOURCE_ROOT / "drowned_harbor_rules_content.gd", "extends RulesContent", "extends RulesContent\n# game/tests/drowned_harbor_dev_only/fixture.json")),
        ("normal catalog registration", lambda root: mutate_json(root / Path("game/data/tales/tale_catalog_v1.json"), lambda value: value["entries"].append({"tale_id": "drowned_harbor"}))),
        ("central provider registration", lambda root: replace(root / Path("game/src/session/tale_provider_registry.gd"), "extends RefCounted", "extends RefCounted\n# drowned_harbor_authorities_v1")),
        ("ordinary export inclusion", lambda root: replace(root / Path("game/export_presets.cfg"), "data/tales/drowned_harbor/*", "data/tales/drowned_harbor_package_only.json")),
        ("private Director input", lambda root: replace(root / validator.SOURCE_ROOT / "drowned_harbor_director_content.gd", '"stage_id"', '"stage_id", "private_terms"')),
        ("developer admission weakened", lambda root: replace(root / validator.SOURCE_ROOT / "drowned_harbor_developer_admission_gate.gd", "developer_only_explicit_launch", "ambiguous_launch")),
        ("complete candidate validation removed", lambda root: replace(root / validator.SOURCE_ROOT / "drowned_harbor_scoped_provider.gd", "_complete_content", "_unchecked_content")),
        ("mutable rejection enabled", lambda root: replace(root / validator.SOURCE_ROOT / "drowned_harbor_scaffold_session.gd", "assert(to_snapshot() == before)", "_revision += 1")),
        ("best-effort restoration enabled", lambda root: replace(root / validator.SOURCE_ROOT / "drowned_harbor_scaffold_session.gd", "unsupported_snapshot_version", "best_effort_field")),
        ("duplicate request guard removed", lambda root: replace(root / validator.SOURCE_ROOT / "drowned_harbor_scaffold_session.gd", "duplicate_request", "repeat_request_allowed")),
        ("rollback cleanup removed", lambda root: replace(root / validator.SOURCE_ROOT / "drowned_harbor_developer_admission_gate.gd", "_session = null", "# session retained")),
        ("production readiness claimed", lambda root: (root / "docs/playtests/v0.2.0-alpha.1-production-tale-scaffold-evidence.md").write_text("production ready\n", encoding="utf-8")),
        ("workflow validator command removed", lambda root: replace(root / validator.WORKFLOW_PATH, "python tools/validate_drowned_harbor_production_scaffold.py", "echo validator omitted")),
        ("focused Godot coverage removed", lambda root: replace(root / validator.TEST_ROOT / "drowned_harbor_production_scaffold_test.gd", "duplicate remains rejected after restore", "duplicate accepted after restore")),
        ("canonical package digest changed", lambda root: mutate_json(root / validator.PACKAGE_PATH, lambda value: value["display"].__setitem__("status", "final"))),
        ("duplicate new UID", lambda root: (root / validator.SOURCE_ROOT / "drowned_harbor_board_definition.gd.uid").write_text((root / validator.SOURCE_ROOT / "drowned_harbor_rules_content.gd.uid").read_text(encoding="ascii"), encoding="ascii")),
        ("malformed new UID", lambda root: (root / validator.SOURCE_ROOT / "drowned_harbor_board_definition.gd.uid").write_text("uid://INVALID\n", encoding="ascii")),
        ("normal navigation reachability", lambda root: replace(root / Path("game/src/main/main.gd"), "extends", "# drowned_harbor\nextends")),
    ]
    for name, mutation in mutations:
        expect_static_failure(name, mutation)
    expect_export_failure(
        "PCK inventory contains scaffold path",
        ["res://project.binary", "res://data/tales/drowned_harbor/tale_package_v1.json"],
    )
    expect_export_failure(
        "PCK bytes contain provider marker",
        ["res://project.binary"],
        b"drowned_harbor_authorities_v1",
    )
    total = len(mutations) + 2
    print(f"Validated {total}/{total} Drowned Harbor alpha.1 fail-closed mutations")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
