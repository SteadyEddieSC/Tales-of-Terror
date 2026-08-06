#!/usr/bin/env python3
"""Dependency-free Terror Turn repository integrity validator."""
from __future__ import annotations

import argparse
import csv
import hashlib
import json
import re
import struct
from collections import defaultdict
from dataclasses import asdict, dataclass
from pathlib import Path
from typing import Iterable, Sequence

ROOT = Path(__file__).resolve().parents[1]
CONFIG = ROOT / "quality" / "quality_config.json"
BLOCK = "blocking"
ADVISORY = "advisory"
GODOT_SUFFIXES = {".tscn", ".tres", ".gd", ".gdshader", ".godot"}
TEXTURES = {".png", ".jpg", ".jpeg", ".webp", ".svg"}
AUDIO = {".wav", ".ogg", ".mp3", ".flac"}
ASSETS = TEXTURES | AUDIO | {".ttf", ".otf"}
RES_REF = re.compile(r"res://[^\s\"'\)\],}]+")
EXT_REF = re.compile(r'^\[ext_resource\s+path="([^"]+)"[^\]]*\s+id="([^"]+)"\]$', re.M)
UID = re.compile(r"uid://[a-z0-9]+")
USES = re.compile(r"^\s*-?\s*uses:\s*([^\s#]+)", re.M)
PINNED = re.compile(r"^[^@\s]+@[0-9a-f]{40}$")
DOCKER_PIN = re.compile(r"^docker://[^@\s]+@sha256:[0-9a-f]{64}$")
ACTION = re.compile(r"^([A-Za-z0-9_]+)=\{", re.M)


@dataclass(frozen=True)
class Finding:
    severity: str
    code: str
    path: str
    message: str


class Validator:
    def __init__(self, root: Path = ROOT, config_path: Path = CONFIG) -> None:
        self.root = root.resolve()
        self.config = json.loads(config_path.read_text(encoding="utf-8"))
        self.findings: list[Finding] = []
        self.metrics: dict[str, object] = {}

    def add(self, severity: str, code: str, path: Path | str, message: str) -> None:
        if isinstance(path, Path):
            try:
                display = path.resolve().relative_to(self.root).as_posix()
            except ValueError:
                display = path.as_posix()
        else:
            display = path
        self.findings.append(Finding(severity, code, display, message))

    def run(self, scopes: Sequence[str]) -> dict[str, object]:
        selected = set(scopes)
        if "all" in selected:
            selected = {"config", "references", "assets", "data", "workflows", "save-fixtures"}
        if "config" in selected:
            self.validate_project_config()
            self.validate_exports()
        if "references" in selected:
            self.validate_references()
            self.validate_uids()
        if "assets" in selected:
            self.validate_assets()
        if "data" in selected:
            self.validate_data()
        if "workflows" in selected:
            self.validate_workflows()
        if "save-fixtures" in selected:
            self.validate_save_fixtures()
        ordered = sorted(self.findings, key=lambda item: (item.severity, item.code, item.path, item.message))
        blocking = sum(item.severity == BLOCK for item in ordered)
        return {
            "schema_version": 1,
            "status": "failed" if blocking else "passed",
            "blocking_count": blocking,
            "advisory_count": sum(item.severity == ADVISORY for item in ordered),
            "metrics": self.metrics,
            "findings": [asdict(item) for item in ordered],
        }

    def validate_project_config(self) -> None:
        path = self.root / "game" / "project.godot"
        if not path.is_file():
            self.add(BLOCK, "CONFIG_PROJECT_MISSING", path, "game/project.godot is required")
            return
        text = path.read_text(encoding="utf-8")
        required = {
            "CONFIG_ENGINE_FEATURE": f'"{self.config["engine"]["feature_family"]}"',
            "CONFIG_RENDERER": f'renderer/rendering_method="{self.config["engine"]["renderer"]}"',
            "CONFIG_MAIN_SCENE": 'run/main_scene="res://src/main/Main.tscn"',
        }
        for code, fragment in required.items():
            if fragment not in text:
                self.add(BLOCK, code, path, f"required project setting is missing: {fragment}")
        section = self._section(text, "input")
        actions = set(ACTION.findall(section))
        self.metrics["input_action_count"] = len(actions)
        for name in self.config["required_input_actions"]:
            if name not in actions:
                self.add(BLOCK, "INPUT_REQUIRED_MISSING", path, f"missing input action '{name}'")
                continue
            line = self._action_line(section, name)
            if '"events": []' in line:
                self.add(BLOCK, "INPUT_REQUIRED_EMPTY", path, f"input action '{name}' is empty")
            if name in self.config["controller_required_actions"] and "InputEventJoypad" not in line:
                self.add(BLOCK, "INPUT_CONTROLLER_MISSING", path, f"'{name}' lacks controller input")
        names = re.findall(r"^([A-Za-z0-9_]+)=", self._section(text, "autoload"), re.M)
        if len(names) != len(set(names)):
            self.add(BLOCK, "CONFIG_AUTOLOAD_DUPLICATE", path, "duplicate autoload singleton names")

    def validate_exports(self) -> None:
        path = self.root / "game" / "export_presets.cfg"
        if not path.is_file():
            self.add(BLOCK, "EXPORT_PRESETS_MISSING", path, "export presets are required")
            return
        text = path.read_text(encoding="utf-8")
        for name in ("Internal Windows x86_64", "Internal Linux x86_64"):
            if f'name="{name}"' not in text:
                self.add(BLOCK, "EXPORT_REQUIRED_PRESET", path, f"missing preset '{name}'")
        for exclusion in ("tests/*", "addons/*"):
            if exclusion not in text:
                self.add(BLOCK, "EXPORT_TEST_RESOURCE_LEAK", path, f"missing exclusion '{exclusion}'")
        if 'custom_features="internal_playtest"' not in text:
            self.add(BLOCK, "EXPORT_FEATURE_CLASSIFICATION", path, "internal_playtest feature is required")
        if "codesign/enable=true" in text:
            self.add(BLOCK, "EXPORT_UNAPPROVED_SIGNING", path, "signing requires a separately approved process")

    def validate_references(self) -> None:
        generated = set(self.config["generated_resource_allowlist"])
        scenes: list[str] = []
        scanned = 0
        for path in self._files(self.root / "game", GODOT_SUFFIXES):
            rel = path.relative_to(self.root).as_posix()
            if rel.startswith(("game/addons/", "game/.godot/")):
                continue
            scanned += 1
            if path.suffix == ".tscn" and not rel.startswith("game/tests/"):
                scenes.append("res://" + path.relative_to(self.root / "game").as_posix())
            text = path.read_text(encoding="utf-8", errors="replace")
            if path.suffix in {".tscn", ".tres"}:
                ids: set[str] = set()
                for ref, resource_id in EXT_REF.findall(text):
                    if resource_id in ids:
                        self.add(BLOCK, "RESOURCE_DUPLICATE_ID", path, f"duplicate ext_resource id '{resource_id}'")
                    ids.add(resource_id)
                    self._check_res_path(path, ref, generated, BLOCK)
            severity = BLOCK if path.suffix in {".tscn", ".tres", ".godot"} else ADVISORY
            for ref in sorted(set(RES_REF.findall(text))):
                self._check_res_path(path, ref.rstrip(".,;:"), generated, severity)
        self.metrics["godot_text_files_scanned"] = scanned
        self.metrics["production_scenes"] = sorted(scenes)
        if not scenes:
            self.add(BLOCK, "SCENE_MANIFEST_EMPTY", self.root / "game", "no production scenes discovered")

    def _check_res_path(self, owner: Path, ref: str, generated: set[str], severity: str) -> None:
        if ref in generated:
            return
        relative = ref.removeprefix("res://")
        if relative.startswith("../") or "/../" in relative:
            self.add(BLOCK, "RESOURCE_OUTSIDE_PROJECT", owner, f"reference escapes project: {ref}")
            return
        target = self.root / "game" / relative
        if target.exists():
            return
        case_match = self._case_match(target)
        if case_match:
            actual = case_match.relative_to(self.root / "game").as_posix()
            self.add(BLOCK, "RESOURCE_CASE_MISMATCH", owner, f"{ref} differs from {actual}")
        else:
            self.add(severity, "RESOURCE_MISSING", owner, f"missing path: {ref}")

    def validate_uids(self) -> None:
        owners: defaultdict[str, list[str]] = defaultdict(list)
        for path in (self.root / "game").rglob("*.uid"):
            rel = path.relative_to(self.root).as_posix()
            if rel.startswith(("game/addons/", "game/.godot/")):
                continue
            value = path.read_text(encoding="utf-8", errors="replace").strip()
            if not UID.fullmatch(value):
                self.add(BLOCK, "UID_INVALID", path, f"invalid UID '{value}'")
            owners[value].append(rel)
        for value, paths in owners.items():
            if value and len(paths) > 1:
                self.add(BLOCK, "UID_DUPLICATE", paths[0], f"{value} is shared by {', '.join(paths)}")
        self.metrics["first_party_uid_count"] = sum(map(len, owners.values()))

    def validate_assets(self) -> None:
        budgets = self.config["asset_budgets"]
        totals = {"texture": 0, "audio": 0, "other": 0}
        hashes: defaultdict[str, list[str]] = defaultdict(list)
        folded: defaultdict[str, list[str]] = defaultdict(list)
        count = 0
        for path in self._files(self.root, ASSETS):
            if any(part in {".git", ".godot", "node_modules", "dist", "builds"} for part in path.parts):
                continue
            rel = path.relative_to(self.root).as_posix()
            count += 1
            hashes[self._sha256(path)].append(rel)
            folded[rel.casefold()].append(rel)
            size = path.stat().st_size
            if rel.startswith(("art/source/", "audio/source/")) and path.read_bytes()[:50].startswith(
                b"version https://git-lfs.github.com/spec/v1"
            ):
                continue
            suffix = path.suffix.lower()
            if suffix in TEXTURES:
                totals["texture"] += size
                self._budget(path, size, budgets["max_texture_bytes"], "ASSET_TEXTURE_SIZE")
                dimensions = self._dimensions(path)
                if dimensions and max(dimensions) > budgets["max_texture_dimension"]:
                    self.add(BLOCK, "ASSET_TEXTURE_DIMENSION", path, f"{dimensions} exceeds dimension budget")
                if suffix in {".png", ".jpg", ".jpeg"} and dimensions is None:
                    self.add(BLOCK, "ASSET_TEXTURE_HEADER", path, "invalid texture header")
            elif suffix in AUDIO:
                totals["audio"] += size
                self._budget(path, size, budgets["max_audio_bytes"], "ASSET_AUDIO_SIZE")
                if not self._audio_header(path):
                    self.add(BLOCK, "ASSET_AUDIO_HEADER", path, f"header does not match {suffix}")
            else:
                totals["other"] += size
                self._budget(path, size, budgets["max_other_asset_bytes"], "ASSET_OTHER_SIZE")
            if not rel.startswith("game/addons/") and (" " in path.name or any(ch.isupper() for ch in path.name)):
                self.add(ADVISORY, "ASSET_FILENAME_POLICY", path, "prefer lowercase snake_case")
        if totals["texture"] > budgets["max_total_texture_bytes"]:
            self.add(BLOCK, "ASSET_TEXTURE_TOTAL", "game/assets", "total texture budget exceeded")
        if totals["audio"] > budgets["max_total_audio_bytes"]:
            self.add(BLOCK, "ASSET_AUDIO_TOTAL", "game/assets", "total audio budget exceeded")
        for paths in folded.values():
            if len(paths) > 1:
                self.add(BLOCK, "ASSET_CASE_COLLISION", paths[0], ", ".join(paths))
        for digest, paths in hashes.items():
            if len(paths) > 1:
                self.add(ADVISORY, "ASSET_DUPLICATE_HASH", paths[0], f"{digest[:12]}: {', '.join(paths)}")
        self.metrics["asset_count"] = count
        self.metrics["asset_bytes"] = totals

    def validate_data(self) -> None:
        json_count = 0
        csv_count = 0
        for path in self._files(self.root, {".json", ".csv"}):
            if any(part in {".git", ".godot", "node_modules", "dist", "builds"} for part in path.parts):
                continue
            try:
                if path.suffix == ".json":
                    json_count += 1
                    duplicate_keys: list[str] = []

                    def collect_pairs(pairs: list[tuple[str, object]]) -> dict[str, object]:
                        result: dict[str, object] = {}
                        for key, value in pairs:
                            if key in result:
                                duplicate_keys.append(key)
                            result[key] = value
                        return result

                    data = json.loads(path.read_text(encoding="utf-8"), object_pairs_hook=collect_pairs)
                    for key in sorted(set(duplicate_keys)):
                        self.add(BLOCK, "DATA_JSON_DUPLICATE_KEY", path, f"duplicate key '{key}'")
                    if "localization" in path.name.lower() and isinstance(data, dict):
                        entries = data.get("entries", data)
                        if not isinstance(entries, dict):
                            self.add(BLOCK, "LOCALIZATION_ENTRIES_INVALID", path, "localization entries must be an object")
                        else:
                            for key, value in entries.items():
                                if not isinstance(key, str) or not key or not isinstance(value, str):
                                    self.add(BLOCK, "LOCALIZATION_ENTRY_INVALID", path, f"invalid entry '{key}'")
                                elif value.count("{") != value.count("}"):
                                    self.add(
                                        BLOCK,
                                        "LOCALIZATION_PLACEHOLDER_INVALID",
                                        path,
                                        f"unbalanced placeholder braces in '{key}'",
                                    )
                else:
                    csv_count += 1
                    with path.open("r", encoding="utf-8", newline="") as handle:
                        rows = list(csv.reader(handle))
                    if rows and len({len(row) for row in rows}) != 1:
                        self.add(BLOCK, "DATA_CSV_RAGGED", path, "inconsistent CSV field counts")
            except (OSError, UnicodeError, json.JSONDecodeError, csv.Error) as exc:
                self.add(BLOCK, "DATA_PARSE_INVALID", path, str(exc))
        self.metrics.update(json_count=json_count, csv_count=csv_count)

    def validate_workflows(self) -> None:
        count = 0
        unpinned = 0
        for path in sorted((self.root / ".github" / "workflows").glob("*.y*ml")):
            count += 1
            text = path.read_text(encoding="utf-8")
            if "pull_request_target:" in text:
                self.add(BLOCK, "WORKFLOW_DANGEROUS_TRIGGER", path, "pull_request_target is prohibited")
            if re.search(r"^permissions:\s*$", text, re.M) is None:
                self.add(BLOCK, "WORKFLOW_PERMISSIONS_MISSING", path, "explicit permissions are required")
            for action in USES.findall(text):
                if action.startswith("./"):
                    continue
                if not PINNED.fullmatch(action) and not DOCKER_PIN.fullmatch(action):
                    unpinned += 1
                    self.add(BLOCK, "WORKFLOW_ACTION_UNPINNED", path, f"not immutable: {action}")
        self.metrics.update(workflow_count=count, workflow_unpinned_actions=unpinned)

    def validate_save_fixtures(self) -> None:
        fixture_dir = self.root / "quality" / "fixtures"
        expected = {
            "coordinator_snapshot_v2.json": 2,
            "coordinator_snapshot_future_v99.json": 99,
            "coordinator_snapshot_unknown_field.json": 2,
        }
        for name, version in expected.items():
            path = fixture_dir / name
            if not path.is_file():
                self.add(BLOCK, "SAVE_FIXTURE_MISSING", path, "required fixture is missing")
                continue
            try:
                data = json.loads(path.read_text(encoding="utf-8"))
            except json.JSONDecodeError as exc:
                self.add(BLOCK, "SAVE_FIXTURE_INVALID", path, str(exc))
                continue
            if data.get("snapshot_version") != version:
                self.add(BLOCK, "SAVE_FIXTURE_VERSION", path, f"expected version {version}")
            if data.get("fixture_classification") != "synthetic_test_only":
                self.add(BLOCK, "SAVE_FIXTURE_CLASSIFICATION", path, "fixture is not synthetic_test_only")
        truncated = fixture_dir / "coordinator_snapshot_truncated.fixture"
        if not truncated.is_file() or truncated.read_text(encoding="utf-8").strip().endswith("}"):
            self.add(BLOCK, "SAVE_TRUNCATED_FIXTURE", truncated, "deliberately truncated fixture is required")

    @staticmethod
    def _section(text: str, name: str) -> str:
        match = re.search(rf"^\[{re.escape(name)}\]\s*$", text, re.M)
        if not match:
            return ""
        tail = text[match.end() :]
        end = re.search(r"^\[[^\]]+\]\s*$", tail, re.M)
        return tail[: end.start()] if end else tail

    @staticmethod
    def _action_line(section: str, name: str) -> str:
        match = re.search(rf"^{re.escape(name)}=(.*)$", section, re.M)
        return match.group(1) if match else ""

    @staticmethod
    def _files(root: Path, suffixes: set[str]) -> Iterable[Path]:
        if not root.exists():
            return []
        return (path for path in root.rglob("*") if path.is_file() and path.suffix.lower() in suffixes)

    def _budget(self, path: Path, size: int, limit: int, code: str) -> None:
        if size > limit:
            self.add(BLOCK, code, path, f"{size} bytes exceeds {limit}")

    @staticmethod
    def _sha256(path: Path) -> str:
        digest = hashlib.sha256()
        with path.open("rb") as handle:
            for chunk in iter(lambda: handle.read(1024 * 1024), b""):
                digest.update(chunk)
        return digest.hexdigest()

    @staticmethod
    def _dimensions(path: Path) -> tuple[int, int] | None:
        data = path.read_bytes()[:32]
        suffix = path.suffix.lower()
        if suffix == ".png" and data[:8] == b"\x89PNG\r\n\x1a\n" and len(data) >= 24:
            return struct.unpack(">II", data[16:24])
        if suffix in {".webp", ".svg"}:
            return (1, 1)
        if suffix in {".jpg", ".jpeg"} and data[:2] == b"\xff\xd8":
            return (1, 1)
        return None

    @staticmethod
    def _audio_header(path: Path) -> bool:
        data = path.read_bytes()[:12]
        suffix = path.suffix.lower()
        return {
            ".wav": len(data) >= 12 and data[:4] == b"RIFF" and data[8:12] == b"WAVE",
            ".ogg": data[:4] == b"OggS",
            ".flac": data[:4] == b"fLaC",
            ".mp3": data[:3] == b"ID3" or (len(data) > 1 and data[0] == 0xFF and data[1] & 0xE0 == 0xE0),
        }.get(suffix, True)

    @staticmethod
    def _case_match(path: Path) -> Path | None:
        try:
            current = Path(path.anchor)
            for part in path.parts[1:]:
                matches = [entry for entry in current.iterdir() if entry.name.casefold() == part.casefold()]
                if len(matches) != 1:
                    return None
                current = matches[0]
            return current
        except OSError:
            return None


def write_reports(report: dict[str, object], report_dir: Path) -> None:
    report_dir.mkdir(parents=True, exist_ok=True)
    (report_dir / "quality-report.json").write_text(
        json.dumps(report, indent=2, sort_keys=True) + "\n",
        encoding="utf-8",
    )
    lines = [
        f"status={report['status']}",
        f"blocking={report['blocking_count']}",
        f"advisory={report['advisory_count']}",
    ]
    lines.extend(
        f"{item['severity']} {item['code']} {item['path']}: {item['message']}"
        for item in report["findings"]
    )
    (report_dir / "quality-report.txt").write_text("\n".join(lines) + "\n", encoding="utf-8")


def main(argv: Sequence[str] | None = None) -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "scopes",
        nargs="*",
        default=["all"],
        choices=["all", "config", "references", "assets", "data", "workflows", "save-fixtures"],
    )
    parser.add_argument("--report-dir", type=Path, default=ROOT / "artifacts" / "quality")
    args = parser.parse_args(argv)
    report = Validator().run(args.scopes)
    write_reports(report, args.report_dir)
    print(json.dumps(report, indent=2, sort_keys=True))
    return 1 if report["blocking_count"] else 0


if __name__ == "__main__":
    raise SystemExit(main())
