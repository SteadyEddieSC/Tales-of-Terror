# Seat Continuity and Multiplayer Admission Contract

**Version:** 0.1  
**Status:** Preproduction systems contract  
**Applies to:** Local controller seats, temporary AI surrogate control, reconnects, late joining, transformed and defeated seats, future remote players, invitations, requests to join, spectators, and host permissions  
**Local-first rule:** Local couch play remains complete without accounts, network services, or online admission flows

## 1. Core principle

**The stable seat owns the game state.**

A human, controller, companion device, remote client, or deterministic AI surrogate may temporarily control a seat, but control changes do not create a new character or erase the seat's history.

The seat retains:

- character and position;
- health, injury, infection, curse, and transformation state;
- role, faction, form, reveal state, and objectives;
- inventory, cards, charges, and quest responsibilities;
- action uses, cooldowns, pending consequences, and completed accomplishments;
- public and private information legitimately acquired by that seat;
- ending eligibility and session history.

A joining player may inherit a seat that is healthy, wounded, empty-handed, carrying a critical item, secretly hostile, publicly transformed, Tidebound, Restless, stranded, or awaiting a replacement transition. Joining is continuity, not respawning.

## 2. Terminology

### Stable seat

The persistent authority identity that owns character state and action rights.

### Human controller

A local or approved remote person currently authorized to issue decisions for a stable seat.

### AI surrogate

A deterministic game-controlled decision-maker temporarily authorized to act for a seat when no human controls it.

### Returning player

A human reclaiming the same seat they controlled earlier in the session.

### Joining player

A human taking control of an eligible AI-controlled seat.

### Safe handoff point

A state where authority can change without interrupting an atomic action, duplicating randomness, leaking private information, or leaving an unresolved multi-authority transaction.

## 3. Departure flow

### Temporary disconnect

1. Reserve the stable seat.
2. Show a public-safe reconnecting indicator.
3. If an immediate seat-owned decision exists, apply the configured grace period.
4. Permit reconnection only to the same seat.
5. If the grace period expires, activate the surrogate at a safe handoff.

A brief controller interruption must not immediately cause an irreversible bot decision.

### Intentional departure

The interface should state:

> The game will continue controlling this seat. All health, items, roles, infections, objectives, and current conditions will remain.

Departure occurs immediately when safe or after the current atomic action resolves.

### Departure during a private reveal

- Clear the private presentation immediately.
- Restore the neutral shared-screen shield.
- Preserve the seat's private state.
- Do not narrate what was shown.
- Allow the surrogate to use only the information legitimately owned by that seat.

## 4. AI surrogate contract

The surrogate is not a separate character. It temporarily controls the same seat.

It must:

- submit only legal actions;
- obey stable-seat ownership;
- respect uses, cooldowns, and action economy;
- use only the seat's public and private information;
- follow deterministic authored decision rules;
- respect actual faction and private objective;
- participate in required votes and prompts;
- continue meaningful transformed or Restless play;
- produce a legal action or intentional pass without silent deadlock;
- yield safely to a human takeover.

It must not:

- inspect another seat's private state;
- use future random outcomes;
- mutate rules or board authority directly;
- receive hidden Director information;
- automatically favor humans because it is a bot;
- automatically sabotage because its seat is secretly hostile;
- invent free-form social claims or impersonate a human;
- consume gameplay RNG merely to choose among otherwise equivalent actions unless explicitly authored.

### Strategy profiles

Reviewed profiles may include Cautious, Cooperative, Objective-Focused, Protective, Risk-Seeking, and Balanced. Public UI must not expose a profile that reveals a hidden faction.

### Social behavior

A surrogate may vote, choose authored responses, use legal faction actions, accept or reject represented bargains, and reveal itself when permitted. It may not generate unrestricted conversation or accusations.

## 5. Local joining and takeover

Local couch play should remain simple:

> Connect controller → choose or receive an eligible game-controlled seat → review inherited state → take control.

Local play does not require:

- friends lists;
- online accounts;
- invitations;
- join codes;
- matchmaking;
- internet access;
- remote host approval.

A joining player sees only public-safe seat summaries before assignment, for example:

- `Seat II — Injured — Bellhouse Square — 2 public items`
- `Seat V — Restless — Lighthouse — Warning available`
- `Seat VII — Tidebound, publicly revealed — Lifeboat Shed`

Hidden faction, private objective, secret inventory, and unrevealed infection remain private until after assignment.

After assignment:

1. wait for a safe handoff;
2. shield the shared screen;
3. authorize the controller or companion;
4. reveal the inherited private role, faction, objective, condition, inventory, and available actions;
5. require acknowledgement;
6. transfer decision authority.

A player may not browse several private seats and choose the most attractive role.

## 6. Returning-player flow

A returning player normally reclaims the same reserved seat. They inherit all legal surrogate decisions made during absence.

A bounded recap may include:

- current location;
- health and public conditions;
- items gained or lost;
- public stage changes;
- public transformations;
- important surrogate actions;
- new private information acquired by the seat.

The recap must not expose another seat's private state.

## 7. Defeated and transformed takeover

A player may inherit a defeated, infected, transformed, or Restless seat.

Publicly revealed conditions should be shown before acceptance. Private conditions are disclosed only after assignment.

Examples:

- a Bell-Witness with one warning remaining;
- a Drowned Guide in a submerged route;
- a publicly revealed Tidebound seat;
- a replacement survivor pending arrival;
- an injured Living seat carrying the final quest object.

No fresh character, healing, new inventory, faction reset, reroll, or immunity is granted merely because control changed.

## 8. Safe handoff rules

Control must not transfer:

- during random-result generation;
- between validation and commit;
- during multi-authority transaction application;
- while a private projection is exposed;
- midway through vote submission;
- between card cost payment and effect resolution;
- during snapshot restoration;
- during ending calculation;
- during rematch reset.

A requested takeover during an unsafe point is queued and shown as pending.

## 9. Shared-screen presentation

Every stable seat should show a control-source indicator that supplements color:

- `PLAYER`
- `GAME CONTROL`
- `RECONNECTING`
- `TAKEOVER PENDING`

This does not replace seat number, character name, public condition, public faction after reveal, or required-action indicator.

## 10. Session options

Suggested local options:

- departure grace period;
- returning-seat reservation;
- late join disabled, stage-boundary only, or any safe handoff;
- player choice, lowest eligible seat, oldest game-controlled seat, or facilitator assignment;
- immediate or short presentation delay for surrogate actions.

Artificial thinking delay is presentation-only and must not change authority results.

# Future online admission

## 11. Separation of admission and seat continuity

Online admission determines **who may enter**. Seat continuity determines **what the admitted player inherits**.

Possessing a join code or invitation does not itself grant gameplay authority or a specific seat.

## 12. Session visibility policies

### Offline / Local Only

No remote connections. This remains the default family and privacy-safe path.

### Invite Only

Only holders of a valid time-limited or one-use invitation may request entry.

### Friends Only

Only recognized friends may request entry. Recommended default: friends of the host only. Friends-of-friends is optional and higher risk.

### Request to Join

Eligible players may submit a request. The host sees display identity, relationship, returning-player status, requested player or spectator role, seat availability, and compatibility warnings.

### Open With Approval

Unknown compatible players may request entry, but the host approves each one. Useful for community games and hosted playtests.

### Open Join

Compatible players may enter without individual approval. Disabled by default and clearly marked higher risk. Restrictions may include spectator-only, game-controlled seats only, stage-boundary joining, password, or account criteria.

### Join Code

A join code is a routing handle, not proof of authority. Approval, invite capability, password, friendship, privacy gate, and seat availability may still be required.

## 13. Join-in-progress policies

- Disabled.
- Returning players only.
- Stage boundaries only.
- Safe handoff anytime.
- Host approval per takeover.

A player may enter as spectator while waiting for an eligible seat.

## 14. Seat reservation policies

When a player leaves, their seat may remain reserved:

- for the entire Tale;
- until the end of the stage;
- for a configured time;
- until the host releases it;
- not at all.

Releasing a reservation must warn that another player may inherit the seat and the original player may be unable to reclaim it.

## 15. Host controls

The host may:

- stop new requests;
- approve or decline;
- reserve or release a seat;
- assign a requester as spectator;
- promote an existing spectator;
- lock a seat as game-controlled;
- kick a disruptive player;
- block re-entry for the session;
- disable remote services while local play continues.

The host may not inspect hidden seat information to choose an attractive assignment, reroll a seat, reset an unfavorable state, or expose private information.

## 16. Request queue

Queue policies may prioritize:

- returning players;
- invited players;
- friends;
- first request;
- manual host selection;
- spectators waiting for promotion.

The queue must never expose seat secrets.

## 17. Spectator mode

Spectators may receive public board state, public narration, public objectives, public faction reveals, and public results.

They may not receive hidden roles, private objectives, controlled reveals, faction-private messages, private cards, unrevealed infection, host capabilities, or gameplay authority.

Promotion to player requires a new authority grant and normal private handoff.

## 18. Kicking and removal

Removing a remote human does not remove the stable seat.

1. Revoke session capability.
2. Close private surfaces.
3. Finish or safely roll back the current atomic action.
4. Transfer the same seat to game control.
5. Preserve all character state.
6. Apply the host's reservation decision.
7. prevent unauthorized immediate reconnection.

A kicked player does not automatically retain reclaim rights.

## 19. Host departure

Future policies may end the session, pause for host return, transfer to a co-host, transfer to a local player, or continue under dedicated authority. Administrative host rights and gameplay-seat rights must remain separate.

## 20. Security and abuse cases

Future online admission must address:

- join-code guessing;
- request spam;
- stolen invitations;
- impersonation;
- seat cycling to discover roles;
- reconnect credential theft;
- unauthorized spectators;
- griefing after takeover;
- deliberate disconnect before consequences;
- kicked-player re-entry;
- host migration abuse.

Safeguards include expiring capabilities, one-use invitations, opaque reconnect credentials, rate limits, session blocklists, request cooldowns, atomic authority transfer, revocation, and minimal personal-data retention.

## 21. Privacy-safe Underteller examples

> Seat III has lost its hand upon the Tale. Its place remains.

> Seat III is now guided by the game. The character, condition, possessions, and obligations remain unchanged.

> Welcome back, Seat III. The Tale continued in your absence.

> A guest waits beyond the fog. The host may invite them closer or leave them to the weather.

> The witness approaches the board. Observation has become participation.

## 22. Automation requirements

Future tests must cover:

- disconnect during navigation, prompt, private reveal, vote, transformation, and afterlife;
- grace expiry and exactly-once surrogate activation;
- deterministic surrogate actions for Living, Bellmarked, Tidebound, Horror, and Restless forms;
- public-safe seat summaries;
- exact preservation of state through takeover;
- same-seat reconnect and rejection of stale or duplicate credentials;
- reservation expiry and release;
- spectators receiving only public projections;
- online service failure leaving local play intact;
- no RNG consumption from control transfer;
- no private data in public history or admission queues;
- rematch clearing all handoff and admission state.

## 23. Implementation boundary

This contract does not authorize full online multiplayer, matchmaking, public server browsing, platform account integration, friends-list integration, chat, persistent bans, dedicated servers, host migration, cloud Chronicle storage, or companion protocol changes.

The first implementation target should be local stable-seat continuity and deterministic surrogate control. Future online admission should layer on top without complicating offline couch play.
