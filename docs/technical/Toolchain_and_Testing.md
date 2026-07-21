# Toolchain and Testing

## Pinned development surface

| Tool | Exact pin | Installation/use |
| --- | --- | --- |
| Godot Windows | `4.7.1.stable.official.a13da4feb` | Official standard Win64 archive, verified with the published SHA-512 before external extraction |
| Godot Linux CI | `4.7.1-stable` standard Linux x86_64 | Direct official release download and SHA-512 verification in `.github/workflows/godot-tests.yml` |
| GUT | tag `v9.7.1`, commit `aeb5d4f3f7f0a6c9b5e178876d6c99b791fda605` | Unmodified tagged `addons/gut` vendored at `game/addons/gut` |
| GDScript Toolkit | direct selection `gdtoolkit==4.5.0`; fully resolved lock in `requirements-dev.txt` | `python -m pip install --disable-pip-version-check --require-hashes --requirement requirements-dev.txt` |
| Python lock generator | `pip-tools==7.6.0` | Local maintenance only; exact generation command below, not a CI runtime dependency |
| CI Python | `3.11.9` | Immutable `actions/setup-python` commit recorded in the workflow |
| Companion Node | `24.18.0` in CI | Existing immutable `actions/setup-node` step and locked `npm ci` |

`game/project.godot` intentionally retains the Godot `4.7` feature-family marker. It also retains `gl_compatibility`, 960×540 logical sizing, `canvas_items` stretch, and kept aspect ratio.

## Official Godot artifacts

The release page is `godotengine/godot-builds` tag `4.7.1-stable`, published July 14, 2026. Verify the following entries against the release's `SHA512-SUMS.txt`:

| Platform | Archive | SHA-512 |
| --- | --- | --- |
| Windows x86_64 | `Godot_v4.7.1-stable_win64.exe.zip` | `a6b02c527c18ba9936e63562032701432b2dc57d98d6483ceaccb00fe14af16af5773ae8a55e7b4d614edf121c4d9e420d870f804edb1dac16362298a01ce6c4` |
| Linux x86_64 | `Godot_v4.7.1-stable_linux.x86_64.zip` | `4ccdab7a48eeccbe8819a2fc1f6262f8d72065d98601bcb3743fcbd7ebd39f373758a788ee3293a05ec5b2c48538266c437404312e372225cd2df273945a2de9` |

Never place either archive, executable, `.godot` cache, or generated report in Git.

## Fully locked Python development environment

`requirements-dev.in` contains the only reviewed direct dependency, `gdtoolkit==4.5.0`. `requirements-dev.txt` is the Python 3.11.9 resolution and contains only exact `==` requirements with SHA-256 hashes. Its reviewed package set is:

| Package | Locked version | Dependency path |
| --- | --- | --- |
| `gdtoolkit` | `4.5.0` | Direct selection |
| `docopt-ng` | `0.9.0` | GDScript Toolkit |
| `lark` | `1.2.2` | GDScript Toolkit |
| `pyyaml` | `6.0.3` | GDScript Toolkit |
| `radon` | `6.0.1` | GDScript Toolkit |
| `setuptools` | `83.0.0` | GDScript Toolkit; included explicitly with `--allow-unsafe` |
| `regex` | `2026.7.19` | `lark[regex]` |
| `mando` | `0.7.1` | `radon` |
| `colorama` | `0.4.6` | `radon` |
| `six` | `1.17.0` | `mando` |

Regenerate only after reviewing dependency changes, using Python 3.11.9 and this exact maintenance tool and command:

```powershell
py -3.11 -m venv .lock-venv
& .\.lock-venv\Scripts\python.exe -m pip install --index-url https://pypi.org/simple pip-tools==7.6.0
$env:CUSTOM_COMPILE_COMMAND = 'python -m piptools compile --generate-hashes --allow-unsafe --resolver=backtracking --strip-extras --no-emit-index-url --output-file=requirements-dev.txt requirements-dev.in'
& .\.lock-venv\Scripts\python.exe -m piptools compile --generate-hashes --allow-unsafe --resolver=backtracking --strip-extras --no-emit-index-url --output-file=requirements-dev.txt requirements-dev.in
Remove-Item Env:CUSTOM_COMPILE_COMMAND
```

The committed lock must install unchanged on both Windows PC-Office and Linux GitHub Actions under Python 3.11.9. Installation and verification are:

```powershell
python -m pip install --disable-pip-version-check --require-hashes --requirement requirements-dev.txt
python -m pip check
python -m pip freeze --all
```

## Windows commands

Set the console executable once from the external installation, then run from the repository root:

```powershell
$godot = 'C:\Users\Eddie\Documents\Codex\Tools\Godot\4.7.1-stable\Godot_v4.7.1-stable_win64_console.exe'
& $godot --version
& $godot --headless --editor --path game --quit
& $godot --headless --path game --quit-after 3
```

Run the complete direct Godot surface:

```powershell
$tests = @(
  'seat_manager_test.gd',
  'visual_language_test.gd',
  'exploration_test.gd',
  'living_board_test.gd',
  'turn_event_card_test.gd',
  'dread_director_test.gd',
  'director_simulation_test.gd',
  'role_session_test.gd',
  'social_simulation_test.gd',
  'companion_room_test.gd',
  'companion_simulation_test.gd'
)
foreach ($test in $tests) {
  & $godot --headless --path game --script "res://tests/$test"
  if ($LASTEXITCODE -ne 0) { throw "$test failed" }
}
```

The live companion host entrypoint is driven by `npm run test:e2e:local`; do not run it independently without the local room service and browser harness.

## GUT conventions and command

First-party GUT tests live in `game/tests/gut`, use `test_*.gd`, extend `GutTest`, and keep parameters, locals, return values, and public model references typed. Tests must use deterministic inputs and public authority methods. They must not create a second gameplay authority or inspect another seat's private state. Keep large multi-seed or full-authority simulations as direct `SceneTree` scripts.

```powershell
New-Item -ItemType Directory -Force game\test-results | Out-Null
& $godot --headless --path game --script res://addons/gut/gut_cmdln.gd `
  -gexit -gjunit_xml_file=res://test-results/gut-junit.xml
```

The committed `.gutconfig.json` supplies the test directory, naming convention, and deterministic JUnit filename. `game/test-results` is ignored. GUT's nonzero exit code is not masked in CI; the JUnit upload uses `if: always()` so a failing report is retained without converting the job to success.

## Enforced first-party GDScript quality gates

Install the exact tool pin:

```powershell
python -m venv .venv
& .\.venv\Scripts\python.exe -m pip install --disable-pip-version-check --require-hashes --requirement requirements-dev.txt
& .\.venv\Scripts\python.exe -m pip check
& .\.venv\Scripts\python.exe -m pip freeze --all
$files = Get-ChildItem game -Recurse -File -Filter *.gd |
  Where-Object { $_.FullName -notlike '*\game\addons\gut\*' -and $_.FullName -notlike '*\game\.godot\*' } |
  Sort-Object FullName | ForEach-Object FullName
& .\.venv\Scripts\gdlint.exe @files
& .\.venv\Scripts\gdformat.exe --check @files
```

The same explicit inclusion rule runs in Linux CI. No `.gdlintrc` weakens the defaults, vendored GUT and `.godot` cache files are the only path exclusions, and CI invokes `gdformat` only with `--check`. The v0.0.9.2 cleanup retained 67 files and moved the inherited state to enforced zero findings:

| Category | Inherited result | v0.0.9.2 result |
| --- | --- | --- |
| First-party inventory | 67 files | 67 files; same construction and reviewed exclusions |
| `max-line-length` | 1,210 | 0 |
| `max-returns` | 17 | 0 |
| `max-public-methods` | 3 | 0; public contracts preserved through typed inherited adapters |
| `function-arguments-number` | 3 | 0 |
| `unused-argument` | 1 | 0; callback signature retained with Godot's underscore convention |
| class-definition order | 1 | 0 |
| `gdformat --check` | 64 files differed | 0 files differ |

Both commands run with `set -euo pipefail`; `tee` records output without masking a nonzero tool status. The `gdscript-quality` artifact contains `first-party-files.txt`, `gdlint.txt`, and `gdformat.txt`, including clean exit-code records. `tools/validate_toolchain.py` rejects warning-only execution, `set +e`, broadened exclusions, inventory changes, source-rewriting `gdformat`, and artifact removal. A future finding or format difference fails the Godot job.

v0.1.1 added nine reviewed first-party scripts—four presentation/report runtime files, two standalone suites, one focused GUT script, the memory-writer test seam, and a full-route capture fixture—raising the explicit inventory from 74 to 83 files. v0.1.2 adds the presentation-only internal build-identity reader and its standalone authority-invariance suite, raising the inventory to 85 files. `playtest_readiness_test.gd`, `playtest_main_route_test.gd`, and `portable_build_identity_test.gd` are fail-closed workflow steps. `tools/validate_playtest_readiness.py` verifies the report fixture schema, exact capture dimensions, full-route capture composition, approved user-data destination, required test surfaces, and absence of reporting network APIs or forbidden serialized identity fields. Both quality gates remain zero-finding over the complete 85-file inventory.

## GitHub Actions orchestration

The existing Godot workflow/job names remain unchanged for branch-policy compatibility. The Godot job performs checksum verification, hash-enforced Python/tool installation plus `pip check` and `pip freeze --all`, enforced lint/format validation and evidence capture, import, main smoke, every legacy test and simulation, locked companion dependency installation, the genuine local native-authority E2E, GUT, and JUnit upload. Companion and repository workflows retain their existing TypeScript, browser, service, audit, build, privacy, secret, JSON, LFS, provenance, oversized-file, title, and whitespace checks.

Repository checkout uses `fetch-depth: 0` so whitespace validation inspects committed work. Pull requests run `git diff --check` on `pull_request.base.sha...pull_request.head.sha`; pushes to `main` compare `github.event.before` with `github.sha`. An all-zero initial-push `before` value checks only the pushed commit against its first parent, or the empty tree for a root commit. Missing or unavailable event SHAs fail closed. The pathspec excludes only `game/addons/gut/**`; first-party files are never exempt.

The source-validation workflow does not deploy, package Android, publish a storefront build, install `godot-ci`, or change production Cloudflare resources. The separate portable-build workflow produces checksum-pinned internal Windows and Linux workflow artifacts only; it does not deploy them or commit generated executables and archives.
