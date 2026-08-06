# AI-ART-POLICY-001 — AI-Only Production Art, Provenance, and Existing Asset Review

## Release coordinates

- Issue: #151
- Original policy merge: PR #152
- Corrective follow-up pull request: pending draft
- Protected-main base: `073e1a65c47f7ec39463fa5a04ed3b4d0e2e73c7`
- Branch: `docs/ai-art-existing-assets-review`
- Type: metadata-only policy, provenance, and preliminary asset-review release
- Binary assets added: none
- Existing Drowned Harbor images reviewed: 25
- Assets promoted: none

## Decision

Terror Turn may use AI-generated or AI-assisted production art without requiring human-drawn or human-painted source art.

The 25 registered Drowned Harbor images are no longer permanently reference-only. They are eligible for controlled direct-source, edited-source, image-to-image, mask, control, extraction, runtime, marketing, or storefront review according to each asset's recorded permitted uses.

Missing historical prompt, model, seed, timestamp, or session metadata remains unknown but is not an automatic rejection.

`DH-AI-SOURCE-001` remains a historical advisory, but its blanket no-upload rule is superseded for these 25 ledgered images when an exact permitted use completes full-resolution review and separate promotion.

## Preliminary review

The review records:

- 1 `eligible_direct_source_after_edit`;
- 16 `eligible_production_input_after_edit`;
- 8 `eligible_model_input_after_review`;
- 0 `retain_reference_only`;
- 0 `reject`;
- 0 promoted.

The review is preliminary and expressly records that the File Library full-image opener was unavailable during this review. Some assets were therefore assessed using File Library visual summaries plus repository records or prior visual-development handoffs. Every exact use still requires review of the original full-resolution binary.

No reverse-image search, provider-side verification, trademark clearance search, or legal opinion was performed.

## Controls

- immutable original filename and SHA-256;
- Project Owner attestation and exact known/unknown provenance;
- closed 25-asset ledger schema;
- per-asset disposition, strengths, blockers, permitted next uses, and required actions;
- full-resolution review before exact use;
- transformation and derivative hashes;
- rights, similarity, accidental-text, watermark, likeness, quality, and continuity review;
- Steam pre-generated-AI disclosure;
- no live generation;
- no automatic promotion;
- no binary import or runtime authority in this release.

## Boundaries

This release creates no source master, edit, generated derivative, Godot import, runtime candidate, ordinary export, marketing asset, storefront asset, public release, accessibility claim, production-readiness claim, legal-clearance claim, or shipping approval.

Automation is not human evidence.
