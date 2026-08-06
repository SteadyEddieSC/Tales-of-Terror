# AI Art Production and Provenance Policy v1

- **Release:** `AI-ART-POLICY-001`
- **Issue:** #151
- **Protected-main baseline:** `0a6686d8cc4d15feac81c128cfc414b954e234b1`
- **Authority:** policy and provenance only
- **Assets admitted:** none

## Production direction

Terror Turn's default direction for new production visuals is AI-generated or AI-assisted source art. Human-drawn or human-painted artwork is not required.

This does not remove human responsibility. Every promoted asset must have a named reviewer and recorded human decisions covering art direction, selection, arrangement, edits, integration, rights, similarity, quality, privacy, accessibility implications, and storefront disclosure.

## Copyright and exclusivity posture

The project does not claim that purely machine-determined pixels are necessarily protected by copyright. The U.S. Copyright Office's January 29, 2025 Part 2 report states that protection depends on sufficient human-authored expressive elements; prompts alone generally do not establish authorship, while human-authored selection, arrangement, or modification may qualify.

For each asset, record separately:

- machine-generated source elements;
- human-authored prompt or brief;
- human selection and rejection;
- human-authored layout, sequencing, typography, masks, compositing, paint, color, animation, and integration;
- compilation or arrangement choices;
- any element excluded from a copyright claim.

Provider ownership language is not treated as a government determination of copyrightability, exclusivity, or non-infringement.

## Approved-provider rule

Only provider records in `art/ai/approved_generators_v1.json` are eligible.

### OpenAI ChatGPT image generation

Eligible after a separate generation activation.

Required:

- Project Owner-controlled account.
- Exact displayed model and version when available.
- Prompt, date, account owner, source-input record, and SHA-256.
- Confirmation that all inputs are owned or authorized.
- Human review before use.
- Acknowledgement that output may not be unique.
- No representation that generated pixels were human-generated.

### Google Gemini Apps image generation

Conditionally eligible after a separate generation activation.

In addition to the common controls:

- retain a dated terms snapshot or stable terms reference for each promotion batch;
- record the exact displayed model and version when available;
- obtain owner or legal review before `storefront_candidate`;
- do not infer exclusive rights from Google's statement that it will not claim ownership.

Unlisted providers, local models, community checkpoints, fine-tunes, LoRAs, adapters, or third-party image services remain prohibited until their model source, license, training or use restrictions, output terms, privacy terms, and commercial-use posture are reviewed.

## Input policy

Every non-text input must be listed with:

- input ID;
- type;
- internal path or stable reference;
- SHA-256 when available;
- owner or licensor;
- rights basis;
- permitted purpose.

Prohibited inputs include:

- artwork copied from the web without documented rights;
- the 25 Drowned Harbor external reference images as source images, masks, control images, hidden layers, texture sources, or image-to-image inputs;
- copyrighted characters, franchise assets, logos, or branded products without written authorization;
- celebrity or private-person likenesses without written authorization;
- images supplied by a client, friend, contractor, or family member without an explicit rights basis;
- private or sensitive data not required for the visual task.

## Prompt policy

Prompts and negative prompts must be retained when available.

Prompts must not request:

- a named living artist's style;
- an active studio's distinctive style;
- a copyrighted character or franchise identifier;
- a recognizable celebrity or private person;
- a third-party logo, signature, watermark, product mark, or protected trade dress;
- a close reproduction of a specific reference image.

Use descriptive visual-language terms instead: period, medium, lighting, palette, composition, material, camera, silhouette, mood, geometry, and functional hierarchy.

## Quarantine and promotion

New output starts as `generated_source_quarantined`.

Before source acceptance:

1. verify provider and account eligibility;
2. verify every input;
3. preserve the original output and SHA-256;
4. inspect C2PA or Content Credentials when present;
5. record watermark or signature disposition;
6. perform rights and similarity review;
7. record human contributions;
8. complete quality review;
9. create an editable master when material edits or arrangement require one;
10. preserve transformation hashes.

Before runtime candidacy:

- export dimensions, format, color space, alpha, compression, and SHA-256;
- verify 960×540 readability and safe regions where applicable;
- verify controller-first hierarchy;
- run asset budgets and Godot import validation;
- add the runtime asset to `art/provenance.json`;
- maintain source-to-runtime lineage.

Before storefront candidacy:

- complete Steam disclosure review;
- confirm store art and build content match;
- confirm no live-generated content is present;
- complete owner or legal review for any conditional provider or unresolved rights question.

## Quality rejection criteria

Reject or revise an asset for:

- malformed anatomy, objects, architecture, or perspective;
- accidental text, gibberish, dates, labels, signatures, logos, or watermarks;
- repeated or fused objects;
- inconsistent lighting, materials, scale, or camera logic;
- continuity drift across states or variants;
- poor silhouette or low-distance readability;
- inaccessible color dependence;
- UI occlusion or unsafe television margins;
- style mismatch;
- unresolved similarity to an identifiable protected work;
- missing source, transformation, or export hashes.

## Steam disclosure

Shipped AI-generated artwork is `Pre-Generated` AI content. Live generation is not authorized.

The maintained draft is in `docs/technical/Steam_PreGenerated_AI_Disclosure_Draft_v1.md`. It must be updated to match the actual build and store materials before submission.

## Drowned Harbor relationship

`AI-ART-POLICY-001` supersedes the future production-method clauses of `DH-SOURCE-PLAN-001` that required blank human-authored source artwork and permanently prohibited all generated pixels.

It does not promote or convert the existing 25 reference images. They remain `R1_private_internal_reference`, `reference_only_nonproduction`, and non-source.

No asset generation, import, Godot integration, ordinary-export inclusion, marketing, or public use is authorized by this policy release.
