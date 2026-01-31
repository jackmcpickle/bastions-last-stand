extends Node

## Main entry point for headless simulation
## Run with: godot --headless -- [options]

# Preload all required classes
const TowerData = preload("res://resources/tower_data.gd")
const EnemyData = preload("res://resources/enemy_data.gd")
const WaveData = preload("res://resources/wave_data.gd")
const MapData = preload("res://resources/map_data.gd")
const TestMap = preload("res://maps/test_map.gd")
const Waves1To10 = preload("res://resources/waves/waves_1_10.gd")
const SimulationRunner = preload("res://simulation/runner/simulation_runner.gd")
const SimulationResults = preload("res://simulation/runner/simulation_results.gd")
const GameState = preload("res://simulation/core/game_state.gd")
const BalanceConfig = preload("res://simulation/core/balance_config.gd")

## Strategy definitions
## Each strategy has towers and walls
## Map is 10x10, spawns at (2,0) and (7,0), shrine at (4,4)

func _get_strategy_a() -> Dictionary:
	## Strategy A: Dual Tower - 2 towers covering both spawn paths
	## Cost: 160g towers = need 160+ starting gold
	return {
		"name": "DualTower",
		"description": "Two towers covering spawn paths",
		"towers": [
			{pos = Vector2i(3, 2), id = "archer"},
			{pos = Vector2i(6, 2), id = "archer"}
		],
		"walls": [] as Array[Vector2i]
	}

func _get_strategy_b() -> Dictionary:
	## Strategy B: Triple Tower - 3 towers in killing zone
	## Cost: 240g towers = need 240+ starting gold OR good economy
	return {
		"name": "TripleTower",
		"description": "Three towers near shrine",
		"towers": [
			{pos = Vector2i(3, 3), id = "archer"},
			{pos = Vector2i(4, 2), id = "archer"},
			{pos = Vector2i(6, 3), id = "archer"}
		],
		"walls": [] as Array[Vector2i]
	}

func _get_strategy_c() -> Dictionary:
	## Strategy C: Flanking - towers on sides covering paths
	## No walls, just good tower positioning
	return {
		"name": "Flanking",
		"description": "Towers on flanks covering spawn paths",
		"towers": [
			{pos = Vector2i(1, 2), id = "archer"},
			{pos = Vector2i(8, 2), id = "archer"}
		],
		"walls": [] as Array[Vector2i]
	}

func _get_strategy_d() -> Dictionary:
	## Strategy D: Central Defense - towers clustered near shrine
	## Concentrated firepower at the end
	return {
		"name": "CentralDefense",
		"description": "Towers clustered defending shrine",
		"towers": [
			{pos = Vector2i(3, 4), id = "archer"},
			{pos = Vector2i(6, 4), id = "archer"}
		],
		"walls": [] as Array[Vector2i]
	}


func _ready() -> void:
	var is_headless := DisplayServer.get_name() == "headless"
	
	if not is_headless:
		print("Bastion's Last Stand - Simulation Engine")
		print("Run with: godot --headless -- [options]")
		return
	
	var args := OS.get_cmdline_user_args()
	
	if "--help" in args or "-h" in args:
		_print_help()
		get_tree().quit()
		return
	
	_run_simulation(args)
	get_tree().quit()


func _print_help() -> void:
	print("""
Bastion's Last Stand - Headless Simulation Engine

Usage:
  godot --headless -- [options]

Options:
  --help, -h           Show this help
  --count N            Simulations per strategy (default: 100)
  --seed N             Base random seed (default: 12345)
  --strategy S         Strategy to run: a, b, c, d, or all (default: all)
  --json               Output results as JSON (for AI optimizer)
  --config FILE        Load balance config from JSON file
  --save-config FILE   Save current config to JSON file
  --output FILE        Save results to file

Strategies:
  a - Baseline: No walls, center tower
  b - Funnel: Walls create chokepoint
  c - Zigzag: Wall line extends path
  d - PathExtension: Vertical walls block direct path

Examples:
  godot --headless -- --strategy all --count 1000 --json
  godot --headless -- --config balance.json --json
  godot --headless -- --save-config default_config.json
""")


func _run_simulation(args: Array) -> void:
	# Parse arguments
	var count := 100
	var base_seed := 12345
	var strategy_arg := "all"
	var json_output := false
	var config_file := ""
	var save_config_file := ""
	var output_file := ""
	
	for i in range(args.size()):
		match args[i]:
			"--count":
				if i + 1 < args.size():
					count = int(args[i + 1])
			"--seed":
				if i + 1 < args.size():
					base_seed = int(args[i + 1])
			"--strategy":
				if i + 1 < args.size():
					strategy_arg = args[i + 1].to_lower()
			"--json":
				json_output = true
			"--config":
				if i + 1 < args.size():
					config_file = args[i + 1]
			"--save-config":
				if i + 1 < args.size():
					save_config_file = args[i + 1]
			"--output":
				if i + 1 < args.size():
					output_file = args[i + 1]
	
	# Load or create balance config
	var config := BalanceConfig.new()
	if config_file != "":
		var err := config.load_from_file(config_file)
		if err != OK:
			push_error("Failed to load config: " + config_file)
			return
	
	# Save config if requested
	if save_config_file != "":
		var err := config.save_to_file(save_config_file)
		if err == OK:
			if not json_output:
				print("Config saved to: " + save_config_file)
		else:
			push_error("Failed to save config: " + save_config_file)
		if config_file == "" and strategy_arg == "all" and count == 100:
			# Just saving config, no simulation
			return
	
	# Load base data (will be overridden by config)
	var map := TestMap.create()
	var waves := Waves1To10.create()

	# Load all tower data
	var archer_data: TowerData = load("res://resources/towers/archer_tower.tres")
	var cannon_data: TowerData = load("res://resources/towers/cannon_tower.tres")
	var frost_data: TowerData = load("res://resources/towers/frost_tower.tres")
	var lightning_data: TowerData = load("res://resources/towers/lightning_tower.tres")
	var flame_data: TowerData = load("res://resources/towers/flame_tower.tres")

	# Load all enemy data
	var grunt_data: EnemyData = load("res://resources/enemies/grunt.tres")
	var runner_data: EnemyData = load("res://resources/enemies/runner.tres")
	var tank_data: EnemyData = load("res://resources/enemies/tank.tres")
	var flyer_data: EnemyData = load("res://resources/enemies/flyer.tres")
	var swarm_data: EnemyData = load("res://resources/enemies/swarm.tres")
	var stealth_data: EnemyData = load("res://resources/enemies/stealth.tres")
	var breaker_data: EnemyData = load("res://resources/enemies/breaker.tres")
	var boss_golem_data: EnemyData = load("res://resources/enemies/boss_golem.tres")

	# Setup runner with config
	var runner := SimulationRunner.new()
	runner.setup(map, waves, config)

	# Register all towers
	runner.register_tower(archer_data)
	runner.register_tower(cannon_data)
	runner.register_tower(frost_data)
	runner.register_tower(lightning_data)
	runner.register_tower(flame_data)

	# Register all enemies
	runner.register_enemy(grunt_data)
	runner.register_enemy(runner_data)
	runner.register_enemy(tank_data)
	runner.register_enemy(flyer_data)
	runner.register_enemy(swarm_data)
	runner.register_enemy(stealth_data)
	runner.register_enemy(breaker_data)
	runner.register_enemy(boss_golem_data)
	
	# Determine which strategies to run
	var strategies_to_run: Array[String] = []
	if strategy_arg == "all":
		strategies_to_run = ["a", "b", "c", "d"]
	else:
		strategies_to_run = [strategy_arg]
	
	# Collect results
	var all_results := {}
	var start_time := Time.get_ticks_msec()
	
	if not json_output:
		print("=================================")
		print("BASTION'S LAST STAND")
		print("Simulation Engine")
		print("=================================")
		print("")
		print("Config:")
		print("  Starting gold: %d" % config.starting_gold)
		print("  Wall cost: %d" % config.wall_cost)
		print("  Archer: %dg, %d dmg, %dms, %d range" % [
			config.archer_cost, config.archer_damage / 1000,
			config.archer_attack_speed_ms, config.archer_range
		])
		print("  Grunt: %d HP, %d speed, %dg" % [
			config.grunt_hp, config.grunt_speed, config.grunt_gold
		])
		print("  Runner: %d HP, %d speed, %dg" % [
			config.runner_hp, config.runner_speed, config.runner_gold
		])
		print("  Shrine: %d HP" % config.shrine_hp)
		print("")
		print("Running %d simulations per strategy..." % count)
		print("")
	
	for strat_id in strategies_to_run:
		var strategy: Dictionary
		match strat_id:
			"a": strategy = _get_strategy_a()
			"b": strategy = _get_strategy_b()
			"c": strategy = _get_strategy_c()
			"d": strategy = _get_strategy_d()
			_:
				push_error("Unknown strategy: " + strat_id)
				continue
		
		var towers: Array[Dictionary] = []
		for t in strategy.towers:
			towers.append(t)
		
		var walls: Array[Vector2i] = []
		for w in strategy.walls:
			walls.append(w)
		
		var results := runner.run_batch(count, base_seed, towers, walls)
		var analysis := SimulationRunner.analyze_results(results)
		
		all_results[strat_id] = {
			"name": strategy.name,
			"description": strategy.description,
			"runs": count,
			"wins": analysis.wins,
			"win_rate": analysis.win_rate,
			"avg_shrine_hp": analysis.avg_shrine_hp,
			"avg_gold": analysis.avg_gold,
			"avg_killed": analysis.avg_killed,
			"avg_leaked": analysis.avg_leaked,
			"avg_duration_ms": analysis.avg_duration_ms,
		}
		
		if not json_output:
			print("Strategy %s (%s):" % [strat_id.to_upper(), strategy.name])
			print("  Win rate: %.1f%%" % [analysis.win_rate * 100])
			print("  Avg shrine HP: %.1f" % analysis.avg_shrine_hp)
			print("  Avg gold: %.1f" % analysis.avg_gold)
			print("  Avg killed/leaked: %.0f / %.0f" % [analysis.avg_killed, analysis.avg_leaked])
			print("")
	
	var end_time := Time.get_ticks_msec()
	
	# Find best strategy
	var best_strategy := ""
	var best_win_rate := -1.0
	for strat_id in all_results:
		if all_results[strat_id].win_rate > best_win_rate:
			best_win_rate = all_results[strat_id].win_rate
			best_strategy = strat_id
	
	# Output results
	if json_output:
		var output := {
			"config": config.to_dict(),
			"strategies": all_results,
			"best_strategy": best_strategy,
			"total_duration_ms": end_time - start_time,
			"timestamp": Time.get_datetime_string_from_system(),
			"parameter_bounds": BalanceConfig.get_parameter_bounds(),
		}
		print(JSON.stringify(output))
	else:
		print("=================================")
		print("Completed in %dms" % (end_time - start_time))
		print("Best strategy: %s (%.1f%% win rate)" % [best_strategy.to_upper(), best_win_rate * 100])
		print("=================================")
	
	# Save to file if requested
	if output_file != "":
		var file := FileAccess.open(output_file, FileAccess.WRITE)
		if file:
			var output := {
				"config": config.to_dict(),
				"strategies": all_results,
				"best_strategy": best_strategy,
			}
			file.store_string(JSON.stringify(output, "  "))
			file.close()
			if not json_output:
				print("Results saved to: %s" % output_file)
