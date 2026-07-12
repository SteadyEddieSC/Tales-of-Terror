# Terror Turn — Living Game Design Document

**Version:** 0.2  
**Date:** July 11, 2026  
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

**Logical viewport:** 960×540, 16:9. UI renders cleanly at output resolution for 1080p and 4K. Compatibility renderer is the baseline for future WebGL 2 support.

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

## Initial campaign/location targets

Greymoor, Blackpine, Last Laugh, Red Moon, Starfall, Castle Vesper, Drowned Harbor, and Winterbound. Exact names remain editable. Monsters and threats are original, including public-domain-inspired vampires, werewolves, ghosts, zombies, aliens, clowns, slashers, witches, sea creatures, and cosmic threats. Recognizable commercial horror characters require licenses and are not base-game content.

## Underteller and Director

The Underteller is fiction and interface. The Director begins as an authored, rule-based and deterministic pacing system—not a cloud language model. It watches health, resources, distance, conflict, skill, time, faction balance, recent events, and inactivity, then adjusts authored event weights, spawn timing, clues, scarcity, music, lighting, and hints within scenario limits.

## Technology

- Godot 4.7 stable; typed GDScript; Compatibility renderer.
- Windows/Linux first; Batocera through Linux validation; Android/Android TV later.
- Native Godot host owns gameplay initially.
- Cloudflare later handles room membership, join codes, private state, reconnect metadata, and companion communication.
- Companion-first online roadmap; full browser/remote parity only after the local vertical slice.

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
