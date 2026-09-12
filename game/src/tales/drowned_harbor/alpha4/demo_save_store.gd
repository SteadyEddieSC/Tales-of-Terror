class_name DrownedHarborDemoSaveStore
extends RefCounted

## Local transport only. Gameplay validates a fresh candidate before adopting a read snapshot.
## No object deserialization, device identity, or private payload logging crosses this boundary.
const FORMAT_VERSION: int = 1
const MAX_BYTES: int = 16 * 1024 * 1024
const MAGIC: String = "TTDH-A4\n"
const HEADER_BYTES: int = 52
const DEFAULT_PATH: String = "user://alpha4_demo_save.dat"

var _path: String = DEFAULT_PATH


func _init(save_path: String = DEFAULT_PATH) -> void:
	_path = save_path


func has_save() -> bool:
	return (
		_valid_path() and (FileAccess.file_exists(_path) or FileAccess.file_exists(_path + ".bak"))
	)


func write_save(snapshot: Dictionary) -> Dictionary:
	if not _valid_path():
		return _reject("invalid_save_path")
	if snapshot.is_empty() or not _safe_value(snapshot, 0, [1000000]):
		return _reject("invalid_snapshot_value")
	var payload: PackedByteArray = var_to_bytes(snapshot)
	if payload.is_empty() or payload.size() > MAX_BYTES:
		return _reject("save_size_limit")
	var temporary: String = _path + ".tmp"
	var file: FileAccess = FileAccess.open(temporary, FileAccess.WRITE)
	if file == null:
		return _reject("save_write_unavailable")
	file.store_buffer(MAGIC.to_utf8_buffer())
	file.store_32(FORMAT_VERSION)
	file.store_64(payload.size())
	file.store_buffer(_digest(payload))
	file.store_buffer(payload)
	file.flush()
	var write_error: Error = file.get_error()
	file.close()
	if write_error != OK or not _read_file(temporary).get("accepted", false):
		return _reject("save_write_incomplete")
	return _commit_temporary(temporary, payload.size())


func _commit_temporary(temporary: String, byte_count: int) -> Dictionary:
	# Retain the last structurally valid save. A corrupt primary never replaces a good backup.
	if FileAccess.file_exists(_path):
		if _read_file(_path).get("accepted", false):
			if FileAccess.file_exists(_path + ".bak"):
				if DirAccess.remove_absolute(_path + ".bak") != OK:
					return _reject("save_backup_unavailable")
			if DirAccess.rename_absolute(_path, _path + ".bak") != OK:
				return _reject("save_backup_unavailable")
		elif DirAccess.remove_absolute(_path) != OK:
			return _reject("save_replace_unavailable")
	if DirAccess.rename_absolute(temporary, _path) != OK:
		return _reject("save_commit_unavailable")
	return {"accepted": true, "reason": "", "bytes": byte_count}


func read_save() -> Dictionary:
	if not _valid_path():
		return _reject("invalid_save_path")
	var primary: Dictionary = _read_file(_path)
	if primary.get("accepted", false):
		primary.recovered_backup = false
		return primary
	var backup: Dictionary = _read_file(_path + ".bak")
	if backup.get("accepted", false):
		backup.recovered_backup = true
		backup.recovery_reason = primary.reason
		return backup
	return primary


func _read_file(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return _reject("save_not_found")
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return _reject("save_read_unavailable")
	return _decode_file(file)


func _decode_file(file: FileAccess) -> Dictionary:
	if file.get_length() < HEADER_BYTES or file.get_length() > MAX_BYTES + HEADER_BYTES:
		return _reject("save_size_limit")
	if file.get_buffer(8).get_string_from_utf8() != MAGIC:
		return _reject("save_header_invalid")
	if file.get_32() != FORMAT_VERSION:
		return _reject("save_version_unsupported")
	var size: int = file.get_64()
	if size < 1 or size > MAX_BYTES or file.get_length() != HEADER_BYTES + size:
		return _reject("save_length_invalid")
	var expected_hash: PackedByteArray = file.get_buffer(32)
	var payload: PackedByteArray = file.get_buffer(size)
	file.close()
	if payload.size() != size or _digest(payload) != expected_hash:
		return _reject("save_checksum_mismatch")
	return _decode_payload(payload)


func _decode_payload(payload: PackedByteArray) -> Dictionary:
	var decoded: Variant = bytes_to_var(payload)
	if not decoded is Dictionary or decoded.is_empty():
		return _reject("save_payload_invalid")
	if not _safe_value(decoded, 0, [1000000]):
		return _reject("save_payload_invalid")
	return {"accepted": true, "reason": "", "snapshot": decoded}


func _valid_path() -> bool:
	if not _path.begins_with("user://"):
		return false
	var filename: String = _path.trim_prefix("user://")
	return (
		not filename.is_empty()
		and filename.length() <= 120
		and not filename.contains("..")
		and not filename.contains("/")
		and not filename.contains("\\")
		and not filename.contains(":")
	)


static func _digest(payload: PackedByteArray) -> PackedByteArray:
	var context := HashingContext.new()
	context.start(HashingContext.HASH_SHA256)
	context.update(payload)
	return context.finish()


static func _safe_value(value: Variant, depth: int, budget: Array) -> bool:
	budget[0] -= 1
	if depth > 64 or budget[0] < 0:
		return false
	if typeof(value) in [TYPE_OBJECT, TYPE_CALLABLE, TYPE_SIGNAL, TYPE_RID]:
		return false
	if value is Dictionary:
		for key: Variant in value:
			if not _safe_value(key, depth + 1, budget):
				return false
			if not _safe_value(value[key], depth + 1, budget):
				return false
	elif value is Array:
		for child: Variant in value:
			if not _safe_value(child, depth + 1, budget):
				return false
	return true


static func _reject(reason: String) -> Dictionary:
	return {"accepted": false, "reason": reason}
