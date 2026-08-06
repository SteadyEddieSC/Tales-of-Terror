# AI Art Production and Provenance Policy v1

- **Release:** `AI-ART-POLICY-001`
- **Issue:** #151
- **Protected-main baseline:** `073e1a65c47f7ec39463fa5a04ed3b4d0e2e73c7`
- **Authority:** policy, provenance, and preliminary existing-asset review
- **Assets promoted:** none

## Production direction

Terror Turn's normal direction for new production visuals is AI-generated or AI-assisted source art. Human-drawn or human-painted source artwork is not required.

Human responsibility remains mandatory for art direction, prompt and brief authorship, output selection, arrangement, modification, integration, rights review, similarity review, quality review, accessibility implications, provenance, Steam disclosure, and final approval.

Machine-determined pixels are not presumed copyrightable, exclusive, non-infringing, or platform-approved.

## Existing Drowned Harbor images

`DH-AI-SOURCE-001` remains a historical planning authority, but its blanket no-upload rule for the registered external images is superseded by the controlled-use ledger for these 25 assets. Other input, privacy, budget, and board-master controls remain in force.

The 25 assets registered by `DH-RIGHTS-001` and attested by `DH-OWNER-ATTEST-001` are eligible for controlled review and later use.

They are not permanently reference-only. Depending on the recorded per-asset disposition, a future exact-use release may authorize:

- use substantially as generated;
- cropping, cleanup, recoloring, retouching, paint-over, compositing, vectorization, extension, or upscaling;
- image-to-image generation;
- masks or control images;
- extraction and cleanup of textures, silhouettes, icons, or decorative fragments;
- source-master incorporation;
- runtime derivatives;
- marketing or storefront derivatives.

Eligibility is not approval. A filename-level disposition applies only to the uses listed in the provenance ledger. Every exact derivative must record its input SHA-256, tool and version, human choices, output SHA-256, and release coordinate.

## Historical unknowns

The following are unavailable for some or all existing images:

- exact prompts and negative prompts;
- exact model variants and versions;
- seeds;
- exact timestamps;
- generation-session identifiers.

These values remain `null` or explicitly unknown. They must not be reconstructed by guessing. Their absence is a risk factor and review limitation, not an automatic rejection, because the repository separately records immutable binary identity, provider family, Project Owner-controlled accounts, no reported external uploaded references, and the known edit/export history.

## Provider posture

Only providers in `art/ai/approved_generators_v1.json` are eligible for new generation.

OpenAI ChatGPT image generation is eligible after a separate generation activation. Google Gemini Apps image generation is conditionally eligible after separate activation, dated terms capture, and owner or legal review before storefront promotion.

Unlisted services, local models, checkpoints, fine-tunes, LoRAs, or adapters remain prohibited until reviewed.

## Input policy

Every non-text input must identify its source, SHA-256 when available, owner or licensor, rights basis, and permitted purpose.

Do not use third-party artwork, protected characters, franchise assets, logos, branded products, celebrity or private-person likenesses, or private data without an appropriate rights basis.

The 25 Drowned Harbor images may be used as inputs only after the exact asset's ledger disposition permits that use and the original binary is reviewed.

## Prompt policy

Do not intentionally request:

- a named living artist's style;
- an active studio's distinctive style;
- a copyrighted character or franchise identifier;
- a recognizable celebrity or private person;
- a third-party logo, signature, watermark, protected trade dress, or close reproduction of a specific work.

Use descriptive art-direction terms such as period, medium, lighting, palette, composition, material, camera, silhouette, mood, geometry, and functional hierarchy.

## Review and promotion

The preliminary review in `art/ai/ai_art_provenance_ledger_v1.json` routes each existing image into one of these dispositions:

- `eligible_direct_source_after_edit`;
- `eligible_production_input_after_edit`;
- `eligible_model_input_after_review`;
- `retain_reference_only`;
- `reject`.

A preliminary disposition does not admit a binary into Git, create a source master, or make a runtime candidate.

Before an exact use:

1. open and inspect the original full-resolution binary;
2. verify its SHA-256 against the registered inventory;
3. review all visible text, logos, marks, signatures, watermarks, people, characters, branded objects, and suspicious similarities;
4. confirm the requested use is listed under `permitted_next_uses`;
5. preserve C2PA or Content Credentials evidence when present and record its disposition;
6. create an edit or generation lineage record;
7. review continuity, quality, geometry, scale, and accessibility implications;
8. produce and hash the derivative;
9. obtain a separate promotion decision.

## Quality requirements

Reject, revise, or quarantine an asset for malformed anatomy, fused objects, perspective errors, accidental text, gibberish, dates, labels, signatures, logos, watermarks, repeated objects, inconsistent lighting or scale, continuity drift, weak silhouette readability, unsafe television margins, inaccessible color dependence, UI occlusion, style mismatch, or unresolved similarity.

Concept sheets normally require isolation and cleanup. Generated text, route overlays, controller glyphs, UI copy, legal-action state, and icon semantics are never authoritative merely because they appear in an image.

## Drowned Harbor board relationship

`DH-ENV-001_Studio_v3.png` is the strongest existing Low-Tide board-source candidate, subject to editing and master-geometry construction.

`DH-ENV-002_Studio_v2.png` is a useful High-Water production input but does not pixel-match the Low-Tide geometry. The final pair must derive from one shared camera, board bounds, landmark anchors, route endpoints, and editable source structure.

Landmark, material, silhouette, profile, UI, icon, and storyboard sheets may supply controlled production inputs after cleanup. They are not automatically runtime-ready flattened assets.

## Steam disclosure

Shipped AI-generated artwork is `Pre-Generated` AI content. Live generation is not authorized. The maintained draft is `docs/technical/Steam_PreGenerated_AI_Disclosure_Draft_v1.md` and must match the actual shipped build and marketing.

## Current boundary

This release authorizes policy and preliminary review only. It creates no generation request, binary import, source acceptance, Godot integration, runtime candidate, ordinary-export inclusion, marketing asset, storefront asset, public release, or shipping approval.

Automation is not human evidence. Physical television, controller, readability, motion, and accessibility conclusions remain under issue #39.
