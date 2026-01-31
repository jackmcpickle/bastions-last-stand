class_name BalancedAI
extends AIPlayer

## Balanced AI strategy
## Places towers for coverage, upgrades highest-value towers, builds walls when needed

const WALL_COST := 10
const MIN_GOLD_RESERVE := 20  # Keep some gold for emergencies


func make_decisions(wave: int) -> void:
	## Called once per wave before wave starts

	# 1. Emergency: build walls if shrine HP low
	if game_state.shrine.hp < 30:
		_build_emergency_walls()

	# 2. Place new towers for coverage
	_place_towers_for_coverage()

	# 3. Upgrade existing towers
	_upgrade_towers()


func _build_emergency_walls() -> void:
	## Build walls near shrine when HP is low
	var shrine_pos := game_state.shrine.position
	var wall_positions := find_valid_wall_positions()

	# Sort by distance to shrine
	wall_positions.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		var da := (a - shrine_pos).length_squared()
		var db := (b - shrine_pos).length_squared()
		return da < db
	)

	# Build up to 3 walls
	var walls_built := 0
	for pos in wall_positions:
		if walls_built >= 3:
			break
		if game_state.can_place_wall(pos):
			game_state.place_wall(pos)
			walls_built += 1


func _place_towers_for_coverage() -> void:
	## Place towers to cover uncovered path sections
	var tower_priorities := ["archer", "cannon", "frost"]

	for tower_id in tower_priorities:
		var data := game_state.get_tower_data(tower_id)
		if not data:
			continue

		# Check if we can afford it
		if data.base_cost > game_state.gold - MIN_GOLD_RESERVE:
			continue

		# Check if there are uncovered path tiles
		var uncovered := find_uncovered_path_tiles()
		if uncovered.is_empty():
			continue

		# Find best position
		var pos := get_best_tower_position(tower_id)
		if pos.x < 0:
			continue

		# Check if this position covers any uncovered tiles
		var covers_uncovered := false
		var tower_center := Vector2(pos.x + 1.0, pos.y + 1.0)
		var range_sq := data.range_tiles * data.range_tiles

		for tile in uncovered:
			var tile_center := Vector2(tile.x + 0.5, tile.y + 0.5)
			var dx := tower_center.x - tile_center.x
			var dy := tower_center.y - tile_center.y
			if dx * dx + dy * dy <= range_sq:
				covers_uncovered = true
				break

		if covers_uncovered:
			game_state.place_tower(pos, tower_id)


func _upgrade_towers() -> void:
	## Upgrade towers with highest kill counts first
	var upgradeable := get_upgradeable_towers()
	if upgradeable.is_empty():
		return

	# Sort by kills (most valuable towers first)
	upgradeable.sort_custom(func(a: SimTower, b: SimTower) -> bool:
		return a.kills > b.kills
	)

	for tower in upgradeable:
		var upgrade := get_best_upgrade_for_tower(tower)
		if not upgrade:
			continue

		if game_state.can_upgrade_tower(tower, upgrade.id):
			game_state.upgrade_tower(tower, upgrade.id)
			# Only upgrade one tower per wave to spread gold
			break
