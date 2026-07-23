extends SceneTree

const SYNTHETIC_CATALOG_PATH: String = (
	"res://tests/fixtures/" + "synthetic_two_entry_tale_catalog_v1.json"
)
const SYNTHETIC_CATALOG_DIGEST: String = (
	"06a1f9968fa255aa9bad1cf09fe30ec2" + "553e64599c3f8995d20aaa1610cc31c1"
)
const FORBIDDEN_PRESENTATION_TERMS: PackedStringArray = [
	"res://",
	"package_sha256",
	"provider_id",
	"source_ledger",
	"catalog_digest",
	"class_name",
	TalePackage.LANTERN_HOUSE_DIGEST,
	TaleCatalog.PRODUCTION_DIGEST,
]

var _failures: int = 0


func _initialize() -> void:
	_test_production_library_uses_governed_metadata()
	_test_route_restoration_and_immutability()
	_test_synthetic_focus_and_atomic_selection()
	_test_fail_closed_matrix()
	_test_public_provenance_exclusion()
	_test_one_to_eight_seats()
	if _failures == 0:
		print("Tale Library controller-first selection tests passed")
	quit(_failures)


func _test_production_library_uses_governed_metadata() -> void:
	var coordinator: VerticalSliceCoordinator = _library_coordinator(1)
	var state: Dictionary = coordinator.public_state()
	var library: Dictionary = state.tale_library
	_expect(coordinator.lifecycle == "tale_library", "places Tale Library after mode confirmation")
	_expect(library.available_count == 1, "reports exactly one available production Tale")
	_expect(library.entries.size() == 1, "renders one production catalog entry")
	if library.entries.is_empty():
		return
	var entry: Dictionary = library.entries[0]
	var governed: Dictionary = JSON.parse_string(
		FileAccess.get_file_as_string("res://data/tales/lantern_house/localization_en.json")
	)
	_expect(entry.display_name == governed["tale.lantern_house.display_name"], "uses governed name")
	_expect(entry.briefing == governed["tale.lantern_house.briefing"], "uses governed briefing")
	_expect(
		entry.public_objective == governed["tale.lantern_house.objective"],
		"uses governed objective",
	)
	_expect(entry.minimum_seats == 1 and entry.maximum_seats == 8, "shows the catalog seat range")
	_expect(entry.focused and entry.selected and not entry.confirmed, "shows focus and selection")
	var view := VerticalSliceView.new()
	view._ready()
	view.present(state, coordinator.seat_manager.get_seats())
	var rendered: String = "%s\n%s\n%s" % [view._title.text, view._body.text, view._footer.text]
	_expect("1 TALE AVAILABLE" in rendered, "renders the truthful singular Tale count")
	_expect("LANTERN HOUSE" in rendered, "renders the governed display name")
	_expect("SUPPORTED SEATS  1-8" in rendered, "renders supported seats")
	_expect("D-PAD / STICK / ARROWS" in rendered, "renders controller and keyboard focus help")
	_expect(_presentation_is_bounded(rendered), "renders no provenance or private diagnostics")
	view.free()


func _test_route_restoration_and_immutability() -> void:
	var coordinator: VerticalSliceCoordinator = _library_coordinator(2)
	var seats_before: Dictionary = coordinator.seat_manager.to_snapshot()
	var selected_before: String = coordinator._selection.selected_tale_id()
	var focused_before: String = coordinator._selection.focused_tale_id
	var mode_before: String = coordinator.requested_mode
	_expect(coordinator.initialize_session(4706, mode_before).accepted, "confirms the focused Tale")
	_expect(coordinator.lifecycle == "briefing", "advances from Tale Library to briefing")
	_expect(
		coordinator.public_state().tale_library.confirmed_tale_id == selected_before,
		"records the confirmed Tale state",
	)
	_expect(
		coordinator.navigate_tale_library("return_from_briefing").accepted,
		"briefing back returns to Tale Library",
	)
	_expect(coordinator.lifecycle == "tale_library", "restores the Tale Library lifecycle")
	_expect(
		coordinator.seat_manager.to_snapshot() == seats_before, "retains stable seats and ownership"
	)
	_expect(coordinator.requested_mode == mode_before, "retains selected mode")
	_expect(coordinator._selection.selected_tale_id() == selected_before, "retains selection")
	_expect(coordinator._selection.focused_tale_id == focused_before, "retains focus")
	_expect(coordinator.tale_package.is_empty(), "removes prepared authorities before reselection")
	_expect(coordinator.initialize_session(4706, mode_before).accepted, "re-prepares atomically")
	_expect(coordinator.begin_tale().accepted, "starts the selected Tale")
	var active_before: Dictionary = coordinator.to_snapshot()
	_expect(
		not coordinator.select_tale(selected_before).accepted,
		"makes Tale selection immutable after session start",
	)
	_expect(coordinator.to_snapshot() == active_before, "late selection cannot mutate authority")


func _test_synthetic_focus_and_atomic_selection() -> void:
	var registry := SyntheticTaleProviderRegistry.new()
	var coordinator: VerticalSliceCoordinator = _library_coordinator(
		1, SYNTHETIC_CATALOG_PATH, registry, SYNTHETIC_CATALOG_DIGEST
	)
	var entries: Array = coordinator.public_state().tale_library.entries
	_expect(entries.size() == 2, "loads two export-excluded synthetic catalog entries")
	_expect(entries[0].tale_id == TalePackage.LANTERN_HOUSE_ID, "keeps stable sorted focus order")
	_expect(entries[1].tale_id == "synthetic_fixture_tale", "places synthetic entry second")
	var before_focus: Dictionary = coordinator.to_snapshot()
	_expect(coordinator.navigate_tale_library("focus", 1).accepted, "moves focus right or down")
	_expect(
		coordinator._selection.focused_tale_id == "synthetic_fixture_tale",
		"focuses the non-default synthetic entry",
	)
	_expect(coordinator.to_snapshot() == before_focus, "focus consumes no authority or RNG state")
	_expect(coordinator.navigate_tale_library("focus", -1).accepted, "moves focus left or up")
	_expect(
		coordinator._selection.focused_tale_id == TalePackage.LANTERN_HOUSE_ID,
		"restores deterministic prior focus",
	)
	_expect(
		coordinator.select_tale("synthetic_fixture_tale").accepted, "selects non-default fixture"
	)
	_expect(
		coordinator._selection.selected_tale_id() == "synthetic_fixture_tale",
		"retains explicit non-default synthetic selection",
	)
	_expect(
		coordinator.to_snapshot() == before_focus, "synthetic selection stays non-authoritative"
	)


func _test_fail_closed_matrix() -> void:
	var invalid_catalog := VerticalSliceCoordinator.new(
		TaleCatalog.PRODUCTION_PATH, TaleProviderRegistry.new(), "0".repeat(64)
	)
	_join_and_open_library(invalid_catalog, 1)
	var invalid_state: Dictionary = invalid_catalog.public_state()
	_expect(invalid_catalog.lifecycle == "tale_library", "invalid catalog remains on Tale Library")
	_expect(invalid_state.tale_library.available_count == 0, "invalid catalog exposes no entry")
	_expect(
		invalid_state.tale_library.notice == "tale_library_unavailable",
		"changed catalog digest uses bounded guidance",
	)
	_expect(
		_presentation_is_bounded(JSON.stringify(invalid_state)), "invalid catalog leaks no details"
	)

	var coordinator: VerticalSliceCoordinator = _library_coordinator(1)
	var selection_before: Dictionary = coordinator._selection.entry.duplicate(true)
	var route_before: Dictionary = coordinator.to_snapshot()
	_expect(
		not coordinator.select_tale("synthetic_unknown_tale").accepted, "rejects unknown Tale ID"
	)
	_expect(coordinator._selection.entry == selection_before, "unknown ID retains prior selection")
	_expect(
		coordinator.to_snapshot() == route_before, "unknown ID retains route, seat, and mode state"
	)

	var registry := SyntheticTaleProviderRegistry.new()
	var rejected: VerticalSliceCoordinator = _library_coordinator(
		1, SYNTHETIC_CATALOG_PATH, registry, SYNTHETIC_CATALOG_DIGEST
	)
	rejected.navigate_tale_library("focus", 1)
	registry.reject_synthetic = true
	var rejected_before: Dictionary = rejected.to_snapshot()
	var selected_before: Dictionary = rejected._selection.entry.duplicate(true)
	_expect(not rejected.initialize_session().accepted, "fails closed on provider rejection")
	_expect(rejected.lifecycle == "tale_library", "provider rejection stays on Tale Library")
	_expect(rejected._selection.entry == selected_before, "provider rejection retains selection")
	_expect(rejected.to_snapshot() == rejected_before, "provider rejection is atomic")
	var rejected_state: Dictionary = rejected.public_state()
	var rejected_rendered: String = _render_library(rejected)
	_expect(
		rejected_state.tale_library.notice == "tale_selection_unavailable",
		"provider rejection exposes only the sanitized selection notice",
	)
	_expect(
		"TALE SELECTION UNAVAILABLE" in rejected_rendered,
		"provider rejection renders the fixed recovery callout",
	)
	_expect(
		rejected_state.tale_library.entries[1].display_name.to_upper() in rejected_rendered,
		"provider rejection keeps the focused Tale card visible",
	)
	_expect(
		_has_recovery_guidance(rejected_rendered),
		"provider rejection renders Help, back, and protected-reset guidance",
	)
	_expect(
		_presentation_is_bounded(rejected_rendered),
		"provider rejection recovery callout leaks no provenance or internal reason",
	)

	for mutation: String in ["package", "missing_localization", "incomplete_display"]:
		var mutated: VerticalSliceCoordinator = _library_coordinator(1)
		var entry: Dictionary = mutated._selection.entry
		if mutation == "package":
			entry.package_sha256 = "0".repeat(64)
		elif mutation == "missing_localization":
			entry.display.objective_key = "tale.missing.objective"
		else:
			entry.display.erase("objective_key")
		var before: Dictionary = mutated.to_snapshot()
		var prior: Dictionary = mutated._selection.entry.duplicate(true)
		_expect(not mutated.initialize_session().accepted, "rejects %s" % mutation)
		_expect(mutated.lifecycle == "tale_library", "%s stays on Tale Library" % mutation)
		_expect(mutated._selection.entry == prior, "%s retains prior selection" % mutation)
		_expect(mutated.to_snapshot() == before, "%s creates no partial mutation" % mutation)
		var mutated_state: Dictionary = mutated.public_state()
		var rendered: String = _render_library(mutated)
		_expect(
			mutated_state.tale_library.notice == "tale_selection_unavailable",
			"%s uses the sanitized selection notice" % mutation,
		)
		_expect(
			"TALE SELECTION UNAVAILABLE" in rendered,
			"%s renders the fixed recovery callout" % mutation,
		)
		_expect(
			mutated_state.tale_library.entries[0].display_name.to_upper() in rendered,
			"%s keeps the focused Tale card visible" % mutation,
		)
		_expect(
			_has_recovery_guidance(rendered),
			"%s renders Help, back, and protected-reset guidance" % mutation,
		)
		_expect(
			_presentation_is_bounded(rendered),
			"%s recovery callout exposes only bounded public guidance" % mutation,
		)


func _test_public_provenance_exclusion() -> void:
	var coordinator: VerticalSliceCoordinator = _library_coordinator(1)
	var library_text: String = JSON.stringify(coordinator.public_state().tale_library)
	_expect(_presentation_is_bounded(library_text), "library projection excludes provenance")
	var snapshot_text: String = JSON.stringify(coordinator.to_snapshot())
	_expect(_presentation_is_bounded(snapshot_text), "pre-session snapshot excludes provenance")
	var report := PlaytestReport.new()
	report.begin(coordinator.public_state(), 4706, "2026-07-22T00:00:00Z", 0)
	var report_text: String = report.to_json()
	_expect(_presentation_is_bounded(report_text), "report excludes Tale provenance")
	coordinator.initialize_session()
	coordinator.begin_tale()
	var runtime_text: String = (
		JSON
		. stringify(
			{
				"snapshot": coordinator.to_snapshot(),
				"public": coordinator.public_state(),
				"companion": coordinator.companion_bridge.public_view(),
			}
		)
	)
	_expect(
		_presentation_is_bounded(runtime_text), "runtime and Companion views exclude provenance"
	)


func _test_one_to_eight_seats() -> void:
	for seat_count: int in range(1, 9):
		var coordinator: VerticalSliceCoordinator = _library_coordinator(seat_count)
		var before: Dictionary = coordinator.seat_manager.to_snapshot()
		coordinator.navigate_tale_library("focus", 1)
		_expect(
			coordinator.seat_manager.to_snapshot() == before,
			"focus preserves %d stable seat%s" % [seat_count, "" if seat_count == 1 else "s"],
		)
		_expect(
			coordinator.initialize_session().accepted,
			"prepares %d-seat no-phone route" % seat_count
		)


func _library_coordinator(
	seat_count: int,
	catalog_path: String = TaleCatalog.PRODUCTION_PATH,
	registry: TaleProviderRegistry = null,
	expected_digest: String = TaleCatalog.PRODUCTION_DIGEST,
) -> VerticalSliceCoordinator:
	var coordinator := VerticalSliceCoordinator.new(catalog_path, registry, expected_digest)
	_join_and_open_library(coordinator, seat_count)
	return coordinator


func _join_and_open_library(coordinator: VerticalSliceCoordinator, seat_count: int) -> void:
	for index: int in seat_count:
		coordinator.seat_manager.join_device(index, "library-pad-%d" % index, "Library Pad")
	coordinator.enter_lobby()
	coordinator.confirm_roster()
	coordinator.navigate_tale_library("open")


func _render_library(coordinator: VerticalSliceCoordinator) -> String:
	var view := VerticalSliceView.new()
	view._ready()
	view.present(coordinator.public_state(), coordinator.seat_manager.get_seats())
	var rendered: String = "%s\n%s\n%s" % [view._title.text, view._body.text, view._footer.text]
	view.free()
	return rendered


func _has_recovery_guidance(text: String) -> bool:
	return (
		"B / ESC: MODE CONFIRMATION" in text
		and "X / H: HELP" in text
		and "HOLD Y / R: RESET" in text
	)


func _presentation_is_bounded(text: String) -> bool:
	var normalized: String = text.to_lower()
	for term: String in FORBIDDEN_PRESENTATION_TERMS:
		if term.to_lower() in normalized:
			return false
	return true


func _expect(condition: bool, message: String) -> void:
	if condition:
		print("PASS: ", message)
		return
	_failures += 1
	push_error("FAILED: %s" % message)
