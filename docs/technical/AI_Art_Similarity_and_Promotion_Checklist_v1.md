# AI Art Similarity and Promotion Checklist v1

Use one completed copy per asset or tightly bounded visual batch. A checked item is evidence only when the reviewer, date, notes, and referenced files or hashes are recorded in the provenance ledger.

## 1. Provider and account

- [ ] Provider ID exists in `art/ai/approved_generators_v1.json`.
- [ ] Provider eligibility permits the requested stage.
- [ ] Account is controlled by the Project Owner or an authorized contributor.
- [ ] Current terms reference or dated snapshot is retained.
- [ ] Exact model name and version are recorded when available.
- [ ] Generation date and account owner are recorded.

## 2. Inputs and prompt

- [ ] Full prompt is retained.
- [ ] Negative prompt is retained when available.
- [ ] Seed is retained when available.
- [ ] Every uploaded image, mask, control image, or other input is listed.
- [ ] Every non-text input has an owner or licensor and rights basis.
- [ ] No Drowned Harbor R1 reference image was uploaded or used as a hidden source.
- [ ] No copyrighted character, franchise asset, logo, trademark, branded product, celebrity, or private-person likeness was requested without written authorization.
- [ ] No named living artist or active studio was requested as the target style.

## 3. Original output

- [ ] Original provider output is preserved.
- [ ] Original output SHA-256 is recorded.
- [ ] C2PA or Content Credentials status is recorded.
- [ ] Provider watermark, signature, or visible mark status is recorded.
- [ ] Output remains quarantined until review is complete.

## 4. Rights and similarity

- [ ] No unintended third-party character, logo, mark, product, signature, or likeness is visible.
- [ ] No accidental text, date, label, watermark, or gibberish remains unresolved.
- [ ] Composition was compared against known references actually consulted.
- [ ] Silhouette, landmark, prop arrangement, decorative detail, palette, material treatment, and typography were reviewed.
- [ ] No substantial similarity concern remains unresolved.
- [ ] Reviewer did not rely solely on automated image similarity.
- [ ] Conditional-provider legal or owner review is complete before storefront promotion.

Allowed similarity dispositions:

- `pass_no_material_similarity_concern`;
- `revise_similarity_or_rights_concern`;
- `stop_inconclusive`;
- `reject_identifiable_third_party_derivation`.

Only the first disposition may advance.

## 5. Human creative contribution

- [ ] Human prompt or brief authorship is recorded.
- [ ] Selection and rejection decisions are recorded.
- [ ] Arrangement, sequencing, layout, typography, masking, compositing, color, paint, animation, or UI integration choices are recorded when present.
- [ ] Machine-determined elements are not mislabeled as human-authored.
- [ ] Any intended copyright claim identifies only supported human-authored material.
- [ ] Output is not represented as wholly human-generated.

## 6. Visual quality

- [ ] Anatomy, object construction, architecture, and perspective are coherent.
- [ ] Lighting, materials, scale, camera, and shadows are coherent.
- [ ] Repeated, fused, or malformed objects are absent.
- [ ] State and character continuity is maintained.
- [ ] Style matches the approved visual family.
- [ ] Essential silhouette and hierarchy remain readable at 960×540.
- [ ] Meaning does not depend on color alone.
- [ ] Television safe areas and UI occlusion are acceptable.
- [ ] Spooky and Grim variants preserve information and mechanics.

## 7. Transformation and export

- [ ] Every material transformation records tool, version, description, input hash, and output hash.
- [ ] Editable master path and hash are recorded when one exists.
- [ ] Runtime dimensions, format, color space, alpha, compression, and SHA-256 are recorded.
- [ ] Runtime path follows repository naming and directory rules.
- [ ] `art/provenance.json` contains the runtime derivative before import.
- [ ] Asset budgets and Godot import validation pass.
- [ ] Source-to-runtime lineage has no broken link.

## 8. Promotion

- [ ] Current promotion stage is recorded.
- [ ] No stage was skipped.
- [ ] Required reviewer and release coordinate are recorded.
- [ ] Steam disclosure batch is assigned before storefront candidacy.
- [ ] Build and store materials match the disclosure.
- [ ] Live AI generation is absent.
- [ ] Rejection or retirement preserves the audit record.
