class_name RandomManager
extends RefCounted

## Seeded random number generator for deterministic simulations
## Use this instead of randf()/randi() for reproducible results

var _rng: RandomNumberGenerator
var _seed: int
var _call_count: int = 0  # Track calls for debugging


func _init(seed_value: int = 0) -> void:
	_rng = RandomNumberGenerator.new()
	set_seed(seed_value)


func set_seed(seed_value: int) -> void:
	_seed = seed_value
	_rng.seed = seed_value
	_call_count = 0


func get_seed() -> int:
	return _seed


func get_call_count() -> int:
	return _call_count


## Returns random int in range [0, max_value) - exclusive upper bound
func randi_range_exclusive(max_value: int) -> int:
	_call_count += 1
	return _rng.randi() % max_value


## Returns random int in range [min_value, max_value] - inclusive
func randi_range(min_value: int, max_value: int) -> int:
	_call_count += 1
	return _rng.randi_range(min_value, max_value)


## Returns random float in range [0.0, 1.0)
func randf() -> float:
	_call_count += 1
	return _rng.randf()


## Returns random float in range [min_value, max_value]
func randf_range(min_value: float, max_value: float) -> float:
	_call_count += 1
	return _rng.randf_range(min_value, max_value)


## Returns true with given probability (0-1000 for x1000 fixed-point)
## e.g., check_probability(500) = 50% chance
func check_probability(chance_x1000: int) -> bool:
	_call_count += 1
	return _rng.randi() % 1000 < chance_x1000


## Shuffles array in place (Fisher-Yates)
func shuffle(array: Array) -> void:
	for i in range(array.size() - 1, 0, -1):
		var j := randi_range_exclusive(i + 1)
		var temp = array[i]
		array[i] = array[j]
		array[j] = temp


## Pick random element from array
func pick(array: Array):
	if array.is_empty():
		return null
	return array[randi_range_exclusive(array.size())]


## Pick random index from array
func pick_index(array: Array) -> int:
	if array.is_empty():
		return -1
	return randi_range_exclusive(array.size())


## Create a child RNG with derived seed (for parallel determinism)
func create_child(child_id: int) -> RandomManager:
	var child_seed := _seed ^ (child_id * 2654435761)  # Hash combine
	return RandomManager.new(child_seed)
