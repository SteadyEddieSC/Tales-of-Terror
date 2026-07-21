# Portable Playtest Bundles

## Boundary

v0.1.2 produces internal, portable Windows and Linux x86_64 session bundles as GitHub Actions artifacts. Generated executables, archives, and export templates are ignored build outputs and are never committed. This is not an installer, storefront build, public demo, signed release, updater, platform-SDK integration, or production deployment.

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

Each versioned directory contains only the platform native executable, its optional launcher, `START_HERE.md`, the facilitator guide, post-session questionnaire, privacy/limitations notice, default manual-validation record, third-party notices, the Godot license, and `build_manifest.json`. `tools/portable_bundle.py` compares the complete file set with this allowlist. It also rejects known source/build/private paths and sensitive or irrelevant extensions.

The Windows archive is `lantern-house-internal-playtest-v0.1.2-windows-x86_64.zip`; the Linux archive uses the same name with `linux`. Each has a sibling `.zip.sha256`. ZIP entry times are fixed for stable archive layout, but the manifest deliberately carries a real build timestamp, so repeated archives are not claimed byte-identical.

## Manifest and content identity

`build_manifest.json` uses schema version 1 and an exact root-key allowlist. It records release, exact source commit, target, pinned engine and renderer, 960×540 viewport, Lantern House scenario v1, report schema v2, bounded internal-release labels, and a sorted per-file SHA-256/size inventory. The manifest excludes itself from that inventory to avoid recursive identity.

`runtime_content.digest` identifies only the native executable record. `bundle_content.digest` identifies every copied payload file before the manifest. Both are canonical SHA-256 digests over sorted records. `build_timestamp_utc` is separately labeled `non_deterministic_metadata_excluded_from_content_identity`. Tests assemble twice with different timestamps and require both content identities to remain equal while rejecting overwrite, missing files, extra files, hash drift, extra manifest keys, and private-data patterns.

The generated in-game identity has exactly release, source commit, platform, architecture, schema, and internal/source-checkout classification. It is presented only on Help page 4. The page advises a generic Godot user-data report location and never exposes a username, machine name, absolute repository path, room secret, token, IP address, device identity, or report contents. Integrated tests compare coordinator snapshots, authority digests, and public-history digests before and after opening it.

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

Use the Linux preset and target values for Linux. CI executes both the Linux native executable and launcher with the bounded `--portable-build-smoke` route and verifies the success marker. The local Windows classification similarly records direct and launcher process results. The smoke opens the real main scene and the build/support page, verifies its content and authority invariance, then exits; it does not simulate a household session or physical controller.

## Manual validation boundary

`packaging/manual_validation_schema.json` defines the human record. The committed `docs/playtests/v0.1.2-manual-hardware-validation.json` defaults all ten checks to `not_tested`, with empty observer/session/timestamp fields. Automation, synthetic controllers, virtual/offscreen images, CI, and browser tests cannot set `physical_in_room`. A human observer must explicitly update a copied record after performing the named physical check.
