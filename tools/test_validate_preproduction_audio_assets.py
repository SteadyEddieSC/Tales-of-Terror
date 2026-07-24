#!/usr/bin/env python3
"""Regression tests for the governed preproduction audio asset validator."""

from __future__ import annotations

import copy

from validate_preproduction_audio_assets import (
    AudioAssetValidationError,
    discover_default_manifests,
    read_manifest,
    validate_manifest,
    validate_manifests,
)


def expect_failure(data: dict, fragment: str) -> None:
    try:
        validate_manifest(data)
    except AudioAssetValidationError as exc:
        assert fragment in str(exc), (fragment, str(exc))
    else:
        raise AssertionError(f"Expected failure containing: {fragment}")


def manifest_with_entry(manifests: list[dict], predicate) -> dict:
    return next(
        manifest
        for manifest in manifests
        if any(predicate(entry) for entry in manifest["entries"])
    )


def main() -> int:
    paths = discover_default_manifests()
    manifest_count, entry_count = validate_manifests(paths)
    assert manifest_count >= 3
    assert entry_count >= 36

    manifests = [read_manifest(path) for path in paths]
    base = manifests[0]

    duplicate = copy.deepcopy(base)
    duplicate["entries"].append(copy.deepcopy(duplicate["entries"][0]))
    expect_failure(duplicate, "duplicate asset id")

    wrong_category = copy.deepcopy(base)
    wrong_category["entries"][0]["category"] = "system"
    expect_failure(wrong_category, "category does not match id prefix")

    weak_signature = copy.deepcopy(base)
    weak_signature["entries"][0]["originality_tier"] = "B"
    expect_failure(weak_signature, "signature assets must remain Tier A")

    premature_approval = copy.deepcopy(base)
    premature_approval["entries"][0]["status"] = "approved"
    expect_failure(premature_approval, "may not approve production audio")

    bad_duration = copy.deepcopy(base)
    bad_duration["entries"][0]["duration"] = {
        "minimum_seconds": 20,
        "target_seconds": 10,
        "maximum_seconds": 30,
    }
    expect_failure(bad_duration, "duration ordering is invalid")

    short_loop = copy.deepcopy(base)
    short_loop["entries"][0]["duration"]["target_seconds"] = 10
    short_loop["entries"][0]["duration"]["minimum_seconds"] = 5
    expect_failure(short_loop, "looped assets require at least 15 target seconds")

    critical_source = manifest_with_entry(
        manifests,
        lambda entry: entry["gameplay_information"] == "critical_redundant",
    )
    missing_caption = copy.deepcopy(critical_source)
    critical = next(
        entry
        for entry in missing_caption["entries"]
        if entry["gameplay_information"] == "critical_redundant"
    )
    critical["accessibility"]["caption_key_required"] = False
    expect_failure(missing_caption, "critical cues require captions")

    hidden_private = copy.deepcopy(base)
    hidden_private["entries"][0]["privacy_class"] = "private_surface_deferred"
    expect_failure(hidden_private, "must use private_surface_deferred spatial mode")

    system_source = manifest_with_entry(
        manifests,
        lambda entry: entry["category"] == "system",
    )
    system_spatial = copy.deepcopy(system_source)
    system_entry = next(
        entry for entry in system_spatial["entries"] if entry["category"] == "system"
    )
    system_entry["spatial_mode"] = "board_localized"
    expect_failure(system_spatial, "system and UI cues must be global nonspatial")

    imitation = copy.deepcopy(base)
    imitation["entries"][0]["generator_guidance"]["prompt"] += (
        " in the style of a famous film composer"
    )
    expect_failure(imitation, "disallowed imitation phrase")

    licensed_source = manifest_with_entry(
        manifests,
        lambda entry: "licensed_transformed"
        in entry["provenance_policy"]["allowed_source_kinds"],
    )
    licensed_distribution = copy.deepcopy(licensed_source)
    licensed_entry = next(
        entry
        for entry in licensed_distribution["entries"]
        if "licensed_transformed"
        in entry["provenance_policy"]["allowed_source_kinds"]
    )
    licensed_entry["provenance_policy"]["raw_public_distribution"] = "allowed"
    expect_failure(licensed_distribution, "license-dependent distribution")

    signature_support = copy.deepcopy(base)
    signature_support["entries"][0]["provenance_policy"][
        "allowed_source_kinds"
    ].append("licensed_supporting")
    expect_failure(signature_support, "signature assets may not use licensed-supporting")

    print("Preproduction audio asset validator tests passed")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
