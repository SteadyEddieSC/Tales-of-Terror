#!/usr/bin/env python3
from __future__ import annotations

import argparse
import copy
import json
from pathlib import Path
from typing import Callable

from validate_p023_alpha3_systems_replayability_contract import (
    ALPHA3_CANDIDATE,
    ALPHA3_MERGE,
    ValidationError,
    validate_contract,
    validate_schema,
    validate_status,
)

ROOT = Path(".")
Mutation = Callable[[], None]


def expect(name: str, mutation: Mutation) -> None:
    try:
        mutation()
    except (ValidationError, KeyError, TypeError, IndexError):
        return
    raise AssertionError(f"mutation did not fail closed: {name}")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--later-succession", action="store_true")
    args = parser.parse_args()

    contract = json.loads(
        (
            ROOT
            / "docs/preproduction/drowned_harbor_alpha3_systems_replayability_contract_v1.json"
        ).read_text(encoding="utf-8")
    )
    schema = json.loads(
        (
            ROOT
            / "docs/preproduction/drowned_harbor_alpha3_systems_replayability_contract_schema_v1.json"
        ).read_text(encoding="utf-8")
    )
    status = json.loads(
        (ROOT / "docs/preproduction/post_prototype_status_v1.json").read_text(
            encoding="utf-8"
        )
    )

    validate_contract(contract)
    validate_schema(schema, contract)
    validate_status(status, later_succession=args.later_succession)

    cases: list[tuple[str, Mutation]] = []

    def contract_case(name: str, change: Callable[[dict], None]) -> None:
        def run() -> None:
            candidate = copy.deepcopy(contract)
            change(candidate)
            validate_contract(candidate)

        cases.append((name, run))

    contract_case(
        "runtime authorized",
        lambda data: data["authorization"].__setitem__("runtime_implementation", True),
    )
    contract_case(
        "alpha3 issue created",
        lambda data: data["authorization"].__setitem__("alpha3_issue_created", True),
    )
    contract_case(
        "alpha2 package identity drift",
        lambda data: data["inherited_alpha2"].__setitem__("package_digest", "0" * 64),
    )
    contract_case(
        "target snapshot weakened",
        lambda data: data["target_versions"].__setitem__("snapshot_version", 2),
    )
    contract_case(
        "cooperative seat one removed",
        lambda data: data["mode_plans"][0].__setitem__("minimum_seats", 2),
    )
    contract_case(
        "hidden mode starts at two",
        lambda data: data["mode_plans"][1].__setitem__("minimum_seats", 2),
    )
    contract_case(
        "deferred mode activated",
        lambda data: data.__setitem__("deferred_modes", ["rival_crews"]),
    )
    contract_case(
        "role removed", lambda data: data["role_system"]["role_archetype_order"].pop()
    )
    contract_case(
        "role required for ending",
        lambda data: data["role_system"].__setitem__("role_required_for_ending", True),
    )
    contract_case(
        "hidden faction required",
        lambda data: data["faction_system"].__setitem__(
            "no_hidden_faction_required_for_valid_route", False
        ),
    )
    contract_case(
        "mid-session cure enabled",
        lambda data: data["transformation_system"].__setitem__(
            "mid_session_cure_supported", True
        ),
    )
    contract_case(
        "restless form removed",
        lambda data: data["continuation_system"]["restless_forms"].pop(),
    )
    contract_case("item removed", lambda data: data["content_system"]["items"].pop())
    contract_case("card removed", lambda data: data["content_system"]["cards"].pop())
    contract_case(
        "resource removed", lambda data: data["content_system"]["resources"].pop()
    )
    contract_case(
        "hazard removed", lambda data: data["content_system"]["hazards"].pop()
    )
    contract_case(
        "encounter removed",
        lambda data: data["content_system"]["encounters_by_stage"]["high_water"].pop(),
    )
    contract_case(
        "unbounded Director",
        lambda data: data["director_system"].__setitem__(
            "unbounded_generation_allowed", True
        ),
    )
    contract_case(
        "ending removed", lambda data: data["ending_system"]["ending_ids"].pop()
    )
    contract_case(
        "seat attribution removed",
        lambda data: data["ending_system"].__setitem__(
            "every_reachable_ending_attributes_every_stable_seat", False
        ),
    )
    contract_case(
        "migration weakened",
        lambda data: data["persistence"].__setitem__("migration_policy", "best_effort"),
    )
    contract_case(
        "exactly-once ID removed",
        lambda data: data["persistence"]["exactly_once_identities"].pop(),
    )
    contract_case(
        "privacy class removed", lambda data: data["privacy"]["classes"].pop()
    )
    contract_case(
        "Director private access",
        lambda data: data["privacy"].__setitem__("director_private_access", True),
    )
    contract_case(
        "surrogate private access",
        lambda data: data["privacy"].__setitem__("surrogate_private_access", True),
    )
    contract_case(
        "run matrix weakened",
        lambda data: data["replayability"].__setitem__("minimum_total_runs", 125),
    )
    contract_case(
        "deadlock requirement removed",
        lambda data: data["replayability"].__setitem__("deadlock_free_required", False),
    )
    contract_case(
        "authoring runtime load",
        lambda data: data["traceability"].__setitem__(
            "runtime_may_load_authoring_references", True
        ),
    )
    contract_case(
        "implementation activated",
        lambda data: data["implementation_issue"].__setitem__(
            "activation_authorized", True
        ),
    )
    contract_case(
        "human evidence claimed",
        lambda data: data["evidence"].__setitem__(
            "automation_is_human_evidence", True
        ),
    )

    def schema_open() -> None:
        candidate = copy.deepcopy(schema)
        candidate["additionalProperties"] = True
        validate_schema(candidate, contract)

    cases.append(("schema opened", schema_open))

    def status_case(name: str, change: Callable[[dict], None]) -> None:
        def run() -> None:
            candidate = copy.deepcopy(status)
            change(candidate)
            validate_status(candidate, later_succession=args.later_succession)

        cases.append((name, run))

    if args.later_succession:
        status_case(
            "Alpha.3 candidate drift",
            lambda data: data["alpha3"].__setitem__("candidate_head_sha", "0" * 40),
        )
        status_case(
            "Alpha.3 merge drift",
            lambda data: data["alpha3"].__setitem__("merged_main_sha", "0" * 40),
        )
        status_case(
            "Alpha.3 package version drift",
            lambda data: data["alpha3"].__setitem__("package_version", 2),
        )
        status_case(
            "Alpha.3 ordinary export enabled",
            lambda data: data["alpha3"].__setitem__("ordinary_export_included", True),
        )
        status_case(
            "current reconciliation issue drift",
            lambda data: data["current_release"].__setitem__("issue", 110),
        )
        status_case(
            "issue 110 activated",
            lambda data: data["recommended_next_release"].update(
                {"state": "active_planning", "activation_authorized": True}
            ),
        )
        status_case(
            "normal catalog registration enabled",
            lambda data: data["production"].__setitem__(
                "drowned_harbor_catalog_registered", True
            ),
        )
        status_case(
            "ordinary Drowned Harbor play enabled",
            lambda data: data["drowned_harbor"].__setitem__("ordinary_playable", True),
        )
        status_case(
            "runtime implementation authorized",
            lambda data: data.__setitem__("runtime_implementation_authorized", True),
        )
        status_case(
            "human evidence claimed",
            lambda data: data.__setitem__("human_evidence_claimed", True),
        )
        status_case(
            "Companion Undici drift",
            lambda data: data["companion_dependency_security"][
                "override_policy"
            ].__setitem__("undici", "7.28.0"),
        )
        status_case(
            "protected-main baseline drift",
            lambda data: data.__setitem__("protected_main", "0" * 40),
        )
        status_case(
            "preserved candidate drift",
            lambda data: data["preserved_authorities"].__setitem__(
                "alpha3_candidate_head", "0" * 40
            ),
        )
        require_constants = (ALPHA3_CANDIDATE, ALPHA3_MERGE)
        if any(len(value) != 40 for value in require_constants):
            raise AssertionError("test authority SHA malformed")
    else:
        status_case(
            "historical status activated",
            lambda data: data["recommended_next_release"].__setitem__(
                "github_issue", 107
            ),
        )

    for name, mutation in cases:
        expect(name, mutation)

    mode = "later succession" if args.later_succession else "historical"
    print(f"Validated {len(cases)} P0.23 fail-closed mutations ({mode})")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
