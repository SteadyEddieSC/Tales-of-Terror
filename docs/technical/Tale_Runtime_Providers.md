# Tale Runtime Provider Boundary

`TaleProviderRegistry` is the static repository-reviewed bridge from catalog data to native Godot content constructors. JSON declares only the stable provider ID/version and four expected authority references. It never declares a class name, script, callback, expression, reflection target, executable, or remote location.

The production allowlist contains only `lantern_house_authorities_v1`. The registry constructs candidate Lantern House board, rules, Director, and social content, validates the exact catalog-bound package against those candidates, checks package/manifest/provider reference coherence, and returns the complete candidate content bundle only after every check succeeds. Unknown, incomplete, changed, or mismatched work returns a source-located diagnostic and no session authority.

`VerticalSliceCoordinator` owns no Lantern House class names or package paths. It loads the reviewed catalog, keeps one pre-session stable-ID selection, asks the registry for a validated candidate, and only then creates temporary `BoardState`, `RulesSession`, Director runtime, `RoleSession`, companion bridge, and pawns. It commits them together after all validators and mode authorization succeed.

Selection is available only before authority initialization. Unknown or rejected selection retains the previous valid entry, consumes no gameplay RNG, and creates no authority. Rematch rebuilds the selected entry through the registry; reset clears session authorities and reselects the catalog default. Restoration uses the existing stable scenario ID to select before restoring unchanged schema-v2 snapshots.

Test-only registry injection is restricted to excluded sources below `game/tests/`. The production registry cannot dynamically register providers. A future production provider requires a separately reviewed design/content issue, static code registration, catalog/package/source updates, deterministic validation, replay evidence, and a new catalog identity.
