# Turn, Event & Card Engine

## Authority boundaries

- `LanternHouseRulesContent` authors the sandbox definitions. It contains no executable callbacks.
- `RulesContent` validates identities, references, conditions, effects, prompt cardinality, and obvious recursive chains.
- `RulesSession` owns runtime rules state and emits presentation payloads.
- `BoardState` remains the exclusive Living Board mutation authority.
- `RulesHud` and diagnostics render copied state and submit seat-scoped semantic responses.

The future Dread Director may request events through the queue. Future faction/afterlife state, companion-private choices, network replication, and campaign save/load do not belong to this model.

## Determinism and timing

The session uses a Park–Miller deterministic stream with an initial seed, current state, and draw counter. Checks validate before drawing. Fisher–Yates deck shuffle and checks share this stream, so snapshot plus ordered inputs reproduces outcomes.

The configured loop is `round_start → player_decision → resolution → event → cleanup`. There are no real-time deadlines. Ready/pass and prompt revisions reject duplicates and stale input. Reserved seats remain eligible and retain responses; reconnect only changes connection status. Late joins queue until the next `cleanup → round_start` boundary.

## Prompt and vote contract

Prompts use stable option IDs, display text, min/max selection counts, eligibility seats, pass policy, and phase revision. A response is immutable after acceptance. Multi-seat resolution counts responses in sorted seat order; equal totals resolve by lexical stable option ID.

Public votes add rule, quorum, abstention, and tie-policy audit fields. The sandbox uses plurality, quorum one, and stable-option-ID ties. Hidden/private voting is intentionally absent.

## Checks

Definitions specify dice, sides, fixed/state-counter modifiers, optional advantage sign, and threshold bands. Results record source, acting seat, sorted raw values, modifier, total, outcome, and RNG counters before/after.

## Cards and inventory

Every shuffled/granted card gets a stable `card_####` instance ID. Zones are draw, per-seat hand, discard, exhausted, and removed. Card play preflights ownership, phase conditions, target count, and effects before changing a zone. Inventory is a separate per-seat stable-ID collection. Shared-screen hands are an explicit development view and are not private.

## Consequences and conflict behavior

Supported effects are board mutation, counter/flag/result changes, draw/grant/discard/exhaust/remove card, add/remove item, queue event, and narrative history. Bundles preserve authored order and are atomic. Preflight uses a cloned BoardState snapshot; an invalid, unknown, idempotent, or impossible effect rejects without partial changes. Repeated accepted effects are history-visible; effects are not assumed idempotent.

## Snapshots and diagnostics

Version-1 snapshots include content/session identity, RNG, round/phase, seats, prompt responses, events, counters/flags, all card zones, inventory, vote, checks/effects, history, and the BoardState snapshot. Restore validates into temporary state and fails atomically on version/content/reference errors.

Diagnostics expose all these fields. Normal HUD content remains within the 0–48 px safe frame and combines words with symbols and shapes.

## Player HUD priority and focus policy

`RulesHud` builds a deterministic player-facing view model rather than rendering the raw diagnostics snapshot. Stable IDs are resolved through authored names or title-cased fallback labels. Seed, RNG counter, phase revision, raw IDs, effect history, and queue details remain exclusive to toggleable diagnostics.

While a prompt or public vote is open, the HUD prioritizes the friendly round/phase, presenter title, choice options, and every participating seat. Each seat combines Roman numeral, a distinct shape, a seat-count pattern, and a textual/status symbol for unresolved current focus (`○`/`▶`), submitted lock (`✓`), pass/abstain (`—`), or ineligible (`×`). Accepted responses cannot be moved.

At terminal state, the result is always shown before host, check, and compact card/inventory summaries. Recent history and additional detail never compete with essential content; the fixed panel displays an explicit `More details: Diagnostics` continuation. The tested player-content budget is 18 lines inside the 420×344 panel at 0, 24, and 48 px safe margins.
