#!/usr/bin/env python3
"""Validate and project P0.14 Drowned Harbor synthetic state fixtures."""

from __future__ import annotations

import copy
import hashlib
import json
import sys
from pathlib import Path
from typing import Any, Iterable

ROOT = Path(".")
PACKAGE_PATH = Path(
    "game/tests/drowned_harbor_dev_only/state_projection_fixtures_v1.json"
)
SCHEMA_PATH = Path(
    "game/tests/drowned_harbor_dev_only/state_projection_fixture_schema_v1.json"
)
EXPORT_PRESETS_PATH = Path("game/export_presets.cfg")
PROTOTYPE_MANIFEST_PATH = Path(
    "game/tests/drowned_harbor_prototype_manifest_v1.json"
)

EXPECTED_PACKAGE_FIELDS = {
    "fixture_package_kind",
    "schema_version",
    "prototype_id",
    "tale_id",
    "status",
    "projection_contract_version",
    "fixture_schema",
    "trace_sources",
    "fixtures",
    "human_validation_required",
    "human_evidence_claimed",
    "approval_boundary",
}
EXPECTED_FIXTURE_FIELDS = {
    "fixture_id",
    "title",
    "trace_id",
    "storyboard_id",
    "fixture_kind",
    "privacy_surface",
    "status",
    "seed",
    "source_revision",
    "result_revision",
    "rng_cursor_before",
    "rng_cursor_after",
    "authoritative_commit",
    "active_stable_seat_id",
    "authorized_actor_kinds",
    "projection_request",
    "source_state",
    "projection_map",
    "expected_events",
    "negative_cases",
    "stable_seat_identity_before",
    "stable_seat_identity_after",
    "human_validation_required",
    "human_evidence_claimed",
    "notes",
}
EXPECTED_REQUEST_FIELDS = {
    "fixture_id",
    "source_revision",
    "actor_kind",
    "stable_seat_id",
    "intent",
}
EXPECTED_STATE_FIELDS = {
    "public",
    "seat_public",
    "private",
    "diagnostic_nonplayer",
}
EXPECTED_EVENT_FIELDS = {
    "event_key",
    "classification",
    "exactly_once",
    "payload_map",
}
EXPECTED_TRACE_BINDINGS = {
    "DH-FIX-001": (
        "DH-IS-003",
        "DH-UI-003",
        "public_shared",
        True,
        {"low_tide_public_action_committed"},
    ),
    "DH-FIX-002": (
        "DH-IS-004",
        "DH-UI-004",
        "public_shared",
        True,
        {"bellhouse_decision_committed"},
    ),
    "DH-FIX-003": (
        "DH-IS-007",
        "DH-UI-007",
        "controlled_private_surface",
        True,
        {
            "harbor_bargain_private_term_committed",
            "harbor_bargain_public_resolution_projected",
        },
    ),
    "DH-FIX-004": (
        "DH-IS-008",
        "DH-UI-008",
        "public_shared",
        True,
        {"high_water_transformation_committed"},
    ),
    "DH-FIX-005": (
        "DH-IS-010",
        "DH-UI-010",
        "public_shared",
        True,
        {"tidebound_transformation_committed"},
    ),
    "DH-FIX-006": (
        "DH-IS-019",
        "DH-UI-019",
        "public_shared",
        False,
        {"invalid_action_recovery_projected"},
    ),
}
PUBLIC_SOURCE_PREFIXES = (
    "public.",
    "seat_public.",
)
PRIVATE_SOURCE_PREFIXES = (
    "private.",
    "seat_public.",
)
META_PATHS = {
    "$source_revision",
    "$result_revision",
    "$seed",
    "$rng_cursor_before",
    "$rng_cursor_after",
}


class ProjectionFixtureError(ValueError):
    """Raised when a synthetic fixture or projection violates P0.14."""


def require(condition: bool, message: str) -> None:
    if not condition:
        raise ProjectionFixtureError(message)


def read_json(path: Path) -> dict[str, Any]:
    try:
        value = json.loads(path.read_text(encoding="utf-8"))
    except FileNotFoundError as exc:
        raise ProjectionFixtureError(f"required file does not exist: {path}") from exc
    except json.JSONDecodeError as exc:
        raise ProjectionFixtureError(f"invalid JSON in {path}: {exc}") from exc
    require(isinstance(value, dict), f"JSON root must be an object: {path}")
    return value


def canonical_json_bytes(value: Any) -> bytes:
    return json.dumps(
        value,
        ensure_ascii=False,
        sort_keys=True,
        separators=(",", ":"),
    ).encode("utf-8")


def canonical_sha256(value: Any) -> str:
    return hashlib.sha256(canonical_json_bytes(value)).hexdigest()


def _resolve_meta(fixture: dict[str, Any], path: str) -> Any:
    key = path.removeprefix("$")
    require(key in fixture, f"unknown fixture metadata path: {path}")
    return copy.deepcopy(fixture[key])


def resolve_path(fixture: dict[str, Any], path: str) -> Any:
    if path.startswith("$"):
        require(path in META_PATHS, f"unauthorized fixture metadata path: {path}")
        return _resolve_meta(fixture, path)
    current: Any = fixture["source_state"]
    for part in path.split("."):
        require(
            isinstance(current, dict) and part in current,
            f"projection path does not resolve: {path}",
        )
        current = current[part]
    return copy.deepcopy(current)


def build_projection(
    fixture: dict[str, Any],
    mapping: dict[str, str],
) -> dict[str, Any]:
    return {
        key: resolve_path(fixture, mapping[key])
        for key in sorted(mapping)
    }


def _validate_request(
    fixture: dict[str, Any],
    request: dict[str, Any],
    *,
    already_committed: bool,
) -> None:
    require(
        set(request) == EXPECTED_REQUEST_FIELDS,
        "projection request fields do not match the closed contract",
    )
    require(request["fixture_id"] == fixture["fixture_id"], "unknown_fixture")
    require(request["source_revision"] == fixture["source_revision"], "stale_source_revision")
    require(request["actor_kind"] in fixture["authorized_actor_kinds"], "unauthorized_actor")
    require(request["stable_seat_id"] == fixture["active_stable_seat_id"], "wrong_stable_seat")
    require(request["intent"] == fixture["projection_request"]["intent"], "unauthorized_intent")
    if fixture["fixture_kind"] == "controlled_private_commit_projection":
        require(
            fixture["privacy_surface"] == "controlled_private_surface",
            "private_surface_required",
        )
    if fixture["privacy_surface"] == "controlled_private_surface":
        require(
            fixture["projection_map"]["private"],
            "private_surface_required",
        )
    if fixture["fixture_kind"] == "once_only_public_transform_projection":
        require(not already_committed, "already_committed")


def project_fixture(
    fixture: dict[str, Any],
    request: dict[str, Any] | None = None,
    *,
    already_committed: bool = False,
) -> dict[str, Any]:
    source_before = copy.deepcopy(fixture["source_state"])
    request_value = copy.deepcopy(
        fixture["projection_request"] if request is None else request
    )
    _validate_request(
        fixture,
        request_value,
        already_committed=already_committed,
    )
    public_projection = build_projection(
        fixture,
        fixture["projection_map"]["public"],
    )
    private_projection: dict[str, Any] = {}
    if fixture["privacy_surface"] == "controlled_private_surface":
        private_projection = build_projection(
            fixture,
            fixture["projection_map"]["private"],
        )

    events: list[dict[str, Any]] = []
    for event in fixture["expected_events"]:
        events.append(
            {
                "event_key": event["event_key"],
                "classification": event["classification"],
                "exactly_once": event["exactly_once"],
                "source_revision": fixture["source_revision"],
                "result_revision": fixture["result_revision"],
                "payload": build_projection(fixture, event["payload_map"]),
            }
        )

    require(
        fixture["source_state"] == source_before,
        "projection mutated the fixture source state",
    )
    require(
        fixture["rng_cursor_before"] == fixture["rng_cursor_after"],
        "reprojection consumed deterministic randomness",
    )
    return {
        "fixture_id": fixture["fixture_id"],
        "trace_id": fixture["trace_id"],
        "source_revision": fixture["source_revision"],
        "result_revision": fixture["result_revision"],
        "rng_cursor": fixture["rng_cursor_after"],
        "public_projection": public_projection,
        "private_projection": private_projection,
        "events": events,
        "authoritative_commit": fixture["authoritative_commit"],
    }


def _collect_private_markers(value: Any) -> set[str]:
    markers: set[str] = set()
    if isinstance(value, dict):
        for child in value.values():
            markers.update(_collect_private_markers(child))
    elif isinstance(value, list):
        for child in value:
            markers.update(_collect_private_markers(child))
    elif isinstance(value, str) and "PRIVATE_" in value:
        markers.add(value)
    return markers


def _validate_mapping_paths(
    fixture: dict[str, Any],
    mapping: dict[str, str],
    *,
    public: bool,
) -> None:
    require(isinstance(mapping, dict), "projection map must be an object")
    require(len(mapping) == len(set(mapping)), "projection map contains duplicate output keys")
    allowed = PUBLIC_SOURCE_PREFIXES if public else PRIVATE_SOURCE_PREFIXES
    for output_key, source_path in mapping.items():
        require(
            isinstance(output_key, str)
            and output_key
            and isinstance(source_path, str)
            and source_path,
            "projection map entries must be non-empty text",
        )
        if source_path.startswith("$"):
            require(
                source_path in META_PATHS,
                f"unauthorized metadata path in projection map: {source_path}",
            )
        else:
            allowed_roots = tuple(prefix.removesuffix(".") for prefix in allowed)
            require(
                source_path in allowed_roots or source_path.startswith(allowed),
                (
                    "public projection may read only public or seat-public state"
                    if public
                    else "private projection may read only private or seat-public state"
                ),
            )
        resolve_path(fixture, source_path)


def _event_contracts(trace: dict[str, Any]) -> dict[str, dict[str, Any]]:
    events = trace["projection_contract"]["emitted_events"]
    return {event["event_key"]: event for event in events}


def load_trace_index(
    package: dict[str, Any],
    root: Path,
) -> dict[str, dict[str, Any]]:
    trace_index: dict[str, dict[str, Any]] = {}
    for source in package["trace_sources"]:
        source_path = root / source
        manifest = read_json(source_path)
        require(
            manifest.get("manifest_kind")
            == "interaction_state_traces_preproduction",
            f"unexpected trace manifest kind: {source}",
        )
        require(
            manifest.get("production_status") == "design_only",
            f"trace manifest must remain design-only: {source}",
        )
        entries = manifest.get("entries")
        require(isinstance(entries, list), f"trace entries must be a list: {source}")
        for trace in entries:
            trace_id = trace.get("trace_id")
            require(
                isinstance(trace_id, str) and trace_id,
                f"trace ID missing: {source}",
            )
            require(trace_id not in trace_index, f"duplicate trace ID: {trace_id}")
            trace_index[trace_id] = trace
    return trace_index


def validate_fixture(
    fixture: dict[str, Any],
    trace_index: dict[str, dict[str, Any]],
) -> None:
    require(
        set(fixture) == EXPECTED_FIXTURE_FIELDS,
        (
            f"{fixture.get('fixture_id')}: "
            "fixture fields do not match the closed contract"
        ),
    )
    fixture_id = fixture["fixture_id"]
    require(fixture_id in EXPECTED_TRACE_BINDINGS, f"unexpected fixture ID: {fixture_id}")
    (
        trace_id,
        storyboard_id,
        privacy_surface,
        commit,
        expected_event_keys,
    ) = EXPECTED_TRACE_BINDINGS[fixture_id]
    require(fixture["trace_id"] == trace_id, f"{fixture_id}: trace binding drifted")
    require(fixture["storyboard_id"] == storyboard_id, f"{fixture_id}: storyboard binding drifted")
    require(fixture["privacy_surface"] == privacy_surface, f"{fixture_id}: privacy surface drifted")
    require(
        fixture["authoritative_commit"] is commit,
        f"{fixture_id}: authoritative commit contract drifted",
    )
    require(
        fixture["status"] == "synthetic_test_only",
        f"{fixture_id}: fixture must remain synthetic",
    )
    require(
        fixture["human_validation_required"] is True,
        f"{fixture_id}: future human validation is required",
    )
    require(
        fixture["human_evidence_claimed"] is False,
        f"{fixture_id}: human evidence may not be claimed",
    )
    require(
        fixture["stable_seat_identity_before"]
        == fixture["stable_seat_identity_after"]
        == fixture["active_stable_seat_id"],
        f"{fixture_id}: stable-seat identity changed",
    )
    require(
        fixture["rng_cursor_before"] == fixture["rng_cursor_after"],
        f"{fixture_id}: fixture projection may not consume RNG",
    )
    if commit:
        require(
            fixture["result_revision"] == fixture["source_revision"] + 1,
            f"{fixture_id}: committed fixture must advance exactly one revision",
        )
    else:
        require(
            fixture["result_revision"] == fixture["source_revision"],
            f"{fixture_id}: non-commit fixture must not advance revision",
        )

    request = fixture["projection_request"]
    require(
        set(request) == EXPECTED_REQUEST_FIELDS,
        f"{fixture_id}: request fields do not match the closed contract",
    )
    require(request["fixture_id"] == fixture_id, f"{fixture_id}: request fixture ID drifted")
    require(
        request["source_revision"] == fixture["source_revision"],
        f"{fixture_id}: request revision drifted",
    )
    require(
        request["stable_seat_id"] == fixture["active_stable_seat_id"],
        f"{fixture_id}: request stable seat drifted",
    )
    require(
        request["actor_kind"] in fixture["authorized_actor_kinds"],
        f"{fixture_id}: request actor is not authorized",
    )
    require(
        request["intent"].startswith("project_"),
        f"{fixture_id}: request intent must be projection-only",
    )

    source_state = fixture["source_state"]
    require(
        set(source_state) == EXPECTED_STATE_FIELDS,
        (
            f"{fixture_id}: "
            "source-state fields do not match the closed contract"
        ),
    )
    require(
        all(
            isinstance(value, dict)
            for value in source_state.values()
        ),
        f"{fixture_id}: source-state domains must be objects",
    )
    require(source_state["private"], f"{fixture_id}: privacy regression data must be present")

    projection_map = fixture["projection_map"]
    require(
        isinstance(projection_map, dict)
        and set(projection_map) == {"public", "private"},
        f"{fixture_id}: projection map fields do not match the closed contract",
    )
    _validate_mapping_paths(
        fixture,
        projection_map["public"],
        public=True,
    )
    if privacy_surface == "controlled_private_surface":
        require(
            projection_map["private"],
            (
                f"{fixture_id}: "
                "controlled-private fixture requires a private projection"
            ),
        )
        _validate_mapping_paths(
            fixture,
            projection_map["private"],
            public=False,
        )
    else:
        require(
            not projection_map["private"],
            (
                f"{fixture_id}: "
                "public fixture may not define a private projection"
            ),
        )

    trace = trace_index.get(trace_id)
    require(trace is not None, f"{fixture_id}: source trace does not exist: {trace_id}")
    require(
        trace["storyboard_id"] == storyboard_id,
        f"{fixture_id}: source trace storyboard differs",
    )
    require(
        trace["privacy_surface"] == privacy_surface,
        f"{fixture_id}: source trace privacy differs",
    )
    require(
        trace["commit_contract"]["authoritative_commit"] is commit,
        f"{fixture_id}: source trace commit contract differs",
    )
    trace_events = _event_contracts(trace)
    fixture_event_keys = {
        event["event_key"]
        for event in fixture["expected_events"]
    }
    require(
        fixture_event_keys == expected_event_keys,
        f"{fixture_id}: expected event-key set drifted",
    )
    require(
        fixture_event_keys.issubset(trace_events),
        f"{fixture_id}: fixture references an unknown source-trace event",
    )

    for event in fixture["expected_events"]:
        require(
            set(event) == EXPECTED_EVENT_FIELDS,
            (
                f"{fixture_id}: "
                "event fields do not match the closed contract"
            ),
        )
        source_event = trace_events[event["event_key"]]
        require(
            event["classification"] == source_event["classification"],
            f"{fixture_id}: event classification differs from source trace",
        )
        require(
            event["exactly_once"] is source_event["exactly_once"],
            f"{fixture_id}: event exactly-once behavior differs from source trace",
        )
        _validate_mapping_paths(
            fixture,
            event["payload_map"],
            public=event["classification"] != "private",
        )

    negative_cases = fixture["negative_cases"]
    require(
        isinstance(negative_cases, list)
        and len(negative_cases) >= 4,
        f"{fixture_id}: negative cases are incomplete",
    )
    case_ids = [case["case_id"] for case in negative_cases]
    require(len(case_ids) == len(set(case_ids)), f"{fixture_id}: duplicate negative case IDs")

    first = project_fixture(fixture)
    second = project_fixture(fixture)
    require(
        canonical_json_bytes(first) == canonical_json_bytes(second),
        f"{fixture_id}: reprojection is not byte-equivalent",
    )
    public_surface = {
        "public_projection": first["public_projection"],
        "events": [
            event
            for event in first["events"]
            if event["classification"] != "private"
        ],
    }
    public_bytes = canonical_json_bytes(public_surface).decode("utf-8")
    for marker in _collect_private_markers(source_state["private"]):
        require(
            marker not in public_bytes,
            f"{fixture_id}: private marker leaked into a public projection",
        )
    if privacy_surface == "controlled_private_surface":
        require(first["private_projection"], f"{fixture_id}: private projection is empty")
    else:
        require(
            not first["private_projection"],
            f"{fixture_id}: public fixture emitted a private projection",
        )


def _mutated_request(
    fixture: dict[str, Any],
    mutation: dict[str, Any],
) -> tuple[dict[str, Any], dict[str, Any], bool]:
    fixture_value = copy.deepcopy(fixture)
    request = copy.deepcopy(fixture_value["projection_request"])
    already_committed = False
    for key, value in mutation.items():
        if key == "source_revision_delta":
            request["source_revision"] += value
        elif key in {"actor_kind", "stable_seat_id", "intent"}:
            request[key] = value
        elif key == "privacy_surface":
            fixture_value["privacy_surface"] = value
        elif key == "already_committed":
            already_committed = bool(value)
        else:
            raise ProjectionFixtureError(f"unsupported negative-case mutation: {key}")
    return fixture_value, request, already_committed


def validate_negative_cases(fixture: dict[str, Any]) -> None:
    for case in fixture["negative_cases"]:
        fixture_value, request, already_committed = _mutated_request(
            fixture,
            case["mutation"],
        )
        try:
            project_fixture(
                fixture_value,
                request,
                already_committed=already_committed,
            )
        except ProjectionFixtureError as exc:
            require(
                case["expected_error"] in str(exc),
                (
                    f"{fixture['fixture_id']}/{case['case_id']}: "
                    f"expected {case['expected_error']}, received {exc}"
                ),
            )
            continue
        raise ProjectionFixtureError(
            f"{fixture['fixture_id']}/{case['case_id']}: negative case did not fail closed"
        )


def validate_export_exclusion(root: Path = ROOT) -> None:
    package_repo_path = str(PACKAGE_PATH).replace("\\", "/")
    require(
        package_repo_path.startswith("game/tests/"),
        "fixture package must remain under the export-excluded test tree",
    )
    presets = (root / EXPORT_PRESETS_PATH).read_text(encoding="utf-8")
    require(
        presets.count("tests/*") == 2,
        "both ordinary export presets must exclude tests/*",
    )
    require(
        "state_projection_fixtures_v1.json" not in presets,
        "export presets may not explicitly include the fixture package",
    )


def validate_prototype_manifest(root: Path = ROOT) -> None:
    manifest = read_json(root / PROTOTYPE_MANIFEST_PATH)
    require(
        manifest.get("completed_work_issues") == [80, 81],
        "prototype manifest must record completed work issues #80 and #81",
    )
    require(
        manifest.get("future_work_issues") == [82, 83, 84, 85, 86],
        "prototype manifest must leave issues #82 through #86 as future work",
    )
    fixture_packages = manifest.get("fixture_packages")
    require(
        fixture_packages
        == [
            "res://tests/drowned_harbor_dev_only/state_projection_fixtures_v1.json"
        ],
        "prototype manifest fixture package registration drifted",
    )
    for field in (
        "production_catalog_registered",
        "production_provider_registered",
        "normal_tale_library_visible",
        "playable_export_authorized",
        "runtime_authority_created",
        "human_evidence_claimed",
    ):
        require(manifest.get(field) is False, f"prototype manifest {field} must remain false")


def validate_package(
    package: dict[str, Any],
    root: Path = ROOT,
) -> tuple[int, int]:
    require(
        set(package) == EXPECTED_PACKAGE_FIELDS,
        "fixture package fields do not match the closed contract",
    )
    require(
        package["fixture_package_kind"]
        == "drowned_harbor_state_projection_fixtures",
        "unexpected fixture package kind",
    )
    require(package["schema_version"] == 1, "unsupported fixture schema")
    require(package["projection_contract_version"] == 1, "unsupported projection contract")
    require(
        package["prototype_id"] == "drowned_harbor_dev_only",
        "fixture package must retain the dev-only prototype identity",
    )
    require(package["tale_id"] == "drowned_harbor", "unexpected fixture Tale ID")
    require(
        package["status"]
        == "synthetic_test_only_export_excluded",
        "fixture package must remain synthetic and export-excluded",
    )
    require(
        package["human_validation_required"] is True,
        "fixture package must retain future human validation",
    )
    require(
        package["human_evidence_claimed"] is False,
        "fixture package may not claim human evidence",
    )
    require(
        len(package["approval_boundary"]) >= 160,
        "fixture package approval boundary is too weak",
    )
    require(
        package["fixture_schema"]
        == str(SCHEMA_PATH).replace("\\", "/"),
        "fixture schema path drifted",
    )
    require((root / SCHEMA_PATH).is_file(), "fixture schema file is missing")

    trace_sources = package["trace_sources"]
    require(
        isinstance(trace_sources, list)
        and len(trace_sources) == 3,
        (
            "fixture package must reference the three "
            "P0.11 trace manifests"
        ),
    )
    require(
        len(trace_sources) == len(set(trace_sources)),
        "fixture trace sources contain duplicates",
    )
    for source in trace_sources:
        require((root / source).is_file(), f"fixture trace source does not exist: {source}")

    fixtures = package["fixtures"]
    require(
        isinstance(fixtures, list)
        and len(fixtures) == 6,
        "fixture package must contain exactly six fixtures",
    )
    fixture_ids = [fixture["fixture_id"] for fixture in fixtures]
    require(len(fixture_ids) == len(set(fixture_ids)), "fixture IDs contain duplicates")
    require(set(fixture_ids) == set(EXPECTED_TRACE_BINDINGS), "fixture ID inventory drifted")

    trace_index = load_trace_index(package, root)
    negative_count = 0
    for fixture in fixtures:
        validate_fixture(fixture, trace_index)
        validate_negative_cases(fixture)
        negative_count += len(fixture["negative_cases"])
    return len(fixtures), negative_count


def validate(root: Path = ROOT) -> tuple[int, int]:
    require((root / PACKAGE_PATH).is_file(), f"fixture package missing: {PACKAGE_PATH}")
    validate_export_exclusion(root)
    validate_prototype_manifest(root)
    package = read_json(root / PACKAGE_PATH)
    return validate_package(package, root)


def main() -> int:
    try:
        fixture_count, negative_count = validate(ROOT)
    except (ProjectionFixtureError, OSError) as exc:
        print(
            f"Drowned Harbor projection fixture validation failed: {exc}",
            file=sys.stderr,
        )
        return 1
    package = read_json(ROOT / PACKAGE_PATH)
    print(
        "Validated "
        f"{fixture_count} deterministic Drowned Harbor state/projection fixtures, "
        f"{negative_count} fail-closed request cases, "
        f"and canonical package identity {canonical_sha256(package)}"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
