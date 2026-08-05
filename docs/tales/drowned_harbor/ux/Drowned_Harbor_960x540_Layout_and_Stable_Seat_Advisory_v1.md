# DH-UX-001 — 960×540 Layout and Stable-Seat Advisory v1

## Standing

All coordinates and sizes are advisory logical-review hypotheses. They are not
implemented, source-art authority, final component specifications, television-
readability evidence, accessibility evidence, or issue #39 human evidence.

## Logical canvas and safe areas

| Region | X | Y | Width | Height |
|---|---:|---:|---:|---:|
| Logical canvas | 0 | 0 | 960 | 540 |
| Critical inner 90% safe area | 48 | 27 | 864 | 486 |
| Decorative safe area | 24 | 14 | 912 | 512 |

Critical actions, objectives, seat identity, captions, confirmation, and legal
prompts should remain inside the critical safe area during review.

## Persistent bands

| Region | X | Y | Width | Height |
|---|---:|---:|---:|---:|
| Upper status | 48 | 27 | 864 | 56 |
| Board/action | 48 | 83 | 864 | 348 |
| Caption reserve overlay | 48 | 377 | 864 | 54 |
| Stable-seat rail | 48 | 431 | 864 | 58 |
| Controller prompts | 48 | 489 | 864 | 24 |

The caption reserve intentionally occupies the lower part of the board/action
region. It is an overlay reserve, not a separate non-overlapping band. Captions
require a high-contrast backing and may not hide a critical route, objective, or
seat.

## Upper status review subdivisions

| Region | X | Y | Width | Height |
|---|---:|---:|---:|---:|
| Stage and objective | 48 | 27 | 312 | 56 |
| Tide/transformation | 360 | 27 | 240 | 56 |
| Authority/status | 600 | 27 | 312 | 56 |

These are proposed reading-order anchors. Exact typography, wrapping, and
component boundaries remain unresolved.

## Board-first review composition

- Board/action region: `x=48, y=83, w=864, h=348`.
- Caption backing hypothesis: `x=180, y=377, w=600, h=54`.
- A transient detail panel may use a governed non-route occlusion zone.
- No persistent decision drawer.

## Decision-focus review composition

- Board context: `x=48, y=83, w=544, h=348`.
- Gap: `12 px`.
- Drawer hypothesis: `x=604, y=83, w=308, h=348`.

The 308-pixel drawer is a feasibility hypothesis. It must be tested with actual
fonts, controller glyphs, long tokens, 135% pseudo-localization, captions, and
safe-frame constraints. A modal fallback is advisory only and does not authorize
a new runtime overlay or action.

## Transformation review composition

The board retains the full board/action region. A settled changed-state summary
may use up to the lower 64 pixels after the presentation. Skip and reduced-motion
controls appear only when existing authority exposes them.

Effects may extend toward decorative edges but cannot hide upper status,
changed-state summary, legal routes, or the stable-seat rail.

## Outcome-attribution review composition

| Region | X | Y | Width | Height |
|---|---:|---:|---:|---:|
| Public ending/result header | 48 | 83 | 864 | 52 |
| Public outcome rail | 48 | 135 | 864 | 132 |
| Public epilogue/consequence | 48 | 279 | 864 | 152 |

Private attribution is excluded. An authorized private handoff uses the neutral
shield instead.

## Private-shield review composition

- Neutral shield: `x=48, y=27, w=864, h=486`.
- The message is centered and generic.
- No seat number, role icon, color, timer, or private category.
- Public captions and transcript are hidden while the private projection is
  active.
- Private content appears only on an authorized private surface.

The private-surface technology is unselected.

## Stable-seat rail hypotheses

### One to four seats

- target tile width: `156–200 px`;
- target tile height: `54 px`;
- minimum gap: `8 px`;
- tiles centered as a group;
- existing stable seats do not reorder during reconnect, surrogate control, or
  transformation.

### Five to eight seats

- eight-seat tile target: `104 px`;
- gap target: `4 px`;
- eight tiles plus seven gaps: `860 px`;
- available rail width: `864 px`;
- target tile height: `50–54 px`;
- no horizontal scrolling.

The four-pixel total remainder is intentionally recorded as a risk. The 104-pixel
target is not accepted as a final component size. It must survive actual
typography, glyphs, multiple identity channels, public condition indicators,
135% pseudo-localization, and issue #39 living-room review.

Compact details may open only through an existing authorized public-safe
details intent; registration creates no drawer action.

## Stable-seat information priority

1. stable-seat number;
2. active/focus state;
3. authorized public form or role;
4. control source;
5. required action;
6. authorized public condition/location.

No state relies on accent color alone.

## Focus and action planning tokens

### Focused

- high-luminance edge or corner bracket;
- stable focus icon;
- visible action label;
- optional low-amplitude pulse only when reduced motion is not selected.

### Selected preview

- filled inner plate or pattern;
- explicit `Preview — not committed` language;
- no committed checkmark;
- public consequence from governed public projection only.

### Confirmation pending

- distinct confirmation panel;
- selected action named plainly;
- irreversible/reversible status;
- confirm and cancel shown together.

### Committed

- persistent `Committed` text;
- check or lock symbol;
- focus leaves the choice;
- presentation begins only after authority reports commitment.

### Unavailable and recovery

Unavailable actions do not appear as legal prompts. Recovery explains the
public-safe reason and returns focus to a legal alternative without state or RNG
mutation.

## Type-size starting hypotheses

| Use | Logical size |
|---|---:|
| Major stage/title | 24 px |
| Panel heading | 20 px |
| Body/action label | 18 px |
| Upper status and seat text | 16–18 px |
| Critical caption | 22 px |
| Secondary text | 14–16 px |

These are starting targets, not final standards or evidence. Critical text should
not be reduced merely to preserve decorative margins.

## Text expansion

Review at least 135% pseudo-localized expansion and long unbroken tokens. Wrap
critical content rather than truncate it. Do not use marquees for legal actions,
consequences, captions, or private terms.

## Required future evidence

- actual 960×540 Compatibility-renderer captures;
- one-, four-, and eight-seat density;
- safe-frame and occlusion;
- grayscale/value and non-color identity;
- text expansion;
- reduced motion;
- interruption, restore, and presentation replay;
- physical controllers and television distance under issue #39.
