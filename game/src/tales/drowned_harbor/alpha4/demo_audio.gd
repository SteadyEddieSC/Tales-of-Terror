class_name DemoAudio
extends Node
## Public, committed event playback only. Never reads a gameplay object or random stream.

signal caption_requested(text: String)

const ASSET_ROOT := "res://assets/drowned_harbor_alpha4/"
const STAGE_LOOPS := {
	"low_tide": "harbor_wind_loop",
	"bellhouse": "bellhouse_memory_loop",
	"council": "lighthouse_memory_loop",
	"flood": "high_water_current_loop",
	"epilogue": "last_light_memory_loop",
	"low_tide_arrival": "harbor_wind_loop",
	"low_tide_v1": "harbor_wind_loop",
	"bellhouse_ledger": "bellhouse_memory_loop",
	"bellhouse_v1": "bellhouse_memory_loop",
	"lighthouse_council": "lighthouse_memory_loop",
	"council_v1": "lighthouse_memory_loop",
	"high_water": "high_water_current_loop",
	"high_water_v1": "high_water_current_loop",
	"last_light": "last_light_memory_loop",
	"last_light_v1": "last_light_memory_loop",
	"ending_resolution": "last_light_memory_loop",
	"ending": "last_light_memory_loop",
}
const PUBLIC_CUES := {
	"bell": ["bell_strike_cue", "[A bronze bell rings.]"],
	"high_water": ["high_water_cue", "[Water surges through the streets.]"],
	"rescue": ["rope_rescue_cue", "[A rope draws taut.]"],
	"record": ["ledger_page_cue", "[A wet page separates.]"],
	"confirm": ["ui_confirm_cue", ""],
	"ending": ["last_light_cue", "[The lens settles.]"],
	"warning": ["route_warning_cue", "[Timber strains.]"],
}
const EVENT_CUES := {
	"search_manifest": "record",
	"search_wreck": "record",
	"search_archive": "record",
	"aid_resident": "rescue",
	"secure_boat": "rescue",
	"salt_ward": "warning",
	"harbor_bargain": "warning",
	"restless_warn": "warning",
	"finish_tale": "ending",
	"inspect_ledger": "record",
	"apply_high_water_transformation": "high_water",
	"attempt_rescue": "rescue",
	"resolve_ending": "ending",
	"commit_bellhouse_choice": "bell",
	"resolve_council_commitment": "bell",
	"apply_defeat_continuation": "warning",
}

var _bed := AudioStreamPlayer.new()
var _effect := AudioStreamPlayer.new()
var _streams: Dictionary = {}
var _stage := ""
var _revision := -1
var _last_event := ""
var _loop_name := ""
var _enabled := true
var _silenced := false
var _master := 0.7
var _music := 0.55
var _effects := 0.65


func _ready() -> void:
	add_child(_bed)
	add_child(_effect)
	_apply_levels()


func present(stage_id: String, revision: int, event_id: String = "") -> void:
	if revision < _revision and stage_id == _stage:
		return
	var stage_changed := stage_id != _stage
	if revision == _revision and event_id == _last_event and not stage_changed:
		return
	_stage = stage_id
	_revision = revision
	_last_event = event_id
	var next_loop := str(STAGE_LOOPS.get(stage_id, ""))
	if next_loop != _loop_name:
		_loop_name = next_loop
		_bed.stop()
		_bed.stream = _stream(next_loop)
		if _enabled and not _silenced and _bed.stream != null:
			_bed.play()
	if stage_changed:
		var stage_cues := {"high_water": "high_water", "high_water_v1": "high_water"}
		play_public_cue(str(stage_cues.get(stage_id, "bell")))
	elif EVENT_CUES.has(event_id):
		play_public_cue(str(EVENT_CUES[event_id]))


func play_public_cue(cue_id: String) -> void:
	if not PUBLIC_CUES.has(cue_id) or _silenced:
		return
	var cue: Array = PUBLIC_CUES[cue_id]
	if not str(cue[1]).is_empty():
		caption_requested.emit(str(cue[1]))
	if not _enabled:
		return
	_effect.stream = _stream(str(cue[0]))
	if _effect.stream != null:
		_effect.play()


func set_levels(master: float, music: float, effects: float) -> void:
	_master = clampf(master, 0.0, 1.0)
	_music = clampf(music, 0.0, 1.0)
	_effects = clampf(effects, 0.0, 1.0)
	_apply_levels()


func set_enabled(value: bool) -> void:
	_enabled = value
	if not value:
		_bed.stop()
		_effect.stop()
	elif not _silenced and _bed.stream != null and not _bed.playing:
		_bed.play()


func set_controlled_reveal(active: bool) -> void:
	_silenced = active
	_bed.stream_paused = active
	_effect.stop()
	if not active and _enabled and _bed.stream != null and not _bed.playing:
		_bed.play()


func stop_all() -> void:
	_bed.stop()
	_effect.stop()
	_stage = ""
	_loop_name = ""
	_revision = -1
	_last_event = ""


func _apply_levels() -> void:
	_bed.volume_db = linear_to_db(maxf(0.00001, _master * _music))
	_effect.volume_db = linear_to_db(maxf(0.00001, _master * _effects))


func _stream(asset_name: String) -> AudioStream:
	if asset_name.is_empty():
		return null
	if not _streams.has(asset_name):
		var path := ASSET_ROOT + asset_name + ".tres"
		if not ResourceLoader.exists(path):
			return null
		_streams[asset_name] = load(path)
	return _streams[asset_name] as AudioStream
