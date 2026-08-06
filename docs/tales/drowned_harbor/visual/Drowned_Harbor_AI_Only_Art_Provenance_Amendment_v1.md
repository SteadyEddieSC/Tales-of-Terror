# Drowned Harbor AI-Only Art and Provenance Amendment v1

- **Release:** `AI-ART-POLICY-001`
- **Issue:** #151
- **Amends future production method in:** `DH-SOURCE-PLAN-001`
- **Historical record changed:** no
- **Existing images reviewed:** 25
- **Assets promoted:** 0
- **Implementation authorized:** no

## Purpose

Record the Project Owner's decision that future Drowned Harbor visuals may use AI-generated or AI-assisted pixels and that the 25 existing registered images may be useful production inputs rather than permanently discarded reference material.

## Superseded requirements

`DH-AI-SOURCE-001` remains an unchanged historical planning record. Its blanket restriction against uploading the registered external images is superseded only for the 25 ledgered assets and only for uses explicitly permitted by their exact-use review.

The following are no longer mandatory:

- beginning from a blank human-authored editable source;
- permanently prohibiting all direct AI-generated pixel use;
- permanently limiting the 25 existing images to abstract reference;
- prohibiting tracing, vectorization, paint-over, compositing, cropping, upscaling, recoloring, retouching, extraction, image-to-image use, masks, control images, or runtime derivatives regardless of review;
- requiring independent human-authorship disposition as the only path to source acceptance.

## New eligibility rule

All 25 images are eligible for controlled, per-asset and per-use review.

A future exact-use release may approve an image for:

- direct or edited source use;
- image-to-image generation;
- masks or control images;
- texture, silhouette, icon, or decorative-fragment extraction;
- runtime derivatives;
- marketing or storefront derivatives.

No image is automatically approved. The exact use must be listed in the provenance ledger, the original full-resolution binary must be reviewed, and every transformation and derivative must retain source-to-output hashes.

## Preliminary review result

The repository review records:

- 1 asset as `eligible_direct_source_after_edit`;
- 16 assets as `eligible_production_input_after_edit`;
- 8 assets as `eligible_model_input_after_review`;
- 0 assets as permanently reference-only;
- 0 assets rejected;
- 0 assets promoted.

The detailed filename-level review is in `art/ai/ai_art_provenance_ledger_v1.json`.

The strongest direct-source candidate is `DH-ENV-001_Studio_v3.png`. The High-Water board, landmark studies, material and family sheets, character/profile studies, UI and icon sheets, and presentation storyboards remain useful, but most require isolation, cleanup, geometry reconciliation, text removal, or component re-authoring before runtime use.

## Preserved evidence and controls

The original external binaries, filenames, SHA-256 values, dimensions, actual formats, provider-family attribution, Project Owner attestation, C2PA observations, and unknown metadata remain authoritative evidence.

Unknown prompts, model variants, seeds, timestamps, and session identifiers remain unknown; they are not reconstructed by guessing.

The following remain required:

- authorized inputs;
- full-resolution human review;
- rights, similarity, quality, watermark, and accidental-text review;
- transformation and export hashes;
- source-to-runtime lineage;
- BoardState, RulesSession, RoleSession, coordinator, and presentation authority boundaries;
- public/private separation;
- one shared Low-Tide/High-Water board master;
- 960×540 and controller-first constraints;
- Spooky/Grim information invariance;
- issue #39 human evidence;
- accurate Steam pre-generated-AI disclosure;
- no unsupported legal-clearance, copyright, exclusivity, non-infringement, accessibility, production, or shipping claim.

## Current boundary

This amendment authorizes eligibility and preliminary review only. It authorizes no binary import, source-master acceptance, image edit, generation request, Godot resource, runtime candidate, ordinary export, marketing asset, storefront asset, public release, paid service, or shipping decision.

Lantern House remains the sole normal/default Tale. Drowned Harbor remains developer-only and ordinary-export excluded.
