#!/usr/bin/env python3
"""Regression tests for the design-only Tale authoring reference validator."""

from __future__ import annotations

import copy
import json
import shutil
import tempfile
from pathlib import Path
from typing import Any

import validate_tale_authoring_reference as validator

REFERENCE_PATH = Path("docs/tales/drowned_harbor/authoring/drowned_harbor_authoring_reference_v1.json")
FIXTURE_PATH = Path("docs/tales/drowned_harbor/authoring/tale_authoring_invalid_cases_v1.json")


def load_json(path: Path) -> dict[str, Any]:
    data = json.loads(path.read_text(encoding="utf-8"))
    assert isinstance(data, dict)
    return data


def referenced_paths(reference: dict[str, Any], root: Path) -> set[str]:
    paths = set(reference["source_authorities"])
    paths.update(reference["content_manifests"])
    for values in reference["media_sources"].values():
        if isinstance(values, list):
            paths.update(values)
        else:
            paths.add(values)
    for decision in reference["open_decisions"]:
        paths.add(decision["source_path"])
    for manifest_path in reference["content_manifests"]:
        manifest = load_json(root / manifest_path)
        for group in manifest["groups"]:
            paths.add(group["source_path"])
    return paths


def copy_closure(source_root: Path, target_root: Path, reference: dict[str, Any]) -> None:
    required = referenced_paths(reference, source_root) | {
        REFERENCE_PATH.as_posix(),
        FIXTURE_PATH.as_posix(),
    }
    for relative in sorted(required):
        source = source_root / relative
        target = target_root / relative
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(source, target)


def find_group(root: Path, reference: dict[str, Any], kind: str) -> tuple[Path, dict[str, Any], dict[str, Any]]:
    for relative in reference["content_manifests"]:
        path = root / relative
        manifest = load_json(path)
        for group in manifest["groups"]:
            if group["kind"] == kind:
                return path, manifest, group
    raise AssertionError(f"No content group of kind {kind}")


def apply_case(root: Path, reference: dict[str, Any], case: dict[str, Any]) -> None:
    operation = case["operation"]
    arguments = case["arguments"]
    if operation == "set_reference_field":
        reference[arguments["field"]] = arguments["value"]
    elif operation == "add_reference_field":
        reference[arguments["field"]] = arguments["value"]
    elif operation == "set_compilation_field":
        reference["compilation_boundary"][arguments["field"]] = arguments["value"]
    elif operation == "clear_production_blockers":
        for decision in reference["open_decisions"]:
            decision["blocks_production"] = False
    elif operation == "remove_transition":
        reference["stage_graph"]["transitions"] = [
            transition
            for transition in reference["stage_graph"]["transitions"]
            if transition["id"] != arguments["id"]
        ]
    elif operation == "set_transformation_field":
        transformation = next(
            item
            for item in reference["signature_transformations"]
            if item["id"] == arguments["id"]
        )
        transformation[arguments["field"]] = arguments["value"]
    elif operation == "duplicate_content_id":
        first_path = root / reference["content_manifests"][0]
        first = load_json(first_path)
        first_id = first["groups"][0]["ids"][0]
        second_path = root / reference["content_manifests"][1]
        second = load_json(second_path)
        second["groups"][0]["ids"].append(first_id)
        second["groups"][0]["ids"].sort()
        second_path.write_text(json.dumps(second, indent=2) + "\n", encoding="utf-8")
    elif operation == "remove_stage_content":
        path, manifest, group = find_group(root, reference, "stage")
        for candidate in manifest["groups"]:
            if candidate["kind"] == "stage" and arguments["id"] in candidate["ids"]:
                candidate["ids"].remove(arguments["id"])
                if not candidate["ids"]:
                    manifest["groups"].remove(candidate)
                break
        path.write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
    elif operation == "remove_group_tag":
        path, manifest, group = find_group(root, reference, arguments["kind"])
        group["tags"].remove(arguments["tag"])
        path.write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
    elif operation == "replace_traceability_concept":
        path, manifest, group = find_group(root, reference, "stage")
        group["traceability_concepts"] = [arguments["value"]]
        path.write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
    elif operation == "set_group_source_path":
        path, manifest, group = find_group(root, reference, "stage")
        group["source_path"] = arguments["value"]
        path.write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
    elif operation == "remove_human_validation_obligations":
        reference["validation_obligations"] = [
            obligation
            for obligation in reference["validation_obligations"]
            if obligation["status"] != "human_validation_required"
        ]
    else:
        raise AssertionError(f"Unknown fixture operation: {operation}")


def validate_in_root(root: Path, reference: dict[str, Any]) -> list[validator.Diagnostic]:
    previous_root = validator.ROOT
    previous_trace = validator.TRACEABILITY_PATH
    try:
        validator.ROOT = root
        validator.TRACEABILITY_PATH = root / "docs/preproduction/drowned_harbor_cross_media_traceability_v1.json"
        return validator.validate_reference(reference, root / REFERENCE_PATH)
    finally:
        validator.ROOT = previous_root
        validator.TRACEABILITY_PATH = previous_trace


def main() -> int:
    source_root = Path(__file__).resolve().parents[1]
    reference = load_json(source_root / REFERENCE_PATH)
    fixture = load_json(source_root / FIXTURE_PATH)

    diagnostics = validator.validate_reference(reference, source_root / REFERENCE_PATH)
    assert diagnostics == [], [diagnostic.as_dict() for diagnostic in diagnostics]
    digest = validator.authoring_digest(reference)
    assert len(digest) == 64
    assert digest == validator.authoring_digest(copy.deepcopy(reference))

    assert fixture["fixture_kind"] == "tale_authoring_invalid_cases"
    assert fixture["schema_version"] == 1
    assert fixture["reference_path"] == REFERENCE_PATH.as_posix()
    case_ids = [case["case_id"] for case in fixture["cases"]]
    assert case_ids == sorted(case_ids)
    assert len(case_ids) == len(set(case_ids))

    for case in fixture["cases"]:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            copy_closure(source_root, root, reference)
            mutated = load_json(root / REFERENCE_PATH)
            apply_case(root, mutated, case)
            (root / REFERENCE_PATH).write_text(
                json.dumps(mutated, indent=2) + "\n", encoding="utf-8"
            )
            diagnostics = validate_in_root(root, mutated)
            codes = {diagnostic.code for diagnostic in diagnostics}
            assert case["expected_code"] in codes, (
                case["case_id"],
                case["expected_code"],
                [diagnostic.as_dict() for diagnostic in diagnostics],
            )

    print(
        f"Tale authoring reference tests passed: {len(fixture['cases'])} "
        "fail-closed invalid fixtures"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
