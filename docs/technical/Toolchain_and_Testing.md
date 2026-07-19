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

## First-party GDScript quality baseline

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

The same explicit inclusion rule runs in Linux CI. No `.gdlintrc` weakens the defaults, vendored GUT is excluded, and `gdformat` only checks. Initial findings are categorized as follows:

| Category | Initial result | Decision |
| --- | --- | --- |
| Correctness/typed-GDScript | No parser or typed-syntax blocker reported | Preserve typed standards; investigate any future correctness finding directly |
| Targeted style/complexity | 17 `max-returns`, 3 argument-count, 3 public-method-count, 1 unused-argument, 1 class-order finding | Review in a bounded cleanup, not alongside gameplay |
| Line-length/style | 1,210 findings | Large repository-wide baseline; informational artifact |
| Formatter-only | 66 of 67 initial files would change | Large baseline; no mass formatting in v0.0.9.1 |
| Parser/tool limitations | None observed with gdtoolkit 4.5.0 across the full first-party tree | No suppression or fallback version needed |

Because the baseline is large, both steps are informational in this release. Their full outputs and exit codes are uploaded as `gdscript-quality-baselines`. v0.1.0 remains blocked until separately bounded cleanup makes the checks enforceable.

## GitHub Actions orchestration

The existing Godot workflow/job names remain unchanged for branch-policy compatibility. The Godot job performs checksum verification, hash-enforced Python/tool installation plus `pip check` and `pip freeze --all`, informational lint/format capture, import, main smoke, every legacy test and simulation, locked companion dependency installation, the genuine local native-authority E2E, GUT, and JUnit upload. Companion and repository workflows retain their existing TypeScript, browser, service, audit, build, privacy, secret, JSON, LFS, provenance, oversized-file, title, and whitespace checks.

Repository checkout uses `fetch-depth: 0` so whitespace validation inspects committed work. Pull requests run `git diff --check` on `pull_request.base.sha...pull_request.head.sha`; pushes to `main` compare `github.event.before` with `github.sha`. An all-zero initial-push `before` value checks only the pushed commit against its first parent, or the empty tree for a root commit. Missing or unavailable event SHAs fail closed. The pathspec excludes only `game/addons/gut/**`; first-party files are never exempt.

This workflow validates source. It does not export, deploy, package Android, publish a storefront build, install `godot-ci`, or change production Cloudflare resources.
