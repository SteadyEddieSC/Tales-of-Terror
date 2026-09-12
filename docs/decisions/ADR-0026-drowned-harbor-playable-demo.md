# ADR-0026: Drowned Harbor playable demo authority and distribution

- Status: Implemented for the Project Owner-authorized Alpha.4 developer demo
- Date: 2026-09-10

The Project Owner's whole-game build request authorizes new gameplay, generated
original assets, local saves and Windows/Linux demo exports. Earlier planning-only
records remain historical. They do not prohibit this bounded implementation.

The demo uses a separate `DemoMain.tscn` and generated export project. Lantern
House remains the ordinary default and catalog entry. Ordinary presets explicitly
exclude the demo assets as well as the existing Drowned Harbor runtime/data.

`DrownedHarborDemoSession` routes bounded stable-seat choices through subclasses
of the existing Alpha.3 session/rules/role and Alpha.2 route authorities. Authored
choice bundles, route requests, objective conditions and ending policies remain
data. A complete candidate is prepared before adoption, so invalid requests cannot
partially change the live Tale. Board work crosses the existing board authority.
Director proposals use a copied isolated Director stream; only a validated rules
effect admits the proposal and its RNG state.

Ending selection uses final votes, council tie-breaking, preparation, rescues and
Harbor claim. It does not use Alpha.3 coverage indexes. Tied final and council
votes resolve in authored order: containment, release, escape, restoration.
Seats act in stable order. Simultaneous input is sorted by seat, then arrival order
within the same seat. Controller identity stays in the input adapter.

The version-4 save contains bounded replay records and an authoritative digest.
A fresh candidate replays and verifies the entire history before replacement.
The disk store preserves typed values, rejects object decoding, verifies SHA-256,
and retains a previous valid backup. It does not claim encryption. Controller
ownership is reclaimed locally and is never serialized as a capability.
Alpha.2/3 prototype snapshots are not silently migrated into this changed policy.

Public, seat-private and faction-private views remain separate. Only the requested
seat can open its controlled handoff. Private nodes are destroyed immediately on
shield, help, pause, disconnect or reset. A declared allegiance is public only
after the owning seat explicitly chooses declaration. Optional phone integration
continues to belong to the existing Companion prototype; this demo is local.

Seven new text-to-image illustrations are authorized demo runtime candidates.
Their retained originals, hashes, source/generator/derivation and review status
are recorded in `art/source/drowned_harbor_alpha4/generation_manifest.json` and
`art/provenance.json`. This bounded batch uses that explicit ledger while the
closed AI-ART-POLICY-001 empty ledger remains a historical policy artifact.
No external reference image was used. No independent human similarity review,
copyright clearance, storefront promotion or accessibility certification is claimed.
The source scripts reproduce the original procedural audio and narrative data.

Physical controllers, viewing distance, target Linux hardware and human art/fun
review remain separate evidence. This decision grants no merge or public-release authority.
