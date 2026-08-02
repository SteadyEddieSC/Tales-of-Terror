class_name DrownedHarborAlpha2DirectorContent
extends RefCounted

const CONTENT_ID: String = "drowned_harbor_graybox_director_v2"
const CONTENT_VERSION: int = 2
const PUBLIC_INPUT_KEYS: PackedStringArray = [
	"authoritative_revision",
	"connected_seat_count",
	"stage_id",
	"public_progress",
	"public_pressure",
	"public_recovery_count",
]


func authorized_input_keys() -> PackedStringArray:
	return PUBLIC_INPUT_KEYS.duplicate()


func accepts_input(value: Dictionary) -> bool:
	if value.size() != PUBLIC_INPUT_KEYS.size():
		return false
	for key: Variant in value:
		if not key is String or not PUBLIC_INPUT_KEYS.has(key):
			return false
	return true


func propose(value: Dictionary) -> Dictionary:
	if not accepts_input(value):
		return {"accepted": false, "reason": "director_input_not_public_allowlisted"}
	return {
		"accepted": true,
		"reason": "",
		"proposal": "graybox_no_op",
		"authority": "proposal_only",
	}
