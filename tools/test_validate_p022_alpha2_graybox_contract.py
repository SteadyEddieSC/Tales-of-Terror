#!/usr/bin/env python3
"""Fail-closed mutations for the P0.22 alpha.2 graybox route contract."""

from __future__ import annotations
import json, shutil, tempfile
from pathlib import Path
from validate_p022_alpha2_graybox_contract import (
    CONTRACT_PATH, SCHEMA_PATH, TECHNICAL_PATH, ISSUE_PATH, RELEASE_PATH,
    STATUS_PATH, ROADMAP_PATH, PREPROD_README_PATH, P021_ISSUE_SET_PATH,
    ValidationError, validate,
)
ROOT = Path(".")

def copy_fixture(target: Path) -> None:
    for path in (CONTRACT_PATH, SCHEMA_PATH, TECHNICAL_PATH, ISSUE_PATH, RELEASE_PATH,
                 STATUS_PATH, ROADMAP_PATH, PREPROD_README_PATH, P021_ISSUE_SET_PATH):
        dst = target / path
        dst.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(ROOT / path, dst)

def edit_json(root: Path, path: Path, fn) -> None:
    full = root / path
    data = json.loads(full.read_text(encoding="utf-8"))
    fn(data)
    full.write_text(json.dumps(data, indent=2) + "\n", encoding="utf-8")

def replace(root: Path, path: Path, old: str, new: str) -> None:
    full = root / path
    text = full.read_text(encoding="utf-8")
    if old not in text:
        raise AssertionError(f"fixture text missing: {old}")
    full.write_text(text.replace(old, new, 1), encoding="utf-8")

def expect_failure(name: str, fn) -> None:
    with tempfile.TemporaryDirectory(prefix="p022-mutation-") as directory:
        target = Path(directory)
        copy_fixture(target)
        fn(target)
        try:
            validate(target, check_git=False)
        except ValidationError:
            print(f"PASS {name}")
            return
        raise AssertionError(f"mutation unexpectedly passed: {name}")

def main() -> int:
    mutations = [
        ("schema_root_opened", lambda r: edit_json(r, SCHEMA_PATH, lambda d: d.update(additionalProperties=True))),
        ("runtime_authorized", lambda r: edit_json(r, CONTRACT_PATH, lambda d: d["authorization"].update(runtime_implementation=True))),
        ("alpha2_issue_created", lambda r: edit_json(r, CONTRACT_PATH, lambda d: d["implementation_issue"].update(github_issue=103))),
        ("alpha2_activated", lambda r: edit_json(r, CONTRACT_PATH, lambda d: d["implementation_issue"].update(activation_authorized=True))),
        ("stage_reordered", lambda r: edit_json(r, CONTRACT_PATH, lambda d: d["stages"].reverse())),
        ("stage_omitted", lambda r: edit_json(r, CONTRACT_PATH, lambda d: d.update(stages=d["stages"][:-1]))),
        ("transition_removed", lambda r: edit_json(r, CONTRACT_PATH, lambda d: d.update(transitions=d["transitions"][:-1]))),
        ("unreachable_transition", lambda r: edit_json(r, CONTRACT_PATH, lambda d: d["transitions"][2].update(to_stage="last_light_v1"))),
        ("terminal_outgoing", lambda r: edit_json(r, CONTRACT_PATH, lambda d: d["transitions"].append(dict(d["transitions"][-1], transition_id="terminal_escape", from_stage="rematch_title_cleanup_v1")))),
        ("ambiguous_owner", lambda r: edit_json(r, CONTRACT_PATH, lambda d: d["stages"][0].update(authority_owner="presentation"))),
        ("rejection_mutates_rng", lambda r: edit_json(r, CONTRACT_PATH, lambda d: d["stages"][0].update(rejection_policy="state_noop_rng_advances"))),
        ("save_boundary_removed", lambda r: edit_json(r, CONTRACT_PATH, lambda d: d["stages"][1].update(save_boundaries=["stage_entry"]))),
        ("council_identity_removed", lambda r: edit_json(r, CONTRACT_PATH, lambda d: d["transitions"][2].update(exactly_once_identity=None))),
        ("high_water_identity_renamed", lambda r: edit_json(r, CONTRACT_PATH, lambda d: d["systems"].update(high_water_identity="other"))),
        ("best_effort_migration", lambda r: edit_json(r, CONTRACT_PATH, lambda d: d["persistence"].update(migration_policy="best_effort"))),
        ("private_director", lambda r: edit_json(r, CONTRACT_PATH, lambda d: d["privacy"].update(director_private_access=True))),
        ("privacy_removed", lambda r: edit_json(r, CONTRACT_PATH, lambda d: d["privacy"].update(classes=d["privacy"]["classes"][:-1]))),
        ("seat_count_missing", lambda r: edit_json(r, CONTRACT_PATH, lambda d: d["safe_routes"].update(supported_seat_counts=list(range(1,8))))),
        ("safe_route_unbounded", lambda r: edit_json(r, CONTRACT_PATH, lambda d: d["safe_routes"].update(maximum_accepted_actions=999))),
        ("prototype_runtime", lambda r: edit_json(r, CONTRACT_PATH, lambda d: d["traceability"].update(runtime_may_load_prototype_fixtures=True))),
        ("human_claim", lambda r: edit_json(r, CONTRACT_PATH, lambda d: d["evidence"].update(automation_is_human_evidence=True))),
        ("status_alpha2_active", lambda r: edit_json(r, STATUS_PATH, lambda d: d["recommended_next_release"].update(activation_authorized=True))),
        ("roadmap_runtime_active", lambda r: replace(r, ROADMAP_PATH, "alpha.2 runtime blocked", "alpha.2 runtime is active")),
        ("issue_stop_removed", lambda r: replace(r, ISSUE_PATH, "Codex must stop", "Codex may continue")),
        ("technical_human_claim", lambda r: replace(r, TECHNICAL_PATH, "Automation is not human evidence", "Automation proves human experience")),
        ("preprod_active", lambda r: replace(r, PREPROD_README_PATH, "Alpha.2 remains `planned_blocked`", "alpha.2 runtime is active")),
    ]
    for name, fn in mutations:
        expect_failure(name, fn)
    print(f"P0.22 mutation suite passed: {len(mutations)}")
    return 0

if __name__ == "__main__":
    raise SystemExit(main())
