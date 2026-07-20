class_name DeterministicRng
extends RefCounted

const MODULUS: int = 2147483647
const MULTIPLIER: int = 48271

var initial_seed: int
var state: int
var counter: int = 0


func _init(seed_value: int = 1) -> void:
	initial_seed = absi(seed_value) % MODULUS
	if initial_seed == 0:
		initial_seed = 1
	state = initial_seed


func draw_range(minimum: int, maximum: int) -> int:
	state = int((state * MULTIPLIER) % MODULUS)
	counter += 1
	return minimum + (state % (maximum - minimum + 1))


func shuffle(values: Array) -> Array:
	var result: Array = values.duplicate(true)
	for index: int in range(result.size() - 1, 0, -1):
		var swap_index: int = draw_range(0, index)
		var value: Variant = result[index]
		result[index] = result[swap_index]
		result[swap_index] = value
	return result


func to_snapshot() -> Dictionary:
	return {"initial_seed": initial_seed, "state": state, "counter": counter}


func restore(snapshot: Dictionary) -> bool:
	if (
		not snapshot.get("initial_seed") is int
		or not snapshot.get("state") is int
		or not snapshot.get("counter") is int
	):
		return false
	if (
		snapshot.initial_seed <= 0
		or snapshot.initial_seed >= MODULUS
		or snapshot.state <= 0
		or snapshot.state >= MODULUS
		or snapshot.counter < 0
	):
		return false
	initial_seed = snapshot.initial_seed
	state = snapshot.state
	counter = snapshot.counter
	return true
