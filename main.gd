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
## Map is 10x10, spawns at (2,0) and (7,0), shrine at (4,4)
## Optional tower_upgrades / wall_upgrades: [{pos, upgrade_id}, ...]


func _tower_path_strategy(
	name: String, description: String, tower_id: String, pos: Vector2i, t2_id: String, t3_id: String
) -> Dictionary:
	return {
		"name": name,
		"description": description,
		"towers": [{pos = pos, id = tower_id}],
		"walls": [] as Array[Vector2i],
		"tower_upgrades": [{pos = pos, upgrade_id = t2_id}, {pos = pos, upgrade_id = t3_id}],
		"wall_upgrades": [],
	}


func _get_all_strategies() -> Dictionary:
	## id -> strategy dict (baselines + upgrade matrix)
	var strategies := {
		"a":
		{
			"name": "DualTower",
			"description": "Two T1 archers covering spawn paths",
			"towers":
			[{pos = Vector2i(3, 2), id = "archer"}, {pos = Vector2i(6, 2), id = "archer"}],
			"walls": [] as Array[Vector2i],
			"tower_upgrades": [],
			"wall_upgrades": [],
		},
		"b":
		{
			"name": "TripleTower",
			"description": "Three T1 archers near shrine",
			"towers":
			[
				{pos = Vector2i(3, 3), id = "archer"},
				{pos = Vector2i(4, 2), id = "archer"},
				{pos = Vector2i(6, 3), id = "archer"}
			],
			"walls": [] as Array[Vector2i],
			"tower_upgrades": [],
			"wall_upgrades": [],
		},
		"c":
		{
			"name": "Flanking",
			"description": "T1 archers on flanks",
			"towers":
			[{pos = Vector2i(1, 2), id = "archer"}, {pos = Vector2i(8, 2), id = "archer"}],
			"walls": [] as Array[Vector2i],
			"tower_upgrades": [],
			"wall_upgrades": [],
		},
		"d":
		{
			"name": "CentralDefense",
			"description": "T1 archers clustered at shrine",
			"towers":
			[{pos = Vector2i(3, 4), id = "archer"}, {pos = Vector2i(6, 4), id = "archer"}],
			"walls": [] as Array[Vector2i],
			"tower_upgrades": [],
			"wall_upgrades": [],
		},
	}

	# Upgrade matrix: one A-final and one B-final per combat tower
	var pos := Vector2i(4, 2)
	strategies["archer_sniper"] = _tower_path_strategy(
		"ArcherSniper", "Archer Marksman→Sniper", "archer", pos, "archer_marksman", "archer_sniper"
	)
	strategies["archer_machine"] = _tower_path_strategy(
		"ArcherMachine",
		"Archer Rapid→Machine Bow",
		"archer",
		pos,
		"archer_rapid_fire",
		"archer_machine_bow"
	)
	strategies["cannon_siege"] = _tower_path_strategy(
		"CannonSiege", "Cannon Mortar→Siege", "cannon", pos, "cannon_mortar", "cannon_siege"
	)
	strategies["cannon_railgun"] = _tower_path_strategy(
		"CannonRailgun",
		"Cannon Artillery→Railgun",
		"cannon",
		pos,
		"cannon_artillery",
		"cannon_railgun"
	)
	strategies["frost_permafrost"] = _tower_path_strategy(
		"FrostPermafrost",
		"Frost Blizzard→Permafrost",
		"frost",
		pos,
		"frost_blizzard",
		"frost_permafrost"
	)
	strategies["frost_cryo"] = _tower_path_strategy(
		"FrostCryo",
		"Frost Ice Shard→Cryo Cannon",
		"frost",
		pos,
		"frost_ice_shard",
		"frost_cryo_cannon"
	)
	strategies["lightning_storm"] = _tower_path_strategy(
		"LightningStorm",
		"Lightning Tesla→Storm Spire",
		"lightning",
		pos,
		"lightning_tesla",
		"lightning_storm_spire"
	)
	strategies["lightning_disruptor"] = _tower_path_strategy(
		"LightningDisruptor",
		"Lightning Arc→Disruptor",
		"lightning",
		pos,
		"lightning_arc_pylon",
		"lightning_disruptor"
	)
	strategies["flame_hellfire"] = _tower_path_strategy(
		"FlameHellfire", "Flame Inferno→Hellfire", "flame", pos, "flame_inferno", "flame_hellfire"
	)
	strategies["flame_plasma"] = _tower_path_strategy(
		"FlamePlasma", "Flame Focused→Plasma", "flame", pos, "flame_focused", "flame_plasma"
	)

	# Wall upgrade paths (with a supporting T1 archer)
	var wall_pos := Vector2i(4, 3)
	var archer_pos := Vector2i(5, 2)
	strategies["wall_fortress"] = {
		"name": "WallFortress",
		"description": "Wall Reinforced→Fortress + T1 archer",
		"towers": [{pos = archer_pos, id = "archer"}],
		"walls": [wall_pos] as Array[Vector2i],
		"tower_upgrades": [],
		"wall_upgrades":
		[
			{pos = wall_pos, upgrade_id = "wall_reinforced"},
			{pos = wall_pos, upgrade_id = "wall_fortress"}
		],
	}
	strategies["wall_tar"] = {
		"name": "WallTar",
		"description": "Wall Reactive→Tar + T1 archer",
		"towers": [{pos = archer_pos, id = "archer"}],
		"walls": [wall_pos] as Array[Vector2i],
		"tower_upgrades": [],
		"wall_upgrades":
		[{pos = wall_pos, upgrade_id = "wall_reactive"}, {pos = wall_pos, upgrade_id = "wall_tar"}],
	}

	return strategies


func _get_upgrade_strategy_ids() -> Array[String]:
	return [
		"archer_sniper",
		"archer_machine",
		"cannon_siege",
		"cannon_railgun",
		"frost_permafrost",
		"frost_cryo",
		"lightning_storm",
		"lightning_disruptor",
		"flame_hellfire",
		"flame_plasma",
		"wall_fortress",
		"wall_tar",
	]


func _ready() -> void:
	var is_headless := DisplayServer.get_name() == "headless"

	if not is_headless:
		# Visual mode - load splash screen (deferred to avoid node removal during _ready)
		get_tree().change_scene_to_file.call_deferred("res://ui/screens/splash_screen.tscn")
		return

	var args := OS.get_cmdline_user_args()

	if "--help" in args or "-h" in args:
		_print_help()
		get_tree().quit()
		return

	_run_simulation(args)
	get_tree().quit()


func _print_help() -> void:
	print(
		"""
Bastion's Last Stand - Headless Simulation Engine

Usage:
  godot --headless -- [options]

Options:
  --help, -h           Show this help
  --count N            Simulations per strategy (default: 100)
  --seed N             Base random seed (default: 12345)
  --strategy S         Strategy: a-d, upgrades, all, or a named upgrade path
  --ai balanced        Run BalancedAI instead of static strategies
  --json               Output results as JSON (for AI optimizer)
  --config FILE        Load balance config from JSON file
  --save-config FILE   Save current config to JSON file
  --output FILE        Save results to file

Strategies:
  a-d       T1 archer baselines (Dual/Triple/Flanking/Central)
  upgrades  Upgrade matrix (each tower A/B final + wall Fortress/Tar)
  all       Baselines + upgrade matrix
  Named     e.g. archer_sniper, cannon_siege, wall_fortress, ...

Examples:
  godot --headless -- --strategy upgrades --count 50 --json
  godot --headless -- --ai balanced --count 100 --json
  godot --headless -- --config balance.json --strategy all --json
"""
	)


func _run_simulation(args: Array) -> void:
	# Parse arguments
	var count := 100
	var base_seed := 12345
	var strategy_arg := "all"
	var json_output := false
	var config_file := ""
	var save_config_file := ""
	var output_file := ""
	var ai_mode := ""

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
			"--ai":
				if i + 1 < args.size():
					ai_mode = args[i + 1].to_lower()
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
	var wall_data: WallData = load("res://resources/walls/basic_wall.tres")

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
	runner.register_wall(wall_data)

	# Register all enemies
	runner.register_enemy(grunt_data)
	runner.register_enemy(runner_data)
	runner.register_enemy(tank_data)
	runner.register_enemy(flyer_data)
	runner.register_enemy(swarm_data)
	runner.register_enemy(stealth_data)
	runner.register_enemy(breaker_data)
	runner.register_enemy(boss_golem_data)

	var all_strategies := _get_all_strategies()
	var strategies_to_run: Array[String] = []
	if ai_mode == "":
		if strategy_arg == "all":
			strategies_to_run = ["a", "b", "c", "d"]
			strategies_to_run.append_array(_get_upgrade_strategy_ids())
		elif strategy_arg == "upgrades":
			strategies_to_run = _get_upgrade_strategy_ids()
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
		print(
			(
				"  Archer: %dg, %d dmg, %dms, %d range"
				% [
					config.archer_cost,
					config.archer_damage / 1000,
					config.archer_attack_speed_ms,
					config.archer_range
				]
			)
		)
		print(
			(
				"  Grunt: %d HP, %d speed, %dg"
				% [config.grunt_hp, config.grunt_speed, config.grunt_gold]
			)
		)
		print(
			(
				"  Runner: %d HP, %d speed, %dg"
				% [config.runner_hp, config.runner_speed, config.runner_gold]
			)
		)
		print("  Shrine: %d HP" % config.shrine_hp)
		if ai_mode != "":
			print("  AI mode: %s" % ai_mode)
		print("")
		print("Running %d simulations per strategy..." % count)
		print("")

	if ai_mode == "balanced":
		var BalancedAIClass = preload("res://simulation/ai/strategies/balanced_ai.gd")
		var results := runner.run_batch_with_ai(
			count,
			base_seed,
			func(game: GameState, wave: int) -> void:
				var ai = BalancedAIClass.new(game)
				ai.make_decisions(wave)
		)
		var analysis := SimulationRunner.analyze_results(results)
		all_results["ai_balanced"] = {
			"name": "BalancedAI",
			"description": "Coverage towers + upgrades + walls",
			"runs": count,
			"wins": analysis.wins,
			"win_rate": analysis.win_rate,
			"avg_shrine_hp": analysis.avg_shrine_hp,
			"avg_gold": analysis.avg_gold,
			"avg_killed": analysis.avg_killed,
			"avg_leaked": analysis.avg_leaked,
			"avg_duration_ms": analysis.avg_duration_ms,
			"upgrade_path_counts": analysis.get("upgrade_path_counts", {}),
		}
		if not json_output:
			print("AI Balanced:")
			print("  Win rate: %.1f%%" % [analysis.win_rate * 100])
			print("  Avg shrine HP: %.1f" % analysis.avg_shrine_hp)
			print("  Upgrade paths: %s" % str(analysis.get("upgrade_path_counts", {})))
			print("")
	else:
		for strat_id in strategies_to_run:
			if not all_strategies.has(strat_id):
				push_error("Unknown strategy: " + strat_id)
				continue
			var strategy: Dictionary = all_strategies[strat_id]

			var towers: Array[Dictionary] = []
			for t in strategy.towers:
				towers.append(t)

			var walls: Array[Vector2i] = []
			for w in strategy.walls:
				walls.append(w)

			var tower_upgrades: Array = strategy.get("tower_upgrades", [])
			var wall_upgrades: Array = strategy.get("wall_upgrades", [])

			var results := runner.run_batch(
				count, base_seed, towers, walls, tower_upgrades, wall_upgrades
			)
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
				"upgrade_path_counts": analysis.get("upgrade_path_counts", {}),
			}

			if not json_output:
				print("Strategy %s (%s):" % [strat_id, strategy.name])
				print("  Win rate: %.1f%%" % [analysis.win_rate * 100])
				print("  Avg shrine HP: %.1f" % analysis.avg_shrine_hp)
				print("  Avg gold: %.1f" % analysis.avg_gold)
				print(
					"  Avg killed/leaked: %.0f / %.0f" % [analysis.avg_killed, analysis.avg_leaked]
				)
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
			"ai_mode": ai_mode,
			"total_duration_ms": end_time - start_time,
			"timestamp": Time.get_datetime_string_from_system(),
			"parameter_bounds": BalanceConfig.get_parameter_bounds(),
		}
		print(JSON.stringify(output))
	else:
		print("=================================")
		print("Completed in %dms" % (end_time - start_time))
		print(
			"Best strategy: %s (%.1f%% win rate)" % [best_strategy.to_upper(), best_win_rate * 100]
		)
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
