# Drowned Harbor Visual Development

**Release stream:** P0.3
**Status:** Preproduction visual development only
**Tale status:** Design-only; Lantern House remains the sole production Tale

## Visual direction

Drowned Harbor uses an original-first **drowned storybook diorama** direction:

- hand-inked contours;
- watercolor and gouache surface variation;
- controlled cel-shaded depth;
- wet timber, salt glass, dark slate, swollen paper, and oxidized brass;
- scarce lantern amber;
- strong board and silhouette readability;
- no photoreal or unmodified marketplace-pack appearance.

The controlling visual foundation is `Drowned_Harbor_Visual_Language_v1.md`.

`Drowned_Harbor_Palette_and_Contrast_Guardrails_v1.md` adds the approved preproduction clarification that dark and dreary scenes must preserve cool maritime color, material separation, and readable midtones rather than collapsing into brown mud, sepia, or one undifferentiated dark mass.

## Provisional reference hierarchy

The external image binaries are not stored in this public package, but their filenames, dimensions, digests, reviews, and dispositions are recorded.

- `cgpt-v2.png` — provisional composition and world north star;
- `Gemini_2.png` — Spooky-profile linework and readability reference;
- `Gemini_3.png` — Grim-profile atmosphere, contrast, and cool-dark palette reference.

No image is final or production-approved.

## Governed brief inventory

The package contains 18 Tier A signature briefs across two manifests.

### First wave

- Drowned Harbor Low-Tide key art;
- Low-Tide board establishing view;
- High Water board transformation;
- lighthouse exterior and lantern room;
- Bellhouse and indexing mechanism;
- Drowned Archive;
- Bellhouse Ledger;
- Tidebound transformation form.

### Second wave

- Cracked Lighthouse Lens;
- Missing-Name Tablet;
- Empty Lifeboat and wet extra seat;
- Bellmarked insignia;
- Bell-Witness form;
- Drowned Guide form;
- Lighthouse Guardian form;
- tide-state icon family;
- stable-seat control indicators;
- Last Light ending composition.

Every brief defines:

- governed asset ID;
- category and originality tier;
- priority and preproduction status;
- intended use and deliverables;
- visual requirements and negative constraints;
- presentation profiles;
- dependencies;
- prompt, negative prompt, aspect ratio, camera direction, and consistency anchor;
- source and public-distribution policy;
- required provenance record;
- explicit non-approval boundary.

## Asset validation

Validate all briefs as one dependency graph:

```bash
python tools/validate_preproduction_visual_assets.py
python tools/test_validate_preproduction_visual_assets.py
```

The validator rejects:

- duplicate IDs within or across manifests;
- missing or circular dependencies;
- signature assets below Originality Tier A;
- production approval inside a design-only package;
- category and ID mismatches;
- weak or imitation-based prompts;
- ungoverned third-party AI inputs;
- incompatible licensing and public-distribution claims.

## Candidate batches

Generated images are not silently treated as repository or production assets.

A candidate batch must be registered with:

- candidate and governed asset IDs;
- generator and tool;
- source kind;
- prompt source and full prompt snapshot;
- negative prompt and aspect ratio;
- input-asset and third-party-input declaration;
- expected output count;
- repository disposition;
- review state;
- approval boundary.

Validate all candidate batches, including governed reviews of external files:

```bash
python tools/validate_preproduction_visual_candidates_reviewed_external.py
python tools/test_validate_preproduction_visual_candidates_reviewed_external.py
```

The registered batch `DH-CB-001` includes planned design-sheet candidates and the reviewed external key-art comparison set.

## External review policy

A candidate may be reviewed while its binary remains external when:

- it is explicitly marked `generated_external`;
- no repository path is claimed;
- generator and tool provenance remain recorded;
- review status and non-approval boundary are explicit;
- filename, dimensions, and SHA-256 digest are preserved in a governed Markdown review record.

The candidate manifest does not pretend an external binary has been uploaded. Its review record preserves identity and disposition separately.

## Candidate lifecycle

1. **Brief drafted** — requirements and constraints exist.
2. **Generation ready** — prompt and provenance policy pass validation.
3. **Candidate planned** — a governed batch entry exists.
4. **Generated externally** — an output exists outside the repository.
5. **External review recorded** — the filename, dimensions, digest, strengths, defects, and disposition are documented without claiming repository storage.
6. **Uploaded unreviewed** — a future candidate path and digest may be recorded when repository storage is appropriate and permitted.
7. **Reviewed repository candidate** — a stored candidate receives an explicit disposition.
8. **Production candidate** — requires a later, separately governed approval package.
9. **Approved** — prohibited inside P0.3.

## Third-party boundary

Raw restricted marketplace, Humble, bundle, commissioned-source, or licensed assets must not be placed in public GitHub unless their license explicitly allows it.

Third-party material must not be used as generative-AI input unless the governing brief explicitly requires permission and that permission is documented.

Signature assets may not be classified as placeholder or licensed-supporting content.

## Claims not made

P0.3 does not establish:

- final art direction;
- final production assets;
- storefront or marketing art;
- final UI or icon accessibility;
- television readability;
- final content rating;
- final Underteller appearance;
- Drowned Harbor runtime integration;
- a second production Tale.
