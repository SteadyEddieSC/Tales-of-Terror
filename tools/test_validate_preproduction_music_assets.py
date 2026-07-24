#!/usr/bin/env python3
"""Regression tests for the governed preproduction music validator."""

from __future__ import annotations

import copy

from validate_preproduction_music_assets import (
    MusicValidationError,
    discover_default_manifests,
    read_manifest,
    validate_manifest,
    validate_manifests,
)


def expect_failure(data: dict, fragment: str) -> None:
    try:
        validate_manifest(data)
    except MusicValidationError as exc:
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
    manifest_count, asset_count = validate_manifests(paths)
    assert manifest_count >= 2
    assert asset_count >= 20

    manifests = [read_manifest(path) for path in paths]
    base = manifests[0]

    duplicate = copy.deepcopy(base)
    duplicate["entries"].append(copy.deepcopy(duplicate["entries"][0]))
    expect_failure(duplicate, "duplicate asset ID")

    category_mismatch = copy.deepcopy(base)
    category_mismatch["entries"][0]["category"] = "transition"
    expect_failure(category_mismatch, "category does not match ID prefix")

    weak_signature = copy.deepcopy(base)
    weak_signature["entries"][0]["originality_tier"] = "B"
    expect_failure(weak_signature, "signature music must remain Tier A")

    approved = copy.deepcopy(base)
    approved["entries"][0]["status"] = "approved"
    expect_failure(approved, "may not approve production music")

    private_leak = copy.deepcopy(base)
    private_leak["entries"][0]["public_state_inputs"].append("Hidden faction assignment")
    expect_failure(private_leak, "private-state marker declared as public input")

    missing_private_boundary = copy.deepcopy(base)
    missing_private_boundary["entries"][0]["forbidden_private_inputs"] = [
        "Unknown state",
        "Other state",
        "Additional state",
    ]
    expect_failure(missing_private_boundary, "must explicitly cover private or hidden state")

    bad_duration = copy.deepcopy(base)
    bad_duration["entries"][0]["duration"] = {
        "minimum_seconds": 60,
        "target_seconds": 40,
        "maximum_seconds": 90,
    }
    expect_failure(bad_duration, "duration ordering is invalid")

    critical_sfx = copy.deepcopy(base)
    critical_sfx["entries"][0]["stem_architecture"]["contains_critical_sfx"] = True
    expect_failure(critical_sfx, "music may not contain critical SFX")

    broken_removal = copy.deepcopy(base)
    broken_removal["entries"][0]["stem_architecture"][
        "reduced_density_removals"
    ].append("pressure")
    expect_failure(broken_removal, "reference unavailable stems")

    no_silence = copy.deepcopy(base)
    no_silence["entries"][0]["transition_policy"]["silence_allowed"] = False
    expect_failure(no_silence, "silence must remain allowed")

    no_duck = copy.deepcopy(base)
    no_duck["entries"][0]["dialogue_policy"]["duck_under_dialogue"] = False
    expect_failure(no_duck, "music must duck under dialogue")

    gameplay_music = copy.deepcopy(base)
    gameplay_music["entries"][0]["accessibility"][
        "contains_required_gameplay_information"
    ] = True
    expect_failure(gameplay_music, "music may not contain required gameplay information")

    imitation = copy.deepcopy(base)
    imitation["entries"][0]["generator_guidance"]["prompt"] += (
        " in the style of a famous film composer"
    )
    expect_failure(imitation, "disallowed imitation phrase")

    weak_negative = copy.deepcopy(base)
    weak_negative["entries"][0]["generator_guidance"]["negative_prompt"] = (
        "generic music without imitation"
    )
    expect_failure(weak_negative, "must contain at least 40 characters")

    content_id = copy.deepcopy(base)
    content_id["entries"][0]["provenance_policy"]["content_id_policy"] = (
        "review_required"
    )
    expect_failure(content_id, "Content ID registration is prohibited")

    signature_support = copy.deepcopy(base)
    signature_support["entries"][0]["provenance_policy"][
        "allowed_source_kinds"
    ].append("licensed_supporting")
    expect_failure(signature_support, "signature music may not use licensed-supporting")

    licensed_source = manifest_with_entry(
        manifests,
        lambda entry: "licensed_transformed"
        in entry["provenance_policy"]["allowed_source_kinds"],
    )
    unsafe_distribution = copy.deepcopy(licensed_source)
    unsafe_entry = next(
        entry
        for entry in unsafe_distribution["entries"]
        if "licensed_transformed"
        in entry["provenance_policy"]["allowed_source_kinds"]
    )
    unsafe_entry["provenance_policy"]["raw_public_distribution"] = "allowed"
    expect_failure(unsafe_distribution, "license-dependent distribution")

    ending_source = manifest_with_entry(
        manifests,
        lambda entry: entry["category"] == "ending_treatment",
    )
    looping_ending = copy.deepcopy(ending_source)
    ending = next(
        entry
        for entry in looping_ending["entries"]
        if entry["category"] == "ending_treatment"
    )
    ending["loop_mode"] = "phrase_bound"
    expect_failure(looping_ending, "ending treatments must not loop")

    print("Preproduction music validator tests passed")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
