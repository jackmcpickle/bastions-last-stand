class_name AIPlayer
extends RefCounted

## Base AI player class for automated balance testing
## Subclasses implement different strategies

var game_state: GameState


func _init(p_game_state: GameState) -> void:
	game_state = p_game_state


func make_decisions(wave: int) -> void:
	## Override in subclasses to implement strategy
	pass


## Helper methods for subclasses


func find_valid_tower_positions(tower_id: String) -> Array[Vector2i]:
	## Returns all valid positions for a tower
	var result: Array[Vector2i] = []
	var map := game_state.map_data

	# Scan entire map for valid positions (towers are 2x2)
	for x in range(map.width - 1):
		for y in range(map.height - 1):
			var pos := Vector2i(x, y)
			if game_state.can_place_tower(pos, tower_id):
				result.append(pos)

	return result


func find_valid_wall_positions() -> Array[Vector2i]:
	## Returns all valid positions for walls
	var result: Array[Vector2i] = []
	var map := game_state.map_data

	for x in range(map.width):
		for y in range(map.height):
			var pos := Vector2i(x, y)
			if game_state.can_place_wall(pos):
				result.append(pos)

	return result


func get_path_tiles() -> Array[Vector2i]:
	## Returns tiles on the enemy path
	var result: Array[Vector2i] = []
	var spawn_points := game_state.map_data.spawn_points

	if spawn_points.is_empty():
		return result

	# Get path from first spawn point
	var path := game_state.pathfinding.get_path(spawn_points[0])
	for tile in path:
		if tile not in result:
			result.append(tile)

	return result


func get_path_coverage(pos: Vector2i, tower_range: int) -> float:
	## Returns how many path tiles are in range of this position
	var tower_center := Vector2(pos.x + 1.0, pos.y + 1.0)
	var path_tiles := get_path_tiles()
	var range_sq := tower_range * tower_range
	var covered := 0

	for tile in path_tiles:
		var tile_center := Vector2(tile.x + 0.5, tile.y + 0.5)
		var dx := tower_center.x - tile_center.x
		var dy := tower_center.y - tile_center.y
		var dist_sq := dx * dx + dy * dy
		if dist_sq <= range_sq:
			covered += 1

	return float(covered)


func find_uncovered_path_tiles(min_range: int = 3) -> Array[Vector2i]:
	## Returns path tiles not covered by any tower
	var path_tiles := get_path_tiles()
	var uncovered: Array[Vector2i] = []

	for tile in path_tiles:
		var covered := false
		for tower in game_state.towers:
			var tower_center := tower.get_center()
			var tile_center := Vector2(tile.x + 0.5, tile.y + 0.5)
			var dist := (tower_center - tile_center).length()
			if dist <= tower.range_tiles:
				covered = true
				break

		if not covered:
			uncovered.append(tile)

	return uncovered


func get_best_tower_position(tower_id: String) -> Vector2i:
	## Returns position with best path coverage
	var valid := find_valid_tower_positions(tower_id)
	if valid.is_empty():
		return Vector2i(-1, -1)

	var tower_data := game_state.get_tower_data(tower_id)
	if not tower_data:
		return Vector2i(-1, -1)

	var best_pos := valid[0]
	var best_score := -1.0

	for pos in valid:
		var coverage := get_path_coverage(pos, tower_data.range_tiles)

		# Bonus for covering uncovered tiles
		var uncovered := find_uncovered_path_tiles()
		var uncovered_bonus := 0.0
		var tower_center := Vector2(pos.x + 1.0, pos.y + 1.0)
		var range_sq := tower_data.range_tiles * tower_data.range_tiles

		for tile in uncovered:
			var tile_center := Vector2(tile.x + 0.5, tile.y + 0.5)
			var dx := tower_center.x - tile_center.x
			var dy := tower_center.y - tile_center.y
			if dx * dx + dy * dy <= range_sq:
				uncovered_bonus += 2.0

		var score := coverage + uncovered_bonus

		if score > best_score:
			best_score = score
			best_pos = pos

	return best_pos


func get_upgradeable_towers() -> Array[SimTower]:
	## Returns towers that can be upgraded
	var result: Array[SimTower] = []
	for tower in game_state.towers:
		var upgrades := tower.get_available_upgrades()
		if not upgrades.is_empty():
			result.append(tower)
	return result


func get_best_upgrade_for_tower(tower: SimTower) -> TowerUpgradeData:
	## Returns best upgrade for tower (by damage increase)
	var upgrades := tower.get_available_upgrades()
	if upgrades.is_empty():
		return null

	# For simplicity, pick first available upgrade
	# More sophisticated AI could evaluate upgrade value
	return upgrades[0]
