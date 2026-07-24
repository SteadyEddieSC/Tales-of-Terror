#!/usr/bin/env python3
"""Regression tests for the accessible narrative registry validator."""

from __future__ import annotations

import copy

from validate_accessible_narrative_registry import (
    AccessibleNarrativeValidationError,
    discover_access_manifests,
    discover_voice_manifests,
    load_voice_families,
    read_json,
    validate_access_manifests,
    validate_unit,
)


def expect_unit_failure(unit: dict, voice_families: dict, fragment: str) -> None:
    try:
        validate_unit(unit, 0, voice_families)
    except AccessibleNarrativeValidationError as exc:
        assert fragment in str(exc), (fragment, str(exc))
    else:
        raise AssertionError(f"Expected unit failure containing: {fragment}")


def expect_manifest_failure(manifests: list, voice_families: dict, fragment: str) -> None:
    try:
        validate_access_manifests(manifests, voice_families)
    except AccessibleNarrativeValidationError as exc:
        assert fragment in str(exc), (fragment, str(exc))
    else:
        raise AssertionError(f"Expected manifest failure containing: {fragment}")


def main() -> int:
    access_paths = discover_access_manifests()
    voice_families = load_voice_families(discover_voice_manifests())
    manifest_count, unit_count = validate_access_manifests(access_paths, voice_families)
    assert manifest_count >= 2
    assert unit_count == len(voice_families)
    assert unit_count >= 22

    manifests = [read_json(path) for path in access_paths]
    base_unit = manifests[0]["entries"][0]

    unknown_source = copy.deepcopy(base_unit)
    unknown_source["source_family_id"] = "DH-VO-NAR-999"
    expect_unit_failure(unknown_source, voice_families, "unknown source family")

    wrong_key = copy.deepcopy(base_unit)
    wrong_key["mechanical_equivalence_key"] = "incorrect_equivalence_key"
    expect_unit_failure(wrong_key, voice_families, "mechanical-equivalence key differs")

    wrong_privacy = copy.deepcopy(base_unit)
    wrong_privacy["privacy_class"] = "plain_system"
    expect_unit_failure(wrong_privacy, voice_families, "privacy class differs")

    missing_source_path = copy.deepcopy(base_unit)
    missing_source_path["source_field_paths"].remove("draft_script.plain_system")
    expect_unit_failure(missing_source_path, voice_families, "all four governed source fields are required")

    unnamed_placeholder = copy.deepcopy(base_unit)
    unnamed_placeholder["placeholder_policy"]["allowed_placeholders"] = ["{0}"]
    expect_unit_failure(unnamed_placeholder, voice_families, "placeholders must be named brace tokens")

    concatenation = copy.deepcopy(base_unit)
    concatenation["placeholder_policy"]["sentence_concatenation"] = True
    expect_unit_failure(concatenation, voice_families, "sentence concatenation is prohibited")

    profile_drift_families = copy.deepcopy(voice_families)
    source_id = base_unit["source_family_id"]
    profile_drift_families[source_id]["draft_script"]["spooky"] += " {seat_name}"
    expect_unit_failure(copy.deepcopy(base_unit), profile_drift_families, "source profile placeholder sets differ")

    undeclared_families = copy.deepcopy(voice_families)
    for profile in undeclared_families[source_id]["draft_script"]:
        undeclared_families[source_id]["draft_script"][profile] += " {seat_name}"
    expect_unit_failure(copy.deepcopy(base_unit), undeclared_families, "source contains undeclared placeholders")

    too_many_lines = copy.deepcopy(base_unit)
    too_many_lines["caption_policy"]["max_lines"] = 3
    expect_unit_failure(too_many_lines, voice_families, "caption target is two lines")

    timed_only = copy.deepcopy(base_unit)
    timed_only["caption_policy"]["timed_only"] = True
    expect_unit_failure(timed_only, voice_families, "may not be timed-only")

    no_transcript = copy.deepcopy(base_unit)
    no_transcript["transcript_policy"]["included"] = False
    expect_unit_failure(no_transcript, voice_families, "transcript inclusion is required")

    focus_mismatch = copy.deepcopy(base_unit)
    focus_mismatch["announcement_policy"]["focus_required"] = True
    expect_unit_failure(focus_mismatch, voice_families, "focus_required flag must match priority")

    interrupt_mismatch = copy.deepcopy(base_unit)
    interrupt_mismatch["announcement_policy"]["interrupt_lower_priority"] = True
    expect_unit_failure(interrupt_mismatch, voice_families, "nonurgent announcements may not interrupt")

    critical_unit = next(
        unit
        for manifest in manifests
        for unit in manifest["entries"]
        if unit["importance"] == "critical"
    )
    no_persistence = copy.deepcopy(critical_unit)
    no_persistence["persistent_text_policy"]["required"] = False
    expect_unit_failure(no_persistence, voice_families, "critical units require persistent text")

    approved = copy.deepcopy(base_unit)
    approved["status"] = "approved"
    expect_unit_failure(approved, voice_families, "may not approve production localization")

    wrong_speaker = copy.deepcopy(base_unit)
    wrong_speaker["speaker_key"] = "speaker.system"
    expect_unit_failure(wrong_speaker, voice_families, "character families must use host speaker key")

    duplicate_source_manifests = copy.deepcopy(manifests)
    duplicate_source_manifests[0]["entries"].append(
        copy.deepcopy(duplicate_source_manifests[0]["entries"][0])
    )
    duplicate_source_manifests[0]["entries"][-1]["unit_id"] = "DH-LOC-VO-099"
    temp_paths = []
    # Validate duplicate-source behavior through temporary JSON files created by the test.
    import tempfile
    from pathlib import Path
    with tempfile.TemporaryDirectory() as tmp:
        for index, manifest in enumerate(duplicate_source_manifests):
            path = Path(tmp) / f"manifest_{index}.json"
            path.write_text(__import__("json").dumps(manifest), encoding="utf-8")
            temp_paths.append(path)
        expect_manifest_failure(temp_paths, voice_families, "source family registered more than once")

    with tempfile.TemporaryDirectory() as tmp:
        partial = copy.deepcopy(manifests[0])
        path = Path(tmp) / "partial.json"
        path.write_text(__import__("json").dumps(partial), encoding="utf-8")
        expect_manifest_failure([path], voice_families, "voice families missing accessibility registry units")

    print("Accessible narrative registry tests passed")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
