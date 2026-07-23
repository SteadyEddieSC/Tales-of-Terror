# Portable Playtest Bundles

## Boundary

v0.1.9 produces internal, portable Windows and Linux x86_64 automated-playthrough and deadlock-lab candidates as GitHub Actions artifacts while retaining the v0.1.3 blank pilot kit. Generated executables, archives, export templates, human evidence, and normalized outputs are ignored or externally reviewed inputs and are never committed. This is not an installer, storefront build, public demo, signed release, updater, platform-SDK integration, or production deployment. No human session or manual validation occurred; issue #39 remains deferred.

The native executable is directly launchable. `launch.cmd` and `launch.sh` are optional convenience helpers that resolve only paths beside themselves, request no administrator access, perform no downloads or network calls, pass command-line arguments through, return the native process status, and exit with a clear code-2 error when the required executable is absent.

## Authoritative export inputs

Both presets in `game/export_presets.cfg` target official Godot 4.7.1-stable templates and embed the PCK in one native executable. CI downloads the official release assets from the `godotengine/godot-builds` v4.7.1-stable release and verifies them before use.

| Input | Pin |
| --- | --- |
| Linux editor | `Godot_v4.7.1-stable_linux.x86_64.zip`; SHA-512 `4ccdab7a48eeccbe8819a2fc1f6262f8d72065d98601bcb3743fcbd7ebd39f373758a788ee3293a05ec5b2c48538266c437404312e372225cd2df273945a2de9` |
| Export templates | `Godot_v4.7.1-stable_export_templates.tpz`; SHA-256 `86409db6200b6f8fd3230989c2d2002851f3dd18acf11d7bdbafddf5a0dd0f72` |
| Windows preset | `Internal Windows x86_64` |
| Linux preset | `Internal Linux x86_64` |

The export includes all runtime resources, explicitly adds the ignored generated build identity, and excludes GUT, tests, `.gutconfig.json`, and the unused engineering-only exploration showcase. Export validation fails if these reviewed preset fragments change. Godot's generated `.godot/exported` transforms and class/UID caches remain engine-owned internals inside the embedded native pack; they are not outer bundle entries. The outer allowlist rejects any `.godot` path.

## Exact bundle layouts

Each versioned directory contains only the platform native executable, optional launcher, `START_HERE.md`, facilitator guide, observation sheet, questionnaire, privacy/limitations notice, exact pilot/findings schemas, blank pilot/findings records, third-party notices, Godot license, and `build_manifest.json`. `tools/portable_bundle.py` compares the complete file set with this allowlist and rejects known source/build/private paths, raw reports, tests, caches, and sensitive or irrelevant extensions. The blank records contain no human result.

The Windows archive is `lantern-house-internal-playtest-v0.1.9-windows-x86_64.zip`; the Linux archive uses the same name with `linux`. Each has a sibling `.zip.sha256`. ZIP entry times are fixed for stable archive layout, but the manifest deliberately carries a real build timestamp, so repeated archives are not claimed byte-identical.

## Manifest and content identity

The exact manifest also records the Tale package kind, schema, stable ID, authored version, and canonical SHA-256 so downloaded artifact evidence can be tied to the reviewed content contract.

`build_manifest.json` uses schema version 1 and an exact root-key allowlist. It records release, exact source commit, target, pinned engine and renderer, 960×540 viewport, Lantern House scenario/package identity, the exact one-entry Tale catalog identity, report schema v2, bounded internal-release labels, and a sorted per-file SHA-256/size inventory. The manifest excludes itself from that inventory to avoid recursive identity.

`runtime_content.digest` identifies only the native executable record. `bundle_content.digest` identifies every copied payload file before the manifest. Both are canonical SHA-256 digests over sorted records. `build_timestamp_utc` is separately labeled `non_deterministic_metadata_excluded_from_content_identity`. Tests assemble twice with different timestamps and require both content identities to remain equal while rejecting overwrite, missing files, extra files, hash drift, extra manifest keys, and private-data patterns.

The generated in-game identity has exactly release, source commit, platform, architecture, schema, and classification. Internal artifacts accept only release `v0.1.9`, a 40-character lowercase hexadecimal source commit, platform `windows` or `linux`, architecture `x86_64`, and classification `internal_playtest`; unknown keys or malformed values reject. The `source_checkout` fallback is permitted only from the editor-bearing source-checkout context and is visibly labeled `SOURCE CHECKOUT`, while a missing or malformed exported identity is visibly invalid and fails smoke validation.

Help page 4 visibly presents the release, short build ID, current platform, architecture, understandable and machine-readable classification, provisional project-folder name, Lantern House scenario version, report schema, protected reset, support-reporting fields, and actionable local report location. Windows uses `%APPDATA%\Godot\app_userdata\Terror Turn\playtest_exports`. Linux uses `$XDG_DATA_HOME/godot/app_userdata/Terror Turn/playtest_exports`, with `~/.local/share/godot/app_userdata/Terror Turn/playtest_exports` documented as the usual fallback when `XDG_DATA_HOME` is unset. These are user-relative forms; the page never exposes a concrete username, machine name, absolute repository path, room secret, token, IP address, device identity, or report contents. Integrated tests compare coordinator snapshots, authority and public-history digests, active reports, RNG-backed authority state, and companion projections before and after opening and paging Help.

## Build and validate

From the repository root, after installing the verified Godot 4.7.1 templates:

```text
python tools/portable_bundle.py validate-repository
python tools/test_portable_bundle.py
python tools/portable_bundle.py write-build-identity --platform windows --source-commit <40-character-sha>
Godot_v4.7.1-stable_win64_console.exe --headless --path game --export-release "Internal Windows x86_64" <absolute-output.exe>
python tools/portable_bundle.py assemble --platform windows --source-commit <40-character-sha> --output-root <ignored-output-root> --exported-binary <absolute-output.exe>
python tools/portable_bundle.py validate-bundle <bundle-directory>
```

Use the Linux preset and target values for Linux. CI executes both the Linux native executable and launcher with the bounded `--portable-build-smoke` route and requires `accepted=true`, the exact workflow source SHA, Linux/x86_64 target, `internal_playtest` classification, visible internal label, correct report guidance, and every authority/report/RNG/companion invariance flag. The local Windows classification similarly records direct and launcher process results against an exact committed implementation head. The smoke opens the real main scene and the build/support page, verifies its content and presentation-only invariance, then exits; synthetic headless input is not a household session or physical-controller test.

## Pilot evidence boundary

`packaging/pilot/pilot_session_schema.json` and `findings_register_schema.json` define exact versioned records. The committed v0.1.3 pilot record defaults all ten manual checks to `not_tested`, route observations to `not_observed`, declarations to false, and human arrays to empty; the findings register contains zero findings. `tools/pilot_evidence.py` accepts an evidence directory containing exactly `PILOT_SESSION_RECORD.json`, matches it against an external frozen candidate identity, rejects unknown/private/ambiguous content, and emits deterministic normalized JSON with source SHA-256 provenance. It has no network, telemetry, upload, cloud, or AI-service dependency. Automation and virtual/offscreen work can never become remote-observed or physical-in-room evidence.
