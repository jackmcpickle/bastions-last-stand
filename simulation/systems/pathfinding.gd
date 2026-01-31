class_name SimPathfinding
extends RefCounted

## A* pathfinding for the simulation grid
## Caches paths per spawn point, invalidates on wall changes

const DIRECTIONS := [
	Vector2i(0, -1),  # Up
	Vector2i(0, 1),  # Down
	Vector2i(-1, 0),  # Left
	Vector2i(1, 0),  # Right
]

var _width: int
var _height: int
var _blocked: Dictionary = {}  # Vector2i -> bool
var _path_cache: Dictionary = {}  # spawn_point (Vector2i) -> path (Array[Vector2i])
var _shrine_pos: Vector2i


func _init(width: int, height: int) -> void:
	_width = width
	_height = height


func set_shrine_position(pos: Vector2i) -> void:
	_shrine_pos = pos
	_path_cache.clear()


func get_shrine_position() -> Vector2i:
	return _shrine_pos


func set_blocked(pos: Vector2i, blocked: bool) -> void:
	if blocked:
		_blocked[pos] = true
	else:
		_blocked.erase(pos)
	_path_cache.clear()  # Invalidate all cached paths


func is_blocked(pos: Vector2i) -> bool:
	return _blocked.has(pos)


func is_walkable(pos: Vector2i) -> bool:
	if pos.x < 0 or pos.x >= _width:
		return false
	if pos.y < 0 or pos.y >= _height:
		return false
	return not _blocked.has(pos)


func get_path(from: Vector2i) -> Array[Vector2i]:
	## Returns cached path or computes new one
	if _path_cache.has(from):
		return _path_cache[from]

	var path := _compute_path(from, _shrine_pos)
	_path_cache[from] = path
	return path


func has_valid_path(from: Vector2i) -> bool:
	var path := get_path(from)
	return not path.is_empty()


func invalidate_cache() -> void:
	_path_cache.clear()


func _compute_path(start: Vector2i, goal: Vector2i) -> Array[Vector2i]:
	## Standard A* implementation
	if not is_walkable(start):
		return []
	if start == goal:
		return [goal]

	var open_set: Array[Vector2i] = [start]
	var came_from: Dictionary = {}
	var g_score: Dictionary = {start: 0}
	var f_score: Dictionary = {start: _heuristic(start, goal)}

	while not open_set.is_empty():
		var current := _get_lowest_f(open_set, f_score)

		if current == goal:
			return _reconstruct_path(came_from, current)

		open_set.erase(current)

		for direction in DIRECTIONS:
			var neighbor: Vector2i = current + direction

			if not is_walkable(neighbor):
				continue

			var tentative_g: int = g_score[current] + 1

			if tentative_g < g_score.get(neighbor, 999999):
				came_from[neighbor] = current
				g_score[neighbor] = tentative_g
				f_score[neighbor] = tentative_g + _heuristic(neighbor, goal)

				if neighbor not in open_set:
					open_set.append(neighbor)

	# No path found
	return []


func _heuristic(a: Vector2i, b: Vector2i) -> int:
	## Manhattan distance
	return absi(a.x - b.x) + absi(a.y - b.y)


func _get_lowest_f(open_set: Array[Vector2i], f_score: Dictionary) -> Vector2i:
	var lowest: Vector2i = open_set[0]
	var lowest_f: int = f_score.get(lowest, 999999)

	for pos in open_set:
		var f: int = f_score.get(pos, 999999)
		if f < lowest_f:
			lowest_f = f
			lowest = pos

	return lowest


func _reconstruct_path(came_from: Dictionary, current: Vector2i) -> Array[Vector2i]:
	var path: Array[Vector2i] = [current]

	while came_from.has(current):
		current = came_from[current]
		path.push_front(current)

	return path


## Debug: Get all blocked positions
func get_all_blocked() -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for pos in _blocked.keys():
		result.append(pos)
	return result


## Get path length (for AI evaluation)
func get_path_length(from: Vector2i) -> int:
	var path := get_path(from)
	if path.is_empty():
		return -1  # No valid path
	return path.size()
