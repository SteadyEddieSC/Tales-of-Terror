# Terror Turn — Living Game Design Document

**Version:** 0.6
**Date:** July 13, 2026
**Status:** Pre-production; preferred working title not legally cleared

## Vision

A controller-first, 1–8 player digital horror board-game adventure with shared-screen play, optional private companion devices, rotating horror settings, shifting alliances, an adaptive Underteller/Director, and meaningful play after defeat.

## Story identity

**The Underteller** is an original undead master of ceremonies who stages living horror tales across impossible boards. He introduces scenarios, comments on player decisions, escalates danger, recaps connected chapters, and delivers personalized epilogues.

The working title **Terror Turn** refers to both board-game turns and signature reversals where the board, objective, loyalty, or player state changes. It is branding, not a requirement that every ordinary turn trigger a twist.

A Tale may remain cooperative, reveal a betrayer, elevate one player into the Horror, split teams, or form a third faction called **The Changed**—zombies, thralls, alien copies, werewolves, cursed clowns, revenants, or another scenario-specific group.

## Design pillars

1. Board game first.
2. Horror is social.
3. No player becomes irrelevant.
4. Every chapter tells a memorable story.
5. Readable on a living-room TV.
6. Private devices are optional but powerful.
7. Systems before content volume.
8. Quality over speed.

## Art direction

An original modern storybook/cel-shaded horror style between the approved colorful shared-screen concept and the dramatic weight of hand-inked gothic games: thick expressive outlines, angular readable silhouettes, painterly textures, dramatic lighting, smooth animation, strong player color/symbol identification, and 2D/2.5D board dioramas. Do not copy Darkest Dungeon assets, UI, characters, compositions, or exact rendering techniques.

The reusable production baseline is defined in docs/art/Visual_Language_Guide.md. Interface values live in replaceable Godot Theme/token resources rather than controller or seat logic. The Terror Turn wordmark remains live provisional text pending formal clearance; do not bake it into production imagery.

**Logical viewport:** 960×540, 16:9. UI renders cleanly at output resolution for 720p, 1080p, and 4K. Compatibility renderer is the baseline for future WebGL 2 support. The input/display foundation keeps controller discovery, reusable seat ownership, and presentation separate; disconnected device identities reserve their seat for reconnection.

## Presentation profiles

- **Spooky** — stylized peril and softer presentation.
- **Grim** — intended default storybook-horror experience.
- **Gore & Dread** — optional mature blood, body-horror, and narration variants.

Gameplay rules remain equivalent across profiles.

## Modes

- Chronicle Campaign
- Standalone Tale
- Quick Fright
- Betrayal
- Hunted (1 vs many)
- Outbreak (dynamic third faction)
- Mystery
- Rival Teams
- Last Light Survival
- Director’s Cut custom mode

## Factions and afterlife

The Living, Betrayer, Horror, Changed, and Restless have scenario-specific objectives. Defeated players transition into zombies/infected, wraiths, monster minions, guardian spirits, witnesses, or replacement investigators instead of becoming passive spectators.

The v0.0.8 foundation represents those categories through validated authored factions and roles/forms rather than hardcoded paths. A Tale selects an explicit social mode: cooperative, hidden/revealed betrayal, Hunted transformation, Outbreak conversion, faction teams, mixed objectives, or a clearly warned no-afterlife variant. Unsupported player counts select an authored no-secret fallback instead of creating a nonsensical hostile layout.

Role, faction, objective, and capability ownership follows the stable seat through disconnect and reconnect. The public television shows only deliberately public identity, cover, lifecycle, objectives, actions, and results. A controlled pass-and-play reveal obscures the whole display and authorizes one stable seat; optional companion devices consume the same filtered views but do not own rules.

Defeat normally opens a meaningful Restless path within one bounded transition: a wraith may place an omen, a guardian may warn, a witness may testify, or an authored replacement may return. Death, faction defeat, individual defeat, and victory are separate authored outcomes. Endings can name several winning factions or individuals and retain partial, escaped, Changed, or Restless results.

## Initial campaign/location targets

Greymoor, Blackpine, Last Laugh, Red Moon, Starfall, Castle Vesper, Drowned Harbor, and Winterbound. Exact names remain editable. Monsters and threats are original, including public-domain-inspired vampires, werewolves, ghosts, zombies, aliens, clowns, slashers, witches, sea creatures, and cosmic threats. Recognizable commercial horror characters require licenses and are not base-game content.

## Underteller and Director

The Underteller is fiction and interface. The Director begins as an authored, rule-based and deterministic pacing system—not a cloud language model. It watches approved rules/board telemetry plus only allowlisted public or aggregate social signals, then adjusts authored event weights, spawn timing, clues, scarcity, music, lighting, and hints within scenario limits. It cannot inspect unrevealed roles, private objectives, targets, messages, or transition plans.

## Technology

- Official Godot 4.7.1-stable; typed GDScript; Compatibility renderer.
- Windows/Linux first; Batocera through Linux validation; Android/Android TV later.
- Native Godot host owns gameplay initially.
- The v0.0.9 Cloudflare-compatible prototype handles only ephemeral room membership, join codes, filtered relays, reconnect capabilities, and companion communication.
- Companion-first online roadmap; full browser/remote parity only after the local vertical slice.

The v0.0.9 companion prototype now proves that boundary locally. A transport-neutral Godot bridge generates filtered public, stable-seat private, and authored faction-private projections on demand. Browser devices submit bounded prompt or role-action intents; the native authorities revalidate and apply them exactly once. The replaceable Cloudflare-compatible coordinator owns only short-lived communication membership, capabilities, ordering, limits, heartbeat, and expiry. It owns no gameplay or player profile.

Join codes are public routing handles and remain distinct from opaque host/resume capabilities. A browser waits for explicit host approval of an existing stable seat, and reconnect restores only that same seat without transferring controller ownership. One seat may use its local controller plus one approved companion surface; revision, request-ID, and authority-level response/use rules reject duplicated input deterministically.

Private browser content is gated and removable, but HTTPS/WSS is transport protection rather than end-to-end encryption against the relay operator. Local shared-screen/controller play remains complete when the service is disabled or unavailable. Production deployment, accounts, matchmaking, campaign persistence, full remote play, and security certification remain later work.

## Shared exploration foundation

The v0.0.4 sandbox establishes seat-owned local pawns in one authored room. Each pawn combines color, Roman numeral, and seat-count pattern, moves through CharacterBody2D collision, and remains attached to its reserved seat through reconnects. Device discovery and presentation remain separate from ownership.

The default camera frames the full active group and adjusts zoom inside authored bounds. Extreme separation first produces a visible warning and outward resistance, then blocks only further outward motion while always permitting regrouping. It does not split the screen or silently relocate players.

Nearby interactions use a reusable focus/request contract. Until a later turn or initiative system exists, simultaneous requests for the same prop resolve to the lowest seat number; distinct props may resolve together.

## Living Board foundation

The v0.0.5 Living Board Engine maps continuous exploration into authored named spaces and typed connectors. Rules reason about stable board IDs, regions, occupancy, reveal state, hazards, features, blockers, and traversability while pawns continue moving smoothly inside those regions. Shared boundaries resolve deterministically and positions outside every authored region remain explicit.

Board definitions are immutable scenario inputs. The native Godot host owns mutable `BoardState`, validates every mutation before application, increments an auditable revision/history only for accepted changes, and can round-trip a versioned in-memory debug snapshot. Presentation follows emitted changes and supplements color with names, symbols, patterns, outlines, and Roman numeral occupancy.

Lowest-seat arbitration remains a temporary deterministic conflict rule, not a turn or initiative system. Future turns, cards, events, Director requests, companions, and networking must request or replicate authoritative mutations rather than directly editing board data.

## First ten releases

1. v0.0.1 Foundation
2. v0.0.2 Input & Display Lab
3. v0.0.3 Visual Language Lab
4. v0.0.4 Shared Exploration Sandbox
5. v0.0.5 Living Board Engine
6. v0.0.6 Turn, Event & Card Engine
7. v0.0.7 Dread Director
8. v0.0.8 Roles, Factions & Afterlife
9. v0.0.9 Companion Room Prototype
10. v0.1.0 First Vertical Slice

The detailed scope, exit gates, risks, accessibility baseline, and technical references are retained in the versioned DOCX export.

## Turn, event, and card rules loop

The v0.0.6 rules foundation advances a configurable round-start, player-decision, resolution, event, and cleanup loop. Stable seats make explicit choices, pass, resolve public votes and seeded checks, play authored cards, and retain separate inventory. Every accepted action and consequence is ordered and reproducible.

Authored events and cards are declarative validated inputs. The native `RulesSession` owns rules state, while Living Board changes remain requests to `BoardState`. The provisional host consumes replaceable presentation payloads and never decides rules. Dread Director selection, factions/afterlife, companion-private state, networking, and campaign persistence remain later layers.

## Dread Director pacing loop

The v0.0.7 Dread Director is a local deterministic authored system, separate from the replaceable fictional host. It reads a normalized copy of authoritative rules/board telemetry, estimates current tension against an authored pacing curve, records an explainable component score for every legal candidate, and proposes one bounded action or an intentional hold.

Pressure, relief, clue, event, board, and ambient proposals obey authored budgets, cooldowns, repetition penalties, seat-target caps, disconnect exclusion, mercy, recovery windows, and rolling pressure limits. The Director owns a separately salted RNG that cannot affect checks or decks and never directly mutates `RulesSession` or `BoardState`. Struggling groups receive recovery space, cruising groups may receive bounded escalation, and stalled groups receive clues or nudges rather than repeated punishment. This protects pacing and recoverability without guaranteeing victory or completing final balance.

## Roles, factions, and afterlife loop

The v0.0.8 `RoleSession` separately owns social assignment, current faction/form, reveal/lifecycle state, private objectives/actions, bounded uses, transitions, outcome references, and a dedicated salted RNG. Authored social content is validated before assignment; fixed plans consume no randomness, invalid plans consume none, and one-seat betrayal selects the declared cooperative fallback.

Social actions validate stable-seat authority, form/lifecycle, targets, phase, use bounds, and cooldowns. General and board consequences cross the existing `RulesSession` and `BoardState` transaction boundary before role state commits. Rejected multi-system work leaves every authority unchanged. Public, seat-private, faction-private, and diagnostics views are built independently, with recursive privacy regression checks and full spoiler separation.

## Companion room loop

The v0.0.9 host creates one ephemeral room for up to eight optional browser companions. A browser enters the human join code, waits while the public host approves a stable seat, passes an explicit privacy gate, receives only that seat's filtered role/objective/prompt/action information, submits one bounded intent, and may disconnect/resume the same seat with an opaque room-scoped capability.

The room coordinator relays already-filtered views and intents; it does not run the board, rules, roles, Director, pawns, controllers, seats, RNG, cards, inventory, or outcomes. Wrong-seat, stale, duplicate, malformed, tampered, expired, rate-limited, and unsupported work fails closed. Invalid network work consumes no gameplay randomness and creates no partial gameplay mutation. Room loss disconnects companions safely while native play continues.

The native host adapter now proves the real local loop through the ephemeral service and back to the browser's authoritative acknowledgement. Wire naming is converted explicitly at the transport boundary, relay time windows survive Durable Object reload without relying on test-only steps, client traffic cannot mask host loss, and unrevealed authored board spaces are absent from every public companion projection.

## First vertical slice

The v0.1.0 Lantern House tale is the first coherent player route through the reviewed foundations. A clean launch moves through title, local stable-seat lobby, scenario and social-mode confirmation, public briefing, active tale stages, deterministic terminal resolution, public ending, and clean rematch or return to title. Hidden Betrayer is the default for three to eight seats; one or two seats receive the authored cooperative fallback.

The tale opens the iron threshold, reveals the archive, resolves a public route vote and deterministic courage check, grants and plays a card, permits one bounded Director decision, and gives a defeated investigator a Restless action before mixed outcomes resolve. These are modest authored fixtures for integration review, not balance or fun certification.

`VerticalSliceCoordinator` owns session-scoped references to the existing authorities and routes only bounded manifest operations through their public methods. The JSON manifest cannot name scripts or callbacks. Complete content and snapshot validation happens before mutation, a failed stage restores every authority snapshot, the Director sees only normalized public social signals, and optional browsers remain filtered input surfaces rather than authorities.

## Tale package authoring boundary

The v0.1.4 Lantern House route is selected through one versioned repository-authored Tale package. It references the accepted manifest and existing authority content, declares seat/mode/fallback/privacy/afterlife compatibility, publishes a deterministic inventory and source ledger, and has a canonical SHA-256 identity. It does not add content or become gameplay authority.

Only reviewed allowlisted identities load. Unknown schema fields, broken references or reachability, unsafe paths/URLs/secrets, unresolved governed text, incompatible social declarations, unstable ordering, and source-hash changes fail closed before authority construction. Package provenance remains outside saves, reports, gameplay RNG, and outcome decisions. This repository contract is not a public modding SDK.
