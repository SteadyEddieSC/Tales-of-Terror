# Terror Turn Visual Language Guide

**Status:** v0.0.3 production baseline

**Branding:** Provisional and replaceable pending formal clearance

## Direction

Terror Turn uses an original modern storybook-horror language: thick expressive outlines, angular and readable silhouettes, restrained painterly texture, theatrical pools of light, and a 2D/2.5D board-diorama viewpoint. Shape and value must communicate before surface detail. Never reproduce another game's characters, interface, compositions, or exact rendering method.

The provisional wordmark is plain live text. Keep it out of baked artwork so a future name change affects copy and localization resources, not production imagery.

## Typography

- Display: 27–36 logical pixels, short uppercase phrases, warm parchment or warning gold.
- Section: 16–20 logical pixels, uppercase, concise.
- Essential body/status: 15 logical pixels minimum at the 960×540 viewport.
- Secondary diagnostics: 14 logical pixels minimum and never the only state cue.

Use the engine's default font until an original or properly licensed family is selected. Favor generous line spacing and short measures. Do not encode state with decorative lettering alone.

## Spacing and composition

Use an 8-pixel base rhythm with 4-pixel half steps. Primary safe margins begin at 24 logical pixels and can be tested from 0–48. Group seats in a 2×4 grid so each card retains a strong silhouette at 720p. Reserve 16–24 pixels between major regions and 6–10 inside compact controls.

## Panels, borders, and shadows

Panels resemble imperfect inked placards: dark violet-black fills, asymmetric 2–8 pixel corner radii, and two-pixel charcoal borders. Active and warning cards gain a four-pixel colored leading edge. Shadows are broad, dark, and subtle; they separate layers without simulating glossy software chrome.

## Icons and player identity

Icons are bold single-color silhouettes with rounded joins and a heavy outline. Every player has both a stable color and a Roman-numeral symbol. Color is supplemental, never the only identifier. Final controller glyphs remain replaceable resources.

## State palette

- Neutral/parchment: readable information and inactive states.
- Green: connected and ready.
- Amber: focus, caution, and adjustable test boundaries.
- Red: disconnected, reserved, danger, or destructive action.
- Eight player hues: identity only; they do not redefine success or danger.

## Motion

Use 120–180 ms focus transitions, 180–260 ms panel reveals, and slow 1–3 second ambient light movement. Favor deliberate ease-out motion, small scale shifts, and restrained overshoot. Respect a future reduced-motion setting and never animate essential text continuously.

## Reusable in-engine primitives

game/assets/theme owns palette and Theme resources. LabBackdrop supplies a subtle board-diorama silhouette, while SeatCard owns seat-card composition, player symbol/color, status badge, active/focus treatment, and reconnect warning treatment. Presentation scripts consume these resources; controller and seat models do not.
