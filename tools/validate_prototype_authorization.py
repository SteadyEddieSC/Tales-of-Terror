#!/usr/bin/env python3
"""Validate the P0.12 Drowned Harbor prototype authorization decision.

Standard-library only. The validator intentionally fails closed when the decision
would authorize runtime execution, alter the closed production Tale inventory,
lose issue/trace coverage, or weaken external gates.
"""

from __future__ import annotations

import hashlib
import json
import re
import sys
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[1]
DECISION_PATH = ROOT / "docs/tales/drowned_harbor/implementation/drowned_harbor_prototype_authorization_v1.json"
SCHEMA_PATH = ROOT / "docs/preproduction/prototype_authorization_schema_v1.json"
CATALOG_PATH = ROOT / "game/data/tales/tale_catalog_v1.json"
TRACE_DIR = ROOT / "docs/tales/drowned_harbor/interaction"
EXPECTED_BASELINE = "0cb4aaaf3b82097a4dcaf38d2ff41d3047e9cd4f"
EXPECTED_CATALOG_SHA256 = "2b478fd0d11fa075c2050409193aa06e6b9ca4dcf6efd4e4c550a9f3a5ff9db6"
EXPECTED_PACKAGE_IDS = [f"DH-PROT-{index:03d}" for index in range(1, 8)]
EXPECTED_ISSUES = list(range(80, 87))
EXPECTED_EXTERNAL_ISSUES = {7, 39, 44}
EXPECTED_UNLOCK_GATES = {
    "p0_11_merged": True,
    "p0_12_merged": False,
    "explicit_user_reopen": False,
    "clean_implementation_branch": False,
    "child_issue_unblocked": False,
    "production_boundaries_reverified": False,
    "exact_checks_defined": False,
    "external_gates_preserved": True,
}
EXPECTED_TOP_LEVEL_KEYS = {
    "decision_id",
    "release_id",
    "tale_id",
    "production_status",
    "authorization_decision",
    "execution_status",
    "parent_issue",
    "baseline_main_sha",
    "production_catalog_path",
    "production_tale",
    "runtime_changes_in_release",
    "production_catalog_change_authorized",
    "provider_change_authorized",
    "playable_export_authorized",
    "human_evidence_claimed",
    "unlock_gates",
    "work_packages",
    "external_gates",
    "promotion_requirements",
    "source_paths",
    "approval_boundary",
}


class PrototypeAuthorizationValidationError(ValueError):
    """Raised when P0.12 authorization data violates the closed contract."""


def read_json(path: Path) -> Any:
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except FileNotFoundError as exc:
        raise PrototypeAuthorizationValidationError(f"missing required file: {path.relative_to(ROOT)}") from exc
    except json.JSONDecodeError as exc:
        raise PrototypeAuthorizationValidationError(
            f"invalid JSON in {path.relative_to(ROOT)}: line {exc.lineno}, column {exc.colno}: {exc.msg}"
        ) from exc


def canonical_sha256(value: Any) -> str:
    encoded = json.dumps(value, ensure_ascii=False, sort_keys=True, separators=(",", ":")).encode("utf-8")
    return hashlib.sha256(encoded).hexdigest()


def require(condition: bool, message: str) -> None:
    if not condition:
        raise PrototypeAuthorizationValidationError(message)


def validate_repo_path(raw_path: str, context: str) -> None:
    require(isinstance(raw_path, str) and bool(raw_path), f"{context}: source path must be a non-empty string")
    require(not raw_path.startswith("/") and ".." not in Path(raw_path).parts, f"{context}: unsafe source path {raw_path!r}")
    path = ROOT / raw_path
    require(path.is_file(), f"{context}: source path does not exist: {raw_path}")


def load_trace_ids() -> set[str]:
    trace_ids: set[str] = set()
    manifests = sorted(TRACE_DIR.glob("drowned_harbor_interaction_*_traces_v1.json"))
    require(len(manifests) == 3, f"expected 3 P0.11 interaction manifests, found {len(manifests)}")
    for path in manifests:
        manifest = read_json(path)
        require(manifest.get("production_status") == "design_only", f"{path.name}: production status must remain design_only")
        for entry in manifest.get("entries", []):
            trace_id = entry.get("trace_id")
            require(isinstance(trace_id, str), f"{path.name}: trace entry missing trace_id")
            require(trace_id not in trace_ids, f"duplicate P0.11 trace ID: {trace_id}")
            trace_ids.add(trace_id)
    require(len(trace_ids) == 22, f"expected 22 P0.11 interaction traces, found {len(trace_ids)}")
    return trace_ids


def validate_catalog() -> None:
    catalog = read_json(CATALOG_PATH)
    require(canonical_sha256(catalog) == EXPECTED_CATALOG_SHA256, "production Tale catalog canonical SHA-256 changed")
    require(catalog.get("catalog_kind") == "tale_catalog", "production catalog kind changed")
    require(catalog.get("schema_version") == 1 and catalog.get("catalog_version") == 1, "production catalog version changed")
    require(catalog.get("default_tale_id") == "lantern_house_vertical_slice", "production default Tale changed")
    entries = catalog.get("entries")
    require(isinstance(entries, list) and len(entries) == 1, "production catalog must contain exactly one Tale")
    require(entries[0].get("tale_id") == "lantern_house_vertical_slice", "Lantern House must remain the sole production Tale")
    require("drowned_harbor" not in json.dumps(catalog).lower(), "Drowned Harbor may not enter the production Tale catalog")


def validate_unlock_gates(gates: Any) -> None:
    require(isinstance(gates, list) and len(gates) == len(EXPECTED_UNLOCK_GATES), "unlock gate set must contain exactly 8 records")
    observed: dict[str, bool] = {}
    for index, gate in enumerate(gates):
        require(isinstance(gate, dict), f"unlock_gates[{index}] must be an object")
        require(set(gate) == {"gate_id", "description", "satisfied_in_p0_12"}, f"unlock_gates[{index}] has unknown or missing fields")
        gate_id = gate["gate_id"]
        require(re.fullmatch(r"[a-z][a-z0-9_]*", gate_id or "") is not None, f"unlock_gates[{index}] has invalid gate_id")
        require(gate_id not in observed, f"duplicate unlock gate: {gate_id}")
        require(isinstance(gate["description"], str) and len(gate["description"]) >= 20, f"unlock gate {gate_id} description is too short")
        require(isinstance(gate["satisfied_in_p0_12"], bool), f"unlock gate {gate_id} satisfaction must be boolean")
        observed[gate_id] = gate["satisfied_in_p0_12"]
    require(observed == EXPECTED_UNLOCK_GATES, "unlock gate identities or current satisfaction values changed")
    require(not observed["explicit_user_reopen"], "runtime execution cannot be authorized before explicit user reopening")
    require(not observed["p0_12_merged"], "P0.12 cannot claim to be merged from its own candidate branch")


def validate_work_packages(packages: Any, trace_ids: set[str]) -> None:
    require(isinstance(packages, list) and len(packages) == 7, "work package set must contain exactly 7 records")
    observed_ids: list[str] = []
    observed_issues: list[int] = []
    covered_traces: set[str] = set()
    for index, package in enumerate(packages):
        context = f"work_packages[{index}]"
        require(isinstance(package, dict), f"{context} must be an object")
        expected_keys = {
            "package_id",
            "github_issue",
            "title",
            "status",
            "depends_on_issues",
            "trace_ids",
            "objective",
            "allowed_outputs",
            "prohibited_outputs",
            "required_checks",
            "source_paths",
        }
        require(set(package) == expected_keys, f"{context} has unknown or missing fields")
        package_id = package["package_id"]
        issue = package["github_issue"]
        require(package_id not in observed_ids, f"duplicate work package ID: {package_id}")
        require(issue not in observed_issues, f"duplicate GitHub issue in work package set: {issue}")
        observed_ids.append(package_id)
        observed_issues.append(issue)
        require(package["status"] == "blocked_pending_explicit_reopen", f"{package_id}: work package must remain blocked")
        require(isinstance(package["title"], str) and len(package["title"]) >= 10, f"{package_id}: title is too short")
        require(isinstance(package["objective"], str) and len(package["objective"]) >= 30, f"{package_id}: objective is too short")

        dependencies = package["depends_on_issues"]
        require(isinstance(dependencies, list) and len(dependencies) == len(set(dependencies)), f"{package_id}: dependencies must be a unique list")
        require(79 in dependencies, f"{package_id}: parent issue #79 must be a dependency")
        require(all(isinstance(dep, int) and dep in {79, *EXPECTED_ISSUES} for dep in dependencies), f"{package_id}: dependency outside the P0.12 issue set")
        require(all(dep < issue for dep in dependencies), f"{package_id}: dependencies must precede the child issue and remain acyclic")

        package_traces = package["trace_ids"]
        require(isinstance(package_traces, list) and len(package_traces) == len(set(package_traces)), f"{package_id}: trace IDs must be unique")
        for trace_id in package_traces:
            require(trace_id in trace_ids, f"{package_id}: unknown P0.11 trace ID {trace_id}")
            covered_traces.add(trace_id)

        for field, minimum in (("allowed_outputs", 2), ("prohibited_outputs", 3), ("required_checks", 2), ("source_paths", 2)):
            values = package[field]
            require(isinstance(values, list) and len(values) >= minimum, f"{package_id}: {field} requires at least {minimum} entries")
            require(len(values) == len(set(values)), f"{package_id}: {field} entries must be unique")
        for check in package["required_checks"]:
            require(re.fullmatch(r"[a-z][a-z0-9_]*", check or "") is not None, f"{package_id}: invalid required check key {check!r}")
        for raw_path in package["source_paths"]:
            validate_repo_path(raw_path, package_id)

        prohibited_text = " ".join(package["prohibited_outputs"]).lower()
        require("production" in prohibited_text, f"{package_id}: prohibited outputs must preserve a production boundary")

    require(observed_ids == EXPECTED_PACKAGE_IDS, f"work package IDs must be ordered exactly as {EXPECTED_PACKAGE_IDS}")
    require(observed_issues == EXPECTED_ISSUES, f"work package issues must be ordered exactly as {EXPECTED_ISSUES}")
    required_slice_traces = {"DH-IS-003", "DH-IS-004", "DH-IS-007", "DH-IS-008", "DH-IS-009", "DH-IS-016", "DH-IS-019"}
    require(required_slice_traces <= covered_traces, "authorized prototype slice is missing one or more required P0.11 traces")


def validate_external_gates(gates: Any) -> None:
    require(isinstance(gates, list) and len(gates) == 3, "external gate set must contain exactly issues 7, 39, and 44")
    observed: set[int] = set()
    for index, gate in enumerate(gates):
        require(isinstance(gate, dict), f"external_gates[{index}] must be an object")
        require(set(gate) == {"issue", "summary", "may_be_suppressed"}, f"external_gates[{index}] has unknown or missing fields")
        issue = gate["issue"]
        require(issue not in observed, f"duplicate external gate issue: {issue}")
        observed.add(issue)
        require(isinstance(gate["summary"], str) and len(gate["summary"]) >= 20, f"issue #{issue}: summary is too short")
        require(gate["may_be_suppressed"] is False, f"issue #{issue}: external gate may not be suppressed")
    require(observed == EXPECTED_EXTERNAL_ISSUES, "external gate set must remain exactly issues 7, 39, and 44")


def validate_decision(decision: Any) -> None:
    require(isinstance(decision, dict), "prototype authorization decision must be an object")
    require(set(decision) == EXPECTED_TOP_LEVEL_KEYS, "prototype authorization decision has unknown or missing top-level fields")
    require(decision["decision_id"] == "DH-PA-001", "decision_id must remain DH-PA-001")
    require(decision["release_id"] == "P0.12", "release_id must remain P0.12")
    require(decision["tale_id"] == "drowned_harbor", "tale_id must remain drowned_harbor")
    require(decision["production_status"] == "design_only", "Drowned Harbor must remain design_only")
    require(decision["authorization_decision"] == "conditional_authorization_in_principle", "authorization decision changed")
    require(decision["execution_status"] == "blocked_pending_explicit_reopen", "execution must remain blocked")
    require(decision["parent_issue"] == 79, "parent issue must remain #79")
    require(decision["baseline_main_sha"] == EXPECTED_BASELINE, "P0.12 baseline must remain the exact P0.11 protected-main squash")
    require(decision["production_catalog_path"] == "game/data/tales/tale_catalog_v1.json", "production catalog path changed")
    require(decision["production_tale"] == "lantern_house_vertical_slice", "Lantern House must remain the production Tale")
    for field in (
        "runtime_changes_in_release",
        "production_catalog_change_authorized",
        "provider_change_authorized",
        "playable_export_authorized",
        "human_evidence_claimed",
    ):
        require(decision[field] is False, f"{field} must remain false in P0.12")

    validate_unlock_gates(decision["unlock_gates"])
    trace_ids = load_trace_ids()
    validate_work_packages(decision["work_packages"], trace_ids)
    validate_external_gates(decision["external_gates"])

    promotion = decision["promotion_requirements"]
    require(isinstance(promotion, list) and len(promotion) >= 8 and len(promotion) == len(set(promotion)), "promotion requirements must contain at least 8 unique entries")
    for raw_path in decision["source_paths"]:
        validate_repo_path(raw_path, "decision")
    boundary = decision["approval_boundary"]
    require(isinstance(boundary, str) and len(boundary) >= 80, "approval boundary is too short")
    boundary_lower = boundary.lower()
    require("authorizes no runtime file" in boundary_lower, "approval boundary must explicitly deny runtime-file authorization")
    require("production tale registration" in boundary_lower, "approval boundary must explicitly deny production Tale registration")
    require("human evidence claim" in boundary_lower, "approval boundary must explicitly deny human evidence claims")


def main() -> int:
    read_json(SCHEMA_PATH)
    validate_catalog()
    decision = read_json(DECISION_PATH)
    validate_decision(decision)
    print("Validated P0.12 prototype authorization: 7 blocked issue packages, 7 governed prototype traces, closed production catalog, and unsuppressed issues 7/39/44")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except PrototypeAuthorizationValidationError as exc:
        print(f"Prototype authorization validation failed: {exc}", file=sys.stderr)
        raise SystemExit(1)
