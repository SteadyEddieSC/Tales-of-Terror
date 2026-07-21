class_name TaleSelectionState
extends RefCounted

var catalog: Dictionary = {}
var catalog_digest: String = ""
var entry: Dictionary = {}
var metadata: Dictionary = {}
var registry: TaleProviderRegistry
var catalog_path: String
var expected_catalog_digest: String


func _init(
	p_catalog_path: String,
	p_registry: TaleProviderRegistry,
	p_expected_catalog_digest: String,
) -> void:
	catalog_path = p_catalog_path
	registry = p_registry
	expected_catalog_digest = p_expected_catalog_digest


func load_default() -> Dictionary:
	var result: Dictionary = TaleCatalog.load_validated(
		catalog_path, registry, expected_catalog_digest
	)
	if not result.get("accepted", false):
		return result
	catalog = result.catalog
	catalog_digest = result.digest
	return select(result.default_tale_id)


func select(tale_id: String) -> Dictionary:
	var candidate_entry: Dictionary = TaleCatalog.entry_by_id(catalog, tale_id)
	if candidate_entry.is_empty():
		return {"accepted": false, "reason": "unknown_tale_selection:%s" % tale_id}
	var candidate: Dictionary = registry.build_candidate(candidate_entry)
	if not candidate.get("accepted", false):
		return {
			"accepted": false,
			"reason": "invalid_tale_selection:%s" % candidate.get("reason", "rejected"),
		}
	var candidate_metadata: Dictionary = TaleCatalog.selection_metadata(candidate_entry, registry)
	if candidate_metadata.is_empty():
		return {"accepted": false, "reason": "invalid_tale_selection:display_rejected"}
	entry = candidate_entry.duplicate(true)
	metadata = candidate_metadata.duplicate(true)
	return {"accepted": true, "selected_tale_id": tale_id, "candidate": candidate}


func selected_tale_id() -> String:
	return entry.get("tale_id", "")
