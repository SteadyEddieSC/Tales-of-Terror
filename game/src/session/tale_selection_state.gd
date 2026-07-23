class_name TaleSelectionState
extends RefCounted

var catalog: Dictionary = {}
var catalog_digest: String = ""
var entry: Dictionary = {}
var metadata: Dictionary = {}
var focused_tale_id: String = ""
var confirmed_tale_id: String = ""
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
	var selected: Dictionary = select(result.default_tale_id)
	if selected.get("accepted", false):
		confirmed_tale_id = ""
	return selected


func select(tale_id: String) -> Dictionary:
	var prepared: Dictionary = prepare(tale_id)
	if not prepared.get("accepted", false):
		return prepared
	commit_prepared(prepared, false)
	return {
		"accepted": true,
		"selected_tale_id": tale_id,
		"candidate": prepared.candidate,
	}


func prepare(tale_id: String) -> Dictionary:
	var candidate_entry: Dictionary = TaleCatalog.entry_by_id(catalog, tale_id)
	if candidate_entry.is_empty():
		return {"accepted": false, "reason": "unknown_tale_selection:%s" % tale_id}
	return prepare_entry(candidate_entry)


func prepare_entry(candidate_entry: Dictionary) -> Dictionary:
	var tale_id: String = candidate_entry.get("tale_id", "")
	var candidate: Dictionary = registry.build_candidate(candidate_entry)
	if not candidate.get("accepted", false):
		return {
			"accepted": false,
			"reason": "invalid_tale_selection:%s" % candidate.get("reason", "rejected"),
		}
	var candidate_metadata: Dictionary = TaleCatalog.selection_metadata(
		candidate_entry, catalog.get("compatibility", {}), registry
	)
	if candidate_metadata.is_empty():
		return {"accepted": false, "reason": "invalid_tale_selection:display_rejected"}
	return {
		"accepted": true,
		"selected_tale_id": tale_id,
		"entry": candidate_entry,
		"metadata": candidate_metadata,
		"candidate": candidate,
	}


func commit_prepared(prepared: Dictionary, confirmed: bool) -> void:
	entry = prepared.get("entry", {}).duplicate(true)
	metadata = prepared.get("metadata", {}).duplicate(true)
	focused_tale_id = entry.get("tale_id", "")
	if confirmed:
		confirmed_tale_id = focused_tale_id
	else:
		confirmed_tale_id = ""


func focus(tale_id: String) -> Dictionary:
	if TaleCatalog.entry_by_id(catalog, tale_id).is_empty():
		return {"accepted": false, "reason": "unknown_tale_focus"}
	focused_tale_id = tale_id
	return {"accepted": true, "focused_tale_id": focused_tale_id}


func move_focus(direction: int) -> Dictionary:
	var ids: PackedStringArray = []
	for catalog_entry: Dictionary in catalog.get("entries", []):
		ids.append(catalog_entry.get("tale_id", ""))
	if ids.is_empty() or direction == 0:
		return {"accepted": false, "reason": "tale_focus_unavailable"}
	var index: int = ids.find(focused_tale_id)
	if index < 0:
		index = ids.find(selected_tale_id())
	if index < 0:
		index = 0
	index = wrapi(index + (1 if direction > 0 else -1), 0, ids.size())
	return focus(ids[index])


func library_entries() -> Array[Dictionary]:
	var entries: Array[Dictionary] = []
	for catalog_entry: Dictionary in catalog.get("entries", []):
		var presentation: Dictionary = TaleCatalog.selection_metadata(
			catalog_entry, catalog.get("compatibility", {}), registry
		)
		if presentation.is_empty():
			return []
		presentation["focused"] = presentation.tale_id == focused_tale_id
		presentation["selected"] = presentation.tale_id == selected_tale_id()
		presentation["confirmed"] = presentation.tale_id == confirmed_tale_id
		entries.append(presentation)
	return entries


func selected_tale_id() -> String:
	return entry.get("tale_id", "")
