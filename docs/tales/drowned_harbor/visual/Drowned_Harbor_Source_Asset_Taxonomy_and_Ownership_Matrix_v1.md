# Drowned Harbor Source Asset Taxonomy and Ownership Matrix v1

**Release:** `DH-SOURCE-PLAN-001`
**Status:** metadata-only planning; no source files exist or are authorized

Every future family starts from a blank human-authored editable source, uses independent geometry and composition, carries complete contributor/tool/font/asset/license records, and remains blocked until source SHA-256, export SHA-256, lineage, and similarity review are complete.

| Family ID | Planned family | Authoritative state owner | Information class | Future source owner | Current status |
|---|---|---|---|---|---|
| DH-SRC-BOARD-MASTER | Shared Low Tide/High Water board master, invariant geometry, spaces, connectors, anchors, elevation, and state masks | BoardState | public | unselected future board-source contributor | planning only; source absent |
| DH-SRC-BOARD-OVERLAYS | Tide, hazard, route, focus, preview, warning, recovery, and committed-state overlays derived from authority | BoardState / RulesSession / presentation | public | unselected future board/UX contributor | planning only; source absent |
| DH-SRC-SEAT-IDENTITY | Stable-seat public identity grammar using text, shape, position, and non-color channels | RulesSession | public | unselected future UX contributor | planning only; source absent |
| DH-SRC-PRIVATE-SHIELD | Neutral private shield and public-safe return treatment | session coordinator / RoleSession | public-safe private boundary | unselected future privacy/UX contributor | planning only; source absent |
| DH-SRC-PUBLIC-HIERARCHY | Stage, objective, Tide, captions, prompts, transcript, replay, warning, recovery, and outcome hierarchy | RulesSession / presentation | public | unselected future UX contributor | planning only; source absent |
| DH-SRC-INTERACTION-TOKENS | Focus, preview, confirmation, commitment, reconnect, game-control, and takeover-pending tokens | authority identified per token | public or public-safe boundary | unselected future UX contributor | planning only; source absent |
| DH-SRC-PROFILE-INTENSITY | Spooky/Grim information-preserving intensity layers | presentation | public | unselected future presentation contributor | planning only; source absent |
| DH-SRC-CAPTION-GLYPH | Caption backing, controller glyph, symbol, and text hierarchy | presentation / RulesSession | public | unselected future localization/accessibility contributor | planning only; fonts and glyphs unselected |
| DH-SRC-PROVENANCE | Contributor, tool, font, asset, license, source, export, hash, and review records | Release Coordination | governance metadata | unselected future provenance steward | planning template only |
| DH-SRC-EVIDENCE | Similarity, geometry, density, privacy, motion, replay, and issue #39 evidence records | Release Coordination and named evidence owner | governance metadata | unselected future evidence steward | unperformed |

## Ownership rules

- Gameplay authority supplies facts; source contributors do not invent legal actions, reachability, state, private information, transformations, outcomes, or runtime fields.
- Presentation owns emphasis and motion only. It may not mutate authority or rerun rules.
- Private fields remain owned by RoleSession and may not enter shared display, captions, transcript, replay, diagnostics, screenshots, mirrors, source files, or public exports.
- Each editable source has one recorded owner and all contributors listed.
- Each export traces to one exact source SHA-256 and one exact export recipe.
- No generated image becomes a source family, source layer, production master, texture, mask, silhouette, icon, text, logo, sign, or runtime asset.

## Fail-closed lifecycle

`planning_only → separately_authorized_blank_source → lineage_complete → similarity_review_passed → later_lifecycle_review`

This release establishes only `planning_only`. Missing ownership, rights, source history, records, hashes, or a passing similarity review stops advancement.
