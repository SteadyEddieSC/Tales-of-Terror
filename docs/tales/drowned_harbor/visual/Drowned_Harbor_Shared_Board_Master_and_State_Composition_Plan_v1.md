# Drowned Harbor Shared Board Master and State Composition Plan v1

## Standing

This is metadata-only planning. It does not create an editable board source, runtime composition, Godot resource, candidate, or export.

Low Tide and High Water must derive from one future human-authored shared board master. Separate independently redrawn boards are prohibited because they could drift in geometry, spaces, connectors, anchors, elevation, routes, and reachability.

## Authority

`BoardState` owns:

- spaces and stable space identifiers;
- connector identifiers and endpoints;
- route reachability;
- pawn positions;
- elevation and relevant terrain classes;
- Tide mutations and state masks;
- public board state.

`RulesSession` may supply public legal intents, warnings, commitment state, and stage context. `presentation` may focus, preview, animate, caption, and emphasize authoritative state but may not invent geometry, routes, reachability, legal actions, mutations, or outcomes.

## Planned source structure

A later authorized board master must keep independently reviewable groups for:

1. invariant coastline and land geometry;
2. spaces, anchors, and stable IDs;
3. connectors, endpoint ownership, and route classes;
4. elevation and terrain classes;
5. Low Tide state masks and public-safe presentation layers;
6. High Water state masks and public-safe presentation layers;
7. hazard and mutation overlays driven only by BoardState;
8. pawn and token anchor locations;
9. public route emphasis, focus, preview, warning, recovery, and committed-state overlays;
10. safe regions reserved for status, seat identity, captions, prompts, and outcome context;
11. optional information-preserving Spooky/Grim intensity layers;
12. provenance, source history, and export metadata.

Exact dimensions, canvas, color profile, tools, formats, layer names, and runtime interfaces remain unselected planning hypotheses.

## State composition

### Invariant master

The authoritative master contains the shared geometry and stable identifiers. Low Tide and High Water are state compositions of that master, not separate authority sources.

### Low Tide

May reveal only authoritative spaces, connectors, routes, hazards, and public state available during Low Tide. It must not predict future mutations or disclose private information.

### High Water

May apply only BoardState-authorized masks, connector changes, blocked or opened routes, hazards, elevation effects, and public state. Presentation effects must settle on the same authoritative geometry and state.

### Transition

The transition is presentation only. It may not rerun reducers, RNG, encounters, transformation, attribution, ending resolution, or cleanup. Reduced-motion and interrupted routes must converge on the identical settled BoardState.

## Occlusion and safe-region planning

A later implementation must preserve readable board context and avoid hiding critical spaces, connectors, pawns, public warnings, legal actions, and outcome context. Safe regions are hypotheses until 960×540 capture review and one-, four-, and eight-seat evidence exist.

Temporary overlays must:

- retain enough board context to explain the current decision;
- avoid horizontal scrolling at the intended logical target;
- preserve captions and legal prompts;
- provide non-color state channels;
- expose no private fields;
- restore focus and authoritative state after dismissal or interruption.

## Source and export lineage

Each future board source and export requires contributor/tool/font/asset/license records, a blank-source statement, independent-composition statement, source SHA-256, exact export recipe, export SHA-256, and independent similarity-review disposition.

## Stop conditions

Stop when generated pixels or derivatives are requested; a separate board is proposed for each Tide state; source geometry lacks a BoardState basis; source history or hashes are missing; route or connector differences cannot be reconciled; private information would enter public layers; or similarity review is inconclusive.

All validation remains unperformed. Drowned Harbor remains developer-only and ordinary-export excluded.
