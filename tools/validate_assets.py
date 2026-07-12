"""Static asset-policy validation used locally and in repository checks."""

from __future__ import annotations

import json
import pathlib
import subprocess
import sys

ROOT = pathlib.Path(__file__).resolve().parents[1]
LFS_EXTENSIONS = {
    ".psd", ".kra", ".blend", ".aseprite", ".xcf",
    ".wav", ".flac", ".aiff", ".aif", ".mp4", ".mov",
}
RUNTIME_BINARY_EXTENSIONS = {".png", ".webp", ".svg", ".ogg", ".mp3", ".glb"}
NORMAL_GIT_BINARY_LIMIT = 20 * 1024 * 1024
REQUIRED_DIRECTORIES = (
    "game/assets",
    "art/source",
    "art/exports",
    "art/licenses",
    "art/placeholders",
    "audio/source",
    "audio/exports",
    "audio/licenses",
)


def lfs_filter(path: pathlib.Path) -> str:
    result = subprocess.run(
        ["git", "check-attr", "filter", "--", path.name],
        cwd=ROOT,
        capture_output=True,
        check=True,
        text=True,
    )
    return result.stdout.rsplit(":", 1)[-1].strip()


def main() -> int:
    failures: list[str] = []
    for relative in REQUIRED_DIRECTORIES:
        if not (ROOT / relative).is_dir():
            failures.append(f"Missing asset directory: {relative}")

    for extension in sorted(LFS_EXTENSIONS):
        if lfs_filter(pathlib.Path(f"verify{extension}")) != "lfs":
            failures.append(f"Git LFS is not active for {extension}")

    provenance_path = ROOT / "art" / "provenance.json"
    try:
        entries = json.loads(provenance_path.read_text(encoding="utf-8"))["assets"]
    except (OSError, KeyError, json.JSONDecodeError) as error:
        failures.append(f"Invalid art/provenance.json: {error}")
        entries = []

    registered = {entry.get("runtime_path") for entry in entries}
    for entry in entries:
        missing = [
            field for field in ("id", "runtime_path", "source", "creator", "license", "derivation")
            if not entry.get(field)
        ]
        if missing:
            failures.append(f"Provenance entry is missing {', '.join(missing)}: {entry}")

    for path in (ROOT / "game" / "assets").rglob("*"):
        if not path.is_file() or path.suffix.lower() not in RUNTIME_BINARY_EXTENSIONS:
            continue
        relative = path.relative_to(ROOT).as_posix()
        if relative not in registered:
            failures.append(f"Runtime asset lacks provenance: {relative}")
        if path.stat().st_size > NORMAL_GIT_BINARY_LIMIT and lfs_filter(path) != "lfs":
            failures.append(f"Normal-Git runtime binary exceeds 20 MiB: {relative}")

    if failures:
        print("\n".join(failures), file=sys.stderr)
        return 1
    print(f"Asset policy valid: {len(LFS_EXTENSIONS)} LFS patterns, {len(entries)} provenance entries")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
