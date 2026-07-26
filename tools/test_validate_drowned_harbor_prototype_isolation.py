#!/usr/bin/env python3
"""Regression tests for the Drowned Harbor isolation validator."""

from __future__ import annotations

import json
import shutil
import tempfile
from pathlib import Path
from typing import Callable

from validate_drowned_harbor_prototype_isolation import (
    CATALOG_PATH,
    EXPORT_PRESETS_PATH,
    GODOT_TEST_PATH,
    MANIFEST_PATH,
    PROVIDER_PATH,
    README_PATH,
    IsolationValidationError,
    read_json,
    validate,
)

ROOT = Path(".")
Mutation = Callable[[Path], None]


def copy_file(source_root: Path, target_root: Path, relative: Path) -> None:
    target = target_root / relative
    target.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(source_root / relative, target)


def make_fixture() -> Path:
    fixture = Path(tempfile.mkdtemp(prefix="drowned-harbor-isolation-"))
    for relative in (
        MANIFEST_PATH,
        CATALOG_PATH,
        PROVIDER_PATH,
        EXPORT_PRESETS_PATH,
        README_PATH,
        GODOT_TEST_PATH,
    ):
        copy_file(ROOT, fixture, relative)
    manifest = read_json(ROOT / MANIFEST_PATH)
    for source in manifest["source_authorities"]:
        copy_file(ROOT, fixture, Path(source))
    for fixture_uri in manifest["fixture_packages"]:
        relative = Path("game") / fixture_uri.removeprefix("res://")
        copy_file(ROOT, fixture, relative)
    return fixture


def write_manifest(root: Path, mutate: Callable[[dict], None]) -> None:
    path = root / MANIFEST_PATH
    data = read_json(path)
    mutate(data)
    path.write_text(
        json.dumps(data, indent=2, ensure_ascii=False) + "\n",
        encoding="utf-8",
    )


def expect_failure(name: str, mutation: Mutation) -> None:
    fixture = make_fixture()
    try:
        mutation(fixture)
        try:
            validate(fixture)
        except (IsolationValidationError, OSError):
            return
        raise AssertionError(f"mutation did not fail closed: {name}")
    finally:
        shutil.rmtree(fixture)


def main() -> int:
    fixture = make_fixture()
    try:
        validate(fixture)
    finally:
        shutil.rmtree(fixture)

    mutations: list[tuple[str, Mutation]] = [
        (
            "production catalog registration",
            lambda root: write_manifest(
                root,
                lambda data: data.__setitem__(
                    "production_catalog_registered",
                    True,
                ),
            ),
        ),
        (
            "production provider registration",
            lambda root: write_manifest(
                root,
                lambda data: data.__setitem__(
                    "production_provider_registered",
                    True,
                ),
            ),
        ),
        (
            "normal Tale Library visibility",
            lambda root: write_manifest(
                root,
                lambda data: data.__setitem__(
                    "normal_tale_library_visible",
                    True,
                ),
            ),
        ),
        (
            "playable export authorization",
            lambda root: write_manifest(
                root,
                lambda data: data.__setitem__(
                    "playable_export_authorized",
                    True,
                ),
            ),
        ),
        (
            "runtime authority creation",
            lambda root: write_manifest(
                root,
                lambda data: data.__setitem__(
                    "runtime_authority_created",
                    True,
                ),
            ),
        ),
        (
            "network dependency",
            lambda root: write_manifest(
                root,
                lambda data: data["dependencies"].__setitem__(
                    "network",
                    True,
                ),
            ),
        ),
        (
            "credential dependency",
            lambda root: write_manifest(
                root,
                lambda data: data["dependencies"].__setitem__(
                    "credentials",
                    True,
                ),
            ),
        ),
        (
            "entry point outside tests",
            lambda root: write_manifest(
                root,
                lambda data: data.__setitem__(
                    "allowed_entry_points",
                    ["res://src/main/main.gd"],
                ),
            ),
        ),
        (
            "fixture package outside tests",
            lambda root: write_manifest(
                root,
                lambda data: data.__setitem__(
                    "fixture_packages",
                    ["res://data/tales/drowned_harbor/fixtures.json"],
                ),
            ),
        ),
        (
            "fixture package missing",
            lambda root: (
                root
                / "game/tests/drowned_harbor_dev_only/"
                "state_projection_fixtures_v1.json"
            ).unlink(),
        ),
        (
            "unknown manifest field",
            lambda root: write_manifest(
                root,
                lambda data: data.__setitem__(
                    "runtime_scene",
                    "res://src/main/main.tscn",
                ),
            ),
        ),
        (
            "shipping status",
            lambda root: write_manifest(
                root,
                lambda data: data.__setitem__(
                    "status",
                    "prototype_playable",
                ),
            ),
        ),
        (
            "completed issue drift",
            lambda root: write_manifest(
                root,
                lambda data: data.__setitem__(
                    "completed_work_issues",
                    [80],
                ),
            ),
        ),
        (
            "future issue drift",
            lambda root: write_manifest(
                root,
                lambda data: data.__setitem__(
                    "future_work_issues",
                    [81, 82, 83, 84, 85, 86],
                ),
            ),
        ),
        (
            "human evidence claim",
            lambda root: write_manifest(
                root,
                lambda data: data.__setitem__(
                    "human_evidence_claimed",
                    True,
                ),
            ),
        ),
        (
            "human validation removed",
            lambda root: write_manifest(
                root,
                lambda data: data.__setitem__(
                    "human_validation_required",
                    False,
                ),
            ),
        ),
        (
            "source authority removed",
            lambda root: write_manifest(
                root,
                lambda data: data.__setitem__(
                    "source_authorities",
                    data["source_authorities"][:-1],
                ),
            ),
        ),
        (
            "production catalog changed",
            lambda root: (root / CATALOG_PATH).write_text(
                (root / CATALOG_PATH)
                .read_text(encoding="utf-8")
                .replace(
                    '"default_tale_id": "lantern_house_vertical_slice"',
                    '"default_tale_id": "drowned_harbor"',
                ),
                encoding="utf-8",
            ),
        ),
        (
            "provider registry changed",
            lambda root: (root / PROVIDER_PATH).write_text(
                (root / PROVIDER_PATH).read_text(encoding="utf-8")
                + "\n# drowned_harbor provider\n",
                encoding="utf-8",
            ),
        ),
        (
            "export exclusion removed",
            lambda root: (root / EXPORT_PRESETS_PATH).write_text(
                (root / EXPORT_PRESETS_PATH)
                .read_text(encoding="utf-8")
                .replace("tests/*,", "", 1),
                encoding="utf-8",
            ),
        ),
        (
            "README current/future boundary removed",
            lambda root: (root / README_PATH).write_text(
                (root / README_PATH)
                .read_text(encoding="utf-8")
                .replace("## What exists today", "## Status"),
                encoding="utf-8",
            ),
        ),
    ]

    for name, mutation in mutations:
        expect_failure(name, mutation)

    print(
        "Drowned Harbor prototype isolation regression tests passed: "
        f"{len(mutations)} fail-closed mutations"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
