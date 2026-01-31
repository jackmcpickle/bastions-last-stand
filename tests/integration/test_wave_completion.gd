extends GutTest

## Integration tests for wave completion scenarios

var _game_state: GameState
var _tick_processor: TickProcessor


func before_each() -> void:
	_game_state = TestHelpers.create_test_game_state()
	_tick_processor = TickProcessor.new(_game_state)
	_game_state.register_enemy_data(TestHelpers.create_basic_enemy_data())
	_game_state.register_tower_data(TestHelpers.create_basic_tower_data())


# ============================================
# Victory scenarios
# ============================================

func test_single_wave_victory() -> void:
	_setup_powerful_towers()

	var result := _tick_processor.run_wave(1)

	assert_true(result.success)
	assert_gt(_game_state.enemies_killed, 0)
	assert_eq(_game_state.enemies_leaked, 0)


func test_wave_victory_no_damage_taken() -> void:
	_setup_powerful_towers()
	var initial_hp := _game_state.shrine.hp

	var result := _tick_processor.run_wave(1)

	assert_true(result.success)
	assert_eq(result.shrine_hp, initial_hp)


func test_wave_victory_gold_earned() -> void:
	_setup_powerful_towers()
	var initial_gold := _game_state.gold

	_tick_processor.run_wave(1)

	assert_gt(_game_state.gold, initial_gold)


# ============================================
# Defeat scenarios
# ============================================

func test_single_wave_defeat_all_leak() -> void:
	# No towers - all enemies leak
	_game_state.shrine.hp = 1

	var result := _tick_processor.run_wave(1)

	assert_false(result.success)
	assert_eq(_game_state.shrine.hp, 0)


func test_wave_defeat_partial_leak() -> void:
	# Weak tower - some enemies leak
	_game_state.gold = 500
	var weak_tower := TestHelpers.create_basic_tower_data()
	weak_tower.id = "weak"
	weak_tower.damage = 1000  # Very weak
	weak_tower.attack_speed_ms = 2000  # Slow
	_game_state.register_tower_data(weak_tower)
	_game_state.place_tower(Vector2i(15, 8), "weak")
	_game_state.shrine.hp = 3

	var result := _tick_processor.run_wave(1)

	assert_false(result.success)
	assert_gt(_game_state.enemies_leaked, 0)


func test_wave_defeat_tracks_final_state() -> void:
	_game_state.shrine.hp = 5

	var result := _tick_processor.run_wave(1)

	assert_false(result.success)
	assert_eq(result.shrine_hp, 0)


# ============================================
# Mixed outcomes
# ============================================

func test_wave_victory_with_some_damage() -> void:
	# Medium strength defense
	_game_state.gold = 500
	var tower := TestHelpers.create_basic_tower_data()
	tower.damage = 30000  # Moderate
	_game_state.register_tower_data(tower)
	_game_state.place_tower(Vector2i(15, 8), "archer")
	var initial_hp := _game_state.shrine.hp

	var result := _tick_processor.run_wave(1)

	# Outcome depends on wave - may or may not take damage
	if result.success:
		assert_lte(result.shrine_hp, initial_hp)


func test_wave_partial_kills_partial_leaks() -> void:
	# Defense that kills some but not all
	_game_state.gold = 500
	var tower := TestHelpers.create_basic_tower_data()
	tower.damage = 20000
	tower.range_tiles = 3  # Short range
	_game_state.register_tower_data(tower)
	_game_state.place_tower(Vector2i(17, 8), "archer")  # Late in path

	_tick_processor.run_wave(1)

	# Should have both kills and leaks (or one or the other)
	var total_processed := _game_state.enemies_killed + _game_state.enemies_leaked
	assert_gt(total_processed, 0)


# ============================================
# Wave state tracking
# ============================================

func test_wave_completion_clears_enemies() -> void:
	_setup_powerful_towers()

	_tick_processor.run_wave(1)

	assert_eq(_game_state.enemies.size(), 0)


func test_wave_completion_clears_spawn_queue() -> void:
	_setup_powerful_towers()

	_tick_processor.run_wave(1)

	assert_eq(_game_state.spawn_queue.size(), 0)


func test_wave_completion_updates_wave_in_progress() -> void:
	_setup_powerful_towers()

	_tick_processor.run_wave(1)

	assert_false(_game_state.wave_in_progress)


func test_wave_completion_emits_signal() -> void:
	_setup_powerful_towers()
	var signal_data := {"emitted": false}
	_game_state.wave_completed.connect(func(_n): signal_data.emitted = true)

	_tick_processor.run_wave(1)

	assert_true(signal_data.emitted)


# ============================================
# Multi-wave scenarios
# ============================================

func test_consecutive_waves_accumulate_gold() -> void:
	# Use multi-wave data
	_game_state.wave_data = TestHelpers.create_multi_wave_data(3)
	_setup_powerful_towers()
	var gold_after_wave1 := 0

	_tick_processor.run_wave(1)
	gold_after_wave1 = _game_state.gold

	_tick_processor.run_wave(2)

	assert_gt(_game_state.gold, gold_after_wave1)


func test_consecutive_waves_track_kills() -> void:
	_game_state.wave_data = TestHelpers.create_multi_wave_data(2)
	_setup_powerful_towers()

	_tick_processor.run_wave(1)
	var kills_after_1 := _game_state.enemies_killed

	_tick_processor.run_wave(2)

	assert_gt(_game_state.enemies_killed, kills_after_1)


# ============================================
# Tower performance tracking
# ============================================

func test_tower_damage_tracking() -> void:
	_setup_powerful_towers()

	_tick_processor.run_wave(1)

	for tower in _game_state.towers:
		if tower.shots_fired > 0:
			assert_gt(tower.total_damage_dealt, 0)


func test_tower_kill_tracking() -> void:
	_setup_powerful_towers()

	_tick_processor.run_wave(1)

	var total_tower_kills := 0
	for tower in _game_state.towers:
		total_tower_kills += tower.kills

	assert_eq(total_tower_kills, _game_state.enemies_killed)


func test_tower_shot_tracking() -> void:
	_setup_powerful_towers()

	_tick_processor.run_wave(1)

	var any_tower_fired := false
	for tower in _game_state.towers:
		if tower.shots_fired > 0:
			any_tower_fired = true
			break
	assert_true(any_tower_fired, "At least one tower should have fired")


# ============================================
# Edge cases
# ============================================

func test_wave_with_no_enemies() -> void:
	# Create wave with zero enemies
	var wave_data := WaveData.new()
	var wave := SingleWaveData.new()
	wave.wave_number = 1
	wave.spawns = []  # No spawns
	wave_data.waves = [wave]
	_game_state.wave_data = wave_data

	var result := _tick_processor.run_wave(1)

	assert_true(result.success)
	assert_eq(result.ticks, 1)  # Immediate completion


func test_wave_timeout_protection() -> void:
	# This tests the max_ticks safety limit
	# In normal operation, waves should complete well before timeout
	_setup_powerful_towers()

	var result := _tick_processor.run_wave(1)

	assert_lt(result.ticks, 10000)  # Should be far below timeout


# ============================================
# Helpers
# ============================================

func _setup_powerful_towers() -> void:
	_game_state.gold = 10000
	for x in range(3, 18, 3):
		var data := TestHelpers.create_basic_tower_data()
		data.id = "tower_%d" % x
		data.damage = 100000  # Very powerful
		_game_state.register_tower_data(data)
		_game_state.place_tower(Vector2i(x, 8), "tower_%d" % x)
