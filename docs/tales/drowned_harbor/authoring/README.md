# Drowned Harbor Authoring Reference

**Release stream:** P0.9
**Status:** Design-only preproduction data
**Runtime authority:** None
**Production Tale catalog:** Unchanged

## Purpose

This directory converts the Drowned Harbor Design Bible into stable, machine-validated authoring references without creating a playable Tale.

The authoring reference sits between narrative design and the accepted closed production Tale package contract.

It does not:

- change production Tale schema v1;
- add a provider registration;
- add a production catalog entry;
- create `game/data/tales/drowned_harbor`;
- modify runtime scenes, resources, state authorities, snapshots, reports, or Companion protocol;
- approve implementation, balance, localization, media, or human evidence.

Lantern House remains the sole production Tale.

## Governing contract and schemas

- `docs/technical/Tale_Authoring_Reference_Contract_v1.md`
- `docs/preproduction/tale_authoring_reference_schema_v1.json`
- `docs/preproduction/tale_authoring_content_group_schema_v1.json`

The production Tale package contract remains independently governed by:

- `docs/technical/Tale_Package_Contract.md`
- `docs/technical/Tale_Catalog_Contract.md`
- `tools/tale_package.py`
- `tools/tale_catalog.py`

## Authoring envelope

`drowned_harbor_authoring_reference_v1.json` declares:

- design-only identity;
- source authorities;
- intended 1–8-seat compatibility;
- cooperative, Hidden Betrayer, Outbreak, Hunted, and Rival Crews mode plans;
- exact production privacy vocabulary;
- five-stage graph;
- deterministic once-only High Water transformation;
- references to four content manifests;
- governed dialogue, visual, audio, music, voice, and accessibility sources;
- no-phone, no-voice, no-music, invalid-action, defeat, and unsupported-feature fallbacks;
- deterministic, continuity, terminal, accessibility, and human-review obligations;
- ten open design decisions;
- an explicit no-compilation/no-runtime/no-catalog boundary;
- an authoring-only SHA-256 identity policy.

## Content manifests

The 120 stable design IDs are divided into four bounded files.

### World

`drowned_harbor_world_content_v1.json`

- 5 stages;
- 5 tide states;
- 13 spaces;
- 6 regions;
- 5 mode identities.

### Social

`drowned_harbor_social_content_v1.json`

- 6 Living roles;
- 4 factions;
- 6 transformed, Restless, or replacement forms.

### Gameplay

`drowned_harbor_gameplay_content_v1.json`

- 8 public resources;
- 12 items;
- 12 cards;
- 12 hazards.

### Narrative

`drowned_harbor_narrative_content_v1.json`

- 19 encounter identities;
- 7 ending families.

Shared metadata is declared once per governed group while each individual ID remains globally unique and stable.

## Privacy

Only these existing privacy classes are allowed:

- `public`;
- `controlled_reveal_private`;
- `seat_private`;
- `faction_private`.

The package may not introduce a new privacy class, leak hidden allegiance through public media, or use a private source as shared-screen authority.

## Stable-seat continuity

Control-source changes do not replace or reset the stable seat.

The following must preserve stable-seat-owned state:

- human departure;
- deterministic surrogate activation;
- human takeover;
- reserved-player return;
- Tidebound transformation;
- Restless continuation;
- replacement-form entry;
- final outcome attribution.

## Validation

Run:

```bash
python tools/validate_tale_authoring_reference.py
python tools/validate_tale_authoring_reference.py --identity
python tools/test_validate_tale_authoring_reference.py
```

The validator checks:

- exact closed fields;
- design-only and no-runtime/no-catalog boundaries;
- safe repository-relative source paths;
- source-anchor existence;
- media-path existence;
- P0.8 traceability IDs;
- stable and globally unique content IDs;
- mode compatibility and cooperative fallbacks;
- stage identity, reachability, and terminal access;
- deterministic once-only High Water transformation;
- exact stage, tide, and ending inventory;
- 120 total stable content IDs;
- hazard warning/response/recovery requirements;
- encounter legal choices;
- role generic alternatives;
- form stable-seat continuity;
- ending attribution;
- human-review obligations;
- production-blocking open decisions;
- the compilation boundary;
- canonical authoring identity.

`tale_authoring_invalid_cases_v1.json` defines fifteen fail-closed mutations used by the regression suite.

## Authoring identity

The validator may print a deterministic SHA-256 identity for the authoring envelope.

This identity:

- detects source-envelope drift;
- is not a production Tale package digest;
- is not a catalog digest;
- is not a provider allowlist entry;
- does not authorize runtime loading.

Content-manifest integrity is established by validation and repository history in P0.9. A later authorized compiler may define a broader compilation identity.

## Open decisions

The package intentionally retains production blockers, including:

- exact Bellmarked origin;
- exact Tidebound conversion rules;
- final role and seat-count plans;
- final inventory, card, and economy values;
- mandatory versus optional encounter sets;
- missing Bellhouse assistant identity.

Deferred nonblocking decisions include the Harbor's in-fiction proper name, relief-vessel name, Chronicle relationship, and whether the provisional host has presented an earlier version.

## Implementation boundary

This authoring reference cannot be loaded by the production Tale loader.

A future authorized implementation would still require reviewed scenario, board, rules, Director, social, and localization authorities; provider registration; catalog identity; runtime tests; portable builds; and human validation.
