# DH-VCB-001 — Drowned Harbor Board Environment Breakdown

**Repository status:** planning authority only
**Source disposition:** `accepted_external_working_specification`
**Baseline:** `DH-VBL-001`
**Candidate batch:** `DH-CB-002`
**Governing issue:** #110
**Implementation authority:** none

## Purpose and governing authorities

This repository brief registers the accepted external Working Draft v1.2 as the bounded production-conversion plan for a future Low-Tide/High-Water Drowned Harbor board. It creates no production-art or runtime authority.

The governing paths are:

- `docs/assets/Original_First_Visual_Asset_Policy.md`
- `docs/tales/drowned_harbor/visual/Drowned_Harbor_Visual_Language_v1.md`
- `docs/tales/drowned_harbor/visual/Drowned_Harbor_Palette_and_Contrast_Guardrails_v1.md`
- `docs/tales/drowned_harbor/visual/README.md`
- `docs/tales/drowned_harbor/visual/drowned_harbor_visual_asset_briefs_v1.json`
- `docs/tales/drowned_harbor/visual/drowned_harbor_visual_asset_briefs_wave2_v1.json`
- `docs/tales/drowned_harbor/visual/visual_asset_brief_schema_v1.json`
- `docs/tales/drowned_harbor/visual/visual_candidate_batch_schema_v1.json`
- `docs/tales/drowned_harbor/visual/drowned_harbor_concept_batch_001.json`
- `docs/tales/drowned_harbor/ui/README.md`
- `docs/tales/drowned_harbor/ui/drowned_harbor_core_storyboards_v1.json`
- `docs/tales/drowned_harbor/ui/drowned_harbor_continuity_accessibility_storyboards_v1.json`
- `docs/preproduction/shared_screen_storyboard_schema_v1.json`
- `docs/technical/Shared_Screen_Storyboard_Contract_v1.md`
- `docs/technical/Asset_Pipeline.md`
- `.gitattributes`
- `art/provenance.json`

The visual asset brief `DH-UI-001` and storyboard `DH-UI-001` are different historical identities. The storyboard family is `DH-UI-001` through `DH-UI-022`; every reference must remain qualified.

## Construction decision gate

The default planning presumption is `layered_painted_2_5d`. `controlled_stylized_3d` or `bounded_hybrid` requires later documented technical evidence. This release does not make the final construction-method decision.

One authoritative shared board master is required. Low Tide and High Water must derive from the same coordinate system, geometry, camera and projection, landmark anchors, route authority, elevation authority, and shoreline/flood boundaries. Two independently painted state images are not acceptable production masters.

The presumptive future master path `art/source/drowned_harbor/environment/board/dh_board_tide_master_v1.kra` is reserved planning language only; this release does not authorize that path.

## Board identity and logical review space

The logical review space is 960 × 540, top-left origin, with 0, 24, and 48-pixel review margins. The future source-authority record must define units, transforms, projection, depth/elevation, z-order, anchors, route endpoints, rounding, permitted change regions, overlay comparison, and quantitative tolerances.

Board modules are `DH-BMOD-001` through `DH-BMOD-007`: Lighthouse, Bellhouse, Drowned Archive, Salt Market, Lifeboat Shed, Causeway/Mudflat Approach, and Supporting Harbor Structures.

Planning vocabulary is limited to `visual_route_classes` and `visual_tide_states`. No runtime enum mapping is created here.

## Tide and route authority

```text
authoritative runtime Tide/stage state
        ↓
visual_tide_state
        ↓
authorized flood/water presentation mapping
        ↓
mask set and presentation derivative
```

A flooded land connection is the **visual representation of authoritative land-connector state**. A navigable water-only connection is the **visual representation of authoritative water-only connector state**.

Presentation may animate, interpolate, reveal, emphasize, transition, or skip to an equivalent final state. Presentation never owns route legality, movement authority, runtime Tide state, runtime stage state, authoritative connector state, or gameplay-event authority.

## Layer, module, route, water, and UI planning

The future master must preserve editable logical separation for landmarks, routes, flood masks, water, occlusion, lights, weather, foreground, and UI-safe guides. Semantic route and flood information must remain deterministic and inspectable until export.

`visual_route_classes` are: open land, secondary open, damaged or uncertain, closed or submerged land, water only, objective linked, elevated safer, flood-prone lower, and locked unavailable. They are presentation classes, not authoritative gameplay state identifiers.

Water is authored, bounded, and state-driven; hydrodynamic simulation is not required or authorized. Essential meaning may not depend on color, transparency, distortion, particle density, volumetric fog, screen-space reflections, compute shaders, or subtle animated normals.

The board must tolerate objective/status, stable-seat rail, prompt/confirmation, caption/narrative, warning, opaque privacy shield, transcript/recovery, and one-, four-, and eight-seat review overlays. Those reviews are not physical-TV, controller, accessibility, or privacy certification.

## Presentation hooks and compatibility

Future mappings may use the namespaced hooks recorded in the machine-readable contract. Each needs full-motion, reduced-motion, no-motion final state, and skip-equivalent behavior.

The future implementation remains constrained to Godot 4.7.1 Compatibility rendering, without Forward+-only, compute, volumetric-fog, or screen-space-reflection dependencies. Final performance budgets and target hardware evidence are deferred.

## Provenance, storage, and evidence boundaries

This release commits no image binary, archive, source art, Godot scene/resource, runtime derivative, catalog/provider registration, or export-policy change. External candidate rights and provenance remain unresolved unless directly evidenced.

Automation may validate metadata, identities, paths, schema closure, and prohibited claims. It is not proof of fun, balance, comprehension, television readability, physical-controller behavior, accessibility, privacy, security, production readiness, or shipping authorization.

Issue #7, issue #39, Alpha.3 developer-only isolation, Lantern House normal/default status, and PR #32 exclusion remain mandatory. No Codex task or successor implementation issue is authorized by this release.
