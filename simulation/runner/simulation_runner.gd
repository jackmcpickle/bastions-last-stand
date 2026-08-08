class_name SimulationRunner
extends RefCounted

## Batch simulation runner for balance testing

signal simulation_started(index: int, total: int)
signal simulation_completed(index: int, result: TickProcessor.GameResult)
signal batch_completed(results: Array)

var _map_data: MapData
var _wave_data: WaveData
var _tower_registry: Dictionary = {}
var _enemy_registry: Dictionary = {}
var _wall_data: WallData
var _balance_config: BalanceConfig


func setup(map: MapData, waves: WaveData, config: BalanceConfig = null) -> void:
	_map_data = map
	_wave_data = waves
	_balance_config = config if config else BalanceConfig.new()


func register_tower(data: TowerData) -> void:
	_tower_registry[data.id] = data


func register_enemy(data: EnemyData) -> void:
	_enemy_registry[data.id] = data


func register_wall(data: WallData) -> void:
	_wall_data = data


func get_balance_config() -> BalanceConfig:
	return _balance_config


func _apply_config_to_tower(data: TowerData) -> TowerData:
	## Apply balance config overrides to tower data (base + upgrade costs)
	match data.id:
		"archer":
			data.base_cost = _balance_config.archer_cost
			data.damage = _balance_config.archer_damage
			data.attack_speed_ms = _balance_config.archer_attack_speed_ms
			data.range_tiles = _balance_config.archer_range
			data.upgrade_cost_t2 = _balance_config.archer_upgrade_t2
			data.upgrade_cost_t3 = _balance_config.archer_upgrade_t3
		"cannon":
			data.upgrade_cost_t2 = _balance_config.cannon_upgrade_t2
			data.upgrade_cost_t3 = _balance_config.cannon_upgrade_t3
		"frost":
			data.upgrade_cost_t2 = _balance_config.frost_upgrade_t2
			data.upgrade_cost_t3 = _balance_config.frost_upgrade_t3
		"lightning":
			data.upgrade_cost_t2 = _balance_config.lightning_upgrade_t2
			data.upgrade_cost_t3 = _balance_config.lightning_upgrade_t3
		"flame":
			data.upgrade_cost_t2 = _balance_config.flame_upgrade_t2
			data.upgrade_cost_t3 = _balance_config.flame_upgrade_t3
	return data


func _apply_config_to_enemy(data: EnemyData) -> EnemyData:
	## Apply balance config overrides to enemy data
	if data.id == "grunt":
		data.hp = _balance_config.grunt_hp
		data.speed = _balance_config.grunt_speed
		data.gold_value = _balance_config.grunt_gold
	elif data.id == "runner":
		data.hp = _balance_config.runner_hp
		data.speed = _balance_config.runner_speed
		data.gold_value = _balance_config.runner_gold
	return data


func run_single(
	seed: int,
	tower_placements: Array[Dictionary],
	wall_placements: Array[Vector2i] = [],
	tower_upgrades: Array = [],
	wall_upgrades: Array = []
) -> TickProcessor.GameResult:
	## Run a single simulation with placements and optional upgrade schedules
	## tower_placements: [{pos: Vector2i, id: String}, ...]
	## wall_placements: [Vector2i, ...]
	## tower_upgrades: [{pos: Vector2i, upgrade_id: String}, ...] applied in order
	## wall_upgrades: [{pos: Vector2i, upgrade_id: String}, ...]

	var game := GameState.new()

	# Register data with config overrides
	for id in _tower_registry:
		var data: TowerData = _tower_registry[id].duplicate(true)
		data = _apply_config_to_tower(data)
		game.register_tower_data(data)
	for id in _enemy_registry:
		var data: EnemyData = _enemy_registry[id].duplicate()
		data = _apply_config_to_enemy(data)
		game.register_enemy_data(data)
	if _wall_data:
		game.register_wall_data(_wall_data.duplicate(true))

	# Initialize with config
	game.initialize_with_config(_map_data, _wave_data, _balance_config, seed)

	# Place walls first (affects pathfinding)
	for pos in wall_placements:
		game.place_wall(pos)

	# Then place towers
	for placement in tower_placements:
		game.place_tower(placement.pos, placement.id)

	# Apply scheduled upgrades (grant gold so schedules are deterministic)
	_apply_scheduled_upgrades(game, tower_upgrades, wall_upgrades)

	# Run simulation
	var processor := TickProcessor.new(game)
	return processor.run_all_waves()


func _apply_scheduled_upgrades(
	game: GameState, tower_upgrades: Array, wall_upgrades: Array
) -> void:
	## Apply pre-wave loadout upgrades without distorting run economy
	if tower_upgrades.is_empty() and wall_upgrades.is_empty():
		return

	var saved_gold := game.gold
	var saved_spent := game.total_gold_spent
	game.gold = 10000

	for entry in tower_upgrades:
		var pos: Vector2i = entry.pos
		var upgrade_id: String = entry.upgrade_id
		var tower := _find_tower_at(game, pos)
		if not tower:
			push_warning("Upgrade schedule: no tower at %s" % str(pos))
			continue
		if not game.upgrade_tower(tower, upgrade_id):
			push_warning("Upgrade schedule failed: %s at %s" % [upgrade_id, str(pos)])

	for entry in wall_upgrades:
		var pos: Vector2i = entry.pos
		var upgrade_id: String = entry.upgrade_id
		var wall := _find_wall_at(game, pos)
		if not wall:
			push_warning("Upgrade schedule: no wall at %s" % str(pos))
			continue
		if not game.upgrade_wall(wall, upgrade_id):
			push_warning("Wall upgrade schedule failed: %s at %s" % [upgrade_id, str(pos)])

	# Restore starting gold / spend so metrics reflect the run, not the schedule
	game.gold = saved_gold
	game.total_gold_spent = saved_spent


func _find_tower_at(game: GameState, pos: Vector2i) -> SimTower:
	for tower in game.towers:
		if tower.position == pos:
			return tower
	return null


func _find_wall_at(game: GameState, pos: Vector2i) -> SimWall:
	for wall in game.walls:
		if wall.position == pos:
			return wall
	return null


func run_batch(
	count: int,
	base_seed: int,
	tower_placements: Array[Dictionary],
	wall_placements: Array[Vector2i] = [],
	tower_upgrades: Array = [],
	wall_upgrades: Array = []
) -> Array[TickProcessor.GameResult]:
	## Run multiple simulations

	var results: Array[TickProcessor.GameResult] = []

	for i in range(count):
		simulation_started.emit(i, count)

		var seed := base_seed + i
		var result := run_single(
			seed, tower_placements, wall_placements, tower_upgrades, wall_upgrades
		)
		results.append(result)

		simulation_completed.emit(i, result)

	batch_completed.emit(results)
	return results


func run_batch_with_ai(
	count: int, base_seed: int, ai_strategy: Callable  # func(game: GameState, wave: int) -> void
) -> Array[TickProcessor.GameResult]:
	## Run simulations where AI places towers between waves

	var results: Array[TickProcessor.GameResult] = []

	for i in range(count):
		simulation_started.emit(i, count)

		var seed := base_seed + i
		var result := _run_with_ai(seed, ai_strategy)
		results.append(result)

		simulation_completed.emit(i, result)

	batch_completed.emit(results)
	return results


func _run_with_ai(seed: int, ai_strategy: Callable) -> TickProcessor.GameResult:
	var game := GameState.new()

	# Register data with same config overrides as run_single
	for id in _tower_registry:
		var data: TowerData = _tower_registry[id].duplicate(true)
		data = _apply_config_to_tower(data)
		game.register_tower_data(data)
	for id in _enemy_registry:
		var data: EnemyData = _enemy_registry[id].duplicate()
		data = _apply_config_to_enemy(data)
		game.register_enemy_data(data)
	if _wall_data:
		game.register_wall_data(_wall_data.duplicate(true))

	game.initialize_with_config(_map_data, _wave_data, _balance_config, seed)

	var processor := TickProcessor.new(game)
	var result := TickProcessor.GameResult.new()
	result.start_time = Time.get_ticks_msec()

	var total_waves := _wave_data.get_total_waves()

	for wave_num in range(1, total_waves + 1):
		# Let AI make decisions before wave
		ai_strategy.call(game, wave_num)

		# Run wave
		var wave_result := processor.run_wave(wave_num)
		result.wave_results.append(wave_result)

		if not wave_result.success:
			result.won = false
			result.final_wave = wave_num
			break

		result.final_wave = wave_num

	if result.final_wave >= total_waves and game.shrine.hp > 0:
		result.won = true

	result.end_time = Time.get_ticks_msec()
	result.final_shrine_hp = game.shrine.hp
	result.final_gold = game.gold
	result.total_gold_earned = game.total_gold_earned
	result.total_gold_spent = game.total_gold_spent
	result.enemies_killed = game.enemies_killed
	result.enemies_leaked = game.enemies_leaked
	result.total_damage_dealt = game.total_damage_dealt

	TickProcessor._fill_result_loadout(result, game)

	return result


## Analysis helpers


static func analyze_results(results: Array[TickProcessor.GameResult]) -> Dictionary:
	if results.is_empty():
		return {}

	var wins := 0
	var total_waves := 0
	var total_shrine_hp := 0
	var total_gold := 0
	var total_duration := 0
	var total_killed := 0
	var total_leaked := 0
	var tower_damage: Dictionary = {}
	var tower_kills: Dictionary = {}
	var upgrade_path_counts: Dictionary = {}

	for result in results:
		if result.won:
			wins += 1
		total_waves += result.final_wave
		total_shrine_hp += result.final_shrine_hp
		total_gold += result.final_gold
		total_duration += result.get_duration_ms()
		total_killed += result.enemies_killed
		total_leaked += result.enemies_leaked

		for tower_key in result.tower_stats:
			var stats: Dictionary = result.tower_stats[tower_key]
			var tower_id: String = str(stats.get("id", tower_key))
			tower_damage[tower_id] = tower_damage.get(tower_id, 0) + stats.damage
			tower_kills[tower_id] = tower_kills.get(tower_id, 0) + stats.kills

		for entry in result.upgrade_loadout:
			var path_key := "%s:T%d%s" % [entry.id, entry.tier, entry.branch]
			upgrade_path_counts[path_key] = upgrade_path_counts.get(path_key, 0) + 1

	var count := results.size()

	return {
		"total_simulations": count,
		"wins": wins,
		"losses": count - wins,
		"win_rate": float(wins) / count,
		"avg_final_wave": float(total_waves) / count,
		"avg_shrine_hp": float(total_shrine_hp) / count,
		"avg_gold": float(total_gold) / count,
		"avg_duration_ms": float(total_duration) / count,
		"avg_killed": float(total_killed) / count,
		"avg_leaked": float(total_leaked) / count,
		"tower_total_damage": tower_damage,
		"tower_total_kills": tower_kills,
		"upgrade_path_counts": upgrade_path_counts,
	}


static func print_analysis(analysis: Dictionary) -> void:
	print("=== SIMULATION ANALYSIS ===")
	print(
		(
			"Total: %d | Wins: %d | Losses: %d"
			% [analysis.total_simulations, analysis.wins, analysis.losses]
		)
	)
	print("Win Rate: %.1f%%" % [analysis.win_rate * 100])
	print(
		(
			"Avg Wave: %.1f | Avg HP: %.1f | Avg Gold: %.1f"
			% [analysis.avg_final_wave, analysis.avg_shrine_hp, analysis.avg_gold]
		)
	)
	print("Avg Duration: %.0fms" % analysis.avg_duration_ms)
	print("Tower Damage: %s" % str(analysis.tower_total_damage))
	print("Tower Kills: %s" % str(analysis.tower_total_kills))
	print("===========================")
