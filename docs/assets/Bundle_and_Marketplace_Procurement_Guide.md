# Bundle and Marketplace Procurement Guide

**Version:** 1.0
**Status:** Active preproduction purchasing policy
**Reviewed:** July 23, 2026
**Applies to:** Humble Bundle, Fanatical, AppSumo, StackSocial, Fab, Unity Asset Store, Godot Asset Store, creator stores, audio libraries, course bundles, lifetime deals, and temporary AI subscriptions

## 1. Purpose

Bundles can save substantial money, but advertised item counts and MSRP do not establish value for Terror Turn.

A purchase is worthwhile only when the licensed, technically usable, stylistically compatible subset directly supports an approved work package.

The project will not buy bundles merely because:

- the stated retail value is large;
- the discount percentage is dramatic;
- the bundle contains many files;
- the offer expires soon;
- the assets might be useful someday;
- the same vendor has appeared in prior bundles.

## 2. Standing purchase rule

Before purchase, record:

- exact bundle name and end date;
- current tier and price;
- complete item list;
- publisher or creator for every relevant item;
- commercial-use rights;
- engine restrictions;
- seat or team limits;
- source-file redistribution restrictions;
- contractor and collaborator access rules;
- asset-conversion rights;
- AI-upload, training, and generated-derivative restrictions;
- redemption deadline;
- download deadline or credit expiry;
- supported formats;
- Godot 4.7 import path;
- overlap with existing assets and subscriptions;
- expected integration effort;
- the three or more concrete project uses that justify purchase.

No purchase should be recommended until the license has been located and saved.

## 3. Minimum purchase gate

A candidate should normally satisfy all of the following:

1. Commercial use is clearly permitted.
2. The license remains usable after the bundle ends.
3. The assets can legally be used in Godot or in a permitted production tool that exports to Godot.
4. At least three included assets, courses, or services map to current approved tasks.
5. The expected usable value exceeds the purchase price without counting speculative future projects.
6. The bundle does not primarily duplicate ChatGPT Plus, Google AI Plus, Blender, Affinity, Krita, Audacity, DaVinci Resolve, or existing repository capabilities.
7. The project can preserve the receipt, bundle page, item list, license, and redemption records.
8. The asset can be used without placing restricted raw source files in a public repository.

## 4. Scoring rubric

Score each category from 0 to 5.

| Category | Question |
|---|---|
| Immediate fit | Does it support an approved release or asset brief now? |
| Style fit | Does it fit the original modern storybook/cel-shaded horror direction? |
| Godot fit | Is there a documented Godot 4.7 path with acceptable conversion work? |
| License clarity | Are commercial, engine, team, and redistribution rights explicit? |
| Usable subset | What percentage of the bundle is likely to be used? |
| Production quality | Are the files editable, organized, and technically suitable? |
| Duplication | Does it provide something our existing tools do not? |
| Provenance | Can every used asset retain a clean source and license record? |
| Integration cost | Is cleanup, conversion, optimization, and retargeting reasonable? |
| Vendor risk | Are redemption, download, and continued-access risks acceptable? |

Interpretation:

- **42–50:** strong candidate;
- **34–41:** buy only for a defined near-term package;
- **25–33:** monitor or buy only at a lower tier;
- **below 25:** skip.

A license failure overrides the numerical score.

## 5. License handling

Humble Bundle does not provide one universal commercial asset license for every bundle.

Licensing may come from:

- a creator-specific EULA;
- a redemption key for Fab, Unity Asset Store, or another marketplace;
- a bundle-specific license;
- a software subscription or download-credit agreement;
- a course platform license;
- separate terms for individual assets inside the same bundle.

For each purchased bundle, preserve:

- purchase receipt;
- screenshot or PDF of the bundle page;
- complete tier and item list;
- EULA text or PDF as it existed at purchase;
- marketplace redemption confirmation;
- redemption and download deadlines;
- source URL and creator identity;
- local checksum or immutable archive identity for downloaded files;
- project asset-register entry.

## 6. Public repository restrictions

Third-party raw assets must not be committed to a public GitHub repository unless the license explicitly permits source redistribution.

The repository may instead store:

- asset metadata;
- license references;
- checksums;
- import instructions;
- attribution text;
- derived configuration that contains no restricted source content;
- screenshots only when the license permits promotional use.

Compiled or embedded distribution inside a commercial game must still follow the applicable license.

## 7. Generative AI restrictions

Do not upload purchased assets to ChatGPT, Gemini, Flow, Firefly, Runway, ElevenLabs, or another generative service unless the applicable license clearly permits that use.

Third-party assets are treated as **not approved for AI input by default**.

This includes:

- reference-image upload;
- style transfer;
- model training or fine-tuning;
- texture generation based on the source asset;
- 3D model generation from source files;
- dataset creation;
- AI-related marketing using restricted vendor assets.

For example, Synty's current one-time license permits commercial use of qualifying Humble assets but limits Humble purchases to one seat and contains explicit restrictions on generative-AI datasets, generation of 3D models through generative programs, and certain AI-related promotional uses. Each vendor must be reviewed independently.

## 8. Engine compatibility

Preferred order:

1. Native Godot asset with a clear commercial license.
2. Engine-neutral source such as FBX, glTF, PNG, WAV, SVG, or Blender files with clear rights.
3. Fab or Unreal asset whose license permits use outside Unreal and whose source can be legally exported.
4. Unity asset whose license and files permit lawful export and use outside Unity.
5. Engine-locked asset only when the project has an approved use inside that engine or tool.

A label such as `Unity + Unreal + Godot` does not guarantee that every item supports every engine.

## 9. Audio bundle rules

Audio bundles should be judged against an approved cue list.

Before purchase, identify required categories such as:

- harbor bell variations;
- lighthouse machinery;
- wet wood and dock movement;
- waves, current, fog, rain, and distant storm;
- interior creaks and flooded-room ambience;
- footsteps on mud, wood, stone, and shallow water;
- Restless transition sounds;
- UI confirmations, warnings, and seat-control cues;
- stingers and transition beds;
- temporary music references.

Confirm:

- whether files are downloaded assets or only credits;
- whether credits expire;
- whether files already downloaded remain licensed indefinitely;
- whether individual or batch download is available;
- whether attribution is required;
- whether stems, loops, and alternate takes are included;
- whether voice packs may be used as final character performances;
- whether the license permits editing and commercial distribution.

Generic SFX libraries do not replace the Underteller voice-design process.

## 10. Visual bundle rules

Visual asset bundles should be evaluated separately for:

- direct production use;
- Blender blockout and camera studies;
- concept-art reference;
- UI or icon use;
- placeholder use;
- promotional use.

A realistic environment pack may be useful for blocking or lighting reference while being unsuitable for final storybook art.

Do not mix visibly incompatible marketplace packs into final art merely because they were inexpensive.

## 11. Course bundle rules

Course bundles are training purchases, not asset purchases.

Buy only when:

- the project owner intends to complete the material;
- the course teaches a current approved workflow;
- the software version is sufficiently current;
- access is permanent or long enough to finish;
- downloadable project files have clear usage rights;
- the same material is not already available through high-quality free documentation.

## 12. Lifetime-deal rules

A lifetime deal is treated as prepaid service access, not a guarantee that the company or model will exist forever.

Require:

- a defined work package;
- an acceptable refund period;
- exportable results;
- no lock-in of project source data;
- commercial-use rights;
- understandable credit policy;
- acceptable privacy terms;
- a replacement path.

Do not buy a lifetime AI plan solely to accumulate monthly credits.

## 13. Temporary subscription rule

A monthly service can be more economical than a lifetime deal when used as a focused production sprint.

Preferred pattern:

1. Finish prompts, scripts, shot lists, and naming conventions first.
2. Subscribe for one month.
3. Generate the approved batch.
4. Download source outputs and metadata.
5. Cancel unless the service remains actively needed.

This is the preferred approach for ElevenLabs, Firefly, Runway, and similar services.

## 14. Current Humble snapshot — July 23, 2026

Availability and pricing may change after this review date.

### Game Audio Collection — Audio Hero

Observed offer:

- full tier approximately $20;
- 103 listed items;
- access to more than 300,000 music and sound assets through included packs and download credit;
- advertised as commercial-ready;
- current end date approximately July 27, 2026;
- redemption deadline reported as July 27, 2027.

Project assessment:

- **Potentially useful**, especially for generic ambience, hazards, environmental effects, and temporary music.
- The 300,000 figure should not be treated as 300,000 locally included files.
- Confirm the exact credit, download, continued-license, batch-download, and expiry terms before purchase.
- Compare against the later Soundsnap offer and ElevenLabs SFX generation after the Drowned Harbor cue list is complete.

Current disposition: **review before expiry; no automatic purchase**.

### Soundsnap 1,000 Sound Effects Bundle

Observed offer:

- approximately $15;
- up to 1,000 selected sound-effect downloads;
- current end date approximately August 7, 2026.

Project assessment:

- Potentially stronger than a broad music-heavy library when we have an exact cue list.
- Community reports indicate individual-download workflow and unusual long-term access language; official terms must be confirmed.
- Do not buy before we know the exact 100–300 sounds we actually want.

Current disposition: **watch for P0.4 audio production**.

### Ultimate Stylized Bundle by SICS Games

Observed offer:

- full tier approximately $22;
- 16 listed items;
- current end date approximately August 8, 2026.

Project assessment:

- The stylized direction may be more relevant than realistic environment megabundles.
- Exact item list, license, formats, performance profile, and Godot path still require review.
- Consider for blockout, props, UI-adjacent objects, or visual-reference work only after matching items to the P0.3 asset brief.

Current disposition: **priority visual bundle to inspect during P0.3**.

### Cosmos Eclipse Game Dev Assets and Tools

Observed offer:

- full tier approximately $30;
- 74 listed items;
- mixed Unity, Unreal, tools, and some Godot-related content;
- current end date approximately August 1–2, 2026 depending on timezone.

Project assessment:

- Large advertised value but a mixed engine and style collection.
- Many included environments appear realistic and may not fit the current visual direction.
- Purchase only if at least three named packs directly support approved Drowned Harbor or general Terror Turn blockouts and have lawful Godot conversion paths.

Current disposition: **low-priority inspection; likely skip without a specific match**.

### Uncharted Frontiers Environment Pack — KitBash3D

Observed offer:

- approximately $30 for 13 packs;
- advertised as more than 400 environment assets;
- current end date approximately August 3, 2026.

Project assessment:

- Potentially valuable for Blender blockout, lighting studies, environment composition, or cinematic concepts.
- The realistic, large-scale environment direction is unlikely to become direct final art without extensive transformation.
- Verify KitBash3D license, export formats, seat rights, and any restrictions on AI-assisted derivative work.

Current disposition: **skip unless P0.3 identifies an exact environment need**.

### Complete Character Creation for Games

Observed offer:

- approximately $25;
- ten Blender-focused courses including low-poly characters, animation, rigging, and Blender-to-Godot material;
- purchase window ending around July 23–24, 2026;
- key redemption deadline reported in 2027.

Project assessment:

- Useful only if the project owner intends to personally learn and perform Blender character creation.
- It is not a ready-made character asset pack.
- No urgency-driven purchase is recommended without a learning plan.

Current disposition: **skip for now**.

## 15. Current priority order

1. Complete P0.2 dialogue before buying voice or audio services.
2. Complete the P0.3 visual asset brief before buying visual bundles.
3. Build the P0.4 audio cue list before buying Audio Hero, Soundsnap, or an ElevenLabs paid month.
4. Prefer a narrow tier when it contains every immediately needed item.
5. Prefer native or engine-neutral assets over conversion-heavy packs.
6. Preserve license evidence before downloading or modifying any purchased asset.

## 16. Review sources

Sources reviewed for the July 2026 snapshot include:

- current GameFromScratch game-development deal roundups;
- current bundle trackers such as GameDev Deals and independent Humble trackers;
- publisher license pages, including Synty's current Humble and one-time license terms;
- creator and course bundle descriptions;
- current Humble redirect destinations and reported end dates.

The live vendor page and saved license at purchase remain authoritative.
