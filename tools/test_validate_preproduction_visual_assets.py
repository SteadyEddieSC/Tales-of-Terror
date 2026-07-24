#!/usr/bin/env python3
"""Regression tests for the preproduction visual asset validator."""

from __future__ import annotations

import copy
import json
import tempfile
from pathlib import Path

from validate_preproduction_visual_assets import (
    DEFAULT_MANIFEST,
    VisualAssetValidationError,
    discover_default_manifests,
    load_and_validate,
    validate_manifest,
    validate_manifests,
)


def expect_failure(data: dict, fragment: str) -> None:
    try:
        validate_manifest(data)
    except VisualAssetValidationError as exc:
        assert fragment in str(exc), (fragment, str(exc))
    else:
        raise AssertionError(f"Expected failure containing: {fragment}")


def expect_manifest_failure(paths: list[Path], fragment: str) -> None:
    try:
        validate_manifests(paths)
    except VisualAssetValidationError as exc:
        assert fragment in str(exc), (fragment, str(exc))
    else:
        raise AssertionError(f"Expected manifest failure containing: {fragment}")


def main() -> int:
    paths = discover_default_manifests()
    manifest_count, asset_count = validate_manifests(paths)
    assert manifest_count >= 2
    assert asset_count >= 18

    valid = load_and_validate(DEFAULT_MANIFEST)
    assert len(valid["entries"]) >= 8

    duplicate = copy.deepcopy(valid)
    duplicate["entries"].append(copy.deepcopy(duplicate["entries"][0]))
    expect_failure(duplicate, "duplicate asset id")

    wrong_category = copy.deepcopy(valid)
    wrong_category["entries"][0]["category"] = "prop"
    expect_failure(wrong_category, "category does not match id prefix")

    weak_tier = copy.deepcopy(valid)
    weak_tier["entries"][0]["originality_tier"] = "C"
    expect_failure(weak_tier, "signature assets must remain Tier A")

    premature_approval = copy.deepcopy(valid)
    premature_approval["entries"][0]["status"] = "approved"
    expect_failure(premature_approval, "may not approve production assets")

    imitation = copy.deepcopy(valid)
    imitation["entries"][0]["generator_guidance"]["prompt"] += (
        " in the style of a famous illustrator"
    )
    expect_failure(imitation, "disallowed imitation phrase")

    missing_dependency = copy.deepcopy(valid)
    missing_dependency["entries"][0]["dependencies"].append("DH-ENV-999")
    expect_failure(missing_dependency, "missing dependency")

    cycle = copy.deepcopy(valid)
    first = cycle["entries"][0]["asset_id"]
    second = cycle["entries"][1]["asset_id"]
    cycle["entries"][0]["dependencies"] = [second]
    cycle["entries"][1]["dependencies"] = [first]
    expect_failure(cycle, "dependency cycle")

    licensed = copy.deepcopy(valid)
    licensed_entry = next(
        entry
        for entry in licensed["entries"]
        if "licensed_transformed"
        in entry["provenance_policy"]["allowed_source_kinds"]
    )
    licensed_entry["provenance_policy"]["raw_public_distribution"] = "allowed"
    expect_failure(licensed, "license-dependent public distribution")

    with tempfile.TemporaryDirectory() as temp_dir:
        first_path = Path(temp_dir) / "visual_a.json"
        second_path = Path(temp_dir) / "visual_b.json"
        first_path.write_text(json.dumps(valid), encoding="utf-8")
        second_path.write_text(json.dumps(valid), encoding="utf-8")
        expect_manifest_failure(
            [first_path, second_path],
            "duplicate asset id across manifests",
        )

    print("Preproduction visual asset validator tests passed")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
