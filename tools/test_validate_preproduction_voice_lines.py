#!/usr/bin/env python3
"""Regression tests for the governed preproduction voice-line validator."""

from __future__ import annotations

import copy

from validate_preproduction_voice_lines import (
    VoiceValidationError,
    discover_default_manifests,
    read_manifest,
    validate_manifest,
    validate_manifests,
)


def expect_failure(data: dict, fragment: str) -> None:
    try:
        validate_manifest(data)
    except VoiceValidationError as exc:
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
    manifest_count, family_count = validate_manifests(paths)
    assert manifest_count >= 2
    assert family_count >= 22

    manifests = [read_manifest(path) for path in paths]
    base = manifests[0]

    duplicate = copy.deepcopy(base)
    duplicate["entries"].append(copy.deepcopy(duplicate["entries"][0]))
    expect_failure(duplicate, "duplicate family ID")

    wrong_category = copy.deepcopy(base)
    wrong_category["entries"][0]["category"] = "system"
    expect_failure(wrong_category, "category does not match ID prefix")

    approved = copy.deepcopy(base)
    approved["entries"][0]["status"] = "approved"
    expect_failure(approved, "may not approve production voice")

    bad_intensity = copy.deepcopy(base)
    bad_intensity["entries"][0]["intensity_range"] = {
        "minimum": 4,
        "target": 2,
        "maximum": 5,
    }
    expect_failure(bad_intensity, "intensity ordering is invalid")

    private_public_fact = copy.deepcopy(base)
    private_public_fact["entries"][0]["required_public_facts"].append(
        "Hidden faction assignment"
    )
    expect_failure(private_public_fact, "private value declared as a required public fact")

    weak_private_boundary = copy.deepcopy(base)
    weak_private_boundary["entries"][0]["forbidden_private_inputs"] = [
        "Unknown condition",
        "Other condition",
        "Additional condition",
    ]
    expect_failure(weak_private_boundary, "must explicitly cover hidden, private, latent, unrevealed, or future state")

    missing_profile = copy.deepcopy(base)
    del missing_profile["entries"][0]["draft_script"]["spooky"]
    expect_failure(missing_profile, "must contain all profiles and plain_system")

    elimination = copy.deepcopy(base)
    elimination["entries"][0]["draft_script"]["grim"] = (
        "The player is out. This line intentionally violates seat continuity."
    )
    expect_failure(elimination, "prohibited reset or elimination phrase")

    bad_timing = copy.deepcopy(base)
    bad_timing["entries"][0]["timing"] = {
        "minimum_seconds": 8,
        "target_seconds": 4,
        "maximum_seconds": 12,
    }
    expect_failure(bad_timing, "timing ordering is invalid")

    no_replay = copy.deepcopy(base)
    no_replay["entries"][0]["playback_policy"]["replayable"] = False
    expect_failure(no_replay, "speech must be replayable")

    blocks_input = copy.deepcopy(base)
    blocks_input["entries"][0]["playback_policy"]["blocks_input"] = True
    expect_failure(blocks_input, "voice playback may not block input")

    imitation = copy.deepcopy(base)
    imitation["entries"][0]["candidate_guidance"]["human_direction"] += (
        " in the style of a famous actor"
    )
    expect_failure(imitation, "imitation-oriented direction is prohibited")

    missing_imitation_boundary = copy.deepcopy(base)
    missing_imitation_boundary["entries"][0]["candidate_guidance"][
        "negative_direction"
    ] = "No shouting, whispering, distortion, or false urgency in this take."
    expect_failure(missing_imitation_boundary, "negative direction must reject imitation")

    unsafe_clone = copy.deepcopy(base)
    unsafe_clone["entries"][0]["provenance_policy"]["voice_clone_consent"] = (
        "not_applicable"
    )
    expect_failure(unsafe_clone, "require an explicit clone-consent boundary")

    unsafe_distribution = copy.deepcopy(base)
    unsafe_distribution["entries"][0]["provenance_policy"][
        "raw_public_distribution"
    ] = "allowed"
    expect_failure(unsafe_distribution, "may not claim unrestricted public distribution")

    system_source = manifest_with_entry(
        manifests,
        lambda entry: entry["privacy_class"] == "plain_system",
    )
    profile_drift = copy.deepcopy(system_source)
    system_entry = next(
        entry
        for entry in profile_drift["entries"]
        if entry["privacy_class"] == "plain_system"
    )
    system_entry["draft_script"]["spooky"] += " A profile-specific flourish."
    expect_failure(profile_drift, "must not change wording across presentation profiles")

    private_surface = copy.deepcopy(base)
    private_surface["entries"][0]["privacy_class"] = "private_surface_deferred"
    expect_failure(private_surface, "private-surface voice must remain deferred")

    ending_source = manifest_with_entry(
        manifests,
        lambda entry: entry["category"] == "ending",
    )
    bad_ending_stage = copy.deepcopy(ending_source)
    ending_entry = next(
        entry for entry in bad_ending_stage["entries"] if entry["category"] == "ending"
    )
    ending_entry["stages"] = ["last_light"]
    expect_failure(bad_ending_stage, "ending families must use ending_resolution only")

    print("Preproduction voice-line validator tests passed")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
