# ADR-0025 — AI-Only Production Art and Existing Drowned Harbor Asset Eligibility

- **Status:** accepted by PR #152; corrective existing-asset eligibility amendment proposed
- **Decision date:** 2026-08-06
- **Release:** `AI-ART-POLICY-001`
- **Issue:** #151
- **Corrective branch:** `docs/ai-art-existing-assets-review`

## Context

Terror Turn intends to use AI-generated or AI-assisted production visuals. Human-drawn or human-painted source art is not required.

The repository already records 25 externally stored Drowned Harbor AI images with immutable filenames, SHA-256 values, dimensions, actual formats, provider-family attribution, and Project Owner attestation. Earlier releases classified all 25 as private reference-only and prohibited pixel reuse because the then-current strategy required clean-room human-authored reconstruction. That strategy is no longer the Project Owner's direction.

The earlier restriction was an internal conservative workflow decision. It was not a finding that the images are illegal, infringing, or unusable.

## Decision

1. AI-generated or AI-assisted source art is the normal production direction.
2. The 25 registered Drowned Harbor images are eligible for controlled, per-asset and per-use evaluation.
3. An approved use may include:
   - direct source candidacy;
   - cropping, cleanup, recoloring, retouching, paint-over, compositing, vectorization, or upscaling;
   - image-to-image use;
   - mask or control-image use;
   - texture, silhouette, icon, or decorative-fragment extraction;
   - runtime candidacy;
   - marketing or storefront candidacy.
4. No image is approved automatically. Every exact use requires a recorded disposition, full-resolution human review, provenance preservation, transformation lineage, and a separate promotion decision.
5. Missing historical prompts, negative prompts, seeds, exact model variants, session identifiers, or timestamps must remain explicitly unknown. Those unknowns do not automatically reject an image when its binary identity, provider family, account owner, and rights basis are otherwise recorded.
6. The original external binary and registered SHA-256 remain immutable evidence even when derivatives are created.
7. Provider terms and owner attestation do not guarantee copyrightability, exclusivity, non-infringement, legal clearance, Steam approval, or platform acceptance.
8. Live AI generation remains outside the game and is not authorized.
9. This release performs a preliminary review of all 25 images but promotes none.

## Historical boundary

`DH-SOURCE-PLAN-001` remains an unchanged historical record. Its future-facing human-authored-only and no-pixel-reuse requirements are superseded by this ADR.

`DH-AI-SOURCE-001` also remains an unchanged historical advisory. Its blanket restriction against uploading the registered external images is superseded for these 25 assets when the exact ledger disposition permits the use and the full-resolution review controls are completed.

The original owner attestation and rights register remain authoritative evidence. Their old lifecycle conclusions are superseded only for future eligibility and review routing; their factual provenance, hashes, and unknowns remain intact.

## Consequences

The existing art is no longer discarded by policy. Strong images may be refined into production sources, while weaker or superseded images may still serve as model inputs, control images, layout studies, comparison references, or fragment sources after review.

Concept sheets containing generated text, provisional icons, flattened UI, or multiple alternatives normally require editing and isolation before runtime use. Board pairs still require exact shared geometry. UI and icon sheets still require component cleanup and accessibility testing.

No binary import, Godot integration, ordinary export, marketing use, storefront use, public release, or shipping claim is authorized by this ADR alone.
