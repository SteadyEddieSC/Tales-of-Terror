# DH-UX-REG-001 — Shared-Screen UX Advisory Registration

## Standing

This metadata-only release registers external advisory `DH-UX-001` as an
accepted UX planning reference with required corrections.

- Governing issue: #120
- Protected-main base: `1cad8495c913d926c4422557ea59e8c6fa1f6c1a`
- Branch: `docs/dh-ux-001-advisory-registration`
- Review disposition: `accepted_external_ux_advisory_with_required_corrections`
- Conversion readiness: `not_ready`
- Implementation authorized: `false`

This release creates planning, metadata, traceability, schema, and validation
authority only. It does not create a runtime UI specification, UX
implementation, visual conversion, source-art decision, Godot task, candidate,
public asset, accessibility claim, human evidence, or successor implementation
issue.

## Verified external package

- Received archive:
  `DH-UX-001_External_UX_Helper_Advisory_Handoff_Package_v1(1).zip`
- Canonical internal package name:
  `DH-UX-001_External_UX_Helper_Advisory_Handoff_Package_v1`
- ZIP bytes: `21,304,764`
- ZIP SHA-256:
  `e3857353dc0257b72866e0e5259b8e3bab2e856126903675f8e73e1f23a02ae3`
- Manifest bytes: `5,622`
- Manifest SHA-256:
  `7742a59b402957d63593917a291d807f3fba7fd4bea82937a22730b65d6d469d`
- Manifested payloads: `25`
- Every payload byte count and SHA-256 matched.
- ZIP CRC validation completed.
- All eight PNG reference inputs decoded at their declared dimensions and RGB
  mode.

The archive and PNGs remain external/private and are not included in Git or a
public GitHub Release.

## Required corrections

### External schema defect

The package contract contains top-level `title`, while the package schema has
`additionalProperties: false` and does not define `title`. The supplied contract
therefore fails the supplied schema with one error.

This repository release records the defect and uses a corrected closed
registration schema. It does not silently claim that the external schema
validated.

### Authority ownership

The advisory's broad assignment of routes to `RulesSession` is rejected.

- `BoardState` owns board geometry, spaces, connectors, pawn positions, Tide
  mutations, and route reachability.
- `RulesSession` owns legal intents, stage progression, Bellhouse
  choice/recovery, Council commitment, High Water transformation, Last Light
  resolution, and public ending resolution.
- `RoleSession` owns private roles, private objectives, hidden factions,
  private transformations, private attribution, and controlled reveal.
- The session coordinator owns safe handoff, control transfer, rematch, and
  title cleanup.
- Presentation owns focus, non-mutating preview, animation, emphasis, captions,
  and presentation-only replay.

No new field, legal action, route, commitment, ending, attribution, replay,
profile-change, private-review, takeover, or cleanup authority is created.

### Reference-image standing

The package's eight PNGs are reference inputs, not production assets.

- `DH-PRESENT-001` through `DH-PRESENT-003` retain their existing registered
  external-storyboard-reference standing.
- The environment, stable-seat, profile, and shared-UI-grammar studies remain
  external reference-only and unregistered.
- None receives a candidate ID, `production_candidate`, or `approved` status.

### Review coordinates and component sizes

The 960×540 coordinates, 104-pixel eight-seat tile, 308-pixel decision drawer,
text sizes, prompt strip, and other dimensions are registered only as advisory
review hypotheses.

They are not:

- final runtime component specifications;
- evidence that four-seat or eight-seat density works;
- evidence of television readability;
- accessibility evidence;
- source/runtime composition authority.

The caption reserve intentionally overlays the lower board/action region. The
registration does not falsely require all declared regions to be disjoint.

## Accepted advisory direction

The release accepts these planning principles:

1. board readability before atmosphere;
2. six layout modes: board-first, decision-focus, transformation,
   outcome-attribution, private shield, and system overlay;
3. persistent stage/objective, Tide, authority, board, caption, stable-seat, and
   legal-prompt hierarchy;
4. stable-seat continuity for 1–8 seats using multiple non-color identity
   channels;
5. explicit available → focused → preview → confirmation → authority-owned
   commit → resolving → settled semantics;
6. no first-focus irreversible commitment;
7. public-only transcript and presentation replay;
8. opaque neutral privacy shield and private-data exclusion;
9. stage-specific UX flow from Low Tide through coordinator-owned cleanup;
10. placeholder microcopy and actionable, non-punitive recovery;
11. Spooky/Grim information invariance;
12. future static, automated, and issue #39 human-evidence work.

Private-review, takeover, profile-change, transcript, replay, help, rematch, and
cleanup controls remain conditional on existing authoritative legal intents.
The registration creates no such intent.

## Next blocker

After UX acceptance, the first blocking prerequisite is:

`rights_and_provenance_resolution_for_external_visual_inputs`

Later prerequisites include explicit source-art and source/runtime-composition
authority, an approved private-surface approach, 960×540 Compatibility-renderer
implementation proof, safe-frame/density/value/text-expansion evidence,
reduced-motion/interruption/replay evidence, and issue #39 human and physical
evidence.

No successor release is selected or activated.

## Governance

Issue #7 remains the naming and branding gate. Issue #39 remains the human and
physical evidence gate. Alpha.3 remains developer-only. Lantern House remains
the sole normal/default Tale. PR #32 remains excluded.

Automation is not human evidence.
