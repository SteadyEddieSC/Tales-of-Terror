#!/usr/bin/env python3
"""Regression tests for P0.14 deterministic projection fixtures."""

from __future__ import annotations

import copy
import json
import shutil
import tempfile
from pathlib import Path
from typing import Callable

from validate_drowned_harbor_projection_fixtures import (
    EXPORT_PRESETS_PATH,
    PACKAGE_PATH,
    PROTOTYPE_MANIFEST_PATH,
    SCHEMA_PATH,
    ProjectionFixtureError,
    canonical_json_bytes,
    project_fixture,
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
    fixture_root = Path(
        tempfile.mkdtemp(prefix="drowned-harbor-projection-fixtures-")
    )
    for relative in (
        PACKAGE_PATH,
        SCHEMA_PATH,
        EXPORT_PRESETS_PATH,
        PROTOTYPE_MANIFEST_PATH,
    ):
        copy_file(ROOT, fixture_root, relative)
    package = read_json(ROOT / PACKAGE_PATH)
    for source in package["trace_sources"]:
        copy_file(ROOT, fixture_root, Path(source))
    return fixture_root


def write_package(root: Path, mutate: Callable[[dict], None]) -> None:
    path = root / PACKAGE_PATH
    data = read_json(path)
    mutate(data)
    path.write_text(
        json.dumps(data, indent=2, ensure_ascii=False) + "\n",
        encoding="utf-8",
    )


def write_manifest(root: Path, mutate: Callable[[dict], None]) -> None:
    path = root / PROTOTYPE_MANIFEST_PATH
    data = read_json(path)
    mutate(data)
    path.write_text(
        json.dumps(data, indent=2, ensure_ascii=False) + "\n",
        encoding="utf-8",
    )


def expect_failure(name: str, mutation: Mutation) -> None:
    root = make_fixture()
    try:
        mutation(root)
        try:
            validate(root)
        except (ProjectionFixtureError, OSError):
            return
        raise AssertionError(f"mutation did not fail closed: {name}")
    finally:
        shutil.rmtree(root)


def fixture_by_id(package: dict, fixture_id: str) -> dict:
    return next(
        fixture
        for fixture in package["fixtures"]
        if fixture["fixture_id"] == fixture_id
    )


def main() -> int:
    root = make_fixture()
    try:
        fixture_count, negative_count = validate(root)
        assert fixture_count == 6
        assert negative_count >= 26
    finally:
        shutil.rmtree(root)

    package = read_json(ROOT / PACKAGE_PATH)
    for fixture in package["fixtures"]:
        source_before = copy.deepcopy(fixture["source_state"])
        first = project_fixture(fixture)
        second = project_fixture(fixture)
        assert canonical_json_bytes(first) == canonical_json_bytes(second)
        assert fixture["source_state"] == source_before
        assert first["rng_cursor"] == fixture["rng_cursor_before"]

    private_fixture = fixture_by_id(package, "DH-FIX-003")
    private_result = project_fixture(private_fixture)
    assert private_result["private_projection"]["term_id"].startswith(
        "PRIVATE_"
    )
    public_bytes = canonical_json_bytes(
        {
            "public_projection": private_result["public_projection"],
            "events": [
                event
                for event in private_result["events"]
                if event["classification"] != "private"
            ],
        }
    ).decode("utf-8")
    assert "PRIVATE_" not in public_bytes

    recovery_fixture = fixture_by_id(package, "DH-FIX-006")
    recovery_result = project_fixture(recovery_fixture)
    assert recovery_result["authoritative_commit"] is False
    assert (
        recovery_result["source_revision"]
        == recovery_result["result_revision"]
    )
    assert recovery_result["public_projection"]["state_changed"] is False
    assert recovery_result["public_projection"]["rng_changed"] is False

    mutations: list[tuple[str, Mutation]] = [
        (
            "fixture removed",
            lambda root: write_package(
                root,
                lambda data: data["fixtures"].pop(),
            ),
        ),
        (
            "duplicate fixture ID",
            lambda root: write_package(
                root,
                lambda data: data["fixtures"].__setitem__(
                    1,
                    {
                        **data["fixtures"][1],
                        "fixture_id": data["fixtures"][0]["fixture_id"],
                    },
                ),
            ),
        ),
        (
            "trace binding drift",
            lambda root: write_package(
                root,
                lambda data: data["fixtures"][0].__setitem__(
                    "trace_id",
                    "DH-IS-004",
                ),
            ),
        ),
        (
            "storyboard binding drift",
            lambda root: write_package(
                root,
                lambda data: data["fixtures"][0].__setitem__(
                    "storyboard_id",
                    "DH-UI-004",
                ),
            ),
        ),
        (
            "private path in public projection",
            lambda root: write_package(
                root,
                lambda data: data["fixtures"][0]["projection_map"][
                    "public"
                ].__setitem__(
                    "hidden_objective",
                    "private.objective",
                ),
            ),
        ),
        (
            "private path in public event",
            lambda root: write_package(
                root,
                lambda data: data["fixtures"][1]["expected_events"][0][
                    "payload_map"
                ].__setitem__(
                    "hidden_faction",
                    "private.faction",
                ),
            ),
        ),
        (
            "public fixture private projection",
            lambda root: write_package(
                root,
                lambda data: data["fixtures"][0]["projection_map"][
                    "private"
                ].__setitem__(
                    "objective",
                    "private.objective",
                ),
            ),
        ),
        (
            "controlled-private surface removed",
            lambda root: write_package(
                root,
                lambda data: data["fixtures"][2].__setitem__(
                    "privacy_surface",
                    "public_shared",
                ),
            ),
        ),
        (
            "result revision drift",
            lambda root: write_package(
                root,
                lambda data: data["fixtures"][3].__setitem__(
                    "result_revision",
                    data["fixtures"][3]["source_revision"] + 2,
                ),
            ),
        ),
        (
            "RNG cursor consumed",
            lambda root: write_package(
                root,
                lambda data: data["fixtures"][3].__setitem__(
                    "rng_cursor_after",
                    data["fixtures"][3]["rng_cursor_before"] + 1,
                ),
            ),
        ),
        (
            "stable seat replaced",
            lambda root: write_package(
                root,
                lambda data: data["fixtures"][4].__setitem__(
                    "stable_seat_identity_after",
                    "seat_07",
                ),
            ),
        ),
        (
            "human evidence claim",
            lambda root: write_package(
                root,
                lambda data: data.__setitem__(
                    "human_evidence_claimed",
                    True,
                ),
            ),
        ),
        (
            "shipping status",
            lambda root: write_package(
                root,
                lambda data: data.__setitem__(
                    "status",
                    "production_candidate",
                ),
            ),
        ),
        (
            "unknown event key",
            lambda root: write_package(
                root,
                lambda data: data["fixtures"][0]["expected_events"][0].__setitem__(
                    "event_key",
                    "unknown_event",
                ),
            ),
        ),
        (
            "trace privacy drift",
            lambda root: (
                root
                / "docs/tales/drowned_harbor/interaction/"
                "drowned_harbor_interaction_resolution_traces_v1.json"
            ).write_text(
                (
                    root
                    / "docs/tales/drowned_harbor/interaction/"
                    "drowned_harbor_interaction_resolution_traces_v1.json"
                )
                .read_text(encoding="utf-8")
                .replace(
                    '"privacy_surface": "controlled_private_surface"',
                    '"privacy_surface": "public_shared"',
                    1,
                ),
                encoding="utf-8",
            ),
        ),
        (
            "trace source missing",
            lambda root: (
                root
                / "docs/tales/drowned_harbor/interaction/"
                "drowned_harbor_interaction_core_traces_v1.json"
            ).unlink(),
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
            "prototype future issue drift",
            lambda root: write_manifest(
                root,
                lambda data: data.__setitem__(
                    "future_work_issues",
                    [81, 82, 83, 84, 85, 86],
                ),
            ),
        ),
        (
            "prototype fixture registration removed",
            lambda root: write_manifest(
                root,
                lambda data: data.__setitem__(
                    "fixture_packages",
                    [],
                ),
            ),
        ),
        (
            "approval boundary weakened",
            lambda root: write_package(
                root,
                lambda data: data.__setitem__(
                    "approval_boundary",
                    "Synthetic fixtures.",
                ),
            ),
        ),
    ]

    for name, mutation in mutations:
        expect_failure(name, mutation)

    print(
        "Drowned Harbor projection fixture regression tests passed: "
        f"{len(mutations)} package mutations plus embedded request cases"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
