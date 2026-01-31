class_name Targeting
extends RefCounted

## Tower targeting system

enum Priority {
	FIRST,      # Furthest along path (default)
	LAST,       # Closest to spawn
	STRONGEST,  # Highest HP
	WEAKEST,    # Lowest HP
	CLOSEST,    # Nearest to tower
}


static func find_target(
	tower_pos: Vector2i,
	enemies: Array[SimEnemy],
	range_tiles: int,
	priority: Priority = Priority.FIRST
) -> SimEnemy:
	## Find best target from enemies in range
	var in_range := get_enemies_in_range(tower_pos, enemies, range_tiles)
	
	# Filter to targetable only
	in_range = in_range.filter(func(e): return e.is_targetable())
	
	if in_range.is_empty():
		return null
	
	match priority:
		Priority.FIRST:
			return _get_first(in_range)
		Priority.LAST:
			return _get_last(in_range)
		Priority.STRONGEST:
			return _get_strongest(in_range)
		Priority.WEAKEST:
			return _get_weakest(in_range)
		Priority.CLOSEST:
			return _get_closest(tower_pos, in_range)
	
	return in_range[0]


static func get_enemies_in_range(
	pos: Vector2i,
	enemies: Array[SimEnemy],
	range_tiles: int
) -> Array[SimEnemy]:
	var result: Array[SimEnemy] = []
	var range_sq := range_tiles * range_tiles
	
	for enemy in enemies:
		var dx := float(pos.x) - enemy.grid_pos.x
		var dy := float(pos.y) - enemy.grid_pos.y
		var dist_sq := dx * dx + dy * dy
		if dist_sq <= range_sq:
			result.append(enemy)
	
	return result


static func get_enemies_in_aoe(
	center: Vector2,
	enemies: Array[SimEnemy],
	radius: float
) -> Array[SimEnemy]:
	## For AOE attacks - center can be sub-tile position
	var result: Array[SimEnemy] = []
	var radius_sq := radius * radius
	
	for enemy in enemies:
		var dx := center.x - enemy.grid_pos.x
		var dy := center.y - enemy.grid_pos.y
		var dist_sq := dx * dx + dy * dy
		if dist_sq <= radius_sq:
			result.append(enemy)
	
	return result


static func _get_first(enemies: Array[SimEnemy]) -> SimEnemy:
	## Furthest along path
	var best: SimEnemy = enemies[0]
	for enemy in enemies:
		if enemy.path_progress > best.path_progress:
			best = enemy
	return best


static func _get_last(enemies: Array[SimEnemy]) -> SimEnemy:
	## Closest to spawn
	var best: SimEnemy = enemies[0]
	for enemy in enemies:
		if enemy.path_progress < best.path_progress:
			best = enemy
	return best


static func _get_strongest(enemies: Array[SimEnemy]) -> SimEnemy:
	var best: SimEnemy = enemies[0]
	for enemy in enemies:
		if enemy.hp > best.hp:
			best = enemy
	return best


static func _get_weakest(enemies: Array[SimEnemy]) -> SimEnemy:
	var best: SimEnemy = enemies[0]
	for enemy in enemies:
		if enemy.hp < best.hp:
			best = enemy
	return best


static func _get_closest(tower_pos: Vector2i, enemies: Array[SimEnemy]) -> SimEnemy:
	var best: SimEnemy = enemies[0]
	var best_dist := _distance_sq(tower_pos, best.grid_pos)
	
	for enemy in enemies:
		var dist := _distance_sq(tower_pos, enemy.grid_pos)
		if dist < best_dist:
			best_dist = dist
			best = enemy
	
	return best


static func _distance_sq(a: Vector2i, b: Vector2) -> float:
	var dx := float(a.x) - b.x
	var dy := float(a.y) - b.y
	return dx * dx + dy * dy
