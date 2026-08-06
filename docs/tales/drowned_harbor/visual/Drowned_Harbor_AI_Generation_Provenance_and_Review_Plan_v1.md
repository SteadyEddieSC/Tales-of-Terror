# Drowned Harbor AI Generation Provenance and Review Plan v1

**Release:** `DH-AI-SOURCE-001`
**Policy dependency:** `AI-ART-POLICY-001`
**Standing:** planning only; the asset ledger remains empty

## Purpose

Extend the repository-wide AI-art policy with the board-master pilot's account-plan, privacy-mode, batch, naming, tool-allocation, and generation-review requirements. The repository-wide closed provenance schema remains authoritative for any later asset ledger entry. This plan supplies additional pilot fields and operating conventions that must be retained in generation logs or later schema evolution before source acceptance.

## Required provenance fields

For every later generated, selected, assembled, edited, exported, rejected, or superseded item, record:

- stable `record_id`;
- `release_id` and generation-activation coordinate;
- source family and intended use;
- provider, service, exact displayed model and version when exposed;
- Project Owner-controlled account identifier and subscription plan;
- generation or authoring timestamp in UTC;
- complete prompt and negative prompt/exclusion list;
- seed, parameters, and settings when exposed, otherwise `unknown_not_exposed`;
- every uploaded reference or other source input, with owner, rights basis, purpose, and SHA-256 when available;
- explicit privacy mode or tool-specific retention note;
- original filename, format, untouched output SHA-256, and C2PA/Content Credentials state;
- watermark, signature, accidental text, logo, and brand disposition;
- every edit, transformation tool/version, input hash, output hash, and whether the step reflects a human-authored choice;
- editable-master filename/path and SHA-256 when one exists;
- export recipe, dimensions, format, color space, alpha, compression, filename/path, and SHA-256;
- human selection, rejection, arrangement, masking, compositing, color, typography, cleanup, animation, and integration decisions;
- authority notes identifying what meaning the asset may support and what it must not own;
- rights, similarity, quality, and later accessibility/readability review records;
- disposition and rejection reason codes;
- Steam pre-generated-AI disclosure batch or planning category;
- terms-snapshot reference;
- release and promotion state.

Unknown or unavailable facts must remain explicitly unknown. Do not infer a model version, seed, rights state, privacy state, or human-authorship conclusion.

## Naming convention

General proposed pattern:

`dh_ai_source_001_{source_family}_{tool}_{yyyymmdd}_b{batch}_v{variant}_{stage}.{ext}`

Examples:

- `dh_ai_source_001_boardmaster_chatgpt_20260806_b01_v01_raw.png`
- `dh_ai_source_001_lowtide_gemini_20260806_b03_v02_raw.png`
- `dh_ai_source_001_atmosphere_spooky_chatgpt_20260806_b05_v01_selected.png`
- `dh_ai_source_001_overlaymotifs_recraft_20260807_b06_v01_raw.svg`
- `dh_ai_source_001_boardmaster_master_20260808_b07_v01_source.psd`
- `dh_ai_source_001_boardmaster_master_20260808_b07_v01_export_lowtide.png`

Allowed stage labels are `raw`, `shortlisted`, `selected`, `assembled`, `exported`, `rejected`, and `superseded`.

## Future folder proposal

This structure is a proposal only and is not created by this release:

```text
art/
  drowned_harbor/
    dh_ai_source_001/
      prompts/
        chatgpt/
        gemini/
        recraft/
        firefly/
      raw_generations/
        chatgpt/
        gemini/
        recraft/
        firefly/
      selected_candidates/
      rejected_generations/
      editable_sources/
        vector/
        layered_raster/
      exports/
        board_master/
        low_tide/
        high_water/
        atmosphere/
      metadata/
        provenance/
        generation_logs/
        review_records/
      hashes/
        source/
        export/
      terms_snapshots/
        chatgpt/
        gemini/
        recraft/
        firefly/
```

Raw outputs must remain unchanged and hashable. Selected and rejected outputs remain distinguishable. Editable sources and flattened exports remain separate. Terms snapshots and provider/privacy notes must be batch-specific.

## Generation-session checklist

Before generation:

1. Confirm a separate generation request is active.
2. Confirm provider and account eligibility in `AI-ART-POLICY-001`.
3. Confirm Project Owner account, plan, privacy setting, and retention note.
4. Confirm no restricted external image or unlicensed input will be uploaded.
5. Freeze the prompt, exclusions, batch number, variant count, expected output type, and cost ceiling.
6. Confirm authoritative geometry and information boundaries.
7. Confirm naming and output location outside production/runtime paths.
8. Capture current terms references.

During generation:

- preserve every prompt revision;
- download and hash each untouched output before editing;
- record displayed model/settings;
- record any tool failure, moderation change, or regenerated variation;
- stop on unexpected text, logos, signatures, brands, recognizable IP, or private information.

After generation:

- quarantine all outputs;
- inspect metadata and Content Credentials;
- assign disposition and rejection reason codes;
- document human selection and arrangement decisions;
- perform similarity, rights, quality, geometry, and state-consistency review;
- create no runtime export without a later promotion release.

## Acceptance criteria

### Geometry and state

- The result supports one shared board master.
- Low Tide and High Water align to identical invariant geometry.
- No alternate spaces, connectors, routes, anchors, elevations, or structures are invented as authoritative facts.
- State layers remain separable.

### Information hygiene

- No baked text, letters, numbers, dates, labels, UI copy, controller glyphs, private facts, legal-action claims, or hidden outcomes.
- No color-only critical meaning.
- Exact dynamic information remains procedural.

### Originality and policy

- No named living-artist or active-studio imitation.
- No copyrighted character, franchise identifier, logo, trademark, branded product, trade dress, celebrity, or private-person likeness.
- No signature, watermark, accidental brand, or suspiciously familiar composition.
- No use or leakage of the 25 R1 external images.
- All provider, prompt, input, terms, privacy, and hash records are complete.

### Production utility

- Strong top-down silhouette and board-safe negative space.
- Readable material separation at intended review scale.
- Useful masks/layers or realistic manual reconstruction path.
- Safe regions remain usable.
- Human editing can produce a coherent layered master without paint-over dependence on restricted material.

Passing these checks makes an output eligible only for the next policy promotion review. It does not approve production art.

## Rejection criteria and codes

Reject or revise for:

- `baked_text`;
- `bad_geometry`;
- `state_inconsistency`;
- `low_readability`;
- `signature_or_watermark`;
- `logo_brand_or_ip`;
- `named_artist_or_studio_imitation`;
- `similarity_concern`;
- `private_info_risk`;
- `authority_conflict`;
- `color_only_meaning`;
- `unusable_layers`;
- `restricted_input_use`;
- `provenance_missing`;
- `rights_unknown`;
- `privacy_mode_unknown`;
- `source_or_export_hash_missing`;
- `paint_over_dependency`;
- `scope_exceeded`.

An output may be retained in the rejected area for evidence, provided its provenance is complete and its storage is authorized. Rejected material may not be recycled into source art without a new review.

## Similarity review

Review geometry, composition, silhouettes, landmarks, object arrangements, palette, material treatment, ornament, text artifacts, signatures, watermarks, logos, characters, and recognizable trade dress. Record what was compared, reviewer identity, date, evidence limitations, and disposition. Any unresolved concern blocks advancement.

## Copyright and disclosure record

Distinguish:

- machine-determined visual elements;
- human-written brief and prompt;
- human selection/rejection;
- human-authored geometry reconstruction;
- human arrangement, compositing, masks, typography, color, cleanup, animation, and integration;
- non-AI procedural or manually authored elements.

Do not claim exclusive copyright in machine-determined pixels. Prepare accurate later Steam `Pre-Generated` AI disclosure. Live generation remains unauthorized.

## Review worksheet planning categories

- `ai_generated_visual_base`
- `ai_generated_atmosphere`
- `ai_generated_overlay_support`
- `human_assembled_from_ai_outputs`
- `non_ai_vector_cleanup`
- `runtime_generated_ui`
- `deferred_needs_review`

## Evidence boundary

Automation may validate records, hashes, closed schemas, path boundaries, dimensions, file types, and source-to-runtime lineage. It does not establish originality, non-infringement, visual quality, accessibility, television readability, fun, production readiness, or platform approval. Issue #39 human evidence remains unperformed.
