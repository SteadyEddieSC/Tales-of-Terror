#!/usr/bin/env python3
"""Assemble and validate bounded v0.1.5 internal playtest bundles."""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import re
import shutil
import stat
import sys
import zipfile
from datetime import datetime, timezone
from pathlib import Path, PurePosixPath
from typing import Any

import tale_package
import tale_catalog


ROOT = Path(__file__).resolve().parents[1]
SPEC_PATH = ROOT / "packaging" / "portable" / "bundle_spec.json"
PILOT_RECORD_PATH = ROOT / "docs" / "playtests" / "v0.1.3-pilot-session-blank.json"
EXPORT_PRESETS = ROOT / "game" / "export_presets.cfg"
BUILD_IDENTITY_PATH = ROOT / "game" / "build_identity.generated.json"
MANIFEST_KEYS = {
    "schema_version",
    "release",
    "source_commit",
    "platform",
    "architecture",
    "godot_version",
    "renderer",
    "logical_viewport",
    "scenario",
    "tale_catalog",
    "tale_package",
    "report_schema_version",
    "build_timestamp_utc",
    "timestamp_classification",
    "runtime_content",
    "bundle_content",
    "bundle_files",
    "working_title_status",
    "distribution_classification",
}
FILE_KEYS = {"path", "size", "sha256"}
PRIVATE_PATTERNS = (
    re.compile(r"[A-Za-z]:[\\/]Users[\\/]", re.IGNORECASE),
    re.compile(r"/(?:home|Users)/[^/\s]+/"),
    re.compile(r'"(?:username|machine_name|repository_path|token|room_secret|ip_address|device_id|report_contents)"\s*:', re.IGNORECASE),
)
NETWORK_TOKENS = (
    "curl ",
    "wget ",
    "invoke-webrequest",
    "http://",
    "https://",
    "powershell",
    "start-process",
)
REPORT_LOCATION_TOKENS = (
    r"%APPDATA%\Godot\app_userdata\Terror Turn\playtest_exports",
    "$XDG_DATA_HOME/godot/app_userdata/Terror Turn/playtest_exports",
    "~/.local/share/godot/app_userdata/Terror Turn/playtest_exports",
)
CONCRETE_PRIVATE_PATH_PATTERNS = (
    re.compile(r"[A-Za-z]:[\\/]Users[\\/][^<%\\/\s]+[\\/]", re.IGNORECASE),
    re.compile(r"/(?:home|Users)/[^<$/~\s]+/"),
    re.compile(r"Documents[\\/]Codex[\\/]Tales-of-Terror", re.IGNORECASE),
)
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


class BundleError(RuntimeError):
    """A bounded bundle input or output failed validation."""


def _read_json(path: Path) -> dict[str, Any]:
    value = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(value, dict):
        raise BundleError(f"expected JSON object: {path}")
    return value


def _sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for block in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def _record(path: Path, relative: str) -> dict[str, Any]:
    return {"path": relative, "size": path.stat().st_size, "sha256": _sha256(path)}


def _content_digest(records: list[dict[str, Any]]) -> str:
    canonical = json.dumps(records, ensure_ascii=True, separators=(",", ":"), sort_keys=True)
    return hashlib.sha256(canonical.encode("utf-8")).hexdigest()


def _iso_timestamp(value: str | None) -> str:
    if value:
        try:
            parsed = datetime.fromisoformat(value.replace("Z", "+00:00"))
        except ValueError as exc:
            raise BundleError("build timestamp must be ISO-8601") from exc
        if parsed.tzinfo is None:
            raise BundleError("build timestamp must include a timezone")
        return parsed.astimezone(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
    return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def _validate_source_commit(value: str) -> None:
    if not re.fullmatch(r"[0-9a-f]{40}", value):
        raise BundleError("source commit must be exactly 40 lowercase hexadecimal characters")


def _spec() -> dict[str, Any]:
    spec = _read_json(SPEC_PATH)
    if set(spec) != {
        "schema_version",
        "release",
        "bundle_prefix",
        "platforms",
        "common_files",
        "forbidden_path_parts",
        "forbidden_extensions",
    }:
        raise BundleError("bundle specification keys changed")
    if spec["schema_version"] != 1 or spec["release"] != "v0.1.5":
        raise BundleError("unsupported bundle specification")
    if set(spec["platforms"]) != {"windows", "linux"}:
        raise BundleError("bundle platforms must be exactly Windows and Linux")
    return spec


def write_build_identity(platform: str, source_commit: str) -> Path:
    spec = _spec()
    _validate_source_commit(source_commit)
    target = spec["platforms"].get(platform)
    if not isinstance(target, dict):
        raise BundleError(f"unsupported platform: {platform}")
    value = {
        "schema_version": 1,
        "release": spec["release"],
        "source_commit": source_commit,
        "platform": platform,
        "architecture": target["architecture"],
        "classification": "internal_playtest",
    }
    BUILD_IDENTITY_PATH.write_text(
        json.dumps(value, indent=2, sort_keys=True) + "\n", encoding="utf-8"
    )
    return BUILD_IDENTITY_PATH


def _tale_package_identity() -> dict[str, Any]:
    package, diagnostics = tale_package.validate_file(tale_package.DEFAULT_PACKAGE)
    if diagnostics:
        raise BundleError(f"Tale package is invalid: {diagnostics[0]}")
    return {
        "kind": package["package_kind"],
        "schema_version": package["schema_version"],
        "id": package["tale_id"],
        "version": package["package_version"],
        "sha256": tale_package.package_digest(package),
    }


def _tale_catalog_identity() -> dict[str, Any]:
    catalog, diagnostics = tale_catalog.validate_file(tale_catalog.DEFAULT_CATALOG)
    if diagnostics:
        raise BundleError(f"Tale catalog is invalid: {diagnostics[0]}")
    return {
        "kind": catalog["catalog_kind"],
        "schema_version": catalog["schema_version"],
        "version": catalog["catalog_version"],
        "default_tale_id": catalog["default_tale_id"],
        "entry_count": len(catalog["entries"]),
        "sha256": tale_catalog.catalog_digest(catalog),
    }


def expected_files(platform: str) -> set[str]:
    spec = _spec()
    target = spec["platforms"][platform]
    return {
        target["native_executable"],
        target["launcher_name"],
        *spec["common_files"].keys(),
        "build_manifest.json",
    }


def _copy_payload(platform: str, binary: Path, bundle_dir: Path) -> list[str]:
    spec = _spec()
    target = spec["platforms"][platform]
    if not binary.is_file():
        raise BundleError(f"required exported binary is missing: {binary}")
    native_name = target["native_executable"]
    shutil.copy2(binary, bundle_dir / native_name)
    launcher_source = ROOT / target["launcher_source"]
    shutil.copy2(launcher_source, bundle_dir / target["launcher_name"])
    copied = [native_name, target["launcher_name"]]
    for destination, source in spec["common_files"].items():
        source_path = ROOT / source
        if not source_path.is_file():
            raise BundleError(f"required bundle document is missing: {source}")
        destination_path = bundle_dir / PurePosixPath(destination)
        destination_path.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(source_path, destination_path)
        copied.append(destination)
    if platform == "linux":
        for relative in (native_name, target["launcher_name"]):
            path = bundle_dir / relative
            path.chmod(path.stat().st_mode | stat.S_IXUSR | stat.S_IXGRP | stat.S_IXOTH)
    return sorted(copied)


def assemble(
    platform: str,
    source_commit: str,
    timestamp: str | None,
    output_root: Path,
    exported_binary: Path | None,
) -> tuple[Path, Path, Path]:
    spec = _spec()
    _validate_source_commit(source_commit)
    if platform not in spec["platforms"]:
        raise BundleError(f"unsupported platform: {platform}")
    target = spec["platforms"][platform]
    binary = exported_binary or ROOT / target["exported_binary"]
    bundle_name = f"{spec['bundle_prefix']}-{spec['release']}-{platform}-{target['architecture']}"
    bundle_dir = output_root / "bundles" / bundle_name
    archive = output_root / "artifacts" / f"{bundle_name}.zip"
    checksum = archive.with_suffix(".zip.sha256")
    for path in (bundle_dir, archive, checksum):
        if path.exists():
            raise BundleError(f"refusing to overwrite versioned output: {path}")
    bundle_dir.mkdir(parents=True)
    copied = _copy_payload(platform, binary.resolve(), bundle_dir)
    records = [_record(bundle_dir / relative, relative) for relative in copied]
    records.sort(key=lambda item: item["path"])
    runtime_names = {target["native_executable"]}
    runtime_records = [item for item in records if item["path"] in runtime_names]
    manifest = {
        "schema_version": 1,
        "release": spec["release"],
        "source_commit": source_commit,
        "platform": platform,
        "architecture": target["architecture"],
        "godot_version": "4.7.1-stable",
        "renderer": "gl_compatibility",
        "logical_viewport": {"width": 960, "height": 540},
        "scenario": {"id": "lantern_house_vertical_slice", "version": 1},
        "tale_catalog": _tale_catalog_identity(),
        "tale_package": _tale_package_identity(),
        "report_schema_version": 2,
        "build_timestamp_utc": _iso_timestamp(timestamp),
        "timestamp_classification": "non_deterministic_metadata_excluded_from_content_identity",
        "runtime_content": {
            "algorithm": "sha256",
            "digest": _content_digest(runtime_records),
            "files": runtime_records,
        },
        "bundle_content": {
            "algorithm": "sha256",
            "digest": _content_digest(records),
            "manifest_excluded_to_avoid_self_reference": True,
        },
        "bundle_files": records,
        "working_title_status": "provisional_pending_issue_7",
        "distribution_classification": "internal_playtest_not_public_release",
    }
    (bundle_dir / "build_manifest.json").write_text(
        json.dumps(manifest, indent=2, sort_keys=True) + "\n", encoding="utf-8"
    )
    validate_bundle(bundle_dir, platform)
    archive.parent.mkdir(parents=True, exist_ok=True)
    with zipfile.ZipFile(archive, "x", compression=zipfile.ZIP_DEFLATED, compresslevel=9) as output:
        for path in sorted(bundle_dir.rglob("*")):
            if path.is_file():
                relative = path.relative_to(bundle_dir).as_posix()
                info = zipfile.ZipInfo(f"{bundle_name}/{relative}", date_time=(1980, 1, 1, 0, 0, 0))
                info.compress_type = zipfile.ZIP_DEFLATED
                info.external_attr = (path.stat().st_mode & 0xFFFF) << 16
                output.writestr(info, path.read_bytes(), compress_type=zipfile.ZIP_DEFLATED, compresslevel=9)
    checksum.write_text(f"{_sha256(archive)}  {archive.name}\n", encoding="ascii")
    validate_archive(archive, bundle_dir)
    return bundle_dir, archive, checksum


def validate_manifest(manifest: dict[str, Any], bundle_dir: Path) -> None:
    if set(manifest) != MANIFEST_KEYS:
        raise BundleError("build manifest exact root keys changed")
    if manifest["schema_version"] != 1 or manifest["release"] != "v0.1.5":
        raise BundleError("unsupported build manifest version")
    _validate_source_commit(manifest["source_commit"])
    if manifest["platform"] not in {"windows", "linux"}:
        raise BundleError("invalid manifest platform")
    if manifest["architecture"] != "x86_64":
        raise BundleError("invalid manifest architecture")
    if manifest["godot_version"] != "4.7.1-stable" or manifest["renderer"] != "gl_compatibility":
        raise BundleError("manifest engine or renderer changed")
    if manifest["logical_viewport"] != {"width": 960, "height": 540}:
        raise BundleError("manifest logical viewport changed")
    if manifest["scenario"] != {"id": "lantern_house_vertical_slice", "version": 1}:
        raise BundleError("manifest scenario changed")
    if manifest["tale_catalog"] != _tale_catalog_identity():
        raise BundleError("manifest Tale catalog identity changed")
    if manifest["tale_package"] != _tale_package_identity():
        raise BundleError("manifest Tale package identity changed")
    if manifest["report_schema_version"] != 2:
        raise BundleError("manifest report schema changed")
    if len(manifest["build_timestamp_utc"]) > 40:
        raise BundleError("manifest timestamp is unbounded")
    if manifest["timestamp_classification"] != "non_deterministic_metadata_excluded_from_content_identity":
        raise BundleError("manifest timestamp classification changed")
    serialized = json.dumps(manifest, ensure_ascii=True, sort_keys=True)
    for pattern in PRIVATE_PATTERNS:
        if pattern.search(serialized):
            raise BundleError("manifest contains a forbidden private-data pattern")
    records = manifest["bundle_files"]
    if not isinstance(records, list) or not records or len(records) > 32:
        raise BundleError("manifest bundle inventory is missing or unbounded")
    if any(set(item) != FILE_KEYS for item in records):
        raise BundleError("manifest file record keys changed")
    sorted_records = sorted(records, key=lambda item: item["path"])
    if records != sorted_records or len({item["path"] for item in records}) != len(records):
        raise BundleError("manifest file inventory must be sorted and unique")
    for item in records:
        path = bundle_dir / PurePosixPath(item["path"])
        if not path.is_file() or _record(path, item["path"]) != item:
            raise BundleError(f"manifest hash or size mismatch: {item['path']}")
    if manifest["bundle_content"] != {
        "algorithm": "sha256",
        "digest": _content_digest(records),
        "manifest_excluded_to_avoid_self_reference": True,
    }:
        raise BundleError("deterministic bundle content identity mismatch")
    runtime = manifest["runtime_content"]
    if set(runtime) != {"algorithm", "digest", "files"} or runtime["algorithm"] != "sha256":
        raise BundleError("runtime content identity keys changed")
    if runtime["digest"] != _content_digest(runtime["files"]):
        raise BundleError("deterministic runtime content identity mismatch")
    for item in runtime["files"]:
        if item not in records:
            raise BundleError("runtime content file is outside bundle inventory")


def validate_bundle(bundle_dir: Path, platform: str | None = None) -> dict[str, Any]:
    manifest_path = bundle_dir / "build_manifest.json"
    if not manifest_path.is_file():
        raise BundleError("bundle is missing build_manifest.json")
    manifest = _read_json(manifest_path)
    platform = platform or manifest.get("platform")
    if platform not in {"windows", "linux"}:
        raise BundleError("bundle platform is invalid")
    actual = {path.relative_to(bundle_dir).as_posix() for path in bundle_dir.rglob("*") if path.is_file()}
    expected = expected_files(platform)
    if actual != expected:
        raise BundleError(f"bundle allowlist mismatch: missing={sorted(expected-actual)} extra={sorted(actual-expected)}")
    spec = _spec()
    for relative in actual:
        path = PurePosixPath(relative)
        if any(part in spec["forbidden_path_parts"] for part in path.parts):
            raise BundleError(f"bundle denylist path detected: {relative}")
        if path.suffix.lower() in spec["forbidden_extensions"]:
            raise BundleError(f"bundle denylist extension detected: {relative}")
    validate_manifest(manifest, bundle_dir)
    return manifest


def validate_archive(archive: Path, bundle_dir: Path) -> None:
    bundle_name = bundle_dir.name
    expected = {
        f"{bundle_name}/{path.relative_to(bundle_dir).as_posix()}"
        for path in bundle_dir.rglob("*")
        if path.is_file()
    }
    with zipfile.ZipFile(archive) as source:
        actual = {name for name in source.namelist() if not name.endswith("/")}
        if actual != expected:
            raise BundleError("archive content differs from validated bundle")
        bad = source.testzip()
        if bad:
            raise BundleError(f"archive CRC validation failed: {bad}")


def validate_pilot_record(path: Path = PILOT_RECORD_PATH) -> dict[str, Any]:
    from pilot_evidence import validate_pilot_record as validate

    value = _read_json(path)
    try:
        validate(value, allow_blank=True)
    except RuntimeError as exc:
        raise BundleError(f"committed pilot record is invalid: {exc}") from exc
    if tuple(item.get("id") for item in value["manual_checks"]) != MANUAL_IDS:
        raise BundleError("pilot manual validation check identities changed")
    return value


def validate_repository() -> None:
    spec = _spec()
    from pilot_evidence import validate_templates

    validate_templates()
    presets = EXPORT_PRESETS.read_text(encoding="utf-8")
    required_preset_fragments = (
        'name="Internal Windows x86_64"',
        'platform="Windows Desktop"',
        'name="Internal Linux x86_64"',
        'platform="Linux/X11"',
        'binary_format/embed_pck=true',
        'export_filter="all_resources"',
        'exclude_filter=".gutconfig.json,tests/*,addons/*,src/exploration/ExplorationShowcase.tscn,src/exploration/exploration_showcase.gd"',
        'include_filter="build_identity.generated.json"',
    )
    for fragment in required_preset_fragments:
        if fragment not in presets:
            raise BundleError(f"export preset requirement missing: {fragment}")
    for platform, target in spec["platforms"].items():
        launcher = (ROOT / target["launcher_source"]).read_text(encoding="utf-8").lower()
        for token in NETWORK_TOKENS:
            if token in launcher:
                raise BundleError(f"{platform} launcher contains forbidden token: {token.strip()}")
        if target["native_executable"].lower() not in launcher:
            raise BundleError(f"{platform} launcher does not use the expected relative executable")
    for destination in ("START_HERE.md", "FACILITATOR_GUIDE.md", "PRIVACY_AND_LIMITATIONS.md"):
        source = ROOT / spec["common_files"][destination]
        text = source.read_text(encoding="utf-8")
        for token in REPORT_LOCATION_TOKENS:
            if token not in text:
                raise BundleError(f"{destination} lacks actionable report location: {token}")
        for pattern in CONCRETE_PRIVATE_PATH_PATTERNS:
            if pattern.search(text):
                raise BundleError(f"{destination} contains a concrete private path")
    project = (ROOT / "game/project.godot").read_text(encoding="utf-8")
    if 'config/name="Terror Turn"' not in project:
        raise BundleError("report guidance no longer matches the exact Godot project folder")
    identity_source = (ROOT / "game/src/build/internal_build_identity.gd").read_text(
        encoding="utf-8"
    )
    required_identity_fragments = (
        'const RELEASE: String = "v0.1.5"',
        '"INTERNAL PLAYTEST"',
        '"SOURCE CHECKOUT"',
        '"INVALID EXPORTED IDENTITY"',
        'value.platform not in ["windows", "linux"]',
        'value.architecture != "x86_64"',
        'value.classification == "internal_playtest"',
        'OS.has_feature("editor")',
        "WINDOWS_REPORT_LOCATION",
        "LINUX_REPORT_LOCATION",
        "LINUX_REPORT_FALLBACK",
    )
    for fragment in required_identity_fragments:
        if fragment not in identity_source:
            raise BundleError(f"internal identity policy fragment missing: {fragment}")
    workflow = (ROOT / ".github/workflows/portable-builds.yml").read_text(encoding="utf-8")
    for fragment in (
        r'grep -F "\"source_commit\":\"$SOURCE_SHA\""',
        '"platform":"linux"',
        '"classification":"internal_playtest"',
        '"rng_backed_state_unchanged":true',
        '"companion_projection_unchanged":true',
        '"catalog_digest":"2b478fd0d11fa075c2050409193aa06e6b9ca4dcf6efd4e4c550a9f3a5ff9db6"',
    ):
        if fragment not in workflow:
            raise BundleError(f"portable smoke exact-output assertion missing: {fragment}")
    for required in (
        ROOT / "tools" / "pilot_evidence.py",
        ROOT / "tools" / "test_pilot_evidence.py",
        ROOT / "packaging" / "pilot" / "pilot_session_schema.json",
        ROOT / "packaging" / "pilot" / "findings_register_schema.json",
    ):
        if not required.is_file():
            raise BundleError(f"pilot evidence surface is missing: {required.relative_to(ROOT)}")
    validate_pilot_record()


def _main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    subparsers = parser.add_subparsers(dest="command", required=True)
    identity = subparsers.add_parser("write-build-identity")
    identity.add_argument("--platform", choices=("windows", "linux"), required=True)
    identity.add_argument("--source-commit", required=True)
    assembly = subparsers.add_parser("assemble")
    assembly.add_argument("--platform", choices=("windows", "linux"), required=True)
    assembly.add_argument("--source-commit", required=True)
    assembly.add_argument("--timestamp")
    assembly.add_argument("--output-root", type=Path, default=ROOT / "builds")
    assembly.add_argument("--exported-binary", type=Path)
    validation = subparsers.add_parser("validate-bundle")
    validation.add_argument("bundle_dir", type=Path)
    subparsers.add_parser("validate-repository")
    subparsers.add_parser("validate-pilot-record")
    args = parser.parse_args()
    try:
        if args.command == "write-build-identity":
            print(write_build_identity(args.platform, args.source_commit))
        elif args.command == "assemble":
            bundle, archive, checksum = assemble(
                args.platform,
                args.source_commit,
                args.timestamp,
                args.output_root.resolve(),
                args.exported_binary.resolve() if args.exported_binary else None,
            )
            print(json.dumps({
                "bundle": str(bundle),
                "archive": str(archive),
                "archive_size": archive.stat().st_size,
                "archive_sha256": _sha256(archive),
                "checksum": str(checksum),
            }, sort_keys=True))
        elif args.command == "validate-bundle":
            manifest = validate_bundle(args.bundle_dir.resolve())
            print(json.dumps({
                "accepted": True,
                "platform": manifest["platform"],
                "runtime_content_digest": manifest["runtime_content"]["digest"],
                "bundle_content_digest": manifest["bundle_content"]["digest"],
            }, sort_keys=True))
        elif args.command == "validate-repository":
            validate_repository()
            print("Portable bundle repository validation passed")
        else:
            validate_pilot_record()
            print("Blank pilot record passed with all human checks not_tested")
    except (BundleError, OSError, json.JSONDecodeError, zipfile.BadZipFile) as exc:
        print(f"ERROR: {exc}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(_main())
