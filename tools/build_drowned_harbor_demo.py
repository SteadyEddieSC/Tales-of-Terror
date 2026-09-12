"""Build the owner-authorized Alpha.4 demo in an isolated generated Godot project."""
from __future__ import annotations

import argparse
import hashlib
import json
import shutil
import subprocess
import tempfile
import zipfile
from contextlib import contextmanager
from pathlib import Path
from collections.abc import Iterator

ROOT = Path(__file__).resolve().parents[1]
VERSION = 'v0.2.0-alpha.4'
TEMPLATES = {
    'windows': ('windows_release_x86_64.exe', 'Internal Windows x86_64', 'drowned_harbor_demo.exe'),
    'linux': ('linux_release.x86_64', 'Internal Linux x86_64', 'drowned_harbor_demo.x86_64'),
}
PACKAGE_METADATA = ('START_HERE.md', 'GODOT_ENGINE_LICENSE.txt', 'BUILD_IDENTITY.json')


def sha(path: Path, kind: str = 'sha256') -> str:
    with path.open('rb') as stream:
        return hashlib.file_digest(stream, kind).hexdigest()


@contextmanager
def fresh_build_directory(build: Path) -> Iterator[Path]:
    """Own only a fresh child; validate containment before recursive temp cleanup."""
    build = build.resolve()
    build.mkdir(parents=True, exist_ok=True)
    temporary = tempfile.TemporaryDirectory(prefix='demo-build-', dir=build)
    directory = Path(temporary.name).resolve()
    if directory.parent != build:
        raise ValueError('Temporary build directory must be a direct child of the build root.')
    try:
        yield directory
    finally:
        # The build tool must never recursively clean an existing project/output directory.
        if Path(temporary.name).resolve() != directory or directory.parent != build:
            raise ValueError('Temporary build directory escaped its validated cleanup boundary.')
        temporary.cleanup()


def copy_game_inputs(source: Path, stage: Path) -> None:
    """Fail rather than overlay an existing staging project with stale source files."""
    stage.mkdir(parents=True, exist_ok=False)
    for name in ('src', 'assets', 'data'):
        shutil.copytree(source / name, stage / name,
            ignore=shutil.ignore_patterns('*.import', '.godot', '__pycache__'))


def publish_bundle(source: Path, destination: Path, archive_path: Path, executable: str) -> None:
    """Publish exactly the binary and three metadata files; preserve unrelated local files."""
    names = (executable, *PACKAGE_METADATA)
    if Path(executable).name != executable:
        raise ValueError('Bundle executable must be a simple filename.')
    missing = [name for name in names if not (source / name).is_file()]
    if missing:
        raise ValueError(f'Incomplete demo output: {missing}')
    # Construct the archive before replacing the last successful stable artifact.
    temporary_archive = source / archive_path.name
    with zipfile.ZipFile(temporary_archive, 'w', compression=zipfile.ZIP_DEFLATED) as bundle:
        for name in sorted(names):
            bundle.write(source / name, name)
    destination.mkdir(parents=True, exist_ok=True)
    for name in names:
        (source / name).replace(destination / name)
    temporary_archive.replace(archive_path)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--godot', required=True, type=Path)
    parser.add_argument('--templates-archive', required=True, type=Path)
    parser.add_argument('--checksums', required=True, type=Path)
    parser.add_argument('--platform', choices=['windows', 'linux', 'both'], default='both')
    args = parser.parse_args()
    version = subprocess.check_output([str(args.godot), '--version'], text=True).strip()
    if version != '4.7.1.stable.official.a13da4feb':
        raise SystemExit('Official Godot 4.7.1-stable is required.')
    expected = next((line.split()[0] for line in args.checksums.read_text(encoding='utf-8').splitlines()
        if line.split() and line.split()[-1] == args.templates_archive.name), None)
    if not expected or sha(args.templates_archive, 'sha512') != expected:
        raise SystemExit('Official export-template checksum mismatch.')
    build = ROOT / 'builds/alpha4'
    templates = build / 'templates'
    templates.mkdir(parents=True, exist_ok=True)
    with zipfile.ZipFile(args.templates_archive) as archive:
        for filename, _, _ in TEMPLATES.values():
            source = 'templates/' + filename
            with archive.open(source) as stream, (templates / filename).open('wb') as target:
                shutil.copyfileobj(stream, target)
    with fresh_build_directory(build) as temporary:
        results, identity = build_demo(args.godot, templates, build, temporary, args.platform, version)
    (build / 'build_manifest.json').write_text(json.dumps({'identity': identity, 'builds': results}, indent=2) + '\n', encoding='utf-8')
    print(json.dumps(results, indent=2))
    return 0


def build_demo(godot: Path, templates: Path, build: Path, temporary: Path,
               selected_platform: str, version: str) -> tuple[list[dict], dict]:
    # Existing builds/alpha4/project and platform directories are never staging inputs.
    stage = temporary / 'project'
    copy_game_inputs(ROOT / 'game', stage)
    project = (ROOT / 'game/project.godot').read_text(encoding='utf-8')
    project = project.replace('run/main_scene="res://src/main/Main.tscn"',
        'run/main_scene="res://src/tales/drowned_harbor/alpha4/DemoMain.tscn"')
    project = project.replace('config/name="Terror Turn"', 'config/name="Terror Turn Drowned Harbor Demo"')
    project = project.replace('config/version="v0.1.9"', f'config/version="{VERSION}"')
    project = project.replace('enabled=PackedStringArray("res://addons/gut/plugin.cfg")', 'enabled=PackedStringArray()')
    (stage / 'project.godot').write_text(project, encoding='utf-8')
    presets = (ROOT / 'game/export_presets.cfg').read_text(encoding='utf-8')
    lines = []
    platform = 'windows'
    for line in presets.splitlines():
        if line == '[preset.1]':
            platform = 'linux'
        if line.startswith('exclude_filter='):
            line = 'exclude_filter=".gutconfig.json,tests/*,addons/*"'
        if line.startswith('include_filter='):
            line = 'include_filter="data/**/*.json,assets/**/*.json,demo_build_identity.json"'
        if line == 'custom_template/release=""':
            line = f'custom_template/release="{(templates / TEMPLATES[platform][0]).as_posix()}"'
        if line.startswith('application/product_name='):
            line = 'application/product_name="Drowned Harbor Alpha.4 Demo"'
        lines.append(line)
    (stage / 'export_presets.cfg').write_text('\n'.join(lines) + '\n', encoding='utf-8')
    commit = subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=ROOT, text=True).strip()
    dirty = bool(subprocess.check_output(['git', 'status', '--porcelain'], cwd=ROOT, text=True).strip())
    identity = {'version': VERSION, 'source_commit': commit, 'uncommitted_changes': dirty,
        'engine': version, 'distribution': 'owner-authorized developer demo; not a production catalog admission'}
    (stage / 'demo_build_identity.json').write_text(json.dumps(identity, indent=2) + '\n', encoding='utf-8')
    subprocess.run([str(godot), '--headless', '--editor', '--path', str(stage), '--quit'], check=True)
    results = []
    for name, (_, preset, executable) in TEMPLATES.items():
        if selected_platform not in ['both', name]:
            continue
        directory = temporary / name
        directory.mkdir(parents=True, exist_ok=True)
        binary = directory / executable
        subprocess.run([str(godot), '--headless', '--path', str(stage), '--export-release', preset, str(binary)], check=True)
        shutil.copy2(ROOT / 'packaging/drowned_harbor_demo/START_HERE.md', directory / 'START_HERE.md')
        shutil.copy2(ROOT / 'packaging/portable/GODOT_ENGINE_LICENSE.txt', directory / 'GODOT_ENGINE_LICENSE.txt')
        (directory / 'BUILD_IDENTITY.json').write_text(json.dumps(identity, indent=2) + '\n', encoding='utf-8')
        archive_path = build / f'drowned-harbor-demo-{VERSION}-{name}.zip'
        publish_bundle(directory, build / name, archive_path, executable)
        results.append({'platform': name, 'binary': str(build / name / executable), 'archive': str(archive_path),
            'sha256': sha(archive_path), 'bytes': archive_path.stat().st_size})
    return results, identity


if __name__ == '__main__':
    raise SystemExit(main())
