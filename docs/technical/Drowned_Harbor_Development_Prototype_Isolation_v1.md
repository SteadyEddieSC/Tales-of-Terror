# Drowned Harbor Development Prototype Isolation

**Release:** P0.13
**Issue:** #80
**Status:** Development-only isolation foundation
**Baseline:** `33ded0d2eca9a9e2bb794778df3a40fd908643d1`

## Purpose

This contract establishes the first implementation boundary for Drowned Harbor without making it a production Tale.

P0.13 creates only an unmistakable, export-excluded development identity and automated proof that normal runtime discovery remains unchanged.

## Current production boundary

The production Tale catalog remains:

`game/data/tales/tale_catalog_v1.json`

Its canonical SHA-256 remains:

`2b478fd0d11fa075c2050409193aa06e6b9ca4dcf6efd4e4c550a9f3a5ff9db6`

The catalog contains exactly one entry and defaults to:

`lantern_house_vertical_slice`

The static production provider registry continues to expose only:

`lantern_house_authorities_v1`

Drowned Harbor has no production Tale directory, package, provider, catalog entry, Tale Library card, runtime authority, or ordinary playable export.

## Development-only manifest

The isolation manifest is:

`game/tests/drowned_harbor_prototype_manifest_v1.json`

Its identity is:

`drowned_harbor_dev_only`

The manifest must continue declaring:

- `development_only_export_excluded` status;
- `explicit_test_script_only` launch policy;
- entry points only below `res://tests/`;
- no production catalog registration;
- no production provider registration;
- no normal Tale Library visibility;
- no playable export authorization;
- no runtime authority creation;
- no network, Companion, credential, telemetry, cloud, or production-asset dependency;
- the existing `tests/*` export exclusion;
- future human validation as required;
- no human evidence claim.

Unknown fields or broadened authority fail validation.

## Export isolation

Both accepted internal export presets already use:

`exclude_filter="...tests/*..."`

The development manifest and its Godot proof live directly below `game/tests/`, so ordinary Windows and Linux exports exclude them.

P0.13 does not add an internal Drowned Harbor export profile. A separately reviewed profile may be considered only in a later issue after its exact contents, audience, and evidence boundaries are defined.

## Runtime isolation

Normal Tale discovery starts with the closed production catalog. Because Drowned Harbor is absent from that catalog and provider registry:

- the Tale Library cannot enumerate it;
- selection cannot resolve it;
- the coordinator cannot construct its authorities;
- no normal session can initialize it;
- no player-facing locked or coming-soon entry appears.

The development manifest is data for validation only. It is not a Tale package and cannot name scripts, callbacks, providers, or runtime constructors.

## Validation

### Repository validator

Run:

```bash
python tools/validate_drowned_harbor_prototype_isolation.py
python tools/test_validate_drowned_harbor_prototype_isolation.py
```

The validator checks:

- the exact closed manifest shape;
- dev-only identity and entry paths;
- the production catalog canonical digest;
- one-entry Lantern House inventory and default;
- absence of Drowned Harbor from the production catalog and provider registry;
- absence of a Drowned Harbor production Tale directory;
- Windows and Linux `tests/*` export exclusion;
- no explicit export inclusion of the development manifest or test;
- governing source paths;
- future issue set #81–#86;
- current/future truthfulness in the root README.

The mutation suite rejects eighteen boundary failures, including production registration, Tale Library visibility, playable-export authorization, runtime authority, network or credential dependencies, unsafe entry paths, catalog/provider drift, export-exclusion removal, human-evidence claims, and README status collapse.

### Godot proof

Run:

```bash
Godot_v4.7.1-stable_linux.x86_64 --headless --path game \
  --script res://tests/drowned_harbor_prototype_isolation_test.gd
```

The Godot test independently verifies:

- the manifest parses and remains fail-closed;
- all entry paths remain under `res://tests/`;
- the production catalog validates through existing runtime code;
- Lantern House remains the only production Tale and provider;
- no Drowned Harbor production package exists;
- both internal exports exclude tests.

## README truth boundary

The root README now distinguishes:

- the current internal vertical slice;
- functionality proven by the repository;
- claims that remain unproven without human evidence;
- the intended finished game;
- Tales as the story-mode unit;
- Lantern House as the sole production Tale;
- Drowned Harbor as future design and an isolated development test case.

The README may be aspirational only inside clearly labeled future sections. It may not describe Drowned Harbor as playable, shipped, production-registered, balanced, or human-validated.

## Deferred work

P0.13 does not begin:

- #81 deterministic state and projection fixtures;
- #82 Low-Tide shared-screen shell;
- #83 Bellhouse decision and invalid-action recovery;
- #84 controlled-private shield proof;
- #85 High Water deterministic transformation;
- #86 prototype automation and export-profile work.

Those issues remain blocked until intentionally selected as separate bounded releases.

## Evidence boundary

This release proves repository structure and automated isolation only.

It does not establish gameplay quality, fun, pacing, fairness, balance, controller behavior, television readability, accessibility compliance, privacy certification, network behavior, art quality, audio quality, or release readiness.
