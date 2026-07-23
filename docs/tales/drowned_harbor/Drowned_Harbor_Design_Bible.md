# Drowned Harbor — Design Bible

**Version:** 0.1  
**Status:** Preproduction design authority  
**Working Tale ID:** `drowned_harbor`  
**Working display name:** Drowned Harbor  
**Classification:** Coastal folk horror, supernatural survival, shifting-faction mystery  
**Target seats:** 1–8  
**Primary modes:** Cooperative, Hidden Betrayer, Outbreak  
**Secondary candidates:** Hunted, Rival Crews  
**Production status:** Design-only; Lantern House remains the sole production Tale

## 1. High concept

At the year's lowest tide, a harbor town rises from the mud where no living chart shows a town.

Its streets are wet but intact. Its lamps still burn. Its lighthouse turns across an empty sea. The harbor bell begins ringing the names of the active stable seats.

Before the tide returns, the group must uncover why the town was drowned, decide whether its light should be restored or extinguished, and reach a valid ending before the Harbor claims enough living memory to remain above water forever.

Halfway through the Tale, **High Water** changes the board, available routes, objectives, faction pressure, and player-state possibilities.

The central question is not merely whether the players can escape. It is what they are willing to guide home with them.

## 2. Tale promise

Drowned Harbor should deliver:

- a visible environmental transformation;
- a deterministic tide progression rather than an unexplained wall-clock timer;
- shared exploration before route collapse;
- a signature Terror Turn that changes at least two major state categories;
- meaningful cooperative play without requiring a Betrayer;
- optional hidden allegiance and dynamic Tidebound conversion;
- active Restless or replacement play after defeat;
- multiple valid endings with explicit seat and faction attribution;
- a final lighthouse choice with meaningful moral and mechanical consequences;
- strong contrast with Lantern House.

The Tale must not depend on companion devices, online services, a hidden enemy, one specific role, voice narration, or unbounded procedural storytelling.

# Narrative truth

## 3. Canonical history

Drowned Harbor did not vanish in an ordinary storm.

For generations, members of its Harbor Council intentionally misaligned the lighthouse during dangerous weather, drawing ships toward the breakwater so the town could salvage their cargo.

During a severe winter, a relief vessel approached carrying food, medicine, and passengers bound for several struggling communities. The Council chose to wreck the ship rather than let it pass.

Survivors reached the town. Too many residents learned what had happened. Ordinary falsified records could no longer contain the crime.

The Council activated an older mechanism beneath the lighthouse. The lens, made from glass recovered from many wrecks, could guide memory in the same way a normal lighthouse guided ships. The Bellhouse Ledger indexed names into that mechanism.

The Council attempted to remove the Harbor, its crimes, and all witnesses from living memory.

The ritual required every resident's name to be recorded and rung. A Bellhouse assistant removed one name after discovering that the ritual would trap innocents rather than release them.

The incomplete ritual removed the town from charts and most living memory, but did not erase it or let its residents die properly. The sea took the physical Harbor while the unfinished mechanism preserved it between memory and oblivion.

At exceptional low tides the town rises and attempts to complete the ritual.

## 4. What the Harbor wants

The Harbor is a place acting through unfinished ritual, trapped memory, accumulated guilt, drowned residents, the lighthouse, the bells, and people who believe the town must be preserved.

To remain in the living world, it needs:

1. a complete set of names;
2. living witnesses capable of carrying its memory;
3. an active lighthouse signal;
4. a destination;
5. resolution of the missing ledger entry.

The Harbor does not distinguish cleanly between remembrance, restoration, forgiveness, repetition, and propagation. It may therefore help the group escape while using them to escape.

## 5. Why player-seat names appear

When a stable seat crosses the mudflat boundary, the Bellhouse detects a new living witness and creates a fictional entry using seat or character identity—not a player's real account name.

The symbols beside each seat represent possible roles in the unfinished ritual:

- witness;
- survivor;
- replacement;
- keeper;
- sacrifice;
- carrier;
- drowned resident;
- missing name.

The ledger does not guarantee death. It creates pressure toward a possible recorded state.

## 6. The extra bell ring

The bell rings once for each active stable seat, then once more.

The additional ring represents the unresolved position in the original ritual. It can become:

- the missing historical name;
- the Harbor seeking recognition;
- a replacement survivor;
- a transformed or sacrificed seat;
- the channel through which the Harbor leaves.

It is not automatically tied to a hidden Betrayer.

## 7. Lighthouse, bells, Archive, and drowned residents

### Lighthouse

The lighthouse guides memory and destination.

- **Seaward:** can reveal escape, contact an offshore response, or carry Harbor memory elsewhere.
- **Inland:** exposes concealed structures and opens the Drowned Archive, but intensifies transformation pressure.
- **Extinguished:** supports containment but removes some escape and release options.
- **Claimed:** a person or item becomes the new signal bearer.

### Bells

The bells index names and possible states. They do not directly kill. A ringing may register a witness, strengthen a name, mark a transformation, activate a debt, communicate with the Restless, or alter the ledger.

The bells appear prophetic because their ringing pressures the Tale toward the recorded state.

### Drowned Archive

The Archive contains overlapping official records, falsified wreck reports, survivor memory, ritual instructions, names of the drowned, and records produced by repeated attempts to finish the ritual.

Its contradictions arise from corruption, falsification, and repetition—not infinite alternate universes.

### Drowned residents

Most residents were not members of the Council. They include families, workers, lighthouse staff, sailors, survivors, and people who opposed the ritual. Different residents seek release, recognition, justice, restoration, revenge, or completion. The Drowned Patrol is a repeated civic routine distorted into a hazard, not a uniform army.

## 8. Bellmarked, Tidebound, and Restless

### Bellmarked

The Bellmarked believe forgetting the Harbor would be a second destruction. Their preservation concern can be sympathetic; their willingness to complete the ritual, preserve the signal, or carry the Harbor into the living world can be dangerous.

### Tidebound

Tidebound participants have partially merged with trapped Harbor memories. They are not ordinary infected zombies and retain meaningful agency. They may remember lives they never lived and pursue preservation, release, propagation, or an unfinished obligation.

### Restless

Restless forms act after bodily defeat through the same stable seat. A Bell-Witness uses the Bellhouse, a Drowned Guide uses submerged routes, and a Lighthouse Guardian acts through the final mechanism.

# Presentation and structure

## 9. Public opening

> At the lowest tide, the sea reveals what it could not digest. Tonight, dear guests, it has returned an entire harbor.
>
> Its lamps are burning. Its bell is ringing. And unless I have miscounted—and I rarely miscount the doomed—it is ringing once for each of you.
>
> Find the lighthouse ledger. Learn why the town was drowned. Leave before the water remembers its proper depth.

Plain objective:

- explore the exposed Harbor;
- recover three pieces of the lighthouse record;
- decide how to handle the Harbor light;
- reach a valid ending before final submergence.

## 10. Board identity

### Core spaces

- `mudflat_approach`
- `salt_market`
- `bellhouse_square`
- `wreckers_lane`
- `netmakers_row`
- `tide_chapel`
- `harbor_office`
- `lifeboat_shed`
- `breakwater`
- `lighthouse_base`
- `lighthouse_lantern_room`
- `drowned_archive`
- `old_ferry_slip`

### Regions

- Outer Mudflats
- Lower Harbor
- Town Center
- High Ground
- Lighthouse
- Submerged Depths

### Tide states

1. `lowest_tide`
2. `returning_tide`
3. `flooded_streets`
4. `harbor_claim`
5. `final_submergence`

Each tide state may change connectors, hazards, space visibility, route type, item movement, Director candidates, and ending eligibility. No transition may permanently strand a seat without an authored recovery or continuation route.

## 11. Signature Terror Turn: High Water

High Water triggers after the Lighthouse Council or the authored investigation threshold. It is not an ordinary random event.

> And now, dear guests, the Terror Turn.
>
> The harbor is no longer where you stand. It is what is rising around you.
>
> The roads you trusted are filling. The doors you ignored are opening. Choose quickly which version of this town you intend to survive.

High Water may:

- advance tide state;
- close low-ground connectors;
- open water-only routes;
- reveal the Archive;
- move or strand unsecured objects;
- change the public objective;
- activate Tidebound eligibility;
- enable hidden-faction actions;
- shift Director weighting toward rescue, scarcity, and route denial;
- begin the final tide budget.

It must change at least two of board, objective, faction, form, route, or resource economy.

# Five-stage graph

## 12. Stage 1 — The Harbor at Low Tide

**ID:** `low_tide_arrival`

Goals:

- enter the town;
- inspect two initial landmarks;
- recover the first record fragment;
- locate Bellhouse Square.

Landmarks include Salt Market, Harbor Office, and Lifeboat Shed.

Early pressure emphasizes lamps turning, distant bells, footsteps, fog, and route inconvenience rather than lethal punishment.

## 13. Stage 2 — The Bellhouse Ledger

**ID:** `bellhouse_ledger`

The Ledger lists every active seat, a possible tide state, and an unresolved blank entry.

The group chooses one priority:

1. Follow the Names.
2. Follow the Light.
3. Follow the Missing.

All routes remain valid and converge without producing an unwinnable Tale.

## 14. Stage 3 — Council Beneath the Lighthouse

**ID:** `lighthouse_council`

Public choices:

1. Restore the Light.
2. Extinguish the Light.
3. Turn the Light Inland.
4. Delay for Evidence.

The choice changes final objectives, Director candidates, ending eligibility, and faction opportunities. High Water begins when the Council resolves.

## 15. Stage 4 — High Water

**ID:** `high_water`

Goals vary by route and may include:

- recovering lamp fuel;
- rescuing stranded seats or residents;
- reaching the Archive;
- repairing a lifeboat;
- disabling a bell mechanism;
- carrying a memory record;
- maintaining the light until a route appears.

Lower Harbor floods, water routes activate, Bellhouse Square becomes hazardous, and defeat may transition into Restless, Tidebound, or replacement play.

## 16. Stage 5 — The Last Light

**ID:** `last_light`

Final options are generated from authoritative state and may include:

- Guide the Living Home.
- Seal the Harbor Below.
- Free the Drowned.
- Claim the Light.
- Abandon the Town.
- Answer the Harbor's Bargain.

Every supported route must produce a deterministic ending with explicit outcomes for every seat and faction.

# Social modes and factions

## 17. Cooperative

All seats begin Living. Tension comes from limited rescue capacity, conflicting public priorities, transformation risk, and moral cost. One- and two-seat games default here unless another authored low-seat plan is selected.

## 18. Hidden Betrayer

The hidden faction is the Bellmarked. Bellmarked goals may include preserving the signal, keeping names in the ledger, carrying Harbor memory out, preserving the bell, or opening an old channel.

Bellmarked presence must be authored and seat-count valid. Public Underteller lines and takeover menus must not reveal allegiance before a legal reveal.

## 19. Outbreak

Seats may become Tidebound through authored exposure, bargain, defeat, or transformation. Tidebound form a dynamic third faction rather than an eliminated state.

## 20. Hunted and Rival Crews candidates

- **Hunted:** one seat becomes the Drowned Keeper after High Water.
- **Rival Crews:** Lighthouse Crew and Lifeboat Crew pursue competing public success conditions.

Both remain deferred pending later review and human evidence.

# Roles and continuation forms

## 21. Primary Living roles

### Lantern Surveyor

Navigation specialist. Inspects connectors and supports route recovery.

### Bellhouse Archivist

Record specialist. Clarifies public evidence and supports truth-based endings. Strong Bellmarked-cover candidate.

### Lifeboat Keeper

Rescue and escape specialist. Repairs capacity and retrieves stranded seats.

### Fog Listener

Hint and danger specialist. Requests bounded public-safe clues and detects false signals.

### Wrecker's Heir

Salvage and risk-reward specialist. Recovers value from destroyed or abandoned resources. Strong Bellmarked candidate.

### Tide Chapel Warden

Protection and Restless-support specialist. Places temporary wards and supports containment or release.

No ending may require a specific named role; generic alternatives must exist.

## 22. Faction overlays and transformed forms

### Bellmarked agent

A private faction/objective overlay placed on a compatible public role.

### Tidebound form

Retains stable seat, location, history, and normally inventory while gaining a new faction and objective.

### Drowned Keeper

Deferred Hunted-mode Horror form focused on lighthouse defense and bounded water-route pressure.

## 23. Restless and replacement forms

### Bell-Witness

Warns against routes, tide changes, false signals, or threatened objectives.

### Drowned Guide

Opens a one-use submerged connector, diverts a current, or guides a Living seat.

### Lighthouse Guardian

Protects a final lighthouse option or sacrifices itself to alter an ending condition.

### Lifeboat Survivor

A bounded replacement Living role entering only through an authored route. It inherits the stable seat's participation history but receives a new character identity and replacement objective.

# Resource economy

## 24. Ownership categories

Objects are declared as:

- seat-owned;
- shared group resource;
- board-owned mechanism;
- publicly tracked quest-carried object;
- faction-private object or marker.

Control transfer never resets ownership, condition, charges, or hidden information.

## 25. Public resources

- Lamp Oil
- Bell Tokens
- Rope
- Salt Marks
- Memory Fragments
- Lifeboat Capacity
- Dry Matches
- Harbor Keys

## 26. Initial item set

- Salt-Stiff Rope
- Dead Man's Compass
- Lifeboat Flare
- Harbor Master's Seal
- Glass Bell Clapper
- Cracked Lighthouse Lens
- Chapel Salt Censer
- Wrecker's Hook
- Tin Lantern
- Ledger Knife
- Oilskin Satchel
- Missing-Name Tablet

Items may be intact, wet, damaged, salt-corroded, spent, lost, claimed, or bound where supported. Flooding changes an item only through a declared deterministic rule.

## 27. Initial card set

- Hold Fast
- Borrowed Breath
- Mark the Door
- Cut the Line
- A Name Remembered
- Share the Weight
- The Long Way Around
- Salt in the Wound
- The Harbor Owes Me
- One More Passenger
- Wrong Bell
- The Light Looks Back

Control transfer, reconnect, invalid action, and surrogate activation consume no draw or card.

## 28. Initial hazard set

- Returning Current
- Bell Shock
- The Street Gives Way
- Lamps Turn Seaward
- Drowned Patrol
- Salt Rot
- Harbor's Claim
- Archive Collapse
- Lifeboat Breaks Free
- The Light Answers
- Water in the Lungs
- The Missing Name

Every hazard declares warning, legal responses, deterministic consequences, recovery path, Director compatibility, and snapshot behavior.

# Encounter library

## 29. Low-Tide encounters

### The Mudflat Mile

Choose raised causeway, half-buried boats, or direct mudflat. Introduces route risk and recovery.

### The Market of Shadows

Take an item freely and accept Harbor debt, leave payment, search for a clue, or leave supplies behind.

### The Empty Lifeboat

Repair the craft, search the wet extra seat, mark it for later, or destroy it only when another ending remains valid.

### The Harbor Office Manifest

Recover the first record, copy it, carry it, or leave it vulnerable to flooding.

## 30. Bellhouse encounters

### The Bell Counts Wrong

Investigate the extra ring, inspect the mechanism, compare bell and ledger, or leave it alone.

### The Names Beneath the Names

Preserve all historical layers, keep only current names, remove current names, or destroy the ledger only after consequence validation.

### The Scratched-Out Door

Open, speak through, preserve for later, or seal a door tied to the missing name and possible replacement route.

### The First Harbor Bargain

A private seat may borrow time, ask one true question, or save another seat at an explicit private cost.

## 31. Lighthouse Council encounters

### The Lens Shows Four Futures

Preview escape, containment, release, and propagation without guaranteeing an outcome.

### Council Beneath the Turning Light

Commit the public route and trigger High Water. Late joiners inherit rather than reopen the result.

## 32. High Water encounters

### The Street Becomes a River

Rescue a stranded seat, recover a critical item, open an alternate route, or accept a valid continuation path.

### The Drowned Archive Opens

Choose among final record, binding mechanism, missing name, or trapped resident. Multiple goals require sufficient support.

### The Lifeboat Breaks Free

Secure, pursue, signal, or abandon the craft when another ending remains valid.

### The Bell Rings a Living Name

Prepare, silence, redirect legally, or destroy the bell with visible ending consequences.

### One More Passenger

Resolve insufficient capacity through repair, resource cost, alternate route, or refusal.

### The Tidebound Offer

An eligible seat may accept transformation to survive or refuse and face the original consequence.

## 33. Last Light encounters

### The Lighthouse Mechanism

Display authoritative final state and generate only valid final options.

### The Last Seat on the Boat

Resolve limited capacity through vote, volunteer, public priority, resource expansion, or distinct valid outcomes. Host removal or control transfer cannot change eligibility.

### The Final Harbor Bargain

Offer a precise costly alternative when the group lacks one requirement for its preferred ending.

# Endings

## 34. The Last Lifeboat

Requires a valid prepared escape route and at least one eligible departing seat. The result may include an escaped Harbor memory, Bellmarked, or Tidebound carrier.

> The boat clears the breakwater. Count the survivors carefully. The harbor has always preferred being counted as one of them.

## 35. The Harbor Sealed

Requires lighthouse and bell neutralization plus a containment action. It is a practical victory but may leave innocent drowned residents unresolved.

> The last light dies. The streets descend. For the first time in a century, the harbor is merely drowned.

## 36. The Drowned Released

Requires complete truth, an understood release mechanism, meaningful cost, and a valid lighthouse or bell configuration.

> The bells ring without names. One by one, the harbor's windows go dark. This time, darkness is an ending.

## 37. The Harbor Rises

The Harbor completes enough of the ritual to remain above water and return to living maps.

> The tide returns, but the town does not sink. Somewhere beyond the fog, cartographers begin correcting their charts.

## 38. The Light Comes Home

The group escapes while a seat or item carries the Harbor's signal beyond the board.

> You escaped the harbor. The harbor, displaying equal initiative, escaped inside the light you carried.

## 39. The Names Erased

The active names are removed from the mechanism. The Harbor loses its claim on the players, but truth or drowned identities may also be lost. This affects fiction only and never deletes real profiles or account data.

## 40. Mixed outcomes

Several factions may achieve compatible or partial objectives. Every seat and faction receives explicit public or controlled-private attribution. Do not simplify to “everyone wins” unless state genuinely supports it.

# Dialogue starter library

## 41. Key lines

Arrival:

> The harbor appears intact. This should concern you more than ruins would.

Ledger:

> There you are, written neatly between the dead and the overdue.

Council:

> You may restore the light, extinguish it, or turn it upon the town itself. Each choice reveals something. None reveals only what you intended.

High Water:

> And now, the Terror Turn. The harbor is no longer where you stand. It is what is rising around you.

Transformation:

> Seat VI has drowned. Seat VI has also returned. These statements are no longer contradictory.

Restless:

> Your lungs have finished their work. Your warning has not.

Finale:

> The lens is ready. Choose what the light will guide home.

Control handoff:

> Seat III is now guided by the game. The character, condition, possessions, and obligations remain unchanged.

Late takeover:

> Welcome to Seat V. The body is unavailable. The unfinished work is not.

## 42. Dialogue authoring requirement

Every final line must declare a stable key, function, trigger, required mechanical fact, profile variant, seat scope, repeat class, display and voice budget, privacy classification, and fallback.

# Automation and validation backlog

## 43. Package and graph validation

Future implementation should verify:

- stable Tale ID and source ledger;
- complete localization keys;
- valid stage graph and terminal reachability;
- seat-count and social-mode plans;
- no executable or unsafe content references;
- deterministic ordering;
- High Water triggers exactly once;
- every final route assigns outcomes to all seats and factions.

## 44. Tide and deadlock validation

- Every connector has a declared state at every tide level.
- No required objective becomes unreachable without a valid alternate ending.
- No active seat is permanently stranded without recovery or continuation.
- Final submergence proceeds immediately to resolution.
- Rejected mutations leave all authorities unchanged.

## 45. Privacy and faction validation

- Unsupported low-seat betrayal uses cooperative fallback.
- Public narration and takeover menus contain no hidden faction keys.
- Tidebound conversion cannot create impossible faction state.
- Surrogates use only seat-private state.
- Private endings remain separated from public results.

## 46. Afterlife and seat continuity validation

- Defeat produces a valid Restless, transformed, replacement, or explicitly declared continuation.
- Every continuation form has a legal action or pass.
- Human departure does not alter state.
- Human takeover preserves exact health, position, inventory, role, faction, objective, and cooldown state.
- Rematch clears all prior handoff and form state.

## 47. Automated playthrough strategies

- fast escape;
- maximum investigation;
- containment;
- rescue priority;
- risk seeking;
- hidden Bellmarked concealment and reveal;
- Tidebound spread and mixed outcome;
- Restless completion;
- disconnect-heavy session with takeover and return.

## 48. Screenshot baseline candidates

- low-tide arrival;
- tide-state indicator;
- Bellhouse Ledger;
- Council choices;
- High Water transition;
- flooded route;
- public transformation;
- Restless activation;
- takeover review;
- final lighthouse decision;
- cooperative and mixed endings.

# Open decisions

## 49. Canon and content decisions

- original Harbor proper name;
- relief vessel name;
- missing assistant identity and ultimate fate;
- exact origin of the Bellmarked;
- whether the Council understood the full ritual cost;
- exact Tidebound conversion rules;
- final seat-count role plans;
- final inventory capacity and card counts;
- mandatory versus optional encounters;
- exact clues for each route;
- final presentation-profile text;
- Chronicle relationship;
- whether the Underteller has hosted a prior version of the Tale.

## 50. Boundaries

This document does not authorize:

- a production Tale package;
- a second catalog entry;
- gameplay implementation;
- new snapshot or report schemas;
- companion protocol changes;
- cloud services;
- balance or fun claims;
- final dialogue or artwork;
- final branding.

It exists to preserve and refine content ahead of a later implementation authorization.
