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


func setup(map: MapData, waves: WaveData) -> void:
	_map_data = map
	_wave_data = waves


func register_tower(data: TowerData) -> void:
	_tower_registry[data.id] = data


func register_enemy(data: EnemyData) -> void:
	_enemy_registry[data.id] = data


func run_single(seed: int, tower_placements: Array[Dictionary]) -> TickProcessor.GameResult:
	## Run a single simulation with specified tower placements
	## tower_placements: [{pos: Vector2i, id: String}, ...]
	
	var game := GameState.new()
	
	# Register data
	for id in _tower_registry:
		game.register_tower_data(_tower_registry[id])
	for id in _enemy_registry:
		game.register_enemy_data(_enemy_registry[id])
	
	# Initialize
	game.initialize(_map_data, _wave_data, seed)
	
	# Place towers
	for placement in tower_placements:
		game.place_tower(placement.pos, placement.id)
	
	# Run simulation
	var processor := TickProcessor.new(game)
	return processor.run_all_waves()


func run_batch(
	count: int,
	base_seed: int,
	tower_placements: Array[Dictionary]
) -> Array[TickProcessor.GameResult]:
	## Run multiple simulations
	
	var results: Array[TickProcessor.GameResult] = []
	
	for i in range(count):
		simulation_started.emit(i, count)
		
		var seed := base_seed + i
		var result := run_single(seed, tower_placements)
		results.append(result)
		
		simulation_completed.emit(i, result)
	
	batch_completed.emit(results)
	return results


func run_batch_with_ai(
	count: int,
	base_seed: int,
	ai_strategy: Callable  # func(game: GameState, wave: int) -> void
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
	
	# Register data
	for id in _tower_registry:
		game.register_tower_data(_tower_registry[id])
	for id in _enemy_registry:
		game.register_enemy_data(_enemy_registry[id])
	
	# Initialize
	game.initialize(_map_data, _wave_data, seed)
	
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
	
	for tower in game.towers:
		result.tower_stats[tower.id] = {
			"damage": tower.total_damage_dealt,
			"kills": tower.kills,
			"shots": tower.shots_fired
		}
	
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
	var tower_damage: Dictionary = {}
	var tower_kills: Dictionary = {}
	
	for result in results:
		if result.won:
			wins += 1
		total_waves += result.final_wave
		total_shrine_hp += result.final_shrine_hp
		total_gold += result.final_gold
		total_duration += result.get_duration_ms()
		
		for tower_id in result.tower_stats:
			var stats: Dictionary = result.tower_stats[tower_id]
			tower_damage[tower_id] = tower_damage.get(tower_id, 0) + stats.damage
			tower_kills[tower_id] = tower_kills.get(tower_id, 0) + stats.kills
	
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
		"tower_total_damage": tower_damage,
		"tower_total_kills": tower_kills,
	}


static func print_analysis(analysis: Dictionary) -> void:
	print("=== SIMULATION ANALYSIS ===")
	print("Total: %d | Wins: %d | Losses: %d" % [
		analysis.total_simulations,
		analysis.wins,
		analysis.losses
	])
	print("Win Rate: %.1f%%" % [analysis.win_rate * 100])
	print("Avg Wave: %.1f | Avg HP: %.1f | Avg Gold: %.1f" % [
		analysis.avg_final_wave,
		analysis.avg_shrine_hp,
		analysis.avg_gold
	])
	print("Avg Duration: %.0fms" % analysis.avg_duration_ms)
	print("Tower Damage: %s" % str(analysis.tower_total_damage))
	print("Tower Kills: %s" % str(analysis.tower_total_kills))
	print("===========================")
