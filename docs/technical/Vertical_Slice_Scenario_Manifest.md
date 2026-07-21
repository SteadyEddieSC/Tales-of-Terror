# Vertical Slice Scenario Manifest

The v1 manifest is `game/data/scenarios/lantern_house_vertical_slice_v1.json`. As of v0.1.4 it is reached only through `game/data/tales/lantern_house/tale_package_v1.json`. `VerticalSliceManifest` still normalizes JSON numbers, rejects unknown top-level and stage keys, validates all authority references against instantiated reviewed content, and accepts only a fixed operation allowlist.

## Required identity and composition

The manifest declares `manifest_version`, stable scenario ID/version, board/rules/Director/social references, Director profile, default and fallback social modes, exact 1–8 seat support, briefing/objective text, ordered stages, terminal/ending/rematch/companion policies, and deterministic fixture seeds/inputs.

Every stage declares a stable ID, public title, entry condition, completion condition, and non-empty bounded operation list. Operations may queue or resolve a known event, submit/resolve the current prompt, open/submit/resolve the authored vote, resolve the reviewed check, apply one named fixture bundle, play a referenced card, evaluate the Director, request a role transition/action, resolve social outcomes, or complete rules. Unknown operations and missing event references fail validation.

The data contains no script paths, callbacks, expressions, loops, network addresses, or executable source. Generic coordinator code interprets only the allowlist and routes work through `RulesSession`, `BoardState`, `DirectorRuntime`/`DirectorProposalApplier`, and `RoleSession` public methods.

## Seat and privacy policy

`hidden_betrayer` is requested by default for 3–8 seats. Its existing authored `cooperative` fallback handles one or two seats. The shared display renders only public views; no-phone private information uses the existing whole-display controlled reveal. Optional companions receive the existing seat/faction-filtered views after explicit stable-seat claim approval.
