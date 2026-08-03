#!/usr/bin/env python3
"""Fail-closed mutations for Drowned Harbor Alpha.3 systems/replayability."""

from __future__ import annotations

import copy
import struct
import tempfile
from pathlib import Path
from typing import Callable

from validate_drowned_harbor_alpha3_systems import (
    CATALOG_PATH,
    EVIDENCE_PATH,
    EXPORT_PRESETS_PATH,
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
    Alpha3ValidationError,
    read_json,
    validate_data,
    validate_documentation,
    validate_export_inventory,
    validate_export_policy,
    validate_production_boundaries,
    validate_sources,
    validate_workflow,
)

ROOT = Path(".")
Mutation = Callable[[], None]
SOURCE_SHA = "3" * 40


def expect_failure(name: str, mutation: Mutation) -> None:
    try:
        mutation()
    except Alpha3ValidationError:
        return
    raise AssertionError(f"mutation did not fail closed: {name}")


def data_mutation(target: str, change: Callable[[dict], None]) -> None:
    package = copy.deepcopy(read_json(ROOT / PACKAGE_PATH))
    scenario = copy.deepcopy(read_json(ROOT / SCENARIO_PATH))
    localization = copy.deepcopy(read_json(ROOT / LOCALIZATION_PATH))
    values = {"package": package, "scenario": scenario, "localization": localization}
    change(values[target])
    validate_data(package, scenario, localization)


def source_mutation(filename: str, old: str, new: str) -> None:
    sources = {
        path.name: path.read_text(encoding="utf-8")
        for path in sorted((ROOT / SOURCE_ROOT).glob("*.gd"))
    }
    if old not in sources[filename]:
        raise AssertionError(f"source mutation target missing: {filename}: {old}")
    sources[filename] = sources[filename].replace(old, new, 1)
    validate_sources(sources, (ROOT / TEST_PATH).read_text(encoding="utf-8"))


def test_mutation(old: str, new: str) -> None:
    test = (ROOT / TEST_PATH).read_text(encoding="utf-8")
    if old not in test:
        raise AssertionError(f"test mutation target missing: {old}")
    sources = {
        path.name: path.read_text(encoding="utf-8")
        for path in sorted((ROOT / SOURCE_ROOT).glob("*.gd"))
    }
    validate_sources(sources, test.replace(old, new, 1))


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


def production_mutation(kind: str) -> None:
    catalog = copy.deepcopy(read_json(ROOT / CATALOG_PATH))
    lantern = copy.deepcopy(read_json(ROOT / "game/data/tales/lantern_house/tale_package_v1.json"))
    registry = (ROOT / REGISTRY_PATH).read_text(encoding="utf-8")
    project = (ROOT / PROJECT_PATH).read_text(encoding="utf-8")
    if kind == "catalog_registration":
        catalog["entries"].append({"tale_id": "drowned_harbor"})
    elif kind == "catalog_identity":
        catalog["schema_version"] = 99
    elif kind == "lantern_identity":
        lantern["package_version"] = 99
    elif kind == "registry_registration":
        registry += '\nconst DROWNED_HARBOR := "drowned_harbor"\n'
    validate_production_boundaries(catalog, lantern, registry, project)


def workflow_mutation(old: str, new: str) -> None:
    workflow = (ROOT / WORKFLOW_PATH).read_text(encoding="utf-8")
    if old not in workflow:
        raise AssertionError(f"workflow mutation target missing: {old}")
    validate_workflow(workflow.replace(old, new, 1))


def documentation_claim(claim: str) -> None:
    validate_documentation(
        (ROOT / RELEASE_PATH).read_text(encoding="utf-8"),
        (ROOT / EVIDENCE_PATH).read_text(encoding="utf-8") + f"\n{claim}\n",
        (ROOT / "CHANGELOG.md").read_text(encoding="utf-8"),
    )


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
        pck = root / "ordinary.pck"
        log = root / "export.log"
        pck.write_bytes(fake_pck(resource_path, extra))
        log.write_text("safe", encoding="utf-8")
        validate_export_inventory("windows", pck, log, SOURCE_SHA)


def main() -> int:
    package = read_json(ROOT / PACKAGE_PATH)
    scenario = read_json(ROOT / SCENARIO_PATH)
    localization = read_json(ROOT / LOCALIZATION_PATH)
    validate_data(package, scenario, localization)
    mutations: list[tuple[str, Mutation]] = [
        ("package version drift", lambda: data_mutation("package", lambda v: v.__setitem__("package_version", 4))),
        ("provider version drift", lambda: data_mutation("package", lambda v: v["provider"].__setitem__("provider_version", 2))),
        ("scenario traceability drift", lambda: data_mutation("package", lambda v: v["content"].__setitem__("scenario_sha256", "0" * 64))),
        ("localization traceability drift", lambda: data_mutation("package", lambda v: v["localization"].__setitem__("catalog_sha256", "0" * 64))),
        ("scenario version drift", lambda: data_mutation("scenario", lambda v: v.__setitem__("scenario_version", 2))),
        ("localization version drift", lambda: data_mutation("localization", lambda v: v.__setitem__("catalog_version", 2))),
        ("role removed", lambda: data_mutation("scenario", lambda v: v["roles"]["archetype_order"].pop())),
        ("role added", lambda: data_mutation("scenario", lambda v: v["roles"]["archetype_order"].append("invented_role"))),
        ("role order changed", lambda: data_mutation("scenario", lambda v: v["roles"]["archetype_order"].reverse())),
        ("Living objective missing", lambda: data_mutation("scenario", lambda v: v["objectives"]["living"].pop())),
        ("Bellmarked objective missing", lambda: data_mutation("scenario", lambda v: v["objectives"]["bellmarked"].pop())),
        ("Tidebound objective missing", lambda: data_mutation("scenario", lambda v: v["objectives"]["tidebound"].pop())),
        ("Cooperative seat range changed", lambda: data_mutation("scenario", lambda v: v["mode_plans"][0].__setitem__("minimum_seats", 2))),
        ("Hidden Betrayer seat range changed", lambda: data_mutation("scenario", lambda v: v["mode_plans"][1].__setitem__("minimum_seats", 2))),
        ("Outbreak seat range changed", lambda: data_mutation("scenario", lambda v: v["mode_plans"][2].__setitem__("minimum_seats", 1))),
        ("Cooperative fallback removed", lambda: data_mutation("scenario", lambda v: v["mode_plans"][1].__setitem__("fallback_mode", None))),
        ("multiple Bellmarked assignments", lambda: data_mutation("scenario", lambda v: v["mode_plans"][1].__setitem__("starting_hidden_faction_count", 2))),
        ("missing Bellmarked assignment", lambda: data_mutation("scenario", lambda v: v["mode_plans"][1].__setitem__("starting_hidden_faction_count", 0))),
        ("starting Tidebound seat", lambda: data_mutation("scenario", lambda v: v["mode_plans"][2].__setitem__("starting_tidebound_count", 1))),
        ("item removed", lambda: data_mutation("scenario", lambda v: v["content"]["items"].pop())),
        ("item added", lambda: data_mutation("scenario", lambda v: v["content"]["items"].append("invented_item"))),
        ("card removed", lambda: data_mutation("scenario", lambda v: v["content"]["cards"].pop())),
        ("resource removed", lambda: data_mutation("scenario", lambda v: v["content"]["resources"].pop())),
        ("hazard removed", lambda: data_mutation("scenario", lambda v: v["content"]["hazards"].pop())),
        ("encounter removed", lambda: data_mutation("scenario", lambda v: v["content"]["encounters_by_stage"]["high_water"].pop())),
        ("content ownership missing", lambda: data_mutation("scenario", lambda v: v["content"]["ownership_classes"].pop())),
        ("ending missing", lambda: data_mutation("scenario", lambda v: v["endings"].pop())),
        ("ending added", lambda: data_mutation("scenario", lambda v: v["endings"].append("invented_ending"))),
        ("privacy class missing", lambda: data_mutation("scenario", lambda v: v["privacy"]["classes"].pop())),
        ("Director private input allowed", lambda: data_mutation("scenario", lambda v: v["director"]["input_allowlist"].append("role_id"))),
        ("Director forbidden input removed", lambda: data_mutation("scenario", lambda v: v["director"]["private_inputs_forbidden"].pop())),
        ("Director anti-repeat window changed", lambda: data_mutation("scenario", lambda v: v["director"].__setitem__("anti_repeat_window", 2))),
        ("exactly-once identity missing", lambda: data_mutation("scenario", lambda v: v["persistence"]["exactly_once_identities"].pop())),
        ("migration weakened", lambda: data_mutation("scenario", lambda v: v["persistence"].__setitem__("migration_policy", "best_effort_defaults"))),
        ("matrix reduced", lambda: data_mutation("scenario", lambda v: v["replayability"].__setitem__("minimum_total_runs", 125))),
        ("repeat equivalence removed", lambda: data_mutation("scenario", lambda v: v["replayability"].__setitem__("repeat_each_case", 1))),
        ("accepted actions unbounded", lambda: data_mutation("scenario", lambda v: v["replayability"].__setitem__("maximum_accepted_actions_per_run", 193))),
        ("diagnostic delayed", lambda: data_mutation("scenario", lambda v: v["replayability"].__setitem__("maximum_rejections_before_diagnostic", 9))),
        ("authoring runtime loading enabled", lambda: data_mutation("scenario", lambda v: v["traceability"].__setitem__("runtime_may_load_authoring_references", True))),
        ("prototype runtime loading enabled", lambda: data_mutation("scenario", lambda v: v["traceability"].__setitem__("runtime_may_load_prototype_fixtures", True))),
        ("normal registration enabled", lambda: data_mutation("scenario", lambda v: v["admission"].__setitem__("normal_catalog_registered", True))),
        ("ordinary export enabled", lambda: data_mutation("scenario", lambda v: v["admission"].__setitem__("ordinary_export_authorized", True))),
        ("conversion before High Water", lambda: source_mutation("drowned_harbor_alpha3_role_authority.gd", "if not after_high_water:", "if after_high_water:")),
        ("refusal persistence removed", lambda: source_mutation("drowned_harbor_alpha3_role_authority.gd", "row.refusal_used = true", "row.refusal_used = false")),
        ("continuation priority broken", lambda: source_mutation("drowned_harbor_alpha3_role_authority.gd", 'continuation_form = "lifeboat_survivor"', 'continuation_form = "bell_witness"')),
        ("permanent inactive seat", lambda: source_mutation("drowned_harbor_alpha3_role_authority.gd", "row.participation_active = true", "row.participation_active = false")),
        ("surrogate private access", lambda: source_mutation("drowned_harbor_alpha3_role_authority.gd", "if not row.connected or row.surrogate:", "if not row.connected:")),
        ("rejection state guard removed", lambda: source_mutation("drowned_harbor_alpha3_session.gd", "assert(to_snapshot() == before)", "assert(true)")),
        ("Director rejection guard removed", lambda: source_mutation("drowned_harbor_alpha3_director_authority.gd", "if not accepts_input(public_input):", "if accepts_input(public_input):")),
        ("migration fail-closed seam removed", lambda: source_mutation("drowned_harbor_alpha3_session.gd", "alpha2_snapshot_v2_rejected", "alpha2_snapshot_v2_defaulted")),
        ("eight-rejection diagnostic removed", lambda: source_mutation("drowned_harbor_alpha3_session.gd", "MAX_REJECTIONS_BEFORE_DIAGNOSTIC: int = 8", "MAX_REJECTIONS_BEFORE_DIAGNOSTIC: int = 9")),
        ("processed request persistence removed", lambda: source_mutation("drowned_harbor_alpha3_session.gd", '"processed_request_ids": _processed_request_ids.duplicate()', '"processed_request_ids": []')),
        ("runtime authoring dependency", lambda: source_mutation("drowned_harbor_alpha3_session.gd", "class_name DrownedHarborAlpha3Session", 'class_name DrownedHarborAlpha3Session\nconst SOURCE = "docs/preproduction/authoring_reference.json"')),
        ("runtime prototype dependency", lambda: source_mutation("drowned_harbor_alpha3_session.gd", "class_name DrownedHarborAlpha3Session", 'class_name DrownedHarborAlpha3Session\nconst FIXTURE = "drowned_harbor_dev_only"')),
        ("matrix loop narrowed", lambda: test_mutation("for seed: int in MATRIX_SEEDS:", "for seed: int in [3101]:")),
        ("126-run assertion removed", lambda: test_mutation("run_count == 126", "run_count == 42")),
        ("private leak assertion removed", lambda: test_mutation("shared output has no private terms", "shared output accepts private terms")),
        ("Alpha.2 exclusion removed", lambda: export_policy_mutation("presets", ",data/scenarios/drowned_harbor_graybox_v2.json", "")),
        ("Alpha.3 exclusion removed", lambda: export_policy_mutation("presets", ",data/scenarios/drowned_harbor_systems_v3.json", "")),
        ("portable Alpha.3 exclusion removed", lambda: export_policy_mutation("portable", 'data/scenarios/drowned_harbor_systems_v3.json"', 'data/scenarios/drowned_harbor_graybox_v2.json"')),
        ("production catalog registration", lambda: production_mutation("catalog_registration")),
        ("catalog identity altered", lambda: production_mutation("catalog_identity")),
        ("Lantern identity altered", lambda: production_mutation("lantern_identity")),
        ("central registry registration", lambda: production_mutation("registry_registration")),
        ("export path leak", lambda: export_mutation("res://data/scenarios/drowned_harbor_systems_v3.json")),
        ("export private marker leak", lambda: export_mutation("res://safe.txt", b"private_objective_assignment_id")),
        ("workflow Alpha.3 validator removed", lambda: workflow_mutation('run_check alpha3-validator python tools/validate_drowned_harbor_alpha3_systems.py "${alpha3_args[@]}"', 'run_check alpha3-validator python tools/validate_removed.py "${alpha3_args[@]}"')),
        ("workflow detached branch support removed", lambda: workflow_mutation('effective_branch="${GITHUB_HEAD_REF:-${GITHUB_REF_NAME:-}}"', 'effective_branch="${GITHUB_REF_NAME:-}"')),
        ("workflow action pin changed", lambda: workflow_mutation("actions/checkout@9c091bb21b7c1c1d1991bb908d89e4e9dddfe3e0", "actions/checkout@v4")),
        ("false human claim", lambda: documentation_claim("Human playtesting passed.")),
        ("false certification claim", lambda: documentation_claim("Privacy certified.")),
        ("false readiness claim", lambda: documentation_claim("Production ready.")),
    ]
    for name, mutation in mutations:
        expect_failure(name, mutation)
    print(f"Drowned Harbor Alpha.3 mutations: {len(mutations)} fail closed")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
