# Asset Pipeline

## Directory contract

| Location | Purpose | Storage |
| --- | --- | --- |
| game/assets | Godot-ready runtime derivatives and text resources | Normal Git unless an exceptional reviewed rule says otherwise |
| art/source | Layered visual masters | Git LFS for reviewed editable formats |
| audio/source | Lossless audio masters | Git LFS |
| art/exports and audio/exports | Modest review renders | Normal Git when useful and small |
| art/licenses and audio/licenses | License and permission records | Normal Git text/PDF where redistribution permits |
| art/placeholders | Clearly temporary source material | Follow the source format's storage rule |
| GitHub Releases | Milestone bundles, downloadable DOCX/PDF snapshots, build packages, and large review deliveries | Release attachment, not repository history |

## Naming and source of truth

Use lowercase snake_case: subject_variant_role.ext, such as seat_frame_warning_panel.kra or greymoor_wind_loop.wav. Editable masters are the source of truth. Runtime derivatives carry the same stem and are regenerated from documented export settings; never hand-edit a derivative without updating its master or recording the exception.

Godot text resources, scenes, scripts, Markdown, JSON, and modest runtime PNG/WebP/SVG/OGG files remain in normal Git. LFS is reserved for the reviewed patterns in .gitattributes; it is not a generic home for every binary.

## Import expectations

1. Confirm authorship and usage rights before adding a source.
2. Add or update art/provenance.json with creator, source, license, derivation, and runtime path.
3. Export at the intended logical scale. Keep essential UI silhouettes crisp at 960×540.
4. Place runtime output beneath game/assets/category.
5. Review Godot import settings for filtering, compression, mipmaps, color space, and loop behavior.
6. Run python tools/validate_assets.py, git lfs track, Godot import, and repository checks.

## Git LFS verification

Install once with git lfs install. This repository activates PSD, KRA, BLEND, ASEPRITE, XCF, WAV, FLAC, AIFF/AIF, MP4, and MOV patterns. Verify without a test binary:

    git lfs version
    git lfs track
    git check-attr filter -- example.kra example.wav example.png
    python tools/validate_assets.py

The first two example paths must report filter: lfs; example.png must remain unspecified. Do not commit a large placeholder merely to prove the filter works.

## Provenance

Every generated or third-party runtime asset needs a register entry. Record the human creator or generator/tool and version, source URL or internal source path, license/permission, prompt or brief reference when relevant, material modifications, and derivation/export settings. Keep purchase or permission evidence under the appropriate license directory when redistribution is allowed. Generated output is not presumed copyrightable, exclusive, or safe to ship.
