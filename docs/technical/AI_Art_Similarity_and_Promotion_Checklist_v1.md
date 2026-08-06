# AI Art Similarity and Promotion Checklist v1

Use this checklist for every exact AI-art use, including direct reuse, editing, image-to-image generation, masks, control images, extraction, runtime assets, marketing, and storefront art.

## Identity and provenance

- [ ] Original filename matches the registered inventory.
- [ ] Original SHA-256 matches the registered inventory.
- [ ] Provider family and account owner are recorded.
- [ ] Known metadata is recorded exactly.
- [ ] Unknown prompt, model, seed, timestamp, or session data remains explicitly unknown.
- [ ] Original external binary is preserved unchanged.
- [ ] Requested use is listed in the asset's `permitted_next_uses`.

## Full-resolution human review

- [ ] The original full-resolution binary was opened and inspected.
- [ ] No unintended third-party character, franchise identifier, logo, trademark, branded product, trade dress, celebrity, or private-person likeness remains unresolved.
- [ ] No accidental signature, watermark, provider mark, generated text, gibberish, date, label, or emblem remains unresolved.
- [ ] No malformed anatomy, fused object, repeated structure, impossible mechanism, or perspective defect remains unresolved.
- [ ] No identifiable protected work or suspiciously close arrangement remains unresolved.
- [ ] Any review uncertainty is recorded rather than guessed.

## Use-specific controls

### Direct or edited source

- [ ] Embedded presentation-board text and borders are removed unless deliberately re-authored.
- [ ] Components are isolated at appropriate resolution.
- [ ] Geometry, silhouette, scale, lighting, and continuity are checked.
- [ ] Human selection, arrangement, editing, compositing, color, typography, animation, and integration choices are recorded.

### Image-to-image, mask, or control use

- [ ] The exact input image and SHA-256 are recorded.
- [ ] The permitted purpose is recorded.
- [ ] Prompt, model, provider, account, settings, and resulting SHA-256 are recorded when available.
- [ ] The result is treated as a new quarantined asset and reviewed independently.

### Texture, icon, silhouette, or fragment extraction

- [ ] The extracted region is identified.
- [ ] Text, logos, signatures, and watermarks are excluded or resolved.
- [ ] Scale, seamlessness, vector quality, alpha, color space, and compression are checked.
- [ ] The extraction does not silently make generated gameplay semantics authoritative.

### Runtime, marketing, or storefront use

- [ ] Runtime path, dimensions, format, alpha, compression, and SHA-256 are recorded.
- [ ] `art/provenance.json` is updated when applicable.
- [ ] 960×540, safe-region, one/four/eight-seat, grayscale, and controller-first review is complete when applicable.
- [ ] Physical television and accessibility evidence is recorded separately under issue #39.
- [ ] Steam pre-generated-AI disclosure matches the actual build and store material.
- [ ] Conditional-provider review is complete.

## Promotion decision

Choose exactly one:

- `approve_exact_use`
- `approve_after_listed_corrections`
- `retain_quarantined`
- `retain_reference_only`
- `reject`

Record reviewer, date, exact input and output hashes, corrections, and release coordinate.

Approval does not guarantee copyrightability, exclusivity, non-infringement, legal clearance, Steam approval, production readiness, or shipping approval.
