# Operating Mode and Artifact Record Policy

**Version:** 1.0
**Effective:** July 24, 2026
**Status:** Active until the project owner explicitly changes it

## 1. Current operating mode

Until the project owner explicitly says otherwise:

- Codex Desktop and the local Windows repository are unavailable for project work.
- Human, household, remote-observed, physical-controller, television, accessibility, balance, fairness, fun, and pacing playtesting are blocked.
- Automated execution is not human-playtest evidence.
- Preproduction work may proceed without an implementation or playtest dependency.
- Gameplay coding may proceed only when it can be created, reviewed, and validated through the available GitHub and sandbox capabilities without claiming local Windows execution.

## 2. Required GitHub record

Every substantive project output must receive a GitHub record.

Substantive outputs include:

- narrative, dialogue, lore, role, encounter, ending, and localization content;
- visual, audio, video, icon, UI, storyboard, and asset briefs;
- generated asset candidates and their provenance metadata;
- source code, schemas, validators, scripts, tests, and fixtures;
- architecture, security, privacy, multiplayer, accessibility, and production contracts;
- roadmap decisions, release plans, research findings, and tool recommendations.

A GitHub record may be:

1. a committed file on an active preproduction branch;
2. a draft or ready pull request;
3. an issue with a complete decision or work contract;
4. a merged preproduction release.

Chat history is not the authoritative long-term record.

## 3. Work this chat can perform directly

This chat may directly:

- create and update GitHub branches, files, issues, and pull requests;
- write GDScript, Python, JavaScript, TypeScript, JSON, YAML, Markdown, and test fixtures;
- create machine-readable content and validation schemas;
- review repository files and pull-request diffs;
- use GitHub Actions as remote validation when available;
- generate or edit visual assets through available image-generation tools;
- create prompt packs and production briefs for Gemini, Flow, ElevenLabs, Firefly, Runway, Blender, Affinity, REAPER, Aseprite, and similar tools;
- inspect user-uploaded outputs and record approved derivatives and provenance;
- create downloadable documents, spreadsheets, slide decks, and other artifacts when needed.

## 4. Work this chat cannot truthfully claim

Without a connected local execution environment, this chat must not claim that it:

- opened or modified the local Windows checkout;
- ran the Godot editor on the user's desktop;
- verified physical-controller behavior;
- verified living-room television readability;
- heard final audio through the target speaker setup;
- performed human playtesting;
- confirmed local generated-file cleanup;
- confirmed a clean local working tree.

GitHub Actions success is valid automated evidence but does not replace those claims.

## 5. Coding boundary

Codex is not required for all coding.

GitHub-native coding is appropriate when:

- the change can be expressed as reviewable repository files;
- remote CI can validate it sufficiently for its stated purpose;
- no local interactive editor or target hardware is required;
- the release makes only evidence-supported claims.

Examples suitable for this chat include:

- dialogue schemas and validators;
- localization catalogs;
- static data contracts;
- deterministic content-analysis scripts;
- documentation linting;
- asset-manifest and provenance tooling;
- unit tests that can run in GitHub Actions;
- noninteractive GDScript components with bounded automated tests.

Examples that should wait for local access include:

- editor-driven scene composition requiring visual inspection;
- controller feel and input tuning;
- display scaling judged on target hardware;
- local import-side effects and generated Godot metadata cleanup;
- final audio mixing against the actual game build.

## 6. Preproduction release stream

The `P0.x` stream records non-playable preparation without consuming gameplay version numbers.

A preproduction release may contain:

- approved narrative and dialogue corpora;
- visual-development packs;
- audio briefs and audition matrices;
- asset inventories and provenance records;
- reusable schemas and validators;
- implementation-ready design contracts.

A preproduction release must not imply that its content is playable, balanced, fun, tested by humans, or present in the production Tale catalog.

## 7. External AI workflow

When another AI service is used:

1. This repository stores the approved brief and prompt.
2. The project owner runs the external service.
3. Source outputs are uploaded for review.
4. Selected outputs receive provenance metadata.
5. Human edits and transformations are documented.
6. Only reviewed outputs become production candidates.

Secrets, credentials, personal data, private communications, and unreleased sensitive material must not be included in third-party prompts.

## 8. Standing release note

Every assistant response that performs or plans project work should identify the next release target at the end of the response.
