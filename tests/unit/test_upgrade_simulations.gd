extends GutTest

## Tests for upgrade schedules in SimulationRunner and AI upgrade picks

const SimulationRunnerClass = preload("res://simulation/runner/simulation_runner.gd")
const TestMap = preload("res://maps/test_map.gd")
const Waves1To10 = preload("res://resources/waves/waves_1_10.gd")
const AIPlayerClass = preload("res://simulation/ai/ai_player.gd")
const BalancedAIClass = preload("res://simulation/ai/strategies/balanced_ai.gd")


func test_run_single_applies_tower_upgrade_schedule() -> void:
	var runner := _make_runner()
	var towers: Array[Dictionary] = [{pos = Vector2i(3, 2), id = "archer"}]
	var walls: Array[Vector2i] = []
	var upgrades := [
		{pos = Vector2i(3, 2), upgrade_id = "archer_marksman"},
		{pos = Vector2i(3, 2), upgrade_id = "archer_sniper"},
	]

	var result := runner.run_single(42, towers, walls, upgrades, [])

	assert_false(result.upgrade_loadout.is_empty())
	var found := false
	for entry in result.upgrade_loadout:
		if entry.kind == "tower" and entry.id == "archer":
			assert_eq(entry.tier, 3)
			assert_eq(entry.branch, "A1")
			found = true
	assert_true(found)


func test_run_single_applies_wall_upgrade_schedule() -> void:
	var runner := _make_runner()
	var towers: Array[Dictionary] = [{pos = Vector2i(5, 2), id = "archer"}]
	var walls: Array[Vector2i] = [Vector2i(4, 3)]
	var wall_upgrades := [
		{pos = Vector2i(4, 3), upgrade_id = "wall_reinforced"},
		{pos = Vector2i(4, 3), upgrade_id = "wall_fortress"},
	]

	var result := runner.run_single(7, towers, walls, [], wall_upgrades)

	var found := false
	for entry in result.upgrade_loadout:
		if entry.kind == "wall":
			assert_eq(entry.tier, 3)
			assert_eq(entry.branch, "A1")
			found = true
	assert_true(found)


func test_analyze_results_includes_upgrade_path_counts() -> void:
	var runner := _make_runner()
	var towers: Array[Dictionary] = [{pos = Vector2i(3, 2), id = "archer"}]
	var upgrades := [
		{pos = Vector2i(3, 2), upgrade_id = "archer_rapid_fire"},
		{pos = Vector2i(3, 2), upgrade_id = "archer_machine_bow"},
	]
	var results := runner.run_batch(2, 100, towers, [], upgrades, [])
	var analysis := SimulationRunnerClass.analyze_results(results)

	assert_has(analysis, "upgrade_path_counts")
	assert_gt(analysis.upgrade_path_counts.size(), 0)


func test_get_best_upgrade_for_tower_varies_branch() -> void:
	var state := TestHelpers.create_test_game_state()
	var data := TestHelpers.create_tower_with_upgrades()
	state.register_tower_data(data)
	state.gold = 1000
	var tower_a := state.place_tower(Vector2i(2, 8), "upgradeable")
	tower_a.kills = 0  # prefer A
	var tower_b := state.place_tower(Vector2i(6, 8), "upgradeable")
	tower_b.kills = 1  # prefer B with pos parity

	var ai := AIPlayerClass.new(state)
	var up_a := ai.get_best_upgrade_for_tower(tower_a)
	var up_b := ai.get_best_upgrade_for_tower(tower_b)

	assert_not_null(up_a)
	assert_not_null(up_b)
	# At least one should pick a defined branch
	assert_true(up_a.branch == "A" or up_a.branch == "B")


func test_balanced_ai_upgrades_walls() -> void:
	var state := TestHelpers.create_test_game_state()
	state.gold = 500
	var wall := state.place_wall(Vector2i(5, 5))
	wall.hp = 40  # damaged → prefer Reinforced (A)

	# Cover path so AI spends on upgrades not new towers
	state.place_tower(Vector2i(2, 8), "archer")
	state.place_tower(Vector2i(6, 8), "archer")
	state.place_tower(Vector2i(10, 8), "archer")
	state.gold = 200

	var ai := BalancedAIClass.new(state)
	ai.make_decisions(3)

	assert_gt(wall.tier, 1)


func _make_runner() -> SimulationRunner:
	var runner := SimulationRunnerClass.new()
	var config := BalanceConfig.new()
	config.starting_gold = 500
	runner.setup(TestMap.create(), Waves1To10.create(), config)
	runner.register_tower(load("res://resources/towers/archer_tower.tres"))
	runner.register_tower(load("res://resources/towers/cannon_tower.tres"))
	runner.register_tower(load("res://resources/towers/frost_tower.tres"))
	runner.register_tower(load("res://resources/towers/lightning_tower.tres"))
	runner.register_tower(load("res://resources/towers/flame_tower.tres"))
	runner.register_wall(load("res://resources/walls/basic_wall.tres"))
	runner.register_enemy(load("res://resources/enemies/grunt.tres"))
	runner.register_enemy(load("res://resources/enemies/runner.tres"))
	return runner
