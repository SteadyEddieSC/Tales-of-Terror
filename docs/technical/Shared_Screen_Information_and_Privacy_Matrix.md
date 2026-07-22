# Shared-Screen Information and Privacy Matrix v1

**Status:** Proposed design and implementation contract  
**Scope:** Documentation only; no production content, schema, identity, Companion, or release change  
**Repository:** `SteadyEddieSC/Tales-of-Terror`  
**Repository baseline used for review:** protected `main` at `0dde8d41c7cb1fc23bb2d85c26cb9281e311c971`  
**Related design:** `Lantern_House_Playable_Session_Contract_v1.md`  
**Implementation dependency:** the bounded v0.1.6 Tale Library correction must be reviewed and merged before implementation work that touches the finalized Library route  
**Working-title notice:** “Terror Turn” and “The Underteller” remain provisional pending issue #7 legal clearance

## 1. Purpose

This contract defines what information may be exposed through every current or planned Terror Turn presentation and evidence surface.

It exists to prevent three failure classes:

1. a public shared-screen view accidentally revealing seat-private or faction-private game information;
2. a setup, failure, report, replay, or diagnostic surface exposing internal package, provider, source, path, identity, capability, or security details;
3. an optional Companion or controlled-reveal path being treated as authoritative or more private than it actually is.

The contract is designed for the current controller-first, native-authority, local shared-screen game and its existing Lantern House vertical slice. It is reusable for future Tales, but approval of this document does not authorize a second production Tale or a package/catalog identity change.

## 2. Player promise

The player-facing privacy promise is:

> The television shows only information deliberately safe for the whole room. Secret information appears only through an explicit seat-scoped reveal or an authorized optional companion. The game never requires a phone, never pretends an ordinary shared screen is private, and never exposes developer diagnostics as player guidance.

The corresponding developer promise is:

> Every outward projection is built from an explicit allowlist for its audience. Redaction is not a substitute for correct projection. Invalid, stale, unauthorized, or failed work produces no partial authority mutation and no privacy leak.

## 3. Existing repository-grounded baseline

The current foundation already establishes the following boundaries:

- the native Godot host owns gameplay authority;
- the shared television receives deliberately public projections;
- roles, factions, objectives, actions, transitions, and outcomes have explicit public, seat-private, faction-private, controlled-reveal, and diagnostics views;
- optional companions receive filtered views and submit bounded intents that native authorities revalidate;
- an ordinary shared browser or television is never treated as private;
- controlled reveal obscures the whole shared display and authorizes one stable seat;
- private role ownership follows the stable seat across controller disconnect and reconnect;
- the Director may consume only approved normalized public or aggregate social signals;
- public history and schema-v2 playtest reports exclude private role information and package/catalog provenance;
- package and catalog identities are internal provenance rather than gameplay or player-facing data;
- no-phone play remains complete when Companion services are unavailable;
- reports are explicit, local-only, non-authoritative, privacy-safe, and non-networked;
- physical/manual privacy results cannot be inferred from automated tests.

This document consolidates those rules into one implementation-ready matrix and adds no new gameplay authority.

## 4. Identity and change guard

The following production identities must remain unchanged during adoption or review of this document:

- Tale stable ID: `lantern_house_vertical_slice`
- Display name: `Lantern House`
- Production catalog SHA-256: `2b478fd0d11fa075c2050409193aa06e6b9ca4dcf6efd4e4c550a9f3a5ff9db6`
- Lantern House package SHA-256: `abb39d6bfbdf8d7de108379f08180c13efb99bbffa3e53f30eaaa8de7f459dee`

Approval of this document does not approve:

- changes to Tale package schema v1;
- changes to current governed localization;
- new catalog fields;
- new Companion dependencies, source, protocol, service, or deployment;
- new persistent profile, account, telemetry, cloud, or matchmaking data;
- new public reports or new exported private evidence;
- changes inside draft PR #46 beyond its separately bounded correction.

## 5. Normative language

The terms **MUST**, **MUST NOT**, **SHOULD**, **SHOULD NOT**, and **MAY** are normative.

- **MUST / MUST NOT** define acceptance gates.
- **SHOULD / SHOULD NOT** define the preferred implementation absent a documented exception.
- **MAY** defines an optional behavior that still has to satisfy all authority, privacy, deterministic, controller, and no-phone rules.

## 6. Privacy principles

### 6.1 Public by deliberate projection, not by omission

A public view MUST be built from an explicit public projection. It MUST NOT be created by copying an authoritative snapshot and deleting known private keys.

The public projection must remain safe when future private fields are added.

### 6.2 Stable seat is the privacy principal

Private information belongs to a stable seat, not to a transient device ID, controller index, browser connection, player name, or display position.

Reconnect MAY restore access only to the same stable seat through the existing authorization boundary. Reconnect MUST NOT transfer private authority to a different seat or device merely because the device index changed.

### 6.3 Shared television is public unless fully obscured

The normal television surface is public.

A panel drawn over the board is not private. Small text, dimming, partial blur, transparency, screen-corner placement, short display time, or an instruction for others to look away does not make a public screen private.

A controlled reveal is private only when the whole relevant display is obscured before the reveal and one stable seat explicitly enters the reveal ceremony.

### 6.4 Optional Companion is a filtered surface, not an authority

A Companion MAY show authorized seat-private or faction-private information after host approval and a privacy gate. It MUST NOT own gameplay, session progression, RNG, board, rules, role, Director, seat, outcome, or replay state.

### 6.5 No-phone path is complete and honest

Every required decision MUST have a controller-first no-phone path.

Where simultaneous secrecy is impossible on one shared display, the game MUST use one of the approved controlled-reveal or open-information fallbacks. It MUST NOT claim simultaneous privacy that the hardware does not provide.

### 6.6 Diagnostics are not player guidance

Developer diagnostics MAY contain bounded internal details only inside developer-only surfaces and logs. Player-facing recovery MUST use fixed sanitized notices and safe actions.

### 6.7 Evidence is audience-specific

Gameplay snapshots, public history, reports, build manifests, portable bundles, screenshots, playtest notes, and diagnostics are different audiences. A field allowed in one is not automatically allowed in another.

### 6.8 Privacy failure fails closed

If the runtime cannot produce a valid projection for the requested audience, it MUST show a sanitized unavailable state and MUST NOT fall back to an authoritative or broader view.

## 7. Classification model

### 7.1 Existing authored content classifications

The current Tale and social content model uses four authored classifications:

| Classification | Meaning | Normal television | Controlled reveal | Authorized Companion |
| --- | --- | --- | --- | --- |
| `public` | Safe for every participant and observer | Allowed | Allowed | Allowed |
| `controlled_reveal_private` | Private to one stable seat, disclosed through an explicit local reveal | Forbidden outside reveal | Allowed for authorized seat | Allowed for authorized seat when mapped to that seat |
| `seat_private` | Private to one stable seat | Forbidden | Allowed for authorized seat | Allowed for authorized seat |
| `faction_private` | Private to current authorized faction members | Forbidden unless authored public consequence | Only through sequential seat-scoped reveal unless an approved local faction ceremony exists | Allowed only to authorized current faction members |

These labels are authored-content classifications. They do not cover diagnostics, provenance, security capabilities, or personal information.

### 7.2 Operational information classes

This contract adds operational classes for surface policy. These are documentation concepts unless a later separately reviewed schema change is approved.

| Operational class | Examples | Player-facing status |
| --- | --- | --- |
| `public_gameplay` | public objective, revealed board, accepted vote result | Safe for shared television |
| `seat_secret` | hidden role, private objective, private hand | Authorized seat only |
| `faction_secret` | faction objective, unrevealed member list, faction action | Authorized faction members only |
| `controlled_reveal` | private ending detail, no-phone role reveal | Full-screen seat-scoped ceremony only |
| `public_recovery` | fixed retry/back/help/reset notice | Safe for shared television |
| `internal_provenance` | package digest, provider ID, source ledger | Never normal player UI, report, or gameplay snapshot |
| `developer_diagnostic` | rejection cause, JSON path, class, stack trace | Developer-only; never public UI or Companion |
| `security_secret` | host capability, resume capability, service secret, token | Never television, report, screenshot, log, or unauthorized client |
| `local_device_metadata` | raw device ID, platform controller name | Local runtime only unless sanitized into a generic public label |
| `personal_observation` | participant name, voice, face, household details | Outside automated game data; consent and de-identification required |

### 7.3 Audience definitions

| Audience ID | Audience |
| --- | --- |
| `TV_PUBLIC` | Normal shared television or projector view |
| `TV_REVEAL_SEAT` | Fully obscured controlled reveal authorized to one stable seat |
| `CONTROLLER_LOCAL` | Controller cues such as vibration or LEDs; never assumed universal |
| `COMPANION_PUBLIC` | Optional browser public room surface |
| `COMPANION_SEAT` | Optional browser authorized to one stable seat |
| `COMPANION_FACTION` | Optional browser authorized to current faction-private data |
| `HELP_PUBLIC` | Shared Help/accessibility surface |
| `SNAPSHOT_AUTH` | Local authoritative gameplay snapshot used for restore/replay |
| `HISTORY_PUBLIC` | Public deterministic history or public-history digest input |
| `REPORT_LOCAL` | Explicitly exported local privacy-safe playtest report |
| `BUILD_INTERNAL` | Internal build manifest and automated evidence |
| `DIAGNOSTIC_DEV` | Developer-only diagnostic panel/log/test output |
| `PLAYTEST_HUMAN` | Consent-based human observation notes, stored outside gameplay authority |

## 8. Surface rules

### 8.1 Normal shared television (`TV_PUBLIC`)

The television MUST show only deliberately public information, public recovery guidance, and safe aggregate status.

It MUST NOT show:

- hidden role or faction identifiers;
- private objective names, text, progress, or scoring;
- private cards, hand order, item ownership intended as secret, or secret action eligibility;
- private targets or uncommitted choices;
- unrevealed transition plans or causes;
- package paths, provider IDs, class names, script paths, source ledgers, or hashes;
- raw rejection reasons, stack traces, JSON paths, or test fixture names;
- room host/resume capabilities, service secrets, tokens, or raw connection metadata;
- another seat’s private content during disconnect or reconnect;
- data visible only because a developer overlay was left enabled.

### 8.2 Controlled local reveal (`TV_REVEAL_SEAT`)

A controlled reveal MUST follow this order:

1. stop normal shared-screen progression;
2. obscure the entire relevant display with a neutral public privacy shield;
3. state publicly which seat may approach or take the controller without naming the secret;
4. require an input from the authorized stable seat;
5. reveal only that seat’s allowlisted private projection;
6. prevent screenshot-like persistence inside public history, previous-frame buffers controlled by the game, Help, or report surfaces;
7. require the authorized seat to close or confirm completion;
8. restore the neutral privacy shield;
9. require a public confirm before normal play resumes.

The reveal MUST have a timeout policy that returns to the neutral shield, not to exposed private content.

The reveal MUST NOT be entered by a generic confirm from any device.

### 8.3 Controller-local cues (`CONTROLLER_LOCAL`)

Controller vibration, light bars, or player indicators MAY supplement identity or private signaling, but MUST NOT be the sole required channel because:

- hardware support varies;
- identical controller models may be ambiguous;
- some players cannot perceive vibration or color cues;
- keyboard fallback has no equivalent hardware channel.

Any gameplay-relevant controller cue MUST have an accessible no-haptics alternative.

### 8.4 Public Companion (`COMPANION_PUBLIC`)

The public Companion MAY show:

- room status;
- public Tale/stage/objective information;
- public board/rules/Director/role projection;
- generic wait, reconnect, or unavailable status;
- sanitized public results.

It MUST NOT show private information, raw internal diagnostics, package/catalog provenance, or security capabilities.

### 8.5 Seat Companion (`COMPANION_SEAT`)

An authorized seat Companion MAY show only:

- the same stable seat identifier used by the host;
- that seat’s private role, faction membership as authorized, objectives, actions, prompt choices, and private ending details;
- public context needed to understand the private information;
- sanitized action rejection appropriate to that seat.

It MUST NOT show:

- any other seat’s secret data;
- hidden members of another faction;
- future role transitions not yet authorized;
- diagnostic causes;
- authority snapshots or RNG state;
- host/resume capability values;
- room service internals.

### 8.6 Faction Companion (`COMPANION_FACTION`)

Faction-private content MAY be projected only after current faction membership is authoritatively validated for the requesting stable seat.

The projection MUST be recalculated after every reveal, conversion, cure, replacement, escape, or faction transition.

A cached faction view MUST become inaccessible immediately after the seat loses authorization. The browser MAY display a generic “private view changed” screen; it MUST NOT retain the prior secret payload in normal application state or visible history.

### 8.7 Shared Help (`HELP_PUBLIC`)

Help is public and presentation-only.

Help MAY show:

- current stage and public objective;
- public control instructions;
- generic waiting-seat status;
- accessibility options;
- public recovery actions;
- bounded internal build identity already approved for the Help surface.

Help MUST NOT show:

- role assignments;
- private objectives or action availability;
- uncommitted choices;
- package path, package digest, provider ID, class, source ledger, or diagnostic reason;
- a summary of private content previously viewed;
- secret-sensitive recommendations.

Opening Help MUST block presentation input and pause or safely gate active play without mutating gameplay outcomes.

### 8.8 Authoritative snapshots (`SNAPSHOT_AUTH`)

Snapshots MAY contain private gameplay state required for deterministic restore. They are not public exports.

Snapshots MUST:

- remain local;
- use exact-key and version validation;
- preserve stable-seat ownership and private authority state;
- exclude raw transient device secrets and network capabilities;
- exclude presentation focus, animation, audio timing, Help state, and rendered text caches;
- exclude package/catalog digests when existing compatibility intentionally uses stable scenario identity instead;
- reject incompatible, malformed, incoherent, or privacy-invalid restores atomically.

A snapshot MUST never be displayed directly in normal UI, copied into a public report, or sent wholesale to a Companion.

### 8.9 Public history (`HISTORY_PUBLIC`)

Public history MAY include:

- accepted public actions and consequences;
- revealed board changes;
- public event/check/vote/card outcomes;
- public lifecycle and ending results;
- neutral statements that a private action caused an authored public consequence.

Public history MUST NOT include:

- hidden actor identity;
- private objective or action ID when it reveals role/faction;
- private target before public resolution;
- secret choice values before authored reveal;
- private RNG/audit fields;
- package/catalog/provider/source provenance;
- raw device or browser identifiers.

### 8.10 Local privacy-safe report (`REPORT_LOCAL`)

The explicit local report MAY include:

- build/release identity already approved for reporting;
- scenario ID/version;
- seat count and sanitized seat status;
- mode and whether a safe fallback was applied;
- stage progress and public outcomes;
- sanitized recovery/rejection categories;
- de-identified playtest observations entered through approved fields;
- manual validation fields that default to `not_tested`.

It MUST NOT include:

- hidden role/faction/objective/action content;
- private choices or targets;
- private ending details;
- package/catalog digest, provider ID, source ledger, class, or path;
- host machine username, absolute paths, home directory, IP address, token, capability, or room secret;
- raw device ID or browser fingerprint;
- inferred physical/manual passes from automation.

Report export MUST be explicit and local. Export failure MUST not mutate gameplay or erase the in-memory finalized report.

### 8.11 Internal build evidence (`BUILD_INTERNAL`)

Internal build manifests and CI evidence MAY contain exact source SHA, release, platform, architecture, artifact hashes, runtime digests, catalog/package identities, and deterministic inventory when needed for provenance.

They MUST NOT contain:

- gameplay secrets;
- report contents;
- participant or host identity;
- absolute local paths;
- tokens or service capabilities;
- private test observations;
- Companion room secrets.

Portable player bundles MUST include only approved internal-playtest documentation and runtime files. Test fixtures, source-only diagnostics, reports, caches, and private evidence remain excluded.

### 8.12 Developer diagnostics (`DIAGNOSTIC_DEV`)

Developer diagnostics MAY include bounded internal codes, authority revisions, component scores, JSON paths, package/provider validation details, and test canaries.

They MUST:

- be inaccessible in normal player mode;
- never be routed to Companion projections;
- never enter gameplay snapshots merely because a panel is open;
- never enter public history or schema-v2 reports;
- be absent from portable builds unless the portable policy explicitly approves a bounded internal diagnostic surface;
- avoid secrets, tokens, capabilities, and personal data even in developer mode.

### 8.13 Human playtest notes (`PLAYTEST_HUMAN`)

Human notes require voluntary participation and de-identification.

The game MUST NOT automatically record voice, video, face, biometric, account, contact, precise location, household identity, device fingerprint, or long-term behavioral profile.

Screenshots or recordings that might capture private reveals require explicit consent and a separate handling decision. Automated success MUST NOT be recorded as human privacy validation.

## 9. Master information matrix

Legend:

- **Yes** — allowed when projected through the audience-specific allowlist.
- **Auth** — allowed only for the currently authorized seat/faction.
- **Sanitized** — only a fixed non-sensitive representation is allowed.
- **Internal** — allowed only in internal evidence or developer diagnostics as specified.
- **No** — prohibited.
- **N/A** — not applicable to the surface.

| Information | TV public | Controlled seat reveal | Seat Companion | Faction Companion | Snapshot | Public history | Local report | Internal build/diagnostic |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Tale display name | Yes | Yes | Yes | Yes | Stable ID only as required | Yes | Yes | Yes |
| Tale stable ID | Sanitized/usually hidden | No need | May be public context | May be public context | Yes | Yes when existing schema requires | Yes when existing schema requires | Yes |
| Public briefing/objective | Yes | Yes | Yes | Yes | Yes if authority restore requires | Yes | Yes | Yes |
| Tale package path | No | No | No | No | No | No | No | Internal only |
| Tale package digest | No | No | No | No | Excluded under current contract | No | No | Internal build only |
| Catalog digest | No | No | No | No | Excluded under current contract | No | No | Internal build only |
| Provider ID/version | No | No | No | No | No | No | No | Internal only |
| Runtime class/script name | No | No | No | No | No | No | No | Developer diagnostic only |
| Source-ledger path/reference | No | No | No | No | No | No | No | Internal provenance only |
| Seat number / Roman numeral | Yes | Yes | Yes | Yes | Yes | Yes | Sanitized | Yes |
| Friendly controller label | Yes when needed | Yes | Yes | Yes | No | No | Generic only | Developer local only |
| Raw device ID/index | No | No | No | No | Avoid/exclude | No | No | Local developer diagnostic only |
| Stable device identity string | No | No | No | No | Only if existing seat restore requires and safe | No | No | Local diagnostic only |
| Connection state | Yes | Yes | Yes | Yes | Yes | Public status only | Sanitized | Yes |
| Room join code | Public routing handle only while active | No | May be shown before claim | May be shown before claim | No | No | No | Bounded service diagnostic |
| Host/resume capability | No | No | Never display raw value | Never display raw value | No | No | No | Security secret; redact from logs |
| IP, user agent, browser fingerprint | No | No | No | No | No | No | No | Avoid collection; never gameplay evidence |
| Selected mode | Yes | Yes | Yes | Yes | Yes | Yes | Yes | Yes |
| Cooperative fallback applied | Yes | Yes | Yes | Yes | Yes | Yes | Yes | Yes |
| Public faction identity | Yes after authored reveal | Yes | Yes | Yes | Yes | Yes | Yes | Yes |
| Hidden faction identity | No | Auth | Auth | Auth current faction only | Yes | No | No | Developer diagnostic only |
| Public cover identity | Yes | Yes | Yes | Yes | Yes | Yes | Yes if useful | Yes |
| Hidden role/form ID | No | Auth | Auth | Only if faction policy authorizes | Yes | No | No | Developer diagnostic only |
| Private objective title/text | No | Auth | Auth | Auth only if faction-shared | Yes | No | No | Developer diagnostic only |
| Private objective progress | No | Auth | Auth | Auth if faction-shared | Yes | No | No | Developer diagnostic only |
| Public objective progress | Yes | Yes | Yes | Yes | Yes | Yes | Yes | Yes |
| Private action availability | No | Auth | Auth | Auth if faction action | Yes | No | No | Developer diagnostic only |
| Public action availability | Yes | Yes | Yes | Yes | Yes | Yes after use | Sanitized | Yes |
| Private target candidate list | No | Auth | Auth | Auth if faction policy permits | Yes | No | No | Developer diagnostic only |
| Submitted private target before resolution | No | Auth | Auth | Auth if faction policy permits | Yes | No | No | Developer diagnostic only |
| Public consequence of private action | Yes with neutral wording | Yes | Yes | Yes | Yes | Yes | Yes | Yes |
| Pending public prompt title/options | Yes | Yes | Yes | Yes | Yes | Yes after resolution as appropriate | Yes if schema permits | Yes |
| Pending seat-private prompt/options | Waiting status only | Auth | Auth | Auth if faction-scoped | Yes | No | No | Developer diagnostic only |
| Other seat’s uncommitted choice | No | No | No | No unless explicitly faction-shared | Yes | No | No | Developer diagnostic only |
| Public vote options | Yes | Yes | Yes | Yes | Yes | Yes | Yes | Yes |
| Individual vote before reveal | Depends on authored open/secret policy; default No | Own vote Auth | Own vote Auth | Faction policy only | Yes | No until resolution | Aggregate/result only | Developer diagnostic only |
| Vote result and tie rule | Yes | Yes | Yes | Yes | Yes | Yes | Yes | Yes |
| Public check definition/result | Yes | Yes | Yes | Yes | Yes | Yes | Yes | Yes |
| Raw RNG state / stream position | No | No | No | No | Yes as required by authority snapshots | No | No | Internal deterministic evidence only |
| Session seed | No in normal UI | No | No | No | Yes | No | No unless existing approved metadata says otherwise | Internal evidence only |
| Dice faces/result | Yes when authored public | Yes | Yes | Yes | Yes | Yes | Yes if schema permits | Yes |
| Public card played/result | Yes | Yes | Yes | Yes | Yes | Yes | Yes | Yes |
| Private hand contents/order | No | Auth | Auth | Auth only if faction policy permits | Yes | No | No | Developer diagnostic only |
| Public inventory | Yes | Yes | Yes | Yes | Yes | Yes | Yes | Yes |
| Secret item ownership | No | Auth | Auth | Auth if faction-shared | Yes | No | No | Developer diagnostic only |
| Revealed board spaces/features/hazards | Yes | Yes | Yes | Yes | Yes | Yes | Yes | Yes |
| Unrevealed board spaces or secret state | No | Only if seat authoring allows | Only if seat authoring allows | Only if faction authoring allows | Yes | No | No | Developer diagnostic only |
| Pawn position / public occupancy | Yes | Yes | Yes | Yes | Yes | Yes if meaningful | Aggregate/sanitized | Yes |
| Director public pressure/decision result | Yes when authored public | Yes | Yes | Yes | Yes | Yes | Yes if schema permits | Yes |
| Director candidate scores, budgets, RNG | No | No | No | No | Yes | No | No | Developer diagnostic only |
| Director private-role telemetry | Prohibited input | Prohibited | Prohibited | Prohibited | Prohibited | Prohibited | Prohibited | Tests must prove absent |
| Hidden transition plan/cause | No | Auth only when current seat is entitled | Auth | Auth when faction-entitled | Yes | No until authored reveal | No | Developer diagnostic only |
| Revealed conversion/defeat/afterlife state | Yes | Yes | Yes | Yes | Yes | Yes | Yes | Yes |
| Private ending details | No | Auth | Auth | Auth if faction detail | Yes | No | No | Developer diagnostic only |
| Public mixed ending/outcome | Yes | Yes | Yes | Yes | Yes | Yes | Yes | Yes |
| Raw rejection reason | No | No | No | No | No unless authority needs a stable safe code | No | No | Developer diagnostic only |
| Sanitized notice code | Yes | Yes | Yes | Yes | Usually presentation-only | May record category only | May record category only | Yes |
| File path / JSON path / stack trace | No | No | No | No | No | No | No | Developer diagnostic only |
| Test fixture/canary value | No | No | No | No | Test-only | No | No | Test-only |
| Build version / source SHA | Help-approved bounded form | Same public form | Same public form | Same public form | No gameplay effect | No gameplay effect | Approved bounded form | Yes |
| Human participant identity | No | No | No | No | No | No | De-identified only | Separate consent record only |

## 10. Route-specific privacy behavior

### 10.1 Title and Seat Lobby

Public television MAY show:

- game working-title text with provisional status handled in documentation/marketing policy;
- generic controller connection status;
- stable seat number, symbol, pattern, and connection state;
- generic “keyboard development” label when relevant;
- join, leave, confirm, Help, safe-area, and protected-reset controls.

It MUST NOT show:

- raw device IDs;
- browser capabilities;
- previously retained role/private data from an earlier session;
- exported-report path;
- absolute local filesystem information.

Protected reset MUST clear every private presentation cache before the fresh title/lobby is drawn.

### 10.2 Mode Confirmation

The shared screen MAY explain the public social-mode promise and truthful cooperative fallback.

It MUST NOT pre-reveal which seat will receive a hidden role or expose assignment weights, plans, salted RNG, or private objective inventory.

### 10.3 Tale Library

The Library MAY show only the governed public projection:

- display name;
- briefing;
- objective;
- supported seat bounds;
- focus, selected, and confirmed state;
- truthful available Tale count.

Preparation failure MUST retain the focused Tale card and show one of the fixed sanitized recovery callouts approved for PR #46. It MUST NOT expose raw package/provider/localization rejection details.

### 10.4 Public Briefing

The briefing is public. It MAY show seat count, public objective, selected mode, and fallback status.

Role assignment or private reveal MUST occur only through the approved controlled-reveal or authorized Companion path, not as an incidental continuation of briefing animation.

### 10.5 Active Tale

The public HUD MUST clearly distinguish:

- public instruction;
- waiting for one or more seats;
- accepted public result;
- private action occurred with an authored neutral consequence;
- pause/help/recovery state.

It MUST NOT reveal private eligibility merely by highlighting a seat differently unless that eligibility is authored public information.

### 10.6 Pause and Help

Pause and Help MUST obscure or remove private content before displaying public controls.

Opening Help while a controlled reveal is active MUST return to the privacy shield first. Help MUST NOT become a route to another seat’s private panel.

### 10.7 Terminal and Ending

Terminal authority results are fixed before ending review.

The public ending MAY show multiple public faction and individual outcomes, including mixed, partial, escaped, Changed, or Restless results when authored public.

Private epilogues or objective details MUST use seat-scoped reveal/Companion. Returning from one private epilogue MUST restore a neutral shield before another seat is authorized.

### 10.8 Rematch and Return

Rematch MAY retain stable seats, selected Tale, requested mode, and seed under the accepted current policy. It MUST rebuild session authorities and clear every prior private presentation cache, Companion private revision, and controlled-reveal state.

Return to title/protected reset MUST clear session authorities, private projections, room access, role/hand/ending caches, and report-in-progress state according to existing policies.

## 11. No-phone privacy protocol

### 11.1 Approved secret-delivery methods

Required private information MAY be delivered through one of these no-phone methods:

1. **Sequential controlled reveal** — preferred baseline for role, objective, private action, or private ending text.
2. **Open-information fallback** — author-approved mode where secrecy is removed but gameplay remains coherent.
3. **Facilitator-mediated sealed choice** — only when the facilitator is explicitly outside the competing information model and the Tale declares it.
4. **Controller-local cue plus public legend** — supplemental only; never sole required content.

### 11.2 Sequential controlled-reveal ceremony

The standard no-phone ceremony MUST provide:

- neutral public shield;
- authorized stable-seat identification using number plus symbol/pattern;
- confirm from that seat’s current authorized controller;
- large readable private content;
- optional narration that does not leak through shared audio unless headphones are explicitly available and optional;
- close/confirm action;
- neutral shield before returning the controller;
- public continuation confirm.

### 11.3 Secret choice collection

For a private choice on the shared display:

- only the authorized seat’s choices may be shown;
- choice focus must not be echoed on public HUD, diagnostics, previous prompt summaries, or controller indicators visible to others;
- accepted choice may remain secret until an authored reveal point;
- cancel returns to the privacy shield, not the normal board with private content still present;
- timeout returns to the shield and leaves authority unchanged;
- stale or wrong-seat input rejects without identifying the attempted private choice.

### 11.4 Faction-private information without phones

Sequential seat-scoped reveal is the safe default. A Tale MAY provide a specially designed local faction ceremony only after a separate design review explains how non-members are excluded and how the shared hardware supports the claim.

The game MUST NOT display a faction-private panel and ask non-members to close their eyes.

## 12. Authoritative state and presentation-only state

### 12.1 Authoritative privacy-relevant state

The appropriate existing authority MAY own:

- stable seat assignment and connection reservation;
- current role, faction, form, lifecycle, reveal state, objective, action, target, and use limits;
- prompt/vote/check/card/inventory state;
- board reveal/hazard/feature state;
- Director budget/cooldown/decision state;
- accepted private choice and authored reveal timing;
- private and public ending results;
- projection revision needed to reject stale requests.

### 12.2 Presentation-only privacy state

Presentation MAY own:

- current public focus;
- privacy-shield animation progress;
- which reveal page is being displayed after authority authorization;
- subtitle page and scroll position;
- temporary “pass controller to Seat III” instruction;
- current controller glyph family;
- public notice animation;
- Help tab and pagination;
- reduced-motion rendering choice.

Presentation MUST NOT decide who is authorized. It consumes an authoritative authorization result.

### 12.3 Private presentation cache policy

Private presentation data SHOULD be held only as long as needed to draw the current authorized view.

On reveal close, authorization change, reset, return, rematch, Companion disconnect, faction transition, or scene destruction, the runtime MUST clear:

- private label text;
- cached private projection dictionaries;
- private option lists;
- selected private target;
- prior private ending page;
- browser private application state under project control;
- queued private narration.

## 13. Deterministic behavior

Privacy behavior must be deterministic for the same authoritative state and accepted intent sequence.

Requirements:

- audience classification uses stable enumerated values;
- projection key order is stable before hashing/testing;
- sanitization maps internal reasons to fixed public notice codes;
- a failed projection consumes no gameplay RNG;
- opening/closing a private view consumes no gameplay RNG;
- public wording selection MUST NOT use nondeterministic randomness;
- Director telemetry excludes secret fields through an allowlist, not runtime luck;
- private reveal ordering is stable-seat order unless the Tale declares another deterministic order;
- tie-breaking for simultaneous authorized requests follows existing deterministic arbitration or an explicitly authored rule;
- replay records accepted semantic intents and authority outcomes, not private UI animation timing;
- privacy tests use stable planted canaries and recursive traversal.

## 14. Sanitized recovery and error contract

### 14.1 Player-facing notice properties

A public notice MUST contain:

- one stable sanitized code;
- one fixed player-readable title;
- one fixed player-readable explanation;
- only safe actions available in the current route;
- a clear clearing condition.

A public notice MUST NOT include concatenated internal reasons.

### 14.2 Required v0.1.6 notice behavior

For the bounded PR #46 correction:

- `tale_selection_unavailable` keeps the focused Tale card visible and provides Retry, Back, Help, and protected-reset guidance;
- `tale_preparation_unavailable` keeps the focused Tale card visible and provides the same safe recovery choices;
- successful recovery clears the notice;
- raw provider, package, localization, path, hash, class, source-ledger, or diagnostic information remains absent.

### 14.3 General runtime notice categories

A future separately reviewed runtime notice taxonomy SHOULD prefer a small closed set such as:

- `action_unavailable`
- `waiting_for_seat`
- `private_view_unavailable`
- `controller_reconnect_required`
- `session_recovery_required`
- `report_export_unavailable`

These are examples for design review, not approved schema or code changes.

## 15. Director privacy boundary

The Director MAY consume normalized copies of approved public or aggregate telemetry, including bounded signals such as:

- public round/stage progress;
- public objective progress;
- revealed hazard pressure;
- aggregate defeated/restless counts;
- public stall/recovery indicators;
- disconnected-seat exclusion;
- prior public Director applications.

The Director MUST NOT consume:

- unrevealed role or faction IDs;
- private objectives;
- private targets or messages;
- hidden transition plans;
- private hand or item information unless the Tale explicitly makes it public;
- browser/device/account identity;
- voice, camera, biometric, emotion, or behavioral profiling;
- source/package/provider provenance.

Director diagnostics MAY explain candidate scoring only in developer-only surfaces and must remain absent from public history, Companion views, reports, and normal HUD.

## 16. Companion-specific security and privacy condition

Issue #44 remains open. Until it is resolved:

- no Companion dependency, source, protocol, room-service, Worker, Cloudflare configuration, or deployment change is authorized by this document;
- no Companion public release or deployment is permitted;
- the known audit result must not be suppressed, overridden, downgraded, or bypassed;
- any different Companion failure or new advisory blocks a release;
- protected main must not be described as fully security-green.

This design MAY be used to review existing Companion projections and tests without changing those blocked surfaces.

## 17. Data and schema impact

### 17.1 No immediate schema change

This document is implementable primarily through:

- projection allowlists;
- presentation routing;
- fixed notice mappings;
- private-cache clearing;
- recursive privacy tests;
- documentation synchronization.

It does not require a production Tale package or catalog change.

### 17.2 Possible future schema concepts

A future ADR may consider reusable authored fields such as:

```text
visibility
reveal_policy
public_consequence_key
private_prompt_key
private_result_key
audience
projection_policy
cache_policy
```

Any such proposal must:

- avoid duplicating existing social privacy fields;
- preserve stable IDs;
- reject unknown fields under current policy;
- update validators, canonicalization, package identity, replay evidence, and migration documentation;
- be reviewed separately from implementation of this matrix.

## 18. Test requirements

### 18.1 Projection unit tests

For every projection function, tests MUST prove:

- exact allowed keys for public, seat-private, faction-private, and diagnostics views;
- no hidden fields appear recursively in public or unauthorized views;
- one seat cannot request another seat’s private view;
- a seat outside a faction cannot request faction-private data;
- authorization updates after every faction/form/lifecycle transition;
- malformed audience values fail closed;
- absent optional data produces an empty safe projection rather than an authority dump.

### 18.2 Planted canary tests

Tests SHOULD plant unmistakable private values in:

- role IDs;
- faction IDs;
- private objective text;
- private action payloads;
- target IDs;
- transition causes;
- package paths;
- provider IDs;
- class names;
- source-ledger values;
- absolute paths;
- host/resume capabilities;
- report fields.

Recursive scans must prove those values are absent from:

- normal shared-screen view models;
- public Companion projections;
- public history;
- schema-v2 reports;
- Help context;
- sanitized notices;
- portable bundles;
- screenshots generated by automated public-view fixtures.

### 18.3 Controlled-reveal view tests

Deterministic view-level tests MUST cover:

- neutral shield before private text;
- wrong-seat confirm rejection;
- authorized-seat entry;
- only authorized content shown;
- timeout to shield;
- cancel to shield;
- Help opened from reveal returning to shield;
- disconnect during reveal;
- reconnect to the same stable seat;
- reset/rematch/return clearing private labels and caches;
- sequential epilogues never showing two seats’ details together.

### 18.4 Tale Library recovery tests

After the bounded PR #46 correction, view-level tests MUST cover:

- provider rejection with valid focused card retained;
- package rejection with valid focused card retained;
- sanitized fixed callout visible;
- Retry, Back, Help, and protected reset guidance;
- no raw reason/path/hash/provider/class/source-ledger text;
- successful retry clears the notice;
- seats, mode, selection, focus, snapshots, RNG, and authorities remain unchanged after rejection.

### 18.5 Report tests

Report tests MUST verify:

- exact schema keys and ordering;
- bounded event counts;
- sanitized rejection categories;
- no private role/faction/objective/action/target content;
- no package/catalog/provider/source provenance;
- no absolute paths, host identity, token, capability, or raw device ID;
- manual validation fields default to `not_tested`;
- automation cannot set physical/controller/television/privacy/manual passes.

### 18.6 Snapshot and replay tests

Tests MUST prove:

- snapshots preserve required private authority for restore;
- public projections after restore remain equivalent;
- unauthorized projections remain denied after restore;
- malformed private state rejects atomically;
- snapshot rejection changes no authority;
- replay/public-history digest excludes private details and provenance;
- opening Help/reveal/presentation does not change authority or RNG digests.

### 18.7 Companion tests

Without changing issue #44-blocked source or dependencies, inherited tests must continue proving:

- host approval of an existing stable seat;
- explicit privacy gate;
- same-seat reconnect;
- cross-seat, stale, duplicate, tampered, expired, and unsupported rejection;
- exactly-once accepted intent behavior;
- no private content in public views;
- room loss leaves native play operational;
- no secret capability or token in logs, reports, or public UI.

### 18.8 Static and bundle scans

Automated gates SHOULD scan for:

- forbidden path prefixes;
- hash-shaped values in normal UI fixtures where not approved;
- provider/class/source-ledger identifiers;
- synthetic fixture names;
- reports or private evidence in export bundles;
- tokens/capabilities/secrets;
- tests and caches in player packages.

False positives must be resolved through narrower approved allowlists, not broad suppression.

## 19. Human playtest requirements

Automation cannot establish the following:

- whether players understand the privacy shield and seat authorization ceremony;
- whether players accidentally look during sequential reveals;
- whether passing a controller is comfortable and practical;
- whether private text is readable without being visible from the rest of the room;
- whether controller vibration/light cues are distinguishable on actual hardware;
- whether television overscan or viewing angle exposes content assumed to be hidden;
- whether the flow creates unacceptable downtime or social awkwardness;
- whether optional companions feel private in a real household setting;
- whether participants understand consent and screenshot/recording boundaries.

Those findings require issue #39 or a future authorized human playtest. They must be recorded as observations, not privacy certification.

## 20. Implementation-ready slices

### Slice P-1 — Documentation and projection inventory

Deliverables:

- adopt this matrix as canonical technical documentation;
- inventory every current outward projection and audience;
- map each projection to an owner and test file;
- identify discrepancies without changing production behavior.

Risk: low. Can proceed after review and does not depend on PR #46 implementation details except its Library projection inventory.

### Slice P-2 — Recursive privacy test harness

Deliverables:

- reusable recursive forbidden-value scanner;
- planted canary fixture helpers;
- explicit audience/key assertions;
- tests for public history, Help, reports, Companion public views, and shared-screen view models.

Risk: low to medium. Must avoid modifying Companion source/dependencies blocked by issue #44.

### Slice P-3 — Controlled-reveal presentation hardening

Deliverables:

- explicit shield/reveal/close states;
- stable-seat authorization gate;
- timeout/cancel/help/disconnect behavior;
- private cache clearing tests.

Risk: medium. Must preserve existing role authority and no-phone behavior.

### Slice P-4 — Runtime sanitized notice taxonomy

Deliverables:

- closed public notice mapping;
- fixed player text and safe actions;
- separation from raw diagnostics;
- deterministic clearing rules.

Risk: medium. The PR #46 bounded correction must land first, and this slice must not reopen or broaden it.

### Slice P-5 — Report/evidence synchronization

Deliverables:

- document exact report audience;
- verify existing schema-v2 exclusions;
- add regression canaries where coverage is missing;
- verify portable bundles exclude reports/private evidence.

Risk: low to medium. No report schema change unless separately approved.

### Slice P-6 — Future Companion privacy review

Deliverables after issue #44 resolution:

- review projection cache invalidation;
- verify faction-transition revocation;
- verify browser private-state clearing;
- conduct actual device/privacy human testing.

Risk: high and blocked by issue #44 plus human-playtest requirements.

## 21. Release and migration risk

| Risk | Consequence | Control |
| --- | --- | --- |
| Broadening PR #46 | Competing change and delayed bounded correction | Keep Library recovery fix separate; implement later slices from merged main |
| Redaction-based public views | New private fields leak by default | Explicit allowlisted projections and exact-key tests |
| Presentation owns authorization | Wrong seat gains private view | Authority validates stable seat and revision before reveal |
| Cached Companion faction view | Former member retains secrets | Recalculate/revoke on every transition and clear browser state |
| Private data in reports | Persistent spoiler/privacy leak | Schema allowlist plus planted-canary recursive tests |
| Private data in screenshots | Playtest evidence leaks secrets | Public-view fixtures only; consent boundary for human captures |
| Snapshot treated as public export | Full authority disclosure | Local-only snapshot policy; never render/relay wholesale |
| Package/catalog provenance enters gameplay | Replay/report compatibility and information leak | Keep provenance in internal build evidence only |
| Controller cue assumed universal | Accessibility and no-phone failure | Always provide non-haptic controller/controlled-reveal path |
| Companion work proceeds before remediation | Security policy violation | Maintain issue #44 freeze and no deployment |
| Automated privacy test called certification | False assurance | Label automated evidence accurately; require issue #39 human observation |
| New schema field changes package identity | Unreviewed content migration | Separate ADR/package/catalog/replay release |

## 22. Acceptance criteria

This design is ready for implementation planning when reviewers agree that:

1. every outward surface has one explicit audience;
2. public projections are allowlisted rather than redacted authority dumps;
3. the normal shared television is always treated as public;
4. controlled reveal fully obscures the screen and authorizes one stable seat;
5. every required secret flow has a complete no-phone path;
6. optional companions remain non-authoritative;
7. package/catalog/provider/source provenance stays out of gameplay UI, snapshots under the current contract, public history, reports, and Companion views;
8. diagnostics never become player-facing guidance;
9. reports and portable evidence remain local, explicit, de-identified, and privacy-safe;
10. deterministic and recursive privacy tests cover planted canaries;
11. issue #44 and issue #39 boundaries remain explicit;
12. no production identity or schema is changed merely by approving the document.

## 23. Recommended next action after approval

The first implementation issue should be a documentation-and-tests-only privacy inventory, not a broad UI rewrite.

Recommended issue objective:

> Map every current public, seat-private, faction-private, controlled-reveal, Help, report, history, snapshot, Companion, and diagnostic projection to this matrix; add reusable recursive canary tests for gaps; preserve all gameplay, package/catalog identities, Companion source/dependencies, deterministic behavior, and player-visible outcomes.

That issue can be prepared after the design document is reviewed. Code touching the finalized Tale Library route must wait for the bounded PR #46 correction and merge.
