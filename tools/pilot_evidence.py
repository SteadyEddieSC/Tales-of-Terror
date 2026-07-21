#!/usr/bin/env python3
"""Validate and normalize bounded v0.1.3 pilot evidence entirely offline."""

from __future__ import annotations

import argparse
import hashlib
import json
import re
import sys
from pathlib import Path, PurePosixPath
from typing import Any


ROOT = Path(__file__).resolve().parents[1]
PILOT_SCHEMA = ROOT / "packaging" / "pilot" / "pilot_session_schema.json"
FINDINGS_SCHEMA = ROOT / "packaging" / "pilot" / "findings_register_schema.json"
BLANK_PILOT = ROOT / "docs" / "playtests" / "v0.1.3-pilot-session-blank.json"
BLANK_FINDINGS = ROOT / "docs" / "playtests" / "v0.1.3-findings-register-blank.json"
PACKAGE_FILE = "PILOT_SESSION_RECORD.json"
MAX_PACKAGE_FILE_BYTES = 64 * 1024
SHA40 = re.compile(r"^[0-9a-f]{40}$")
SHA64 = re.compile(r"^[0-9a-f]{64}$")
SESSION_ID = re.compile(r"^PILOT-[A-Z0-9]{8}$")
DATE = re.compile(r"^[0-9]{4}-[0-9]{2}-[0-9]{2}$")
SAFE_TEXT = re.compile(r"^[^\x00-\x08\x0b\x0c\x0e-\x1f]*$")

MANUAL_IDS = (
    "one_physical_controller",
    "multiple_physical_controllers",
    "disconnect_reconnect_ownership",
    "keyboard_fallback",
    "tv_distance_readability",
    "safe_margins_720p_1080p_native_4k",
    "physical_phones_and_no_phone_path",
    "household_wifi_router_firewall",
    "long_session_stability",
    "accessibility_assistive_technology",
)
HUMAN_CLASSES = {"remote_observed", "physical_in_room"}
AUTOMATED_CLASSES = {"automated_ci", "virtual_offscreen"}
CATEGORIES = {
    "launch",
    "controller_input",
    "lifecycle_recovery",
    "usability_guidance",
    "readability",
    "privacy_reveal",
    "companion_no_phone",
    "performance_stability",
    "content_clarity",
    "balance_pacing",
    "accessibility",
    "reporting_evidence",
    "other",
}
SEVERITIES = {"P0_blocker", "P1_major", "P2_moderate", "P3_minor", "observation_only"}
REPRODUCIBILITY = {
    "confirmed",
    "repeated_in_session",
    "single_occurrence",
    "unable_to_reproduce",
    "not_applicable",
}
DISPOSITIONS = {
    "open_issue_required",
    "research_required",
    "defer",
    "duplicate",
    "not_actionable",
    "accepted_limitation",
}
CERTIFICATION_LIMIT = (
    "one_pilot_does_not_certify_balance_fun_accessibility_duration_privacy_or_security"
)

PRIVATE_PATTERNS = (
    ("email address", re.compile(r"\b[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}\b", re.IGNORECASE)),
    ("username", re.compile(r"(?<![A-Za-z0-9])@[A-Za-z0-9_]{2,39}\b")),
    ("IPv4 address", re.compile(r"\b(?:\d{1,3}\.){3}\d{1,3}\b")),
    ("IPv6 address", re.compile(r"\b(?:[0-9a-f]{1,4}:){2,7}[0-9a-f]{1,4}\b", re.IGNORECASE)),
    ("Windows absolute path", re.compile(r"\b[A-Za-z]:[\\/]")),
    ("private home path", re.compile(r"/(?:home|Users)/[^/\s]+/", re.IGNORECASE)),
    ("repository path", re.compile(r"(?:Documents[\\/]Codex[\\/]|Tales-of-Terror)", re.IGNORECASE)),
    ("GitHub token", re.compile(r"\b(?:gh[opusr]_[A-Za-z0-9_]{20,}|github_pat_[A-Za-z0-9_]{20,})\b")),
    ("generic token", re.compile(r"\b(?:token|secret|password)\s*[:=]\s*\S+", re.IGNORECASE)),
    ("room code", re.compile(r"\broom(?:\s|_)*(?:code|secret)\s*[:=]?\s*[A-Za-z0-9-]+", re.IGNORECASE)),
    ("device identifier", re.compile(r"\b(?:device|serial)(?:\s|_)*(?:id|number)\s*[:=]?\s*\S+", re.IGNORECASE)),
    ("named username", re.compile(r"\buser(?:name)?\s*[:=]\s*\S+", re.IGNORECASE)),
    ("direct name", re.compile(r"\b(?:full\s+name|participant\s+name|facilitator\s+name)\s*[:=]", re.IGNORECASE)),
    ("exact age", re.compile(r"\b(?:age|aged)\s*[:=]?\s*\d{1,3}\b", re.IGNORECASE)),
    ("phone number", re.compile(r"(?<!\d)(?:\+?1[-.\s]?)?\(?\d{3}\)?[-.\s]\d{3}[-.\s]\d{4}(?!\d)")),
)


class PilotError(RuntimeError):
    """Pilot evidence violated a bounded contract."""


def _read_json(path: Path) -> dict[str, Any]:
    try:
        value = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, UnicodeDecodeError, json.JSONDecodeError) as exc:
        raise PilotError(f"invalid JSON: {path}") from exc
    if not isinstance(value, dict):
        raise PilotError(f"expected JSON object: {path}")
    return value


def _write_json(path: Path, value: dict[str, Any]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(value, indent=2, sort_keys=True) + "\n", encoding="utf-8")


def _sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for block in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def _exact_keys(value: Any, keys: set[str], label: str) -> dict[str, Any]:
    if not isinstance(value, dict) or set(value) != keys:
        raise PilotError(f"{label} exact keys changed")
    return value


def _bounded_string(value: Any, limit: int, label: str, required: bool = False) -> str:
    if not isinstance(value, str) or len(value) > limit or not SAFE_TEXT.fullmatch(value):
        raise PilotError(f"{label} must be a bounded text string")
    if required and not value.strip():
        raise PilotError(f"{label} is required")
    return value


def _bounded_int(value: Any, minimum: int, maximum: int, label: str) -> int:
    if isinstance(value, bool) or not isinstance(value, int) or not minimum <= value <= maximum:
        raise PilotError(f"{label} is outside its bounded integer range")
    return value


def _scan_private(value: Any, path: str = "record") -> None:
    if isinstance(value, dict):
        for key, child in value.items():
            _scan_private(child, f"{path}.{key}")
    elif isinstance(value, list):
        for index, child in enumerate(value):
            _scan_private(child, f"{path}[{index}]")
    elif isinstance(value, str):
        for label, pattern in PRIVATE_PATTERNS:
            if pattern.search(value):
                raise PilotError(f"{path} contains prohibited {label}")


def _validate_schema_documents() -> None:
    pilot = _read_json(PILOT_SCHEMA)
    findings = _read_json(FINDINGS_SCHEMA)
    if pilot.get("$id") != "urn:tales-of-terror:pilot-session:v1":
        raise PilotError("pilot session schema identity changed")
    if findings.get("$id") != "urn:tales-of-terror:findings-register:v1":
        raise PilotError("findings register schema identity changed")
    if pilot.get("additionalProperties") is not False or findings.get("additionalProperties") is not False:
        raise PilotError("schemas must reject unknown root keys")


def _validate_candidate(candidate: Any, allow_blank: bool) -> dict[str, Any]:
    keys = {
        "source_sha", "platform", "architecture", "artifact_name", "archive_sha256",
        "native_sha256", "runtime_digest", "bundle_digest", "build_timestamp_utc",
        "classification",
    }
    value = _exact_keys(candidate, keys, "candidate")
    if allow_blank and value == {
        "source_sha": "", "platform": "not_tested", "architecture": "",
        "artifact_name": "", "archive_sha256": "", "native_sha256": "",
        "runtime_digest": "", "bundle_digest": "", "build_timestamp_utc": "",
        "classification": "not_tested",
    }:
        return value
    if not SHA40.fullmatch(value["source_sha"]):
        raise PilotError("candidate source SHA must be exact lowercase SHA-1")
    if value["platform"] not in {"windows", "linux"} or value["architecture"] != "x86_64":
        raise PilotError("candidate target must be reviewed Windows/Linux x86_64")
    expected_name = f"lantern-house-internal-playtest-v0.1.3-{value['platform']}-x86_64"
    if value["artifact_name"] != expected_name:
        raise PilotError("candidate artifact name does not match release and target")
    for key in ("archive_sha256", "native_sha256", "runtime_digest", "bundle_digest"):
        if not isinstance(value[key], str) or not SHA64.fullmatch(value[key]):
            raise PilotError(f"candidate {key} must be an exact lowercase SHA-256")
    _bounded_string(value["build_timestamp_utc"], 40, "candidate timestamp", required=True)
    if value["classification"] != "internal_playtest":
        raise PilotError("candidate classification must be internal_playtest")
    return value


def validate_pilot_record(record: dict[str, Any], allow_blank: bool = False) -> dict[str, Any]:
    root_keys = {
        "schema_version", "release", "record_classification", "candidate", "session",
        "route", "durations", "counts", "manual_checks", "observations",
        "questionnaire", "declarations", "provenance",
    }
    value = _exact_keys(record, root_keys, "pilot record")
    if value["schema_version"] != 1 or value["release"] != "v0.1.3":
        raise PilotError("unsupported pilot record version")
    if value["record_classification"] != "pilot_evidence_non_authoritative":
        raise PilotError("pilot record classification changed")
    _validate_candidate(value["candidate"], allow_blank)

    session_keys = {
        "session_id", "session_date_utc", "mode", "facilitator_evidence_class",
        "participant_count", "stable_seat_count", "participant_grouping",
        "controller_count", "controller_categories", "phone_path", "display_class",
        "resolution_category",
    }
    session = _exact_keys(value["session"], session_keys, "session")
    if allow_blank and session["session_id"] == "":
        if session != {
            "session_id": "", "session_date_utc": "", "mode": "not_tested",
            "facilitator_evidence_class": "not_tested", "participant_count": 0,
            "stable_seat_count": 0, "participant_grouping": [], "controller_count": 0,
            "controller_categories": [], "phone_path": "not_tested",
            "display_class": "not_tested", "resolution_category": "not_tested",
        }:
            raise PilotError("blank session contains pre-populated human values")
    else:
        if not SESSION_ID.fullmatch(session["session_id"]) or not DATE.fullmatch(session["session_date_utc"]):
            raise PilotError("session ID or bounded calendar date is invalid")
        mode_class = {"household_in_room": "physical_in_room", "remote_observed": "remote_observed"}
        if mode_class.get(session["mode"]) != session["facilitator_evidence_class"]:
            raise PilotError("session mode and facilitator evidence class disagree")
        _bounded_int(session["participant_count"], 1, 8, "participant count")
        _bounded_int(session["stable_seat_count"], 1, 8, "stable seat count")
        if session["stable_seat_count"] > session["participant_count"]:
            raise PilotError("stable seat count exceeds participant count")
        _bounded_int(session["controller_count"], 0, 8, "controller count")
        if not isinstance(session["participant_grouping"], list) or len(session["participant_grouping"]) > 2 or not set(session["participant_grouping"]) <= {"adult", "youth_with_guardian"}:
            raise PilotError("participant grouping is not bounded")
        if not isinstance(session["controller_categories"], list) or len(session["controller_categories"]) > 4 or not set(session["controller_categories"]) <= {"xinput_style", "playstation_style", "switch_style", "generic_gamepad", "keyboard_fallback"}:
            raise PilotError("controller categories are not bounded")
        if session["phone_path"] not in {"none", "optional_used", "unavailable"}:
            raise PilotError("phone path is invalid")
        if session["display_class"] not in {"monitor", "television", "projector", "remote_stream"}:
            raise PilotError("display class is invalid")
        if session["resolution_category"] not in {"720p", "1080p", "1440p", "native_4k", "other_bounded"}:
            raise PilotError("resolution category is invalid")

    route = _exact_keys(value["route"], {"completion_state", "ending_disposition", "reset", "reconnect", "rematch", "report_export", "report_hashes"}, "route")
    if route["completion_state"] not in {"not_observed", "not_started", "partial", "ending_reached", "completed_with_rematch", "completed_return_to_title"}:
        raise PilotError("route completion state is invalid")
    if route["ending_disposition"] not in {"not_observed", "rematch", "return_to_title", "reset"}:
        raise PilotError("ending disposition is invalid")
    for key in ("reset", "reconnect", "rematch", "report_export"):
        if route[key] not in {"not_observed", "pass", "fail", "deferred", "blocked"}:
            raise PilotError(f"route {key} status is invalid")
    if not isinstance(route["report_hashes"], list) or len(route["report_hashes"]) > 2:
        raise PilotError("report hash list is unbounded")
    for item in route["report_hashes"]:
        item = _exact_keys(item, {"format", "sha256"}, "report hash")
        if item["format"] not in {"json", "markdown"} or not SHA64.fullmatch(item["sha256"]):
            raise PilotError("report hash entry is invalid")

    if not isinstance(value["durations"], list) or len(value["durations"]) > 8:
        raise PilotError("durations are unbounded")
    for item in value["durations"]:
        item = _exact_keys(item, {"stage", "minutes"}, "duration")
        if not re.fullmatch(r"[a-z0-9_]{1,40}", item["stage"]):
            raise PilotError("duration stage is invalid")
        _bounded_int(item["minutes"], 0, 240, "duration minutes")
    counts = _exact_keys(value["counts"], {"interruptions", "assistance"}, "counts")
    _bounded_int(counts["interruptions"], 0, 99, "interruption count")
    _bounded_int(counts["assistance"], 0, 99, "assistance count")

    checks = value["manual_checks"]
    if not isinstance(checks, list) or tuple(item.get("id") for item in checks if isinstance(item, dict)) != MANUAL_IDS:
        raise PilotError("manual check IDs or order changed")
    for item in checks:
        item = _exact_keys(item, {"id", "status", "evidence_class", "notes"}, "manual check")
        if item["status"] not in {"not_tested", "pass", "fail", "deferred", "blocked"}:
            raise PilotError("manual check status is invalid")
        if item["evidence_class"] not in {"not_tested", *HUMAN_CLASSES, *AUTOMATED_CLASSES}:
            raise PilotError("manual evidence class is invalid")
        _bounded_string(item["notes"], 500, "manual check notes")
        if item["status"] == "not_tested":
            if item["evidence_class"] != "not_tested" or item["notes"]:
                raise PilotError("not-tested manual check contains evidence")
        elif item["evidence_class"] not in HUMAN_CLASSES:
            raise PilotError("automated evidence cannot become a performed manual check")

    observations = value["observations"]
    if not isinstance(observations, list) or len(observations) > 64:
        raise PilotError("observations are unbounded")
    for item in observations:
        item = _exact_keys(item, {"source_type", "evidence_class", "category", "stage", "note"}, "observation")
        _bounded_string(item["category"], 40, "observation category", required=True)
        _bounded_string(item["stage"], 40, "observation stage", required=True)
        _bounded_string(item["note"], 500, "observation note", required=True)
        if item["source_type"] == "automated" and item["evidence_class"] not in AUTOMATED_CLASSES:
            raise PilotError("automated evidence cannot be promoted to human evidence")
        if item["source_type"] in {"observed", "participant_reported"} and item["evidence_class"] not in HUMAN_CLASSES:
            raise PilotError("human evidence source requires a human observation class")
        if item["source_type"] not in {"observed", "participant_reported", "automated"}:
            raise PilotError("observation source type is invalid")

    questionnaire = value["questionnaire"]
    if not isinstance(questionnaire, list) or len(questionnaire) > 20:
        raise PilotError("questionnaire is unbounded")
    for item in questionnaire:
        item = _exact_keys(item, {"question_id", "evidence_class", "rating", "response"}, "questionnaire entry")
        if not re.fullmatch(r"Q[0-9]{1,2}", item["question_id"]) or item["evidence_class"] not in HUMAN_CLASSES:
            raise PilotError("questionnaire identity or evidence class is invalid")
        _bounded_int(item["rating"], 0, 5, "questionnaire rating")
        _bounded_string(item["response"], 500, "questionnaire response")

    declarations = _exact_keys(value["declarations"], {"voluntary_participation_confirmed", "stop_at_any_time_explained", "direct_identifiers_excluded", "human_observation_entered", "non_authoritative", "single_pilot_not_certification", "automated_evidence_is_physical"}, "declarations")
    if declarations["non_authoritative"] is not True or declarations["single_pilot_not_certification"] is not True or declarations["automated_evidence_is_physical"] is not False:
        raise PilotError("pilot evidence declarations changed")
    for key in ("voluntary_participation_confirmed", "stop_at_any_time_explained", "direct_identifiers_excluded", "human_observation_entered"):
        if not isinstance(declarations[key], bool):
            raise PilotError(f"declaration {key} must be boolean")
    if allow_blank:
        if any(declarations[key] for key in ("voluntary_participation_confirmed", "stop_at_any_time_explained", "direct_identifiers_excluded", "human_observation_entered")):
            raise PilotError("blank record pre-populates human declarations")
        if observations or questionnaire or value["durations"] or route["report_hashes"]:
            raise PilotError("blank record pre-populates human evidence")
        if route != {"completion_state": "not_observed", "ending_disposition": "not_observed", "reset": "not_observed", "reconnect": "not_observed", "rematch": "not_observed", "report_export": "not_observed", "report_hashes": []}:
            raise PilotError("blank route pre-populates an observation")
    else:
        if not all(declarations[key] for key in ("voluntary_participation_confirmed", "stop_at_any_time_explained", "direct_identifiers_excluded", "human_observation_entered")):
            raise PilotError("human pilot declarations must be explicitly true")

    provenance = value["provenance"]
    if not isinstance(provenance, list) or len(provenance) > 4:
        raise PilotError("provenance is unbounded")
    for item in provenance:
        item = _exact_keys(item, {"source_file", "sha256", "normalization"}, "provenance")
        if item["source_file"] != PACKAGE_FILE or not SHA64.fullmatch(item["sha256"]) or item["normalization"] != "offline_exact_schema_v1":
            raise PilotError("provenance entry is invalid")
    if allow_blank and provenance:
        raise PilotError("blank record must not contain provenance")
    _scan_private(value)
    return value


def validate_blank_findings(value: dict[str, Any]) -> None:
    expected = {
        "schema_version": 1,
        "release": "v0.1.3",
        "candidate_source_sha": "",
        "generated_from_session_id": "",
        "findings": [],
        "declarations": {
            "single_pilot_not_certification": True,
            "no_inferred_participant_intent": True,
            "human_judgment_required": True,
        },
    }
    if value != expected:
        raise PilotError("committed findings register is not the exact blank default")


def validate_templates() -> None:
    _validate_schema_documents()
    validate_pilot_record(_read_json(BLANK_PILOT), allow_blank=True)
    validate_blank_findings(_read_json(BLANK_FINDINGS))


def safe_package_path(package_dir: Path, member: str) -> Path:
    posix = PurePosixPath(member)
    if posix.is_absolute() or ".." in posix.parts or posix.parts != (PACKAGE_FILE,):
        raise PilotError("evidence package path traversal or unknown file rejected")
    root = package_dir.resolve()
    target = (root / member).resolve()
    if target.parent != root:
        raise PilotError("evidence package member escapes its root")
    return target


def normalize(package_dir: Path, expected_identity_path: Path, output: Path) -> dict[str, Any]:
    if not package_dir.is_dir() or package_dir.is_symlink():
        raise PilotError("evidence package must be a normal directory")
    members = list(package_dir.iterdir())
    if {item.name for item in members} != {PACKAGE_FILE}:
        raise PilotError("evidence package must contain exactly PILOT_SESSION_RECORD.json")
    source = safe_package_path(package_dir, PACKAGE_FILE)
    if source.is_symlink() or not source.is_file():
        raise PilotError("evidence package file must not be a link or special file")
    if source.stat().st_size > MAX_PACKAGE_FILE_BYTES:
        raise PilotError("evidence package file exceeds 64 KiB")
    expected_identity = _validate_candidate(_read_json(expected_identity_path), allow_blank=False)
    record = validate_pilot_record(_read_json(source), allow_blank=False)
    if record["candidate"] != expected_identity:
        raise PilotError("pilot record does not match the exact frozen candidate identity")
    normalized = json.loads(json.dumps(record))
    normalized["provenance"] = [{
        "source_file": PACKAGE_FILE,
        "sha256": _sha256(source),
        "normalization": "offline_exact_schema_v1",
    }]
    validate_pilot_record(normalized, allow_blank=False)
    _write_json(output, normalized)
    return normalized


FINDING_INPUT_KEYS = {
    "category", "evidence_source", "session_id", "classification", "severity",
    "reproducibility", "confidence", "evidence_limits", "affected_platform",
    "seat_count", "stage", "steps", "expected_result", "observed_result", "notes",
    "disposition", "proposed_issue_title", "certification_limit",
}


def _validate_finding_input(item: Any, session: dict[str, Any]) -> dict[str, Any]:
    finding = _exact_keys(item, FINDING_INPUT_KEYS, "finding input")
    if finding["category"] not in CATEGORIES or finding["severity"] not in SEVERITIES:
        raise PilotError("finding category or severity is invalid")
    if finding["evidence_source"] not in {"observed", "participant_reported"}:
        raise PilotError("findings require human observed or participant-reported evidence")
    if finding["session_id"] != session["session"]["session_id"]:
        raise PilotError("finding session ID does not match normalized evidence")
    if finding["classification"] != session["session"]["facilitator_evidence_class"]:
        raise PilotError("finding evidence classification does not match the session")
    if finding["reproducibility"] not in REPRODUCIBILITY or finding["confidence"] not in {"low", "medium", "high"}:
        raise PilotError("finding reproducibility or confidence is invalid")
    if finding["affected_platform"] not in {"windows", "linux", "both", "not_applicable"}:
        raise PilotError("finding platform is invalid")
    if finding["disposition"] not in DISPOSITIONS:
        raise PilotError("finding disposition is invalid")
    _bounded_int(finding["seat_count"], 0, 8, "finding seat count")
    for key, limit, required in (("evidence_limits", 300, True), ("stage", 40, True), ("expected_result", 500, False), ("observed_result", 500, True), ("notes", 500, False), ("proposed_issue_title", 120, False)):
        _bounded_string(finding[key], limit, f"finding {key}", required)
    if not isinstance(finding["steps"], list) or not 1 <= len(finding["steps"]) <= 8:
        raise PilotError("finding steps must be a bounded non-empty list")
    for step in finding["steps"]:
        _bounded_string(step, 200, "finding step", required=True)
    if finding["disposition"] == "open_issue_required" and not finding["proposed_issue_title"].strip():
        raise PilotError("actionable finding requires a proposed issue title")
    if finding["certification_limit"] != CERTIFICATION_LIMIT:
        raise PilotError("finding certification limit changed")
    _scan_private(finding, "finding")
    return finding


def _finding_id(finding: dict[str, Any]) -> str:
    canonical = json.dumps(finding, ensure_ascii=True, separators=(",", ":"), sort_keys=True)
    return "FND-" + hashlib.sha256(canonical.encode("utf-8")).hexdigest()[:12].upper()


def generate_findings(session_path: Path, input_path: Path, output: Path) -> dict[str, Any]:
    session = validate_pilot_record(_read_json(session_path), allow_blank=False)
    raw = _read_json(input_path)
    raw = _exact_keys(raw, {"findings"}, "findings input")
    if not isinstance(raw["findings"], list) or len(raw["findings"]) > 128:
        raise PilotError("findings input is unbounded")
    findings = []
    for item in raw["findings"]:
        validated = json.loads(json.dumps(_validate_finding_input(item, session)))
        findings.append({"finding_id": _finding_id(validated), **validated})
    findings.sort(key=lambda item: item["finding_id"])
    if len({item["finding_id"] for item in findings}) != len(findings):
        raise PilotError("duplicate deterministic finding IDs")
    register = {
        "schema_version": 1,
        "release": "v0.1.3",
        "candidate_source_sha": session["candidate"]["source_sha"],
        "generated_from_session_id": session["session"]["session_id"],
        "findings": findings,
        "declarations": {
            "single_pilot_not_certification": True,
            "no_inferred_participant_intent": True,
            "human_judgment_required": True,
        },
    }
    _write_json(output, register)
    return register


def _main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    commands = parser.add_subparsers(dest="command", required=True)
    commands.add_parser("validate-templates")
    normalize_parser = commands.add_parser("normalize")
    normalize_parser.add_argument("--package-dir", type=Path, required=True)
    normalize_parser.add_argument("--expected-identity", type=Path, required=True)
    normalize_parser.add_argument("--output", type=Path, required=True)
    triage_parser = commands.add_parser("triage")
    triage_parser.add_argument("--session", type=Path, required=True)
    triage_parser.add_argument("--input", type=Path, required=True)
    triage_parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    try:
        if args.command == "validate-templates":
            validate_templates()
        elif args.command == "normalize":
            normalize(args.package_dir, args.expected_identity, args.output)
        else:
            generate_findings(args.session, args.input, args.output)
    except PilotError as exc:
        print(f"Pilot evidence validation failed: {exc}", file=sys.stderr)
        return 1
    print("Pilot evidence validation passed")
    return 0


if __name__ == "__main__":
    raise SystemExit(_main())
