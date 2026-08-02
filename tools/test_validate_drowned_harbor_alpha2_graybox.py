#!/usr/bin/env python3
"""Fail-closed mutations for the Drowned Harbor alpha.2 graybox."""

from __future__ import annotations

import copy
import struct
import tempfile
from pathlib import Path
from typing import Callable

from validate_drowned_harbor_alpha2_graybox import (
    CATALOG_PATH,
    EVIDENCE_PATH,
    EXPORT_PRESETS_PATH,
    FORBIDDEN_EXPORT_MARKERS,
    GATE_PATH,
    LOCALIZATION_PATH,
    PACKAGE_PATH,
    PORTABLE_PATH,
    PROJECT_PATH,
    REGISTRY_PATH,
    RELEASE_PATH,
    SCENARIO_PATH,
    SOURCE_ROOT,
    TEST_PATH,
    WORKFLOW_PATH,
    Alpha2ValidationError,
    read_json,
    validate_documentation,
    validate_export_inventory,
    validate_export_policy,
    validate_package_data,
    validate_production_boundaries,
    validate_sources,
    validate_workflow,
)

ROOT = Path(".")
Mutation = Callable[[], None]
SOURCE_SHA = "1" * 40


def expect_failure(name: str, mutation: Mutation) -> None:
    try:
        mutation()
    except Alpha2ValidationError:
        return
    raise AssertionError(f"mutation did not fail closed: {name}")


def package_mutation(change: Callable[[dict], None]) -> None:
    package = copy.deepcopy(read_json(ROOT / PACKAGE_PATH))
    scenario = copy.deepcopy(read_json(ROOT / SCENARIO_PATH))
    localization = copy.deepcopy(read_json(ROOT / LOCALIZATION_PATH))
    change(package)
    validate_package_data(package, scenario, localization)


def scenario_mutation(change: Callable[[dict], None]) -> None:
    package = copy.deepcopy(read_json(ROOT / PACKAGE_PATH))
    scenario = copy.deepcopy(read_json(ROOT / SCENARIO_PATH))
    localization = copy.deepcopy(read_json(ROOT / LOCALIZATION_PATH))
    change(scenario)
    validate_package_data(package, scenario, localization)


def localization_mutation(change: Callable[[dict], None]) -> None:
    package = copy.deepcopy(read_json(ROOT / PACKAGE_PATH))
    scenario = copy.deepcopy(read_json(ROOT / SCENARIO_PATH))
    localization = copy.deepcopy(read_json(ROOT / LOCALIZATION_PATH))
    change(localization)
    validate_package_data(package, scenario, localization)


def source_mutation(filename: str, old: str, new: str) -> None:
    sources = {
        path.name: path.read_text(encoding="utf-8")
        for path in sorted((ROOT / SOURCE_ROOT).glob("*.gd"))
    }
    if old not in sources[filename]:
        raise AssertionError(f"source mutation target missing: {filename}: {old}")
    sources[filename] = sources[filename].replace(old, new, 1)
    validate_sources(
        sources,
        (ROOT / GATE_PATH).read_text(encoding="utf-8"),
        (ROOT / TEST_PATH).read_text(encoding="utf-8"),
    )


def gate_mutation(old: str, new: str) -> None:
    gate = (ROOT / GATE_PATH).read_text(encoding="utf-8")
    if old not in gate:
        raise AssertionError(f"gate mutation target missing: {old}")
    sources = {
        path.name: path.read_text(encoding="utf-8")
        for path in sorted((ROOT / SOURCE_ROOT).glob("*.gd"))
    }
    validate_sources(sources, gate.replace(old, new, 1), (ROOT / TEST_PATH).read_text(encoding="utf-8"))


def test_mutation(old: str, new: str) -> None:
    test = (ROOT / TEST_PATH).read_text(encoding="utf-8")
    if old not in test:
        raise AssertionError(f"test mutation target missing: {old}")
    sources = {
        path.name: path.read_text(encoding="utf-8")
        for path in sorted((ROOT / SOURCE_ROOT).glob("*.gd"))
    }
    validate_sources(sources, (ROOT / GATE_PATH).read_text(encoding="utf-8"), test.replace(old, new, 1))


def production_mutation(change: Callable[[dict, str, str, dict], None]) -> None:
    catalog = copy.deepcopy(read_json(ROOT / CATALOG_PATH))
    registry = (ROOT / REGISTRY_PATH).read_text(encoding="utf-8")
    project = (ROOT / PROJECT_PATH).read_text(encoding="utf-8")
    lantern = copy.deepcopy(read_json(ROOT / "game/data/tales/lantern_house/tale_package_v1.json"))
    values = [catalog, registry, project, lantern]
    change(*values)
    validate_production_boundaries(*values)


def export_policy_mutation(target: str, old: str, new: str) -> None:
    presets = (ROOT / EXPORT_PRESETS_PATH).read_text(encoding="utf-8")
    portable = (ROOT / PORTABLE_PATH).read_text(encoding="utf-8")
    if target == "presets":
        if old not in presets:
            raise AssertionError("preset mutation target missing")
        presets = presets.replace(old, new, 1)
    else:
        if old not in portable:
            raise AssertionError("portable mutation target missing")
        portable = portable.replace(old, new, 1)
    validate_export_policy(presets, portable)


def workflow_mutation(old: str, new: str) -> None:
    workflow = (ROOT / WORKFLOW_PATH).read_text(encoding="utf-8")
    if old not in workflow:
        raise AssertionError(f"workflow mutation target missing: {old}")
    validate_workflow(workflow.replace(old, new, 1))


def documentation_mutation(old: str, new: str) -> None:
    release = (ROOT / RELEASE_PATH).read_text(encoding="utf-8")
    evidence = (ROOT / EVIDENCE_PATH).read_text(encoding="utf-8")
    changelog = (ROOT / "CHANGELOG.md").read_text(encoding="utf-8")
    if old not in evidence:
        raise AssertionError(f"documentation mutation target missing: {old}")
    validate_documentation(release, evidence.replace(old, new, 1), changelog)


def fake_pck(resource_path: str, extra: bytes = b"") -> bytes:
    encoded = resource_path.encode("utf-8") + b"\x00"
    padded_length = (len(encoded) + 3) & ~3
    header = bytearray(112)
    header[:4] = b"GDPC"
    struct.pack_into("<II", header, 4, 4, 4)
    struct.pack_into("<Q", header, 32, 112)
    directory = bytearray(struct.pack("<I", 1))
    directory.extend(struct.pack("<I", len(encoded)))
    directory.extend(encoded)
    directory.extend(b"\x00" * (padded_length - len(encoded)))
    directory.extend(b"\x00" * 36)
    return bytes(header + directory + extra)


def export_mutation(resource_path: str, extra: bytes = b"") -> None:
    with tempfile.TemporaryDirectory() as temporary:
        root = Path(temporary)
        pck = root / "test.pck"
        log = root / "export.log"
        pck.write_bytes(fake_pck(resource_path, extra))
        log.write_bytes(b"safe export log")
        validate_export_inventory("windows", pck, log, SOURCE_SHA)


def main() -> int:
    validate_package_data(
        read_json(ROOT / PACKAGE_PATH),
        read_json(ROOT / SCENARIO_PATH),
        read_json(ROOT / LOCALIZATION_PATH),
    )
    mutations: list[tuple[str, Mutation]] = [
        ("package version drift", lambda: package_mutation(lambda p: p.__setitem__("package_version", 3))),
        ("provider identity drift", lambda: package_mutation(lambda p: p["provider"].__setitem__("provider_id", "other"))),
        ("snapshot version drift", lambda: package_mutation(lambda p: p["persistence"].__setitem__("snapshot_version", 1))),
        ("migration weakened", lambda: package_mutation(lambda p: p["persistence"].__setitem__("migration_policy", "best_effort"))),
        ("best effort restore enabled", lambda: package_mutation(lambda p: p["persistence"].__setitem__("best_effort_restore", True))),
        ("privacy class removed", lambda: package_mutation(lambda p: p["privacy"]["classes"].pop())),
        ("stage omitted", lambda: scenario_mutation(lambda s: s["stage_order"].pop(3))),
        ("stage reordered", lambda: scenario_mutation(lambda s: s["stage_order"].reverse())),
        ("transition omitted", lambda: scenario_mutation(lambda s: s["transitions"].pop())),
        ("transition source unreachable", lambda: scenario_mutation(lambda s: s["transitions"][1].__setitem__("from", "high_water_v1"))),
        ("transition target wrong", lambda: scenario_mutation(lambda s: s["transitions"][4].__setitem__("to", "epilogue_attribution_v1"))),
        ("unauthorized transition added", lambda: scenario_mutation(lambda s: s["transitions"].append(copy.deepcopy(s["transitions"][0])))),
        ("Council exactly once removed", lambda: scenario_mutation(lambda s: s["transitions"][2].pop("exactly_once_identity"))),
        ("High Water exactly once removed", lambda: scenario_mutation(lambda s: s["transitions"][3].pop("exactly_once_identity"))),
        ("RNG stream removed", lambda: scenario_mutation(lambda s: s["determinism"]["rng_streams"].pop())),
        ("action bound unbounded", lambda: scenario_mutation(lambda s: s["determinism"].__setitem__("maximum_accepted_actions", 9999))),
        ("rejection bound weakened", lambda: scenario_mutation(lambda s: s["determinism"].__setitem__("maximum_rejections_before_diagnostic", 99))),
        ("Director private input", lambda: scenario_mutation(lambda s: s["privacy"]["director_input_allowlist"].append("seat_private"))),
        ("normal catalog admission enabled", lambda: scenario_mutation(lambda s: s["admission"].__setitem__("normal_catalog_registered", True))),
        ("ordinary export admission enabled", lambda: scenario_mutation(lambda s: s["admission"].__setitem__("ordinary_export_authorized", True))),
        ("stage localization missing", lambda: localization_mutation(lambda l: l["entries"].pop("stage.high_water_v1"))),
        ("localization promoted", lambda: localization_mutation(lambda l: l.__setitem__("status", "production_final"))),
        ("BoardState ownership removed", lambda: source_mutation("drowned_harbor_alpha2_board_authority.gd", "var _state := BoardState.new(_definition)", "var _state := RefCounted.new()")),
        ("High Water atomic seam removed", lambda: source_mutation("drowned_harbor_alpha2_board_authority.gd", "apply_high_water_atomic", "apply_partial_high_water")),
        ("Council identity commit duplicated", lambda: source_mutation("drowned_harbor_alpha2_rules_authority.gd", "_council_commitment_id = _identity(", "_council_commitment_id = _identity(\n\t_council_commitment_id = _identity(")),
        ("High Water identity commit duplicated", lambda: source_mutation("drowned_harbor_alpha2_rules_authority.gd", "_high_water_transformation_id = _identity(", "_high_water_transformation_id = _identity(\n\t_high_water_transformation_id = _identity(")),
        ("private projection owner removed", lambda: source_mutation("drowned_harbor_alpha2_role_authority.gd", "seat_private_view", "seat_public_only")),
        ("public event signal removed", lambda: source_mutation("drowned_harbor_alpha2_session.gd", "signal public_event_committed(event: Dictionary)", "signal event_hidden(event: Dictionary)")),
        ("processed request persistence removed", lambda: source_mutation("drowned_harbor_alpha2_session.gd", '"processed_request_ids": _processed_request_ids.duplicate()', '"processed_request_ids": []')),
        ("processed event persistence removed", lambda: source_mutation("drowned_harbor_alpha2_session.gd", '"processed_event_ids": _processed_event_ids.duplicate()', '"processed_event_ids": []')),
        ("projection recovery removed", lambda: source_mutation("drowned_harbor_alpha2_session.gd", "func reproject_committed_result(identity_kind: String) -> Dictionary:", "func recompute_committed_result(identity_kind: String) -> Dictionary:")),
        ("deadlock diagnostic removed", lambda: source_mutation("drowned_harbor_alpha2_session.gd", "bounded_progress_watchdog", "silent_deadlock")),
        ("runtime loads prototype", lambda: source_mutation("drowned_harbor_alpha2_session.gd", "class_name DrownedHarborAlpha2Session", 'class_name DrownedHarborAlpha2Session\nconst FIXTURE = "drowned_harbor_dev_only"')),
        ("runtime loads authoring docs", lambda: source_mutation("drowned_harbor_alpha2_session.gd", "class_name DrownedHarborAlpha2Session", 'class_name DrownedHarborAlpha2Session\nconst DOCS = "docs/authoring.json"')),
        ("alpha2 admission removed", lambda: gate_mutation("admit_alpha2", "admit_removed")),
        ("migration entry removed", lambda: gate_mutation("migrate_alpha1_snapshot_to_alpha2", "migration_removed")),
        ("seat-count eight omitted", lambda: test_mutation("for seat_count: int in range(1, 9):", "for seat_count: int in range(1, 8):")),
        ("private leak assertion removed", lambda: test_mutation('"PRIVATE_" not in _canonical(first.final_projection)', '"PUBLIC_" not in _canonical(first.final_projection)')),
        ("catalog production entry", lambda: production_mutation(lambda c, _r, _p, _l: c["entries"].append({"tale_id": "drowned_harbor"}))),
        ("central registry registration", lambda: production_mutation(lambda _c, r, _p, _l: None) if False else production_mutation_with_registry()),
        ("Lantern House identity drift", lambda: production_mutation(lambda _c, _r, _p, l: l.__setitem__("package_version", 99))),
        ("Windows export exclusion removed", lambda: export_policy_mutation("presets", ",data/scenarios/drowned_harbor_graybox_v2.json", "")),
        ("portable exclusion removed", lambda: export_policy_mutation("portable", "drowned_harbor_graybox_v2.json", "removed_graybox.json")),
        ("workflow skips alpha2 mutations", lambda: workflow_mutation("run_check alpha2-mutations python tools/test_validate_drowned_harbor_alpha2_graybox.py", "run_check alpha2-mutations python tools/removed_mutations.py")),
        ("workflow skips Linux export", lambda: workflow_mutation("export-inventory --platform linux", "export-inventory --platform omitted")),
        ("PCK contains alpha2 path", lambda: export_mutation("res://data/scenarios/drowned_harbor_graybox_v2.json")),
        ("PCK contains private marker", lambda: export_mutation("res://safe.txt", FORBIDDEN_EXPORT_MARKERS[-1])),
        ("unsupported human claim", lambda: documentation_mutation("Automation is machine evidence", "Automation is machine evidence. Human playtesting passed.")),
        ("unsupported privacy certification", lambda: documentation_mutation("Automation is machine evidence", "Automation is machine evidence. Privacy certified.")),
    ]
    for name, mutation in mutations:
        expect_failure(name, mutation)
    print(f"Validated {len(mutations)} alpha.2 fail-closed mutation cases")
    return 0


def production_mutation_with_registry() -> None:
    catalog = copy.deepcopy(read_json(ROOT / CATALOG_PATH))
    registry = (ROOT / REGISTRY_PATH).read_text(encoding="utf-8") + "\ndrowned_harbor\n"
    project = (ROOT / PROJECT_PATH).read_text(encoding="utf-8")
    lantern = copy.deepcopy(read_json(ROOT / "game/data/tales/lantern_house/tale_package_v1.json"))
    validate_production_boundaries(catalog, registry, project, lantern)


if __name__ == "__main__":
    raise SystemExit(main())
