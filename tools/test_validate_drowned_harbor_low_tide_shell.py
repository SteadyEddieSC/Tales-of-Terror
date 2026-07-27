#!/usr/bin/env python3
"""Fail-closed regression tests for the P0.15 Low Tide shell validator."""

from __future__ import annotations

import json
import shutil
import tempfile
from pathlib import Path
from typing import Callable

from validate_drowned_harbor_low_tide_shell import (
    ADAPTER_PATH,
    CATALOG_PATH,
    EXPORT_PRESETS_PATH,
    FIXTURE_PATH,
    MANIFEST_PATH,
    PROJECT_PATH,
    PROVIDER_PATH,
    SCENE_PATH,
    SHELL_PATH,
    SUMMARY_PATH,
    TECHNICAL_PATH,
    TEST_PATH,
    LowTideShellValidationError,
    read_json,
    validate,
)

ROOT = Path(".")
Mutation = Callable[[Path], None]
BASE_FILES = (
    ADAPTER_PATH,
    ADAPTER_PATH.with_suffix(".gd.uid"),
    CATALOG_PATH,
    EXPORT_PRESETS_PATH,
    FIXTURE_PATH,
    MANIFEST_PATH,
    PROJECT_PATH,
    PROVIDER_PATH,
    SCENE_PATH,
    SHELL_PATH,
    SHELL_PATH.with_suffix(".gd.uid"),
    SUMMARY_PATH,
    TECHNICAL_PATH,
    TEST_PATH,
    TEST_PATH.with_suffix(".gd.uid"),
)


def copy_file(source_root: Path, target_root: Path, relative: Path) -> None:
    target = target_root / relative
    target.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(source_root / relative, target)


def make_fixture() -> Path:
    fixture = Path(tempfile.mkdtemp(prefix="drowned-harbor-low-tide-shell-"))
    for relative in BASE_FILES:
        copy_file(ROOT, fixture, relative)
    return fixture


def rewrite_json(root: Path, relative: Path, mutate: Callable[[dict], None]) -> None:
    path = root / relative
    data = read_json(path)
    mutate(data)
    path.write_text(
        json.dumps(data, indent=2, ensure_ascii=False) + "\n",
        encoding="utf-8",
    )


def mutate_low_tide(root: Path, mutate: Callable[[dict], None]) -> None:
    def mutate_package(package: dict) -> None:
        fixture = next(
            item
            for item in package["fixtures"]
            if item.get("fixture_id") == "DH-FIX-001"
        )
        mutate(fixture)

    rewrite_json(root, FIXTURE_PATH, mutate_package)


def replace_text(root: Path, relative: Path, old: str, new: str) -> None:
    path = root / relative
    text = path.read_text(encoding="utf-8")
    if old not in text:
        raise AssertionError(f"mutation source text not found in {relative}: {old}")
    path.write_text(text.replace(old, new, 1), encoding="utf-8")


def remove_controller_mapping(root: Path, action: str) -> None:
    path = root / PROJECT_PATH
    lines = path.read_text(encoding="utf-8").splitlines()
    changed = False
    for index, line in enumerate(lines):
        if not line.startswith(f"{action}="):
            continue
        line = line.replace(
            ', Object(InputEventJoypadButton,"device":-1,"button_index":0)',
            "",
        )
        line = line.replace(
            ', Object(InputEventJoypadMotion,"device":-1,"axis":0,"axis_value":1.0)',
            "",
        )
        lines[index] = line
        changed = True
        break
    if not changed:
        raise AssertionError(f"input action not found: {action}")
    path.write_text("\n".join(lines) + "\n", encoding="utf-8")


def expect_failure(name: str, mutation: Mutation) -> None:
    fixture = make_fixture()
    try:
        mutation(fixture)
        try:
            validate(fixture)
        except (LowTideShellValidationError, OSError):
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
            "fixture trace drift",
            lambda root: mutate_low_tide(
                root,
                lambda fixture: fixture.__setitem__("trace_id", "DH-IS-004"),
            ),
        ),
        (
            "private projection path",
            lambda root: mutate_low_tide(
                root,
                lambda fixture: fixture["projection_map"]["public"].__setitem__(
                    "objective",
                    "private.objective",
                ),
            ),
        ),
        (
            "RNG consumption",
            lambda root: mutate_low_tide(
                root,
                lambda fixture: fixture.__setitem__("rng_cursor_after", 5),
            ),
        ),
        (
            "stable seat replacement",
            lambda root: mutate_low_tide(
                root,
                lambda fixture: fixture.__setitem__(
                    "stable_seat_identity_after",
                    "seat_02",
                ),
            ),
        ),
        (
            "adapter stale guard removed",
            lambda root: replace_text(
                root,
                ADAPTER_PATH,
                "stale_source_revision",
                "stale_guard_removed",
            ),
        ),
        (
            "shell persistent voice-off contract removed",
            lambda root: replace_text(
                root,
                SHELL_PATH,
                "persistent_text_when_voice_off",
                "voice_only_information",
            ),
        ),
        (
            "final gameplay commit enabled",
            lambda root: replace_text(
                root,
                SHELL_PATH,
                '"authoritative_commit": false',
                '"authoritative_commit": true',
            ),
        ),
        (
            "scene moved to production script",
            lambda root: replace_text(
                root,
                SCENE_PATH,
                "res://tests/drowned_harbor_dev_only/"
                "low_tide_shared_screen_shell.gd",
                "res://src/main/main.gd",
            ),
        ),
        (
            "controller mapping removed",
            lambda root: remove_controller_mapping(root, "ui_confirm"),
        ),
        (
            "manifest production registration",
            lambda root: rewrite_json(
                root,
                MANIFEST_PATH,
                lambda manifest: manifest.__setitem__(
                    "production_catalog_registered",
                    True,
                ),
            ),
        ),
        (
            "future issue activation drift",
            lambda root: rewrite_json(
                root,
                MANIFEST_PATH,
                lambda manifest: manifest.__setitem__(
                    "future_work_issues",
                    [84, 85, 86],
                ),
            ),
        ),
        (
            "production catalog registration",
            lambda root: replace_text(
                root,
                CATALOG_PATH,
                '"default_tale_id": "lantern_house_vertical_slice"',
                '"default_tale_id": "drowned_harbor"',
            ),
        ),
        (
            "production provider registration",
            lambda root: (root / PROVIDER_PATH).write_text(
                (root / PROVIDER_PATH).read_text(encoding="utf-8")
                + "\n# drowned_harbor provider\n",
                encoding="utf-8",
            ),
        ),
        (
            "export exclusion removed",
            lambda root: replace_text(
                root,
                EXPORT_PRESETS_PATH,
                "tests/*",
                "tests/legacy_only/*",
            ),
        ),
        (
            "human evidence claim",
            lambda root: rewrite_json(
                root,
                MANIFEST_PATH,
                lambda manifest: manifest.__setitem__(
                    "human_evidence_claimed",
                    True,
                ),
            ),
        ),
    ]

    for name, mutation in mutations:
        expect_failure(name, mutation)

    print(
        "Drowned Harbor Low Tide shell regression tests passed: "
        f"{len(mutations)} fail-closed mutations"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
