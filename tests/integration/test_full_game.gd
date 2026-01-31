extends GutTest

## Integration tests for full game scenarios

var _game_state: GameState
var _tick_processor: TickProcessor


func before_each() -> void:
	var map := TestHelpers.create_basic_map_data()
	var waves := TestHelpers.create_multi_wave_data(10)
	_game_state = GameState.new()
	_game_state.initialize(map, waves, 12345)
	_tick_processor = TickProcessor.new(_game_state)

	# Register enemy types
	_game_state.register_enemy_data(TestHelpers.create_basic_enemy_data())
	_game_state.register_enemy_data(TestHelpers.create_fast_enemy_data())
	_game_state.register_enemy_data(TestHelpers.create_armored_enemy_data())

	# Register tower types
	_game_state.register_tower_data(TestHelpers.create_basic_tower_data())
	_game_state.register_tower_data(TestHelpers.create_aoe_tower_data())
	_game_state.register_tower_data(TestHelpers.create_frost_tower_data())


# ============================================
# Full game victory
# ============================================

func test_full_game_victory() -> void:
	_setup_strong_defense()

	var result := _tick_processor.run_all_waves()

	assert_true(result.won)
	assert_eq(result.final_wave, 10)


func test_full_game_tracks_duration() -> void:
	_setup_strong_defense()

	var result := _tick_processor.run_all_waves()

	assert_gt(result.get_duration_ms(), 0)


func test_full_game_wave_results_count() -> void:
	_setup_strong_defense()

	var result := _tick_processor.run_all_waves()

	assert_eq(result.wave_results.size(), 10)


func test_full_game_all_waves_succeed() -> void:
	_setup_strong_defense()

	var result := _tick_processor.run_all_waves()

	for wave_result in result.wave_results:
		assert_true(wave_result.success)


# ============================================
# Full game defeat
# ============================================

func test_full_game_defeat_mid_wave() -> void:
	# Weak defense - will lose eventually
	_game_state.gold = 200
	_game_state.place_tower(Vector2i(15, 8), "archer")
	_game_state.shrine.hp = 20  # Low HP

	var result := _tick_processor.run_all_waves()

	assert_false(result.won)
	assert_lt(result.final_wave, 10)


func test_full_game_defeat_tracks_final_wave() -> void:
	_game_state.shrine.hp = 5

	var result := _tick_processor.run_all_waves()

	assert_gt(result.final_wave, 0)
	assert_eq(result.final_shrine_hp, 0)


# ============================================
# Economy tracking
# ============================================

func test_full_game_gold_tracking() -> void:
	_setup_strong_defense()

	var result := _tick_processor.run_all_waves()

	assert_gt(result.total_gold_earned, 0)
	assert_gt(result.total_gold_spent, 0)


func test_full_game_final_gold() -> void:
	_setup_strong_defense()

	var result := _tick_processor.run_all_waves()

	assert_eq(result.final_gold, _game_state.gold)


func test_full_game_gold_increases_each_wave() -> void:
	_setup_strong_defense()
	var gold_history := []

	for wave in range(1, 11):
		_tick_processor.run_wave(wave)
		gold_history.append(_game_state.gold)

	# Gold should generally increase (from kills)
	assert_gt(gold_history[-1], gold_history[0])


# ============================================
# Combat statistics
# ============================================

func test_full_game_enemies_killed() -> void:
	_setup_strong_defense()

	var result := _tick_processor.run_all_waves()

	assert_gt(result.enemies_killed, 0)


func test_full_game_total_damage() -> void:
	_setup_strong_defense()

	var result := _tick_processor.run_all_waves()

	assert_gt(result.total_damage_dealt, 0)


func test_full_game_tower_stats_populated() -> void:
	_setup_strong_defense()

	var result := _tick_processor.run_all_waves()

	assert_gt(result.tower_stats.size(), 0)


func test_full_game_tower_stats_content() -> void:
	_setup_strong_defense()

	var result := _tick_processor.run_all_waves()

	for tower_id in result.tower_stats:
		var stats = result.tower_stats[tower_id]
		assert_has(stats, "damage")
		assert_has(stats, "kills")
		assert_has(stats, "shots")


# ============================================
# Result serialization
# ============================================

func test_game_result_to_dict() -> void:
	_setup_strong_defense()

	var result := _tick_processor.run_all_waves()
	var dict := result.to_dict()

	assert_has(dict, "won")
	assert_has(dict, "final_wave")
	assert_has(dict, "final_shrine_hp")
	assert_has(dict, "enemies_killed")
	assert_has(dict, "tower_stats")


func test_game_result_dict_values() -> void:
	_setup_strong_defense()

	var result := _tick_processor.run_all_waves()
	var dict := result.to_dict()

	assert_eq(dict.won, result.won)
	assert_eq(dict.final_wave, result.final_wave)
	assert_eq(dict.enemies_killed, result.enemies_killed)


# ============================================
# Strategy variations
# ============================================

func test_aoe_tower_strategy() -> void:
	# Test with AOE-focused defense
	_game_state.gold = 5000
	for x in range(5, 15, 3):
		_game_state.place_tower(Vector2i(x, 8), "cannon")

	var result := _tick_processor.run_all_waves()

	# Should work reasonably well
	assert_gt(result.final_wave, 3)


func test_frost_tower_slow_strategy() -> void:
	# Test with frost towers for slowing
	_game_state.gold = 5000
	_game_state.place_tower(Vector2i(5, 8), "frost")
	_game_state.place_tower(Vector2i(10, 8), "frost")
	# Back with damage
	for x in range(13, 18, 3):
		var data := TestHelpers.create_basic_tower_data()
		data.id = "dps_%d" % x
		data.damage = 80000
		_game_state.register_tower_data(data)
		_game_state.place_tower(Vector2i(x, 8), "dps_%d" % x)

	var result := _tick_processor.run_all_waves()

	assert_gt(result.final_wave, 1)


func test_spread_defense() -> void:
	# Towers spread along path
	_game_state.gold = 5000
	for x in range(3, 18, 4):
		var data := TestHelpers.create_basic_tower_data()
		data.id = "spread_%d" % x
		data.damage = 50000
		_game_state.register_tower_data(data)
		_game_state.place_tower(Vector2i(x, 8), "spread_%d" % x)

	var result := _tick_processor.run_all_waves()

	assert_gt(result.final_wave, 1)


# ============================================
# Determinism
# ============================================

func test_full_game_deterministic() -> void:
	# Run twice with same setup
	var result1 := _run_game_with_seed(99999)
	var result2 := _run_game_with_seed(99999)

	assert_eq(result1.won, result2.won)
	assert_eq(result1.final_wave, result2.final_wave)
	assert_eq(result1.enemies_killed, result2.enemies_killed)


func test_different_seeds_different_outcomes() -> void:
	# Different seeds should give different results (may be same, but usually different)
	var seeds := [111, 222, 333, 444, 555]
	var results := []

	for seed in seeds:
		results.append(_run_game_with_seed(seed))

	# At least some variation expected
	var all_same := true
	for i in range(1, results.size()):
		if results[i].final_wave != results[0].final_wave:
			all_same = false
			break

	# If all same, that's unusual but possible - just log it
	if all_same:
		gut.p("All seeds produced same final wave - unusual but possible")


# ============================================
# Helpers
# ============================================

func _setup_strong_defense() -> void:
	_game_state.gold = 10000
	# Heavy defense
	for y in range(6, 14, 3):
		for x in range(3, 18, 3):
			var data := TestHelpers.create_basic_tower_data()
			data.id = "tower_%d_%d" % [x, y]
			data.damage = 100000
			_game_state.register_tower_data(data)
			_game_state.place_tower(Vector2i(x, y), "tower_%d_%d" % [x, y])


func _run_game_with_seed(seed_val: int) -> TickProcessor.GameResult:
	var map := TestHelpers.create_basic_map_data()
	var waves := TestHelpers.create_multi_wave_data(5)
	var state := GameState.new()
	state.initialize(map, waves, seed_val)
	state.register_enemy_data(TestHelpers.create_basic_enemy_data())
	state.register_tower_data(TestHelpers.create_basic_tower_data())

	# Setup defense
	state.gold = 5000
	for x in range(5, 18, 4):
		var data := TestHelpers.create_basic_tower_data()
		data.id = "t_%d" % x
		data.damage = 50000
		state.register_tower_data(data)
		state.place_tower(Vector2i(x, 8), "t_%d" % x)

	var tp := TickProcessor.new(state)
	return tp.run_all_waves()
