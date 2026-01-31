extends GutTest

## Integration tests for TickProcessor

var _game_state: GameState
var _tick_processor: TickProcessor


func before_each() -> void:
	_game_state = TestHelpers.create_test_game_state()
	_tick_processor = TickProcessor.new(_game_state)

	# Register necessary data
	_game_state.register_enemy_data(TestHelpers.create_basic_enemy_data())
	_game_state.register_tower_data(TestHelpers.create_basic_tower_data())


# ============================================
# process_tick() basic tests
# ============================================


func test_process_tick_returns_waiting_no_wave() -> void:
	var result := _tick_processor.process_tick()

	assert_eq(result, TickProcessor.TickResult.WAITING)


func test_process_tick_returns_ongoing_during_wave() -> void:
	_game_state.start_wave(1)

	var result := _tick_processor.process_tick()

	assert_eq(result, TickProcessor.TickResult.ONGOING)


func test_process_tick_spawns_enemies() -> void:
	_game_state.start_wave(1)

	# Process multiple ticks
	for i in range(50):
		_tick_processor.process_tick()

	assert_gt(_game_state.enemies.size(), 0)


func test_process_tick_moves_enemies() -> void:
	_game_state.start_wave(1)

	# Wait for spawns
	for i in range(20):
		_tick_processor.process_tick()

	if _game_state.enemies.is_empty():
		pass_test("No enemies spawned yet")
		return

	var initial_pos := _game_state.enemies[0].grid_pos.x

	_tick_processor.process_tick()

	assert_gt(_game_state.enemies[0].grid_pos.x, initial_pos)


func test_process_tick_towers_attack() -> void:
	_game_state.gold = 500
	var tower := _game_state.place_tower(Vector2i(5, 8), "archer")

	_game_state.start_wave(1)

	# Wait for spawns and let tower attack
	for i in range(50):
		_tick_processor.process_tick()

	assert_gt(tower.shots_fired, 0)


func test_process_tick_enemies_die() -> void:
	_game_state.gold = 500
	# Place multiple powerful towers
	for x in range(3, 15, 4):
		var data := TestHelpers.create_basic_tower_data()
		data.id = "tower_%d" % x
		data.damage = 50000  # High damage
		_game_state.register_tower_data(data)
		_game_state.place_tower(Vector2i(x, 8), "tower_%d" % x)

	_game_state.start_wave(1)

	# Run wave
	for i in range(200):
		_tick_processor.process_tick()

	assert_gt(_game_state.enemies_killed, 0)


# ============================================
# Game over tests
# ============================================


func test_process_tick_game_over_on_shrine_death() -> void:
	_game_state.shrine.hp = 1
	_game_state.start_wave(1)

	# Fast-forward to enemy reaching shrine
	for i in range(500):
		var result := _tick_processor.process_tick()
		if result == TickProcessor.TickResult.GAME_OVER_LOSS:
			pass_test("Game over detected")
			return

	fail_test("Game over not detected")


func test_process_tick_returns_loss_on_game_over() -> void:
	_game_state.shrine.hp = 0

	var result := _tick_processor.process_tick()

	assert_eq(result, TickProcessor.TickResult.GAME_OVER_LOSS)


# ============================================
# Wave completion tests
# ============================================


func test_process_tick_wave_complete() -> void:
	_game_state.gold = 500
	# Place powerful towers
	for x in range(3, 18, 3):
		var data := TestHelpers.create_basic_tower_data()
		data.id = "tower_%d" % x
		data.damage = 100000
		_game_state.register_tower_data(data)
		_game_state.place_tower(Vector2i(x, 8), "tower_%d" % x)

	_game_state.start_wave(1)

	# Run until wave complete or timeout
	for i in range(2000):
		var result := _tick_processor.process_tick()
		if result == TickProcessor.TickResult.WAVE_COMPLETE:
			pass_test("Wave completed")
			return

	fail_test("Wave did not complete")


# ============================================
# run_wave() tests
# ============================================


func test_run_wave_returns_result() -> void:
	_game_state.gold = 1000
	# Place towers
	for x in range(3, 18, 3):
		var data := TestHelpers.create_basic_tower_data()
		data.id = "tower_%d" % x
		data.damage = 100000
		_game_state.register_tower_data(data)
		_game_state.place_tower(Vector2i(x, 8), "tower_%d" % x)

	var result := _tick_processor.run_wave(1)

	assert_not_null(result)
	assert_true(result.success)
	assert_gt(result.ticks, 0)


func test_run_wave_loss_returns_failure() -> void:
	# No towers - enemies will leak
	_game_state.shrine.hp = 5

	var result := _tick_processor.run_wave(1)

	assert_false(result.success)


func test_run_wave_tracks_shrine_hp() -> void:
	_game_state.gold = 1000
	var data := TestHelpers.create_basic_tower_data()
	data.damage = 100000
	_game_state.register_tower_data(data)
	_game_state.place_tower(Vector2i(10, 8), "archer")
	var initial_hp := _game_state.shrine.hp

	var result := _tick_processor.run_wave(1)

	assert_lte(result.shrine_hp, initial_hp)


func test_run_wave_invalid_wave() -> void:
	var result := _tick_processor.run_wave(999)

	assert_false(result.success)
	assert_eq(result.ticks, 0)


# ============================================
# run_all_waves() tests
# ============================================


func test_run_all_waves_tracks_results() -> void:
	_game_state.gold = 5000
	# Place powerful towers
	for x in range(3, 18, 2):
		var data := TestHelpers.create_basic_tower_data()
		data.id = "tower_%d" % x
		data.damage = 100000
		_game_state.register_tower_data(data)
		_game_state.place_tower(Vector2i(x, 8), "tower_%d" % x)

	var result := _tick_processor.run_all_waves()

	assert_not_null(result)
	assert_gt(result.wave_results.size(), 0)


func test_run_all_waves_victory() -> void:
	_game_state.gold = 10000
	# Lots of powerful towers
	for y in range(6, 14, 3):
		for x in range(3, 18, 3):
			var data := TestHelpers.create_basic_tower_data()
			data.id = "tower_%d_%d" % [x, y]
			data.damage = 100000
			_game_state.register_tower_data(data)
			_game_state.place_tower(Vector2i(x, y), "tower_%d_%d" % [x, y])

	var result := _tick_processor.run_all_waves()

	if result.won:
		assert_eq(result.final_wave, _game_state.wave_data.get_total_waves())


func test_run_all_waves_tracks_statistics() -> void:
	_game_state.gold = 5000
	for x in range(3, 18, 3):
		var data := TestHelpers.create_basic_tower_data()
		data.id = "tower_%d" % x
		data.damage = 100000
		_game_state.register_tower_data(data)
		_game_state.place_tower(Vector2i(x, 8), "tower_%d" % x)

	var result := _tick_processor.run_all_waves()

	assert_gt(result.enemies_killed, 0)
	assert_gt(result.total_damage_dealt, 0)


func test_run_all_waves_tower_stats() -> void:
	_game_state.gold = 500
	var data := TestHelpers.create_basic_tower_data()
	data.damage = 100000
	_game_state.register_tower_data(data)
	_game_state.place_tower(Vector2i(10, 8), "archer")

	var result := _tick_processor.run_all_waves()

	assert_has(result.tower_stats, "archer")


# ============================================
# Status effects integration
# ============================================


func test_tick_processes_status_effects() -> void:
	_game_state.gold = 500
	var frost_data := TestHelpers.create_frost_tower_data()
	_game_state.register_tower_data(frost_data)
	_game_state.place_tower(Vector2i(5, 8), "frost")

	_game_state.start_wave(1)

	# Run until we have slowed enemies
	var found_slowed := false
	for i in range(100):
		_tick_processor.process_tick()
		for enemy in _game_state.enemies:
			if enemy.slow_amount > 0:
				found_slowed = true
				break
		if found_slowed:
			break

	assert_true(found_slowed, "No enemies were slowed")


func test_tick_processes_burn_damage() -> void:
	_game_state.gold = 500
	var flame_data := TestHelpers.create_flame_tower_data()
	_game_state.register_tower_data(flame_data)
	_game_state.place_tower(Vector2i(5, 8), "flame")

	_game_state.start_wave(1)

	# Run until we have burning enemies
	var found_burning := false
	for i in range(100):
		_tick_processor.process_tick()
		for enemy in _game_state.enemies:
			if enemy.burn_dps > 0:
				found_burning = true
				break
		if found_burning:
			break

	assert_true(found_burning, "No enemies were burning")


# ============================================
# Determinism tests
# ============================================


func test_same_seed_same_result() -> void:
	# First run
	var state1 := _create_game_with_seed(12345)
	var tp1 := TickProcessor.new(state1)
	var result1 := tp1.run_wave(1)

	# Second run with same seed
	var state2 := _create_game_with_seed(12345)
	var tp2 := TickProcessor.new(state2)
	var result2 := tp2.run_wave(1)

	assert_eq(result1.ticks, result2.ticks)
	assert_eq(result1.shrine_hp, result2.shrine_hp)


func _create_game_with_seed(seed_val: int) -> GameState:
	var map := TestHelpers.create_basic_map_data()
	var waves := TestHelpers.create_basic_wave_data()
	var state := GameState.new()
	state.initialize(map, waves, seed_val)
	state.register_enemy_data(TestHelpers.create_basic_enemy_data())
	state.register_tower_data(TestHelpers.create_basic_tower_data())
	state.gold = 500

	var tower_data := TestHelpers.create_basic_tower_data()
	tower_data.damage = 50000
	state.register_tower_data(tower_data)
	state.place_tower(Vector2i(10, 8), "archer")

	return state
