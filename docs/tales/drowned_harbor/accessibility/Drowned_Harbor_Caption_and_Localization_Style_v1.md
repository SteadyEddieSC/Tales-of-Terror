# Drowned Harbor Caption and Localization Style

**Version:** 1.0
**Status:** P0.7 preproduction style contract
**Tale status:** Design-only
**Production approval:** None
**Depends on:** `docs/accessibility/Localization_Captions_and_Accessible_Narrative_Direction_v1.md`

## 1. Tale identity in text

Drowned Harbor copy should feel:

- cold and maritime;
- materially specific;
- elegant but readable;
- attentive to names, records, routes, bells, lenses, rope, and returning water;
- dark without relying on illegible typography or vague fragments;
- capable of humor without mocking the player;
- exact when mechanics matter.

Atmosphere may surround the instruction. It may not replace it.

## 2. Speaker keys

Use localizable keys rather than provisional displayed names:

- `speaker.host` — the provisional Underteller role;
- `speaker.system` — neutral plain-system information;
- `speaker.harbor` — publicly authorized Harbor-origin text;
- `speaker.bellhouse` — public mechanism text where a distinct label is useful;
- `speaker.lighthouse` — public mechanism text where a distinct label is useful;
- `speaker.seat` — a public seat statement when authored;
- `speaker.none` — captions or persistent text with no speaker.

The default player-facing label for `speaker.host` remains localizable and may be changed after issue #7. Stable source IDs must not contain the final marketing name.

## 3. Terminology register

### Stable seat

Definition:

> The persistent gameplay identity that owns character state, role, faction, form, inventory, objectives, location, injuries, transformations, continuation state, and outcome history.

Avoid:

- player slot when discussing persistent state;
- bot character;
- replacement character;
- respawned player;
- disconnected character.

Constrained UI form:

- `Seat` only where persistent meaning is already clear.

### Human control

Definition:

> A human currently supplies decisions for the stable seat.

Avoid:

- human character;
- owner of the character;
- original player when another human may legally take over.

### Game control

Definition:

> The deterministic surrogate currently supplies legal decisions for the same stable seat.

Avoid:

- bot replacement;
- AI character;
- NPC takeover;
- reset.

### Bellhouse

Definition:

> The public bell-and-record mechanism that indexes names, marks, and unresolved positions.

Capitalization:

- capitalized as a unique landmark and mechanism.

Avoid:

- church;
- chapel bell;
- prophecy tower;
- death bell unless a specific public event authorizes that description.

### Bellmarked

Definition:

> A publicly revealable preservation-aligned faction identity whose exact motive and objective may vary.

Avoid:

- traitor as an automatic synonym;
- evil faction;
- cultist unless a separate authored role uses that term;
- doomed.

### Tidebound

Definition:

> A public transformed form that preserves stable-seat agency while changing capabilities and restrictions.

Avoid:

- zombie;
- infected as a universal synonym;
- possessed;
- monster player;
- eliminated player.

### Bell-Witness

Definition:

> A Restless continuation form associated with Bellhouse warnings and public actions.

Avoid:

- ghost spectator;
- dead player;
- eliminated seat.

### Drowned Guide

Definition:

> A Restless continuation form associated with submerged routes and navigation.

Avoid:

- drowned NPC;
- ghost guide as a generic replacement;
- route answer.

### Lighthouse Guardian

Definition:

> A Restless continuation form associated with lighthouse protection and potential sacrifice actions.

Avoid:

- angel;
- martyr as an automatic description;
- automatic sacrifice;
- dead player.

### Low Tide

Definition:

> The exposed Harbor stage before the High Water transformation.

Capitalization:

- capitalized when referring to the authored stage or state;
- ordinary lowercase for generic tidal description.

### High Water

Definition:

> The committed Terror Turn stage in which the public board changes to flooded route geography.

Avoid:

- flood cutscene;
- automatic disaster loss;
- tsunami.

### Last Light

Definition:

> The final public decision stage.

Avoid:

- final battle;
- good-ending choice;
- bad-ending choice.

### Harbor bargain

Definition:

> An optional governed transaction whose authorized terms appear on the proper public or private surface.

Avoid:

- deal with the devil;
- automatic trap;
- mandatory bargain;
- free reward.

### Drowned Archive

Definition:

> The publicly accessible record location containing damaged histories and several possible objectives or interpretations.

Avoid:

- magical library;
- truth room;
- guaranteed correct answer.

## 4. Capitalization

Capitalize unique authored places, stages, forms, and factions where they function as proper names:

- Drowned Harbor;
- Bellhouse;
- Salt Market;
- Drowned Archive;
- Bellhouse Ledger;
- Low Tide;
- High Water;
- Last Light;
- Bellmarked;
- Tidebound;
- Bell-Witness;
- Drowned Guide;
- Lighthouse Guardian.

Do not capitalize generic uses of:

- harbor;
- lighthouse;
- bell;
- tide;
- route;
- seat;
- water;
- archive.

Translation teams may adjust capitalization to the target language's conventions while preserving term identity.

## 5. Public-state placeholders

Approved provisional placeholders:

| Placeholder | Meaning | Privacy |
|---|---|---|
| `{seat_name}` | Localized public stable-seat display name | Public only when the seat is publicly named |
| `{route_name}` | Localized public route or space name | Public |
| `{location_name}` | Localized public landmark | Public |
| `{form_name}` | Localized publicly revealed form | Public after reveal |
| `{faction_name}` | Localized publicly revealed faction | Public after reveal |
| `{count}` | Public count rendered with locale-aware number rules | Public |
| `{action_name}` | Localized legal public action | Public |
| `{stage_name}` | Localized public stage | Public |
| `{item_name}` | Localized public item name | Public only when item identity is public |

Disallowed public placeholders include:

- private objective text;
- hidden faction identity;
- latent transformation state;
- private bargain cost;
- hidden target;
- private item or route knowledge;
- account, network, or voice-derived identity.

## 6. Speech captions

Use the localizable speaker label plus spoken text when labels are enabled.

Example:

```text
HOST: High Water is active. Land and water routes have changed as shown.
```

Do not use quotation marks around every spoken caption.

Profile wording may differ, but the plain-system text and mechanical-equivalence key remain available in transcript details or plain-language mode.

## 7. Non-speech Harbor captions

Preferred forms:

- `[The Bellhouse rings.]`
- `[A bell rings once beyond the visible count.]`
- `[The Bellhouse ropes pull taut.]`
- `[Water enters {route_name}.]`
- `[The lifeboat mooring strains.]`
- `[The lifeboat breaks free.]`
- `[The lighthouse lens begins to turn.]`
- `[The Drowned Archive gives way.]`
- `[Human control ends; the stable seat remains.]`
- `[Game control activates for the same stable seat.]`
- `[Human control returns to the same stable seat.]`

Use sentence case and terminal punctuation for complete caption statements.

## 8. Hidden-cause protection

Captions describe the public effect, not a hidden author.

Do not write:

- `[The Bellmarked player rings the bell.]`
- `[A hidden objective causes the route to fail.]`
- `[The future Tidebound seat begins changing.]`
- `[The correct destination calls from the lighthouse.]`
- `[The surrogate discovers a private route.]`

When the cause becomes public, a later unit may state it.

## 9. Spatial captions

Directional wording may be used only when:

- direction is public;
- it is useful to orient the shared board;
- a visual indicator also exists;
- the caption remains understandable in mono and without spatial audio.

Preferred:

- `[Water rises near the Salt Market.]`
- `[A collapse begins beyond the Bellhouse.]`

Avoid relying on:

- left;
- right;
- rear channel;
- headphone direction;
- caption position alone.

Board geography should use localized landmark and route names.

## 10. Caption segmentation

Split at mechanical and grammatical boundaries.

Preferred:

```text
High Water is active.
Land and water routes have changed as shown.
```

Avoid:

```text
High Water is active. Land and
water routes have changed as shown.
```

Do not separate:

- `not` from its verb;
- a count from its noun;
- a route name across lines where avoidable;
- `stable seat` across lines where it could read as ordinary furniture;
- form prefixes and suffixes such as `Bell-Witness`.

## 11. Persistent panel copy

For critical decisions, persistent text should use this order:

1. stage or event label;
2. public state summary;
3. required action;
4. legal choices;
5. public consequence preview;
6. confirmation rule;
7. replay, transcript, or help access.

Example:

```text
LAST LIGHT
Choose one displayed final option.
Review each public consequence.
The choice commits only after confirmation.
```

The theatrical voice line may play around this panel, but the panel remains mechanically authoritative.

## 12. Plain-language copy

Plain-language Drowned Harbor copy should:

- name the current state first;
- use one action per sentence;
- distinguish warning from committed loss;
- distinguish human control from stable-seat state;
- distinguish public reveal from private information;
- distinguish transformation from elimination;
- avoid maritime metaphor before the instruction.

Preferred:

> The named public route is unstable. Collapse has not committed. Choose one displayed response.

Avoid:

> The street is considering whether it still wishes to carry you.

The latter may be used as flavor only when the direct instruction remains visible.

## 13. Transcript labels

Suggested localized event labels:

- Opening;
- Stage Change;
- Public Warning;
- Public Reveal;
- Transformation;
- Continuation;
- Control Change;
- Bargain;
- Decision;
- Ending Result;
- System Guidance.

Transcript entries must not expose internal IDs or diagnostic hashes in ordinary player view.

## 14. Reading-order examples

### Bellhouse reveal

1. Bellhouse Ledger heading;
2. public count;
3. extra-ring caption;
4. unresolved-position explanation;
5. currently legal actions;
6. replay and transcript.

### Tidebound transformation

1. public seat name;
2. public form change;
3. active-seat continuity;
4. displayed capability changes;
5. current legal actions;
6. replay and details.

### Human takeover

1. control-change confirmation;
2. same stable-seat statement;
3. public evolved-state summary;
4. private-surface instruction;
5. continue control.

### Mixed ending

1. ending family;
2. public seat result segments;
3. public faction result segments;
4. unresolved or shared Harbor result;
5. transcript and Chronicle note where later approved.

## 15. Text expansion priorities

When text grows:

1. reflow and enlarge the panel;
2. reduce decorative margins;
3. move optional lore to details;
4. paginate at semantic boundaries;
5. preserve action labels and consequences;
6. never reduce below the configured readable scale merely to retain the original composition.

The visual world may crop or reposition decor. Critical text may not be clipped.

## 16. Profile equivalence review

For each Spooky, Grim, and Gore & Dread set, reviewers should compare:

- public facts;
- legal actions;
- consequence certainty;
- timing implication;
- placeholder set;
- privacy;
- stable-seat continuity;
- ending attribution.

Differences in imagery are acceptable. Differences in mechanics are not.

## 17. Pseudolocalization examples

A pseudolocalized test may:

- expand words by 35–50 percent;
- add accented characters;
- wrap `Drowned Harbor`, `Lighthouse Guardian`, and long player names;
- preserve `{route_name}` and other placeholders exactly;
- simulate right-to-left container order without mirroring fixed board geography;
- test two-line captions and persistent panels simultaneously;
- use long-form speaker labels.

Pseudolocalized strings must be visibly nonproduction and never mistaken for a real locale.

## 18. Approval boundary

This style contract does not approve final English copy, translations, caption segmentation, layout, timing, fonts, speaker labels, assistive-technology behavior, right-to-left support, accessibility claims, or Drowned Harbor runtime integration.
