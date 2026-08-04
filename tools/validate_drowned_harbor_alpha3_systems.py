#!/usr/bin/env python3
"""Validate the governed Drowned Harbor Alpha.3 systems and replayability release."""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import re
import struct
import subprocess
import sys
from pathlib import Path
from typing import Any, Iterable

ROOT = Path(".")
BASELINE = "04533e174bab463689308492402fd0626890047d"
BRANCH = "feature/v0.2.0-alpha.3-systems-replayability"
PACKAGE_PATH = Path("game/data/tales/drowned_harbor/tale_package_v3.json")
SCENARIO_PATH = Path("game/data/scenarios/drowned_harbor_systems_v3.json")
LOCALIZATION_PATH = Path("game/data/tales/drowned_harbor/localization_systems_en_v3.json")
SOURCE_ROOT = Path("game/src/tales/drowned_harbor/alpha3")
TEST_PATH = Path(
    "game/tests/drowned_harbor_alpha3_systems/drowned_harbor_alpha3_systems_test.gd"
)
WORKFLOW_PATH = Path(".github/workflows/v020-alpha3-systems-replayability.yml")
RELEASE_PATH = Path("docs/releases/v0.2.0-alpha.3-systems-replayability.md")
EVIDENCE_PATH = Path(
    "docs/playtests/v0.2.0-alpha.3-systems-replayability-evidence.md"
)
EXPORT_PRESETS_PATH = Path("game/export_presets.cfg")
PORTABLE_PATH = Path("tools/portable_bundle.py")
CATALOG_PATH = Path("game/data/tales/tale_catalog_v1.json")
LANTERN_PATH = Path("game/data/tales/lantern_house/tale_package_v1.json")
REGISTRY_PATH = Path("game/src/session/tale_provider_registry.gd")
PROJECT_PATH = Path("game/project.godot")
PACKAGE_DIGEST = "5c0b8434c1d3a25558a7d8df334021bb05909008ae40fe0c9325338917b37123"
SCENARIO_DIGEST = "0bdb6800525631406f8a0aa43b2cff7115916928f81e5e35fba353b3a55710d2"
LOCALIZATION_DIGEST = "f094c2364fe75f78f6bb0991fbe027c6fad3023159261651763b3c323948fc73"
CATALOG_DIGEST = "2b478fd0d11fa075c2050409193aa06e6b9ca4dcf6efd4e4c550a9f3a5ff9db6"
LANTERN_DIGEST = "abb39d6bfbdf8d7de108379f08180c13efb99bbffa3e53f30eaaa8de7f459dee"

ROLES = [
    "bellhouse_archivist",
    "fog_listener",
    "lantern_surveyor",
    "lifeboat_keeper",
    "tide_chapel_warden",
    "wreckers_heir",
]
LIVING_OBJECTIVES = [
    "recover_the_truth",
    "preserve_escape_capacity",
    "protect_another_witness",
    "contain_the_harbor",
    "release_the_drowned",
    "carry_memory_safely",
]
BELLMARKED_OBJECTIVES = [
    "preserve_signal",
    "keep_names_in_ledger",
    "carry_harbor_memory_out",
    "preserve_bell",
    "open_old_channel",
]
TIDEBOUND_OBJECTIVES = [
    "preserve_harbor_memory",
    "seek_release",
    "propagate_memory",
    "complete_unfinished_obligation",
]
ITEMS = [
    "chapel_salt_censer",
    "cracked_lighthouse_lens",
    "dead_mans_compass",
    "glass_bell_clapper",
    "harbor_masters_seal",
    "ledger_knife",
    "lifeboat_flare",
    "missing_name_tablet",
    "oilskin_satchel",
    "salt_stiff_rope",
    "tin_lantern",
    "wreckers_hook",
]
CARDS = [
    "a_name_remembered",
    "borrowed_breath",
    "cut_the_line",
    "hold_fast",
    "mark_the_door",
    "one_more_passenger",
    "salt_in_the_wound",
    "share_the_weight",
    "the_harbor_owes_me",
    "the_light_looks_back",
    "the_long_way_around",
    "wrong_bell",
]
RESOURCES = [
    "bell_tokens",
    "dry_matches",
    "harbor_keys",
    "lamp_oil",
    "lifeboat_capacity",
    "memory_fragments",
    "rope",
    "salt_marks",
]
HAZARDS = [
    "archive_collapse",
    "bell_shock",
    "drowned_patrol",
    "harbors_claim",
    "lamps_turn_seaward",
    "lifeboat_breaks_free",
    "light_answers",
    "missing_name",
    "returning_current",
    "salt_rot",
    "street_gives_way",
    "water_in_lungs",
]
ENCOUNTERS = [
    "empty_lifeboat",
    "harbor_office_manifest",
    "market_of_shadows",
    "mudflat_mile",
    "bell_counts_wrong",
    "first_harbor_bargain",
    "missing_name_door",
    "names_beneath_names",
    "council_beneath_turning_light",
    "lens_shows_four_futures",
    "bell_rings_living_name",
    "drowned_archive_opens",
    "lifeboat_breaks_free_encounter",
    "one_more_passenger_encounter",
    "street_becomes_river",
    "tidebound_offer",
    "final_harbor_bargain",
    "last_seat_on_boat",
    "lighthouse_mechanism",
]
ENDINGS = [
    "drowned_released",
    "harbor_rises",
    "harbor_sealed",
    "last_lifeboat",
    "light_comes_home",
    "mixed_outcomes",
    "names_erased",
]
EXACTLY_ONCE_IDS = [
    "council_commitment_id",
    "high_water_transformation_id",
    "role_assignment_id",
    "private_objective_assignment_id",
    "faction_assignment_id",
    "tidebound_conversion_id",
    "continuation_transition_id",
    "director_selection_id",
    "ending_resolution_id",
]
PRIVACY_CLASSES = [
    "public",
    "controlled_reveal_private",
    "seat_private",
    "faction_private",
]
DIRECTOR_ALLOWLIST = [
    "authoritative_revision",
    "connected_seat_count",
    "stage_id",
    "tide_state",
    "living_count",
    "restless_count",
    "tidebound_count",
    "unresolved_rescue_count",
    "public_resource_pressure",
    "recent_public_candidate_ids",
    "ending_eligibility_count",
]
DIRECTOR_FORBIDDEN = [
    "role_id",
    "private_objective_id",
    "bellmarked_seat_ids",
    "unrevealed_faction_id",
    "private_item_marker",
    "desirability_score",
]
MODE_MATRIX = {
    "cooperative": list(range(1, 9)),
    "hidden_betrayer": list(range(3, 9)),
    "outbreak": list(range(2, 9)),
}
EXPECTED_SOURCES = {
    "drowned_harbor_alpha3_developer_admission.gd",
    "drowned_harbor_alpha3_director_authority.gd",
    "drowned_harbor_alpha3_role_authority.gd",
    "drowned_harbor_alpha3_rules_authority.gd",
    "drowned_harbor_alpha3_scoped_provider.gd",
    "drowned_harbor_alpha3_session.gd",
}
AUTHORIZED_PATHS = {
    ".github/workflows/v020-alpha1-production-tale-scaffold.yml",
    ".github/workflows/v020-alpha2-end-to-end-graybox.yml",
    ".github/workflows/v020-alpha3-systems-replayability.yml",
    "package-lock.json",
    "package.json",
    "tools/test_validate_drowned_harbor_controlled_private_shield.py",
    "tools/validate_drowned_harbor_controlled_private_shield.py",
    "CHANGELOG.md",
    "docs/playtests/v0.2.0-alpha.3-systems-replayability-evidence.md",
    "docs/releases/v0.2.0-alpha.3-systems-replayability.md",
    "game/data/scenarios/drowned_harbor_systems_v3.json",
    "game/data/tales/drowned_harbor/localization_systems_en_v3.json",
    "game/data/tales/drowned_harbor/tale_package_v3.json",
    "game/export_presets.cfg",
    *{
        f"game/src/tales/drowned_harbor/alpha3/{name}"
        for name in EXPECTED_SOURCES
    },
    *{
        f"game/src/tales/drowned_harbor/alpha3/{name}.uid"
        for name in EXPECTED_SOURCES
    },
    "game/tests/drowned_harbor_alpha3_systems/drowned_harbor_alpha3_systems_test.gd",
    "game/tests/drowned_harbor_alpha3_systems/drowned_harbor_alpha3_systems_test.gd.uid",
    "tools/portable_bundle.py",
    "tools/test_validate_drowned_harbor_alpha3_systems.py",
    "tools/test_validate_p022_alpha2_graybox_contract.py",
    "tools/test_validate_p021_production_architecture.py",
    "tools/test_validate_post_prototype_reconciliation.py",
    "tools/validate_drowned_harbor_alpha2_graybox.py",
    "tools/validate_drowned_harbor_alpha3_systems.py",
    "tools/validate_p022_alpha2_graybox_contract.py",
    "tools/validate_p021_production_architecture.py",
    "tools/validate_post_prototype_reconciliation.py",
}
EXACT_EXCLUDE_FILTER = (
    'exclude_filter=".gutconfig.json,tests/*,addons/*,'
    'src/exploration/ExplorationShowcase.tscn,'
    'src/exploration/exploration_showcase.gd,'
    'data/scenarios/drowned_harbor_scaffold_v1.json,'
    'data/tales/drowned_harbor/*,src/tales/drowned_harbor/*,'
    'data/scenarios/drowned_harbor_graybox_v2.json,'
    'data/scenarios/drowned_harbor_systems_v3.json"'
)
FORBIDDEN_EXPORT_PATH_PARTS = (
    "data/scenarios/drowned_harbor_scaffold_v1.json",
    "data/scenarios/drowned_harbor_graybox_v2.json",
    "data/scenarios/drowned_harbor_systems_v3.json",
    "data/tales/drowned_harbor/",
    "src/tales/drowned_harbor/",
    "tests/drowned_harbor_alpha3_systems/",
)
FORBIDDEN_EXPORT_MARKERS = tuple(
    value.encode()
    for value in (
        "drowned_harbor_scaffold_v1",
        "drowned_harbor_graybox_v2",
        "drowned_harbor_systems_v3",
        "drowned_harbor_alpha3",
        "bellhouse_archivist",
        "recover_the_truth",
        "preserve_signal",
        "preserve_harbor_memory",
        "faction_private",
        "private_objective_assignment_id",
        "tidebound_conversion_id",
        "continuation_transition_id",
        "ending_resolution_id",
    )
)


class Alpha3ValidationError(RuntimeError):
    """A governed Alpha.3 assertion failed."""


def require(condition: bool, message: str) -> None:
    if not condition:
        raise Alpha3ValidationError(message)


def read_json(path: Path) -> dict[str, Any]:
    try:
        value = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        raise Alpha3ValidationError(f"invalid or missing JSON: {path}: {exc}") from exc
    require(isinstance(value, dict), f"JSON root must be an object: {path}")
    return value


def canonical_digest(value: Any) -> str:
    payload = json.dumps(value, ensure_ascii=False, sort_keys=True, separators=(",", ":"))
    return hashlib.sha256(payload.encode()).hexdigest()


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for block in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def strings(value: Any) -> Iterable[str]:
    if isinstance(value, dict):
        for key, nested in value.items():
            yield str(key)
            yield from strings(nested)
    elif isinstance(value, list):
        for nested in value:
            yield from strings(nested)
    elif isinstance(value, str):
        yield value


def validate_data(
    package: dict[str, Any], scenario: dict[str, Any], localization: dict[str, Any]
) -> None:
    require(canonical_digest(package) == PACKAGE_DIGEST, "package v3 canonical identity drifted")
    require(sha256_file(SCENARIO_PATH) == SCENARIO_DIGEST, "scenario v3 identity drifted")
    require(sha256_file(LOCALIZATION_PATH) == LOCALIZATION_DIGEST, "localization v3 identity drifted")
    require(package.get("package_version") == 3, "package target must be version 3")
    require(scenario.get("scenario_version") == 3, "scenario target must be version 3")
    require(localization.get("catalog_version") == 3, "localization target must be version 3")
    require(
        package.get("provider")
        == {
            "provider_id": "drowned_harbor_authorities_v1",
            "provider_version": 3,
            "board_reference": "drowned_harbor_graybox_board_v2",
            "rules_reference": "drowned_harbor_systems_rules_v3",
            "director_reference": "drowned_harbor_systems_director_v3",
            "social_reference": "drowned_harbor_systems_role_session_v3",
        },
        "provider v3 identity drifted",
    )
    require(package.get("content", {}).get("scenario_sha256") == SCENARIO_DIGEST, "scenario traceability drifted")
    require(package.get("localization", {}).get("catalog_sha256") == LOCALIZATION_DIGEST, "localization traceability drifted")
    require(scenario.get("roles", {}).get("archetype_order") == ROLES, "role order drifted")
    objectives = scenario.get("objectives", {})
    require(objectives.get("living") == LIVING_OBJECTIVES, "Living objective inventory drifted")
    require(objectives.get("bellmarked") == BELLMARKED_OBJECTIVES, "Bellmarked objective inventory drifted")
    require(objectives.get("tidebound") == TIDEBOUND_OBJECTIVES, "Tidebound objective inventory drifted")
    plans = scenario.get("mode_plans", [])
    require([row.get("mode_id") for row in plans] == list(MODE_MATRIX), "mode plan order drifted")
    require(plans[0].get("minimum_seats") == 1 and plans[0].get("maximum_seats") == 8, "Cooperative seat range drifted")
    require(plans[1].get("minimum_seats") == 3 and plans[1].get("fallback_mode") == "cooperative", "Hidden Betrayer fallback drifted")
    require(plans[2].get("minimum_seats") == 2 and plans[2].get("fallback_mode") == "cooperative", "Outbreak fallback drifted")
    require(all(row.get("starting_tidebound_count") == 0 for row in plans), "a mode starts Tidebound")
    require(plans[1].get("starting_hidden_faction_count") == 1, "Hidden Betrayer must start exactly one Bellmarked")
    content = scenario.get("content", {})
    require(content.get("items") == ITEMS, "item inventory drifted")
    require(content.get("cards") == CARDS, "card inventory drifted")
    require(content.get("resources") == RESOURCES, "resource inventory drifted")
    require(content.get("hazards") == HAZARDS, "hazard inventory drifted")
    encounters = [
        encounter
        for values in content.get("encounters_by_stage", {}).values()
        for encounter in values
    ]
    require(encounters == ENCOUNTERS, "encounter inventory drifted")
    require(content.get("ownership_classes") == [
        "seat_owned", "shared_group", "board_owned", "public_quest_carried", "faction_private"
    ], "content ownership inventory drifted")
    require(scenario.get("endings") == ENDINGS, "ending inventory drifted")
    persistence = scenario.get("persistence", {})
    require(persistence.get("snapshot_version") == 3, "snapshot target must be version 3")
    require(persistence.get("exactly_once_identities") == EXACTLY_ONCE_IDS, "exactly-once identity inventory drifted")
    require(
        persistence.get("migration_policy")
        == "explicit_alpha2_snapshot_v2_to_alpha3_snapshot_v3_or_fail_closed",
        "migration policy weakened",
    )
    require(scenario.get("privacy", {}).get("classes") == PRIVACY_CLASSES, "privacy classes drifted")
    director = scenario.get("director", {})
    require(director.get("input_allowlist") == DIRECTOR_ALLOWLIST, "Director allowlist drifted")
    require(director.get("private_inputs_forbidden") == DIRECTOR_FORBIDDEN, "Director forbidden inputs drifted")
    require(director.get("anti_repeat_window") == 3, "Director anti-repeat window drifted")
    replayability = scenario.get("replayability", {})
    require(replayability.get("mode_seat_matrix") == MODE_MATRIX, "mode/seat matrix drifted")
    require(replayability.get("seeds") == [3101, 3102, 3103], "seed set drifted")
    require(replayability.get("repeat_each_case") == 2, "repeat count drifted")
    require(replayability.get("minimum_total_runs") == 126, "matrix reduced below 126")
    require(replayability.get("maximum_accepted_actions_per_run") == 192, "accepted-action bound drifted")
    require(replayability.get("maximum_rejections_before_diagnostic") == 8, "diagnostic bound drifted")
    admission = scenario.get("admission", {})
    require(admission.get("policy") == "developer_only_explicit_launch", "developer admission drifted")
    require(admission.get("normal_catalog_registered") is False, "normal catalog registration enabled")
    require(admission.get("normal_provider_registered") is False, "normal provider registration enabled")
    require(admission.get("ordinary_export_authorized") is False, "ordinary export authorized")
    require(scenario.get("traceability", {}).get("runtime_may_load_authoring_references") is False, "authoring runtime load enabled")
    require(scenario.get("traceability", {}).get("runtime_may_load_prototype_fixtures") is False, "prototype runtime load enabled")
    executable = {"script", "class", "callback", "expression", "url", "credential"}
    require(not executable.intersection(strings(scenario)), "scenario contains executable fields")


def active_gdscript(source: str) -> str:
    return "\n".join(
        line for line in source.splitlines() if not line.lstrip().startswith("#")
    )


def function_body(source: str, name: str) -> str:
    lines = active_gdscript(source).splitlines()
    start = next(
        (index for index, line in enumerate(lines) if line.startswith(f"func {name}(")),
        None,
    )
    require(start is not None, f"GDScript function missing: {name}")
    end = len(lines)
    for index in range(start + 1, len(lines)):
        if lines[index].startswith(("func ", "static func ")):
            end = index
            break
    return "\n".join(lines[start:end])


def validate_sources(source_texts: dict[str, str], test: str) -> None:
    require(set(source_texts) == EXPECTED_SOURCES, "Alpha.3 native source inventory drifted")
    active = {name: active_gdscript(value) for name, value in source_texts.items()}
    combined = "\n".join(active[name] for name in sorted(active))
    obligations = {
        "drowned_harbor_alpha3_developer_admission.gd": (
            "class_name DrownedHarborAlpha3DeveloperAdmission",
            'DEVELOPER_ADMISSION_REQUEST_KIND: String = "developer_only_explicit_launch"',
            "migrate_alpha2_snapshot",
        ),
        "drowned_harbor_alpha3_role_authority.gd": (
            "class_name DrownedHarborAlpha3RoleAuthority",
            "ROLE_ORDER",
            "LIVING_OBJECTIVES",
            "BELLMARKED_OBJECTIVES",
            "TIDEBOUND_OBJECTIVES",
            'if _effective_mode == "hidden_betrayer":',
            'row.private_faction_id = "bellmarked"',
            'row.public_form = "tidebound"',
            "row.refusal_used = true",
            'var continuation_form: String = "bell_witness"',
            'continuation_form = "lifeboat_survivor"',
            'continuation_form = "lighthouse_guardian"',
            'continuation_form = "drowned_guide"',
            "row.participation_active = true",
            "seat_private_view",
            "faction_private_view",
        ),
        "drowned_harbor_alpha3_rules_authority.gd": (
            "class_name DrownedHarborAlpha3RulesAuthority",
            "ITEMS",
            "CARDS",
            "RESOURCES",
            "HAZARDS",
            "ENCOUNTERS_BY_STAGE",
            "ENDINGS",
            "transfer_item",
            "attempt_rescue",
            "ending_resolution_id",
        ),
        "drowned_harbor_alpha3_director_authority.gd": (
            "class_name DrownedHarborAlpha3DirectorAuthority",
            'RNG_STREAM: String = "drowned_harbor_director_authority"',
            "ANTI_REPEAT_WINDOW: int = 3",
            "INPUT_ALLOWLIST",
            "FORBIDDEN_INPUTS",
            "if not accepts_input(public_input):",
        ),
        "drowned_harbor_alpha3_session.gd": (
            "class_name DrownedHarborAlpha3Session",
            "SNAPSHOT_VERSION: int = 3",
            "MAX_REJECTIONS_BEFORE_DIAGNOSTIC: int = 8",
            "DrownedHarborAlpha2Session.new",
            '"processed_request_ids": _processed_request_ids.duplicate()',
            '"processed_event_ids": _processed_event_ids.duplicate()',
            "func exactly_once_identities() -> Dictionary:",
            "migrate_alpha2_candidate",
            "alpha2_snapshot_v2_rejected",
            "bounded_progress_watchdog",
            "assert(to_snapshot() == before)",
        ),
        "drowned_harbor_alpha3_scoped_provider.gd": (
            "class_name DrownedHarborAlpha3ScopedProvider",
            "PROVIDER_VERSION: int = 3",
            PACKAGE_DIGEST[:33],
            PACKAGE_DIGEST[33:],
            SCENARIO_DIGEST[:32],
            SCENARIO_DIGEST[32:],
            LOCALIZATION_DIGEST[:32],
            LOCALIZATION_DIGEST[32:],
        ),
    }
    for filename, phrases in obligations.items():
        for phrase in phrases:
            require(phrase in active[filename], f"{filename} missing governed seam: {phrase}")
    role = active["drowned_harbor_alpha3_role_authority.gd"]
    require(role.count('row.private_faction_id = "bellmarked"') == 1, "Bellmarked assignment path must be singular")
    require(role.index('continuation_form = "lifeboat_survivor"') < role.index('continuation_form = "lighthouse_guardian"') < role.index('continuation_form = "drowned_guide"'), "continuation priority drifted")
    offer_body = function_body(role, "offer_tidebound")
    require("if not after_high_water:" in offer_body, "conversion offer may occur before High Water")
    require("row.refusal_used" in role and "refusal_persisted" in role, "refusal persistence missing")
    require(
        "if not row.connected or row.surrogate:"
        in function_body(role, "seat_private_view"),
        "surrogate may receive a seat-private projection",
    )
    require(
        "if not row.connected or row.surrogate or row.private_faction_id.is_empty():"
        in function_body(role, "faction_private_view"),
        "surrogate may receive a faction-private projection",
    )
    director = active["drowned_harbor_alpha3_director_authority.gd"]
    for forbidden in DIRECTOR_FORBIDDEN:
        require(f'"{forbidden}"' in director, f"Director forbidden input missing: {forbidden}")
    session = active["drowned_harbor_alpha3_session.gd"]
    require(
        "assert(to_snapshot() == before)" in function_body(session, "process_request"),
        "request rejection no-op guard missing",
    )
    for identity in EXACTLY_ONCE_IDS:
        require(f'"{identity}"' in session, f"session identity missing: {identity}")
    for prohibited in (
        "drowned_harbor_dev_only",
        "docs/tales/",
        "docs/preproduction/",
        "authoring_reference",
        "prototype_fixture",
        "Time.get_",
        "DateTime",
        "HTTPRequest",
        "WebSocket",
    ):
        require(prohibited not in combined, f"runtime contains prohibited dependency: {prohibited}")
    active_test = active_gdscript(test)
    for phrase in (
        "_test_repeated_session_matrix",
        "run_count == 126",
        "accepted_actions <= 192",
        "for seed: int in MATRIX_SEEDS:",
        "repeat_each_case",
        "all six role archetypes are assigned",
        "all Living objective families are assigned",
        "all Bellmarked objective families are assigned",
        "all Tidebound objective families are assigned",
        "all continuation forms are reached through authority",
        "all nineteen encounters are observed",
        "all seven endings are reached",
        "shared output has no private terms",
        "surrogate receives no private projection",
        "same stable seat receives same private view",
        "failed migration preserves active session",
        "eighth rejection emits actionable bounded diagnostic",
        "DROWNED_HARBOR_ALPHA3_SYSTEMS_EVIDENCE:",
    ):
        require(phrase in active_test, f"focused Godot proof missing: {phrase}")


def validate_uids(root: Path = ROOT) -> None:
    targets = [root / SOURCE_ROOT / f"{name}.uid" for name in EXPECTED_SOURCES]
    targets.append(root / TEST_PATH.with_suffix(".gd.uid"))
    seen: dict[str, Path] = {}
    for path in (root / "game").rglob("*.gd.uid"):
        value = path.read_text(encoding="utf-8").strip()
        require(re.fullmatch(r"uid://[a-z0-9]{11,13}", value) is not None, f"invalid UID: {path}")
        require(value not in seen, f"duplicate UID: {path} and {seen.get(value)}")
        seen[value] = path
    for path in targets:
        require(path.is_file(), f"Alpha.3 UID missing: {path}")


def validate_production_boundaries(
    catalog: dict[str, Any], lantern: dict[str, Any], registry: str, project: str
) -> None:
    require(canonical_digest(catalog) == CATALOG_DIGEST, "production catalog identity changed")
    require(canonical_digest(lantern) == LANTERN_DIGEST, "Lantern House identity changed")
    require(catalog.get("default_tale_id") == "lantern_house_vertical_slice", "normal default changed")
    require(len(catalog.get("entries", [])) == 1, "normal catalog inventory changed")
    require("drowned_harbor" not in json.dumps(catalog).lower(), "Drowned Harbor entered normal catalog")
    require("drowned_harbor" not in registry.lower(), "Drowned Harbor entered central registry")
    require('run/main_scene="res://src/main/Main.tscn"' in project, "normal startup changed")


def validate_export_policy(presets: str, portable: str) -> None:
    require(presets.count(EXACT_EXCLUDE_FILTER) == 2, "both ordinary exports must use exact Alpha.3 exclusion")
    require("drowned_harbor_graybox_v2.json" in portable, "portable policy lost Alpha.2 scenario")
    require("drowned_harbor_systems_v3.json" in portable, "portable policy lacks Alpha.3 scenario")
    require("exact_exclude_filter" in portable, "portable exact-filter enforcement missing")


def validate_workflow(workflow: str) -> None:
    for phrase in (
        "name: v0.2.0-alpha.3 Drowned Harbor systems and replayability",
        BRANCH,
        "GITHUB_HEAD_REF",
        "GITHUB_REF_NAME",
        "Enforce exact Alpha.3 protected-base path boundary",
        "validate_drowned_harbor_alpha3_systems.py",
        "test_validate_drowned_harbor_alpha3_systems.py",
        'run_check alpha3-validator python tools/validate_drowned_harbor_alpha3_systems.py "${alpha3_args[@]}"',
        'effective_branch="${GITHUB_HEAD_REF:-${GITHUB_REF_NAME:-}}"',
        "validate_drowned_harbor_alpha2_graybox.py --skip-git-boundary",
        "test_validate_drowned_harbor_alpha2_graybox.py",
        "validate_p022_alpha2_graybox_contract.py --skip-git-boundary --later-succession",
        "test_validate_p022_alpha2_graybox_contract.py",
        "validate_p021_production_architecture.py --skip-git-boundary --later-succession",
        "test_validate_p021_production_architecture.py",
        "validate_post_prototype_reconciliation.py --skip-git-boundary --later-succession",
        "test_validate_post_prototype_reconciliation.py",
        "drowned_harbor_alpha3_systems_test.gd",
        "automated_playthrough_lab_test.gd",
        "Godot_v4.7.1-stable",
        "gdformat --check",
        "gdlint",
        "export-inventory --platform windows",
        "export-inventory --platform linux",
        "p020-alpha3-drowned-harbor-systems-evidence",
        "Prove source tree remains clean",
    ):
        require(phrase in workflow, f"Alpha.3 workflow missing: {phrase}")
    require("actions/checkout@9c091bb21b7c1c1d1991bb908d89e4e9dddfe3e0" in workflow, "checkout pin changed")
    require("actions/setup-python@ece7cb06caefa5fff74198d8649806c4678c61a1" in workflow, "Python pin changed")
    require("actions/upload-artifact@043fb46d1a93c77aae656e7c1c64a875d1fc6a0a" in workflow, "artifact pin changed")
    for path in AUTHORIZED_PATHS:
        require(path in workflow, f"workflow boundary missing path: {path}")


def validate_documentation(release: str, evidence: str, changelog: str) -> None:
    combined = "\n".join((release, evidence, changelog)).lower()
    for phrase in (
        "v0.2.0-alpha.3",
        "issue #108",
        "5161266617",
        "developer-only",
        "snapshot v3",
        "126",
        "council_commitment_id",
        "ending_resolution_id",
        "windows",
        "linux",
        "automation is machine evidence",
        "issue #39",
    ):
        require(phrase in combined, f"Alpha.3 documentation missing: {phrase}")
    for claim in (
        "human playtesting passed",
        "privacy certified",
        "security certified",
        "accessibility certified",
        "physical-controller validated",
        "television readability validated",
        "production ready",
        "beta ready",
        "rc ready",
        "public release authorized",
        "fun validated",
        "balance validated",
    ):
        require(claim not in combined, f"unsupported evidence claim found: {claim}")


def _run_git(root: Path, *args: str) -> str:
    return subprocess.check_output(["git", *args], cwd=root, text=True).strip()


def validate_git_boundary(root: Path = ROOT) -> None:
    require(_run_git(root, "rev-parse", "origin/main") == BASELINE, "protected origin/main changed")
    branch = (
        os.environ.get("GITHUB_HEAD_REF")
        or os.environ.get("GITHUB_REF_NAME")
        or _run_git(root, "branch", "--show-current")
    )
    require(branch == BRANCH, f"wrong Alpha.3 branch: {branch}")
    require(_run_git(root, "merge-base", "HEAD", BASELINE) == BASELINE, "Alpha.3 baseline changed")
    changed = set(filter(None, _run_git(root, "diff", "--name-only", BASELINE).splitlines()))
    changed.update(filter(None, _run_git(root, "ls-files", "--others", "--exclude-standard").splitlines()))
    require(changed == AUTHORIZED_PATHS, f"Alpha.3 path boundary mismatch; missing={sorted(AUTHORIZED_PATHS-changed)} unexpected={sorted(changed-AUTHORIZED_PATHS)}")


def pck_inventory(path: Path) -> list[str]:
    data = path.read_bytes()
    require(len(data) >= 112 and data[:4] == b"GDPC", "not a Godot PCK v4 archive")
    pack_format, engine_major = struct.unpack_from("<II", data, 4)
    require(pack_format == 4 and engine_major == 4, "unsupported PCK format")
    directory_offset = struct.unpack_from("<Q", data, 32)[0]
    require(112 <= directory_offset <= len(data) - 4, "invalid PCK directory offset")
    cursor = directory_offset
    file_count = struct.unpack_from("<I", data, cursor)[0]
    cursor += 4
    require(0 < file_count < 100_000, "invalid PCK file count")
    paths: list[str] = []
    for _ in range(file_count):
        require(cursor + 4 <= len(data), "truncated PCK directory")
        path_length = struct.unpack_from("<I", data, cursor)[0]
        cursor += 4
        require(1 <= path_length <= 16_384 and cursor + path_length <= len(data), "invalid PCK path")
        encoded = data[cursor : cursor + path_length]
        cursor += (path_length + 3) & ~3
        resource_path = encoded.rstrip(b"\x00").decode("utf-8")
        require(resource_path and ".." not in Path(resource_path).parts, "unsafe PCK path")
        require(cursor + 36 <= len(data), "truncated PCK record")
        cursor += 36
        paths.append(resource_path.replace("\\", "/"))
    require(len(paths) == len(set(paths)), "PCK inventory contains duplicate paths")
    return paths


def validate_export_inventory(
    platform: str, pck: Path, export_log: Path, source_sha: str
) -> dict[str, Any]:
    require(platform in {"windows", "linux"}, "unsupported export platform")
    require(re.fullmatch(r"[0-9a-f]{40}", source_sha) is not None, "invalid source SHA")
    require(pck.is_file() and export_log.is_file(), "missing actual export evidence")
    inventory = pck_inventory(pck)
    lowered = [item.lower() for item in inventory]
    path_hits = [item for item in lowered if any(part in item for part in FORBIDDEN_EXPORT_PATH_PARTS)]
    raw = pck.read_bytes() + export_log.read_bytes()
    marker_hits = [marker.decode() for marker in FORBIDDEN_EXPORT_MARKERS if marker in raw]
    require(not path_hits, f"Drowned Harbor path leaked into {platform} export: {path_hits}")
    require(not marker_hits, f"Drowned Harbor marker leaked into {platform} export: {marker_hits}")
    return {
        "accepted": True,
        "classification": "automated_internal_machine_evidence",
        "human_evidence_claimed": False,
        "platform": platform,
        "source_sha": source_sha,
        "pck_file_count": len(inventory),
        "pck_size": pck.stat().st_size,
        "pck_sha256": sha256_file(pck),
        "export_log_sha256": sha256_file(export_log),
        "inventory_digest": hashlib.sha256("\n".join(sorted(inventory)).encode()).hexdigest(),
        "forbidden_path_hit_count": 0,
        "forbidden_marker_hit_count": 0,
    }


def validate_static(root: Path = ROOT, *, git_boundary: bool = True) -> dict[str, Any]:
    validate_data(read_json(root / PACKAGE_PATH), read_json(root / SCENARIO_PATH), read_json(root / LOCALIZATION_PATH))
    sources = {
        path.name: path.read_text(encoding="utf-8")
        for path in sorted((root / SOURCE_ROOT).glob("*.gd"))
    }
    validate_sources(sources, (root / TEST_PATH).read_text(encoding="utf-8"))
    validate_uids(root)
    validate_production_boundaries(
        read_json(root / CATALOG_PATH),
        read_json(root / LANTERN_PATH),
        (root / REGISTRY_PATH).read_text(encoding="utf-8"),
        (root / PROJECT_PATH).read_text(encoding="utf-8"),
    )
    validate_export_policy(
        (root / EXPORT_PRESETS_PATH).read_text(encoding="utf-8"),
        (root / PORTABLE_PATH).read_text(encoding="utf-8"),
    )
    validate_workflow((root / WORKFLOW_PATH).read_text(encoding="utf-8"))
    validate_documentation(
        (root / RELEASE_PATH).read_text(encoding="utf-8"),
        (root / EVIDENCE_PATH).read_text(encoding="utf-8"),
        (root / "CHANGELOG.md").read_text(encoding="utf-8"),
    )
    if git_boundary:
        validate_git_boundary(root)
    return {
        "accepted": True,
        "package_digest": PACKAGE_DIGEST,
        "scenario_digest": SCENARIO_DIGEST,
        "localization_digest": LOCALIZATION_DIGEST,
        "provider_version": 3,
        "snapshot_version": 3,
        "role_count": len(ROLES),
        "item_count": len(ITEMS),
        "card_count": len(CARDS),
        "resource_count": len(RESOURCES),
        "hazard_count": len(HAZARDS),
        "encounter_count": len(ENCOUNTERS),
        "ending_count": len(ENDINGS),
        "matrix_run_count": 126,
        "human_evidence_claimed": False,
    }


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser()
    parser.add_argument("--skip-git-boundary", action="store_true")
    subparsers = parser.add_subparsers(dest="command")
    export = subparsers.add_parser("export-inventory")
    export.add_argument("--platform", required=True, choices=("windows", "linux"))
    export.add_argument("--pck", required=True, type=Path)
    export.add_argument("--export-log", required=True, type=Path)
    export.add_argument("--source-sha", required=True)
    export.add_argument("--output", type=Path)
    return parser


def main(argv: list[str] | None = None) -> int:
    args = build_parser().parse_args(argv)
    try:
        if args.command == "export-inventory":
            result = validate_export_inventory(args.platform, args.pck, args.export_log, args.source_sha)
        else:
            result = validate_static(git_boundary=not args.skip_git_boundary)
    except (Alpha3ValidationError, OSError, UnicodeDecodeError, subprocess.CalledProcessError) as exc:
        print(f"Drowned Harbor Alpha.3 validation failed: {exc}", file=sys.stderr)
        return 1
    payload = json.dumps(result, sort_keys=True, separators=(",", ":"))
    if args.command == "export-inventory" and args.output is not None:
        args.output.parent.mkdir(parents=True, exist_ok=True)
        args.output.write_text(payload + "\n", encoding="utf-8")
    print(payload)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())