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

The controlling direction is `Drowned_Harbor_Visual_Language_v1.md`.

## Governed brief inventory

The package currently contains 18 Tier A signature briefs across two manifests.

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

## Validation

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

A candidate batch must be registered before generation with:

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

Validate all candidate batches:

```bash
python tools/validate_preproduction_visual_candidates.py
python tools/test_validate_preproduction_visual_candidates.py
```

The first registered batch, `DH-CB-001`, covers:

- `DH-CAND-001-A` — `DH-KEY-001`;
- `DH-CAND-002-A` — `DH-ENV-001`;
- `DH-CAND-003-A` — `DH-ENV-003`;
- `DH-CAND-004-A` — `DH-PROP-001`.

These candidates begin as external and unreviewed. A generated image is not claimed as stored in GitHub until its public repository path and SHA-256 digest are recorded.

## Candidate lifecycle

1. **Brief drafted** — requirements and constraints exist.
2. **Generation ready** — prompt and provenance policy pass validation.
3. **Candidate planned** — a governed batch entry exists.
4. **Generated externally** — an output exists outside the repository.
5. **Uploaded unreviewed** — a candidate path and digest are recorded.
6. **Reviewed** — disposition is `needs_revision`, `reference_only`, `rejected`, or `preproduction_shortlist`.
7. **Production candidate** — requires a later, separately governed approval package.
8. **Approved** — prohibited inside P0.3.

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
