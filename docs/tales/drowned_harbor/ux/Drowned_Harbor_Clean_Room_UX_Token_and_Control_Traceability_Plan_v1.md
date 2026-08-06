# Drowned Harbor Clean-Room UX Token and Control Traceability Plan v1

## Standing

Metadata-only planning. No source, UI, private surface, runtime control, Godot implementation, candidate, or validation evidence is created.

Each future control must trace to an existing authoritative owner, legal-intent or informational source, availability condition, information class, interaction category, source owner/contributor record, and hypothetical future runtime consumer. No illustrative control becomes a new legal action or runtime field.

| Control ID | Control | Owner | Existing source | Availability | Information class | Category | Future source responsibility | Hypothetical future consumer |
|---|---|---|---|---|---|---|---|---|
| DH-UX-CTRL-SEAT-IDENTITY | Stable-seat public identity tile | RulesSession | existing public seat projection | stable public seat exists | public | informational | human-authored non-color identity grammar; exclude private fields | future seat-rail consumer, not implemented |
| DH-UX-CTRL-ROUTE-EMPHASIS | Legal route emphasis | BoardState | route reachability and public focus context | route is currently reachable or inspectable | public | informational/focus | depict authority-owned route classes without inventing reachability | future board-route consumer, not implemented |
| DH-UX-CTRL-FOCUS | Focus token | presentation | current authoritative focusable target | authorized public target is focusable | public | focus | non-color focus treatment with reduced-motion settled form | future focus consumer, not implemented |
| DH-UX-CTRL-PREVIEW | Selected preview token | presentation | current legal intent or BoardState route preview | existing legal public preview selected | public | preview | clearly separate non-mutating preview from commitment | future preview consumer, not implemented |
| DH-UX-CTRL-CONFIRMATION | Explicit confirmation boundary | RulesSession | existing confirmable legal intent | authority exposes confirm/cancel as legal | public | confirmation | name selected action and distinguish reversible/irreversible effects | future confirmation consumer, not implemented |
| DH-UX-CTRL-COMMITTED | Committed-state token | RulesSession | accepted commitment result | RulesSession accepts commitment | public | commitment result | persistent text-and-shape treatment distinct from preview | future committed-state consumer, not implemented |
| DH-UX-CTRL-WARNING | Public-safe warning | RulesSession | existing public warning or consequence projection | before commitment when public-safe warning exists | public | warning | disclose no hidden cause, moral label, desirability hint, or private fact | future warning consumer, not implemented |
| DH-UX-CTRL-RECOVERY | Public-safe recovery state | RulesSession | existing invalid-action or recovery projection | authority reports recoverable state and legal alternatives | public | recovery | actionable, non-punitive, state/RNG-neutral presentation | future recovery consumer, not implemented |
| DH-UX-CTRL-RECONNECT | Reconnect status | session coordinator | existing reconnect state | stable seat is reserved during reconnect | public | informational status | preserve seat identity; imply no reset, healing, defeat, or replacement | future session-status consumer, not implemented |
| DH-UX-CTRL-GAME-CONTROL | Game-control status | session coordinator | existing surrogate-control state | same seat is under authorized surrogate control | public | informational status | separate control source from character, role, or form | future session-status consumer, not implemented |
| DH-UX-CTRL-TAKEOVER-PENDING | Takeover-pending status | session coordinator | existing legal takeover intent and safe-handoff state | takeover is legal and queued for safe handoff | public | coordinator transition | expose no private seat contents or multi-seat private browsing | future takeover-status consumer, not implemented |
| DH-UX-CTRL-PRIVATE-SHIELD | Neutral private shield | session coordinator / RoleSession | controlled reveal and safe handoff | authorized private handoff is active | public-safe private boundary | private shield | opaque neutral presentation; suppress public transcript/captions and all hints | future private-shield consumer, not implemented |
| DH-UX-CTRL-PUBLIC-RETURN | Public-safe return state | session coordinator | private acknowledgement complete and public return | private sequence is cleared | public | coordinator transition | neutral clearing/return with no private residue | future public-return consumer, not implemented |
| DH-UX-CTRL-UPPER-STATUS | Public upper-status hierarchy | RulesSession | public stage, objective, Tide, authority, and status fields | fields exist in public authoritative projection | public | informational | hierarchy only; dimensions, fonts, wrapping remain hypotheses | future shared-status consumer, not implemented |
| DH-UX-CTRL-CAPTIONS | Public captions | presentation | authorized public caption stream | public caption content exists | public | informational | backing and hierarchy; exclude hidden/private content | future caption consumer, not implemented |
| DH-UX-CTRL-PROMPTS | Legal prompt strip | RulesSession / coordinator | current legal public and system intents | action is currently legal | public | action prompt | pair critical glyphs with text; later glyph license required | future prompt consumer, not implemented |
| DH-UX-CTRL-TRANSCRIPT | Public transcript access | presentation | existing authorized transcript intent | transcript access is legal | public | system overlay request | public-only container preserving active decision; exclude private content | future transcript consumer, not implemented |
| DH-UX-CTRL-REPLAY | Presentation-replay access | presentation | existing authorized presentation-replay intent | replay is legal | public | presentation replay request | public-only settled-state replay; never rerun authority or RNG | future replay consumer, not implemented |
| DH-UX-CTRL-OUTCOME | Public outcome hierarchy | RulesSession | public ending result | ending result exists | public | informational outcome | support mixed outcomes; private attribution stays controlled | future outcome consumer, not implemented |
| DH-UX-CTRL-PROFILE-INTENSITY | Spooky/Grim intensity treatment | presentation | authorized presentation-profile state | profile is already authorized | public | presentation intensity | preserve identical information, routes, actions, privacy, mechanisms, and outcomes | future profile consumer, not implemented |

## Common source requirements

Every future source for these controls must be blank and human-authored, independently composed, fully traceable, and free of generated pixels, traced/vectorized shapes, paint-over, composites, extracted textures, generated text/icons/logos, and private information. Contributor, tool, font, asset, license, source SHA-256, export SHA-256, and similarity-review records are mandatory.

## Stable-seat identity grammar

Identity must survive reconnect, surrogate control, takeover-pending state, transformation, and return to public play. Critical identity and state may not rely on color alone. Seat number, name, form, control state, and public status must remain distinct. Private role, objective, faction, target, inventory, transformation, or attribution fields remain excluded unless an existing controlled reveal explicitly authorizes them.

## Focus, preview, confirmation, and commitment

Focus never mutates state. Preview never predicts hidden information or commits an action. Confirmation exists only for an existing legal intent. Commitment appears only after authority accepts it. Warning states that nothing has committed. Recovery offers only authority-provided legal alternatives. Presentation replay never reruns reducers, events, RNG, transformations, ending resolution, attribution, or cleanup.

## Private shielding

The shared display must use a neutral shield during private handoff. It may not hint at seat, private category, timing significance, desirability, role, faction, objective, target, item, transformation, or result. Public captions, transcript, replay, diagnostics, screenshots, mirrors, and logs must not receive private content. Public return occurs only after RoleSession and the session coordinator clear the private sequence.

## Board occlusion and hierarchy

Later implementation must retain enough board context to understand the current decision, protect critical spaces/connectors/pawns, preserve captions and legal prompts, avoid horizontal scrolling at the intended logical target, and restore focus after dismissal or interruption. Exact 960×540 dimensions and safe regions remain unperformed hypotheses.

## Spooky and Grim profiles

Profiles may change intensity, decoration, motion, texture density, and presentation tone only. They must preserve identical routes, objectives, legal actions, stable-seat identity, private/public boundaries, mechanics, outcomes, focus order, confirmation requirements, captions, transcript meaning, and settled state.

## Evidence boundary

Similarity, 960×540 capture, seat density, privacy, motion/replay, physical-controller, television, readability, remote, accessibility, and issue #39 human evidence are unperformed. Automation is not human evidence.
