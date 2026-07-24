#!/usr/bin/env python3
"""Regression tests for validate_preproduction_dialogue.py."""

from __future__ import annotations

import copy
import json
import tempfile
from pathlib import Path

from validate_preproduction_dialogue import (
    DEFAULT_CATALOGS,
    DialogueValidationError,
    load_and_validate,
    validate_catalog,
    validate_catalogs,
)


def expect_failure(data: dict, expected_fragment: str) -> None:
    try:
        validate_catalog(data)
    except DialogueValidationError as exc:
        assert expected_fragment in str(exc), (expected_fragment, str(exc))
    else:
        raise AssertionError(
            f"Expected validation failure containing: {expected_fragment}"
        )


def expect_catalog_failure(paths: list[Path], expected_fragment: str) -> None:
    try:
        validate_catalogs(paths)
    except DialogueValidationError as exc:
        assert expected_fragment in str(exc), (expected_fragment, str(exc))
    else:
        raise AssertionError(
            f"Expected catalog validation failure containing: {expected_fragment}"
        )


def main() -> int:
    valid = load_and_validate(DEFAULT_CATALOGS[0])
    assert len(valid["entries"]) >= 20

    duplicate = copy.deepcopy(valid)
    duplicate["entries"].append(copy.deepcopy(duplicate["entries"][0]))
    expect_failure(duplicate, "duplicate dialogue key")

    missing_profile = copy.deepcopy(valid)
    del missing_profile["entries"][0]["variants"]["spooky"]
    expect_failure(missing_profile, "variants must contain exactly")

    leaked_placeholder = copy.deepcopy(valid)
    leaked_placeholder["entries"][0]["placeholders"] = [
        {
            "name": "private_objective",
            "type": "governed_public_text",
            "visibility": "public_safe",
        }
    ]
    leaked_placeholder["entries"][0]["variants"]["spooky"] += (
        " {private_objective}"
    )
    leaked_placeholder["entries"][0]["variants"]["grim"] += (
        " {private_objective}"
    )
    leaked_placeholder["entries"][0]["variants"]["gore_and_dread"] += (
        " {private_objective}"
    )
    leaked_placeholder["entries"][0]["fallback"] += " {private_objective}"
    expect_failure(leaked_placeholder, "forbidden public placeholder")

    private_type_in_public = copy.deepcopy(valid)
    private_type_in_public["entries"][0]["placeholders"] = [
        {
            "name": "secret_summary",
            "type": "governed_private_text",
            "visibility": "public_safe",
        }
    ]
    for profile in ("spooky", "grim", "gore_and_dread"):
        private_type_in_public["entries"][0]["variants"][profile] += (
            " {secret_summary}"
        )
    private_type_in_public["entries"][0]["fallback"] += " {secret_summary}"
    expect_failure(
        private_type_in_public,
        "public entries may not use private placeholder types",
    )

    undeclared = copy.deepcopy(valid)
    undeclared["entries"][0]["variants"]["spooky"] += " {seat}"
    expect_failure(undeclared, "placeholder mismatch")

    over_budget = copy.deepcopy(valid)
    over_budget["entries"][0]["variants"]["spooky"] = "x" * 601
    over_budget["entries"][0]["display_budget"]["max_characters"] = 600
    expect_failure(over_budget, "exceeds max_characters")

    private_skippable = copy.deepcopy(valid)
    private_entry = next(
        entry
        for entry in private_skippable["entries"]
        if entry["classification"] == "controlled_reveal_private"
    )
    private_entry["display_budget"]["skippable"] = True
    expect_failure(private_skippable, "may not be skippable")

    malformed_key = copy.deepcopy(valid)
    malformed_key["entries"][0]["key"] = "drowned harbor opening"
    expect_failure(malformed_key, "invalid format")

    with tempfile.TemporaryDirectory() as temp_dir:
        temp = Path(temp_dir)
        first = temp / "catalog_a.json"
        second = temp / "catalog_b.json"
        first.write_text(json.dumps(valid), encoding="utf-8")
        second.write_text(json.dumps(valid), encoding="utf-8")

        loaded = load_and_validate(first)
        assert loaded["tale_id"] == "drowned_harbor"

        expect_catalog_failure(
            [first, second],
            "duplicate dialogue key across catalogs",
        )

    print("Preproduction dialogue validator tests passed")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
