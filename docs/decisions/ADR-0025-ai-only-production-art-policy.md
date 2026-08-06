# ADR-0025: AI-Only Production Art and Provenance Policy

- **Status:** Proposed for review
- **Date:** 2026-08-05
- **Decision scope:** repository-wide visual-source policy and provenance; no asset generation, import, runtime integration, ordinary-export admission, marketing, storefront publication, or public release

## Context

The Project Owner intends Terror Turn's new production visuals to be created with generative-AI tools rather than requiring human-drawn or human-painted source artwork.

The historical `DH-SOURCE-PLAN-001` clean-room plan was deliberately stricter. It required blank human-authored editable sources and permanently prohibited direct generated-pixel use. That approach protected against accidental derivation from the 25 external Drowned Harbor reference images, but it no longer reflects the intended production method.

The historical record remains valid as a record of what was approved at that time. This ADR changes the future production-art method without converting any existing reference image into source art and without authorizing an asset.

Current official authorities reviewed for this decision include:

- U.S. Copyright Office, *Copyright and Artificial Intelligence, Part 2: Copyrightability* (released 2025-01-29): generative-AI output is protected only where a human author determines sufficient expressive elements; prompts alone generally are not enough, while human-authored selection, arrangement, or modification may be protected.
- Steamworks Content Survey documentation, reviewed 2026-08-05: shipped artwork created with AI during development is `Pre-Generated` AI content and must be disclosed; the developer remains responsible for illegal or infringing content and consistency with marketing.
- OpenAI Terms of Use effective 2026-01-01: as between the user and OpenAI and to the extent permitted by law, the user owns Output and OpenAI assigns any right, title, and interest it has; outputs may not be unique, inputs must be authorized, outputs require review, and AI output may not be represented as human-generated.
- Google Terms of Service effective 2024-05-22 and Gemini image-help documentation reviewed 2026-08-05: Google states it will not claim ownership over original generated content, while the user remains responsible for rights, privacy, and lawful use. Because these public terms are less explicit than OpenAI's output assignment, Gemini assets require a dated terms reference and owner or legal review before storefront promotion.

These are policy inputs, not legal opinions or guarantees of non-infringement, copyrightability, exclusivity, or platform acceptance.

## Decision

1. New production visual sources will normally be AI-generated or AI-assisted. A human-drawn or human-painted source is not required.
2. Human creative responsibility remains required for:
   - art direction;
   - prompt and brief authorship;
   - selection and rejection;
   - arrangement, sequencing, layout, typography, masking, compositing, color, animation, and UI integration;
   - rights, similarity, quality, accessibility, privacy, and storefront review.
3. Machine-determined pixels are not presumed copyrightable or exclusive. The repository records protectable human-authored contributions separately and accurately.
4. A generated output is never production-ready merely because a provider's terms permit use. It must pass the repository promotion lifecycle and complete provenance.
5. Approved or conditionally eligible providers are recorded in `art/ai/approved_generators_v1.json`. Unlisted providers are prohibited until reviewed.
6. Each asset must use the closed provenance schema in `art/ai/ai_art_provenance_schema_v1.json` and be entered in the ledger before source acceptance.
7. The following are prohibited without specific written authorization:
   - copyrighted characters or franchise identifiers;
   - third-party logos, trademarks, branded products, signatures, or watermarks;
   - celebrity or private-person likenesses;
   - third-party artwork as an input;
   - requests to imitate a named living artist or active studio;
   - unresolved substantial similarity to an identifiable work.
8. Shipped AI artwork is classified as Steam `Pre-Generated` AI content. Live generation remains unauthorized.
9. `AI-ART-POLICY-001` supersedes only the future-facing blank-human-source, permanent generated-pixel prohibition, and independent-human-authorship acceptance requirements of `DH-SOURCE-PLAN-001`.
10. The following `DH-SOURCE-PLAN-001` protections remain:
    - all 25 external images remain private R1 references and are not source files;
    - no tracing, vectorization, paint-over, compositing, fragment extraction, or hidden-layer use of those reference images;
    - complete contributor, provider, input, terms, hash, transformation, export, and lineage records;
    - independent similarity review;
    - authority, privacy, controller-first, 960×540, accessibility-evidence, and ordinary-export boundaries.
11. This ADR authorizes policy and validation only. A separate release must authorize generation, and each asset or bounded batch requires promotion evidence before runtime or storefront use.

## Asset promotion lifecycle

1. `policy_only_no_assets`
2. `generation_request_approved`
3. `generated_source_quarantined`
4. `rights_and_similarity_review`
5. `source_accepted_not_runtime`
6. `runtime_candidate`
7. `ordinary_export_candidate`
8. `storefront_candidate`
9. `retired_or_rejected`

No stage may be skipped. A later stage does not retroactively cure missing source-input rights or provenance.

## Consequences

Terror Turn may use an AI-only visual-production strategy while preserving a defensible record of provider terms, inputs, transformations, human creative decisions, review, and shipped disclosure.

The tradeoff is accepted: individual machine-determined pixels may have weak or no copyright protection, outputs may be non-unique, and provider terms do not guarantee non-infringement or platform acceptance.

The repository gains a deterministic policy gate but still requires human visual review, legal judgment where risk is material, television and controller testing, accessibility review, and Steam prerelease review.

Automation is not legal advice, human evidence, art-direction approval, or platform certification.
