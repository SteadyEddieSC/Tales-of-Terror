# Third-Party Asset and Dependency Register

Record every external code package, Godot addon, font, image, sound, music track, voice asset, and reference pack before it enters a release. Include source, author, version, license, proof of purchase/permission, attribution requirements, modification notes, and redistribution limits.

The current haunted-board concept is an AI-generated internal visual baseline and is not final production art. The game must use original characters and monsters unless a separate license is obtained.

Runtime asset-level provenance is recorded in art/provenance.json. Before importing third-party or generated material, record its stable ID, runtime path, source, creator or generator/tool, license or permission, and derivation/export notes. Preserve distributable evidence under art/licenses or audio/licenses; use GitHub Release storage for large review or delivery packages rather than repository history.

## Development code and tool register

| Dependency | Pinned source | Repository use | License and retained notice | Modification |
| --- | --- | --- | --- | --- |
| GUT 9.7.1 | `bitwes/Gut` tag `v9.7.1`, commit `aeb5d4f3f7f0a6c9b5e178876d6c99b791fda605` | Vendored unchanged at `game/addons/gut` for focused Godot unit/boundary tests | MIT in `game/addons/gut/LICENSE.md`; bundled font notices remain in `game/addons/gut/fonts/OFL.txt` and adjacent upstream files | None; byte-for-byte copy of the tagged `addons/gut` directory |
| GDScript Toolkit 4.5.0 | PyPI package `gdtoolkit==4.5.0`; source tag commit `b7a4935fc6483d51837f7080598dad456f4f7645` | Local/CI `gdlint` and `gdformat --check`; not shipped with the game | MIT in `third_party/licenses/gdtoolkit-4.5.0-MIT.txt` | Not vendored; installed from the exact requirement pin |

Godot and Node executables remain external local/CI tools and are never committed. Their release artifact checksums and installation paths are recorded in the applicable toolchain evidence matrix.
