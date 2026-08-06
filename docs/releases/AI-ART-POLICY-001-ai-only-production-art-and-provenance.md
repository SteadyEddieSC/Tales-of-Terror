# AI-ART-POLICY-001 — AI-Only Production Art and Provenance

## Disposition

**Proposed metadata-only policy release.**

- Governing issue: #151
- Protected-main baseline: `0a6686d8cc4d15feac81c128cfc414b954e234b1`
- Release type: policy, schema, empty ledger, documentation, and deterministic validation
- Asset generation: not authorized
- Asset import: not authorized
- Runtime integration: not authorized
- Ordinary-export inclusion: not authorized
- Marketing or storefront use: not authorized
- Live generation: not authorized

## Decision

New production visual sources may be AI-generated or AI-assisted and do not require human-drawn or human-painted artwork.

Human art direction, selection, arrangement, modification, integration, rights review, similarity review, quality review, provenance, and final approval remain required.

Purely machine-determined pixels are not presumed copyrightable, exclusive, non-infringing, or platform-approved.

## Supersession

This release preserves `DH-SOURCE-PLAN-001` as a historical record while superseding three future-facing requirements:

1. blank human-authored editable source is mandatory;
2. all direct AI-generated pixel use is permanently prohibited;
3. independent human authorship is the only acceptable future source disposition.

All 25 Drowned Harbor external images remain R1 private references, non-source, nonproduction, and unusable as generated-image inputs, masks, control images, hidden layers, extracted fragments, or runtime assets.

## Registered controls

- ADR-0025 repository decision;
- AI production and provenance policy;
- Drowned Harbor amendment;
- approved-provider registry;
- closed per-asset provenance schema;
- empty policy-state ledger;
- similarity and promotion checklist;
- Steam pre-generated-AI disclosure draft;
- dependency-free validator and mutation tests;
- dedicated GitHub Actions workflow.

## Current provider posture

- OpenAI ChatGPT image generation: eligible only after a separate generation activation.
- Google Gemini Apps image generation: conditionally eligible only after a separate generation activation and with a dated terms reference plus owner or legal review before storefront promotion.
- All other providers, checkpoints, models, fine-tunes, LoRAs, and services: prohibited until reviewed and registered.

## Persistent boundaries

No asset is admitted by this release. `art/ai/ai_art_provenance_ledger_v1.json` must remain `policy_only_no_assets` with an empty `assets` array.

Lantern House remains the sole normal/default Tale. Drowned Harbor remains developer-only and ordinary-export excluded. Issue #39 remains the human-evidence authority. Automation is not legal advice, human evidence, art-direction approval, accessibility certification, or Steam certification.
