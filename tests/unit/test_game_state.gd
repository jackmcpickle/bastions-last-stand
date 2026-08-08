extends GutTest

## Unit tests for GameState

var _game_state: GameState


func before_each() -> void:
	_game_state = TestHelpers.create_test_game_state()


# ============================================
# place_tower() tests
# ============================================


func test_place_tower_basic() -> void:
	_game_state.gold = 200
	var data := TestHelpers.create_basic_tower_data()
	_game_state.register_tower_data(data)

	var tower := _game_state.place_tower(Vector2i(5, 5), "archer")

	assert_not_null(tower)
	assert_eq(tower.position, Vector2i(5, 5))
	assert_eq(_game_state.towers.size(), 1)


func test_place_tower_deducts_gold() -> void:
	_game_state.gold = 200
	var data := TestHelpers.create_basic_tower_data()
	data.base_cost = 80
	_game_state.register_tower_data(data)

	_game_state.place_tower(Vector2i(5, 5), "archer")

	assert_eq(_game_state.gold, 120)


func test_place_tower_tracks_spent() -> void:
	_game_state.gold = 200
	var data := TestHelpers.create_basic_tower_data()
	data.base_cost = 80
	_game_state.register_tower_data(data)

	_game_state.place_tower(Vector2i(5, 5), "archer")

	assert_eq(_game_state.total_gold_spent, 80)


func test_place_tower_blocks_tiles() -> void:
	_game_state.gold = 200
	var data := TestHelpers.create_basic_tower_data()
	_game_state.register_tower_data(data)

	_game_state.place_tower(Vector2i(5, 5), "archer")

	# Tower is 2x2
	assert_true(_game_state.pathfinding.is_blocked(Vector2i(5, 5)))
	assert_true(_game_state.pathfinding.is_blocked(Vector2i(6, 5)))
	assert_true(_game_state.pathfinding.is_blocked(Vector2i(5, 6)))
	assert_true(_game_state.pathfinding.is_blocked(Vector2i(6, 6)))


func test_place_tower_repaths_ground_enemies() -> void:
	_game_state.gold = 200
	var data := TestHelpers.create_basic_tower_data()
	_game_state.register_tower_data(data)

	var enemy := SimEnemy.new()
	enemy.initialize(
		TestHelpers.create_basic_enemy_data(), Vector2i(0, 10), _game_state.pathfinding
	)
	_game_state.enemies.append(enemy)

	assert_has(enemy.path, Vector2i(10, 10))

	# 2x2 tower at (9,9) covers (10,10) on the straight path
	_game_state.place_tower(Vector2i(9, 9), "archer")

	assert_false(enemy.path.has(Vector2i(10, 10)))
	assert_eq(enemy.path[-1], _game_state.pathfinding.get_shrine_position())


func test_place_tower_insufficient_gold() -> void:
	_game_state.gold = 10
	var data := TestHelpers.create_basic_tower_data()
	data.base_cost = 80
	_game_state.register_tower_data(data)

	var tower := _game_state.place_tower(Vector2i(5, 5), "archer")

	assert_null(tower)
	assert_eq(_game_state.towers.size(), 0)


func test_place_tower_overlapping() -> void:
	_game_state.gold = 500
	var data := TestHelpers.create_basic_tower_data()
	_game_state.register_tower_data(data)

	_game_state.place_tower(Vector2i(5, 5), "archer")
	var tower2 := _game_state.place_tower(Vector2i(6, 6), "archer")  # Overlaps

	assert_null(tower2)
	assert_eq(_game_state.towers.size(), 1)


func test_place_tower_initializes_hp_from_data() -> void:
	_game_state.gold = 200
	var data := TestHelpers.create_basic_tower_data()
	data.hp = 100
	_game_state.register_tower_data(data)

	var tower := _game_state.place_tower(Vector2i(5, 5), "archer")

	assert_eq(tower.hp, 100)
	assert_eq(tower.max_hp, 100)


func test_destroy_tower_removes_from_towers() -> void:
	_game_state.gold = 200
	var data := TestHelpers.create_basic_tower_data()
	_game_state.register_tower_data(data)
	var tower := _game_state.place_tower(Vector2i(5, 5), "archer")

	_game_state.destroy_tower(tower)

	assert_false(_game_state.towers.has(tower))
	assert_eq(_game_state.towers.size(), 0)


func test_destroy_tower_unblocks_2x2_tiles() -> void:
	_game_state.gold = 200
	var data := TestHelpers.create_basic_tower_data()
	_game_state.register_tower_data(data)
	var tower := _game_state.place_tower(Vector2i(5, 5), "archer")

	_game_state.destroy_tower(tower)

	assert_false(_game_state.pathfinding.is_blocked(Vector2i(5, 5)))
	assert_false(_game_state.pathfinding.is_blocked(Vector2i(6, 5)))
	assert_false(_game_state.pathfinding.is_blocked(Vector2i(5, 6)))
	assert_false(_game_state.pathfinding.is_blocked(Vector2i(6, 6)))


func test_destroy_tower_emits_tower_destroyed() -> void:
	_game_state.gold = 200
	var data := TestHelpers.create_basic_tower_data()
	_game_state.register_tower_data(data)
	var tower := _game_state.place_tower(Vector2i(5, 5), "archer")

	var signal_data := {"emitted": false, "tower": null}
	_game_state.tower_destroyed.connect(
		func(t: SimTower):
			signal_data.emitted = true
			signal_data.tower = t
	)

	_game_state.destroy_tower(tower)

	assert_true(signal_data.emitted)
	assert_eq(signal_data.tower, tower)


# ============================================
# can_place_tower() tests
# ============================================


func test_can_place_tower_valid() -> void:
	_game_state.gold = 200
	var data := TestHelpers.create_basic_tower_data()
	_game_state.register_tower_data(data)

	assert_true(_game_state.can_place_tower(Vector2i(5, 5), "archer"))


func test_can_place_tower_no_gold() -> void:
	_game_state.gold = 10
	var data := TestHelpers.create_basic_tower_data()
	data.base_cost = 80
	_game_state.register_tower_data(data)

	assert_false(_game_state.can_place_tower(Vector2i(5, 5), "archer"))


func test_can_place_tower_unknown_type() -> void:
	_game_state.gold = 200

	assert_false(_game_state.can_place_tower(Vector2i(5, 5), "unknown"))


func test_can_place_tower_on_shrine() -> void:
	_game_state.gold = 200
	var data := TestHelpers.create_basic_tower_data()
	_game_state.register_tower_data(data)
	var shrine_pos := _game_state.shrine.position

	# Tower would overlap shrine
	assert_false(_game_state.can_place_tower(shrine_pos - Vector2i(1, 0), "archer"))


func test_can_place_tower_existing_structure() -> void:
	_game_state.gold = 500
	var data := TestHelpers.create_basic_tower_data()
	_game_state.register_tower_data(data)

	_game_state.place_tower(Vector2i(5, 5), "archer")

	assert_false(_game_state.can_place_tower(Vector2i(5, 5), "archer"))


# ============================================
# place_wall() tests
# ============================================


func test_place_wall_basic() -> void:
	_game_state.gold = 200

	var wall := _game_state.place_wall(Vector2i(5, 5))

	assert_not_null(wall)
	assert_eq(wall.position, Vector2i(5, 5))
	assert_eq(_game_state.walls.size(), 1)


func test_place_wall_deducts_gold() -> void:
	_game_state.gold = 200
	var initial_gold := _game_state.gold

	_game_state.place_wall(Vector2i(5, 5))

	assert_lt(_game_state.gold, initial_gold)


func test_place_wall_blocks_tile() -> void:
	_game_state.gold = 200

	_game_state.place_wall(Vector2i(5, 5))

	assert_true(_game_state.pathfinding.is_blocked(Vector2i(5, 5)))


func test_place_wall_repaths_ground_enemies() -> void:
	_game_state.gold = 200

	var enemy := SimEnemy.new()
	enemy.initialize(
		TestHelpers.create_basic_enemy_data(), Vector2i(0, 10), _game_state.pathfinding
	)
	_game_state.enemies.append(enemy)

	assert_has(enemy.path, Vector2i(10, 10))

	_game_state.place_wall(Vector2i(10, 10))

	assert_false(enemy.path.has(Vector2i(10, 10)))
	assert_eq(enemy.path[-1], _game_state.pathfinding.get_shrine_position())


func test_place_wall_insufficient_gold() -> void:
	_game_state.gold = 5

	var wall := _game_state.place_wall(Vector2i(5, 5))

	assert_null(wall)


# ============================================
# can_place_wall() tests
# ============================================


func test_can_place_wall_valid() -> void:
	_game_state.gold = 200

	assert_true(_game_state.can_place_wall(Vector2i(5, 5)))


func test_can_place_wall_no_gold() -> void:
	_game_state.gold = 5

	assert_false(_game_state.can_place_wall(Vector2i(5, 5)))


func test_can_place_wall_on_shrine() -> void:
	_game_state.gold = 200

	assert_false(_game_state.can_place_wall(_game_state.shrine.position))


func test_can_place_wall_existing_structure() -> void:
	_game_state.gold = 200
	_game_state.place_wall(Vector2i(5, 5))

	assert_false(_game_state.can_place_wall(Vector2i(5, 5)))


# ============================================
# start_wave() tests
# ============================================


func test_start_wave_basic() -> void:
	var data := TestHelpers.create_basic_enemy_data()
	_game_state.register_enemy_data(data)

	var result := _game_state.start_wave(1)

	assert_true(result)
	assert_eq(_game_state.current_wave, 1)
	assert_true(_game_state.wave_in_progress)


func test_start_wave_sets_spawn_queue() -> void:
	var data := TestHelpers.create_basic_enemy_data()
	_game_state.register_enemy_data(data)

	_game_state.start_wave(1)

	assert_gt(_game_state.spawn_queue.size(), 0)


func test_start_wave_already_in_progress() -> void:
	var data := TestHelpers.create_basic_enemy_data()
	_game_state.register_enemy_data(data)
	_game_state.start_wave(1)

	var result := _game_state.start_wave(2)

	assert_false(result)
	assert_eq(_game_state.current_wave, 1)


func test_start_wave_invalid_wave() -> void:
	var result := _game_state.start_wave(999)

	assert_false(result)


# ============================================
# process_spawns() tests
# ============================================


func test_process_spawns_spawns_enemies() -> void:
	var data := TestHelpers.create_basic_enemy_data()
	_game_state.register_enemy_data(data)
	_game_state.start_wave(1)

	# Process enough ticks to spawn
	for i in range(50):
		_game_state.process_spawns(100)

	assert_gt(_game_state.enemies.size(), 0)


func test_process_spawns_respects_delay() -> void:
	var data := TestHelpers.create_basic_enemy_data()
	_game_state.register_enemy_data(data)
	_game_state.start_wave(1)

	_game_state.process_spawns(1)  # 1ms - too early

	# Check spawn queue still has entries
	assert_gt(_game_state.spawn_queue.size(), 0)


# ============================================
# remove_enemy() tests
# ============================================


func test_remove_enemy_killed() -> void:
	var enemy := _spawn_enemy()
	var initial_gold := _game_state.gold

	_game_state.remove_enemy(enemy, true)

	assert_eq(_game_state.enemies.size(), 0)
	assert_eq(_game_state.gold, initial_gold + enemy.gold_value)
	assert_eq(_game_state.enemies_killed, 1)


func test_remove_enemy_leaked() -> void:
	var enemy := _spawn_enemy()
	var initial_gold := _game_state.gold

	_game_state.remove_enemy(enemy, false)

	assert_eq(_game_state.enemies.size(), 0)
	assert_eq(_game_state.gold, initial_gold)
	assert_eq(_game_state.enemies_leaked, 1)


# ============================================
# damage_shrine() tests
# ============================================


func test_damage_shrine_reduces_hp() -> void:
	var initial_hp := _game_state.shrine.hp

	_game_state.damage_shrine(10)

	assert_eq(_game_state.shrine.hp, initial_hp - 10)


func test_damage_shrine_ends_game() -> void:
	_game_state.shrine.hp = 5
	_game_state.wave_in_progress = true

	_game_state.damage_shrine(10)

	assert_eq(_game_state.shrine.hp, 0)
	assert_false(_game_state.wave_in_progress)


# ============================================
# State query tests
# ============================================


func test_is_wave_complete_no_enemies() -> void:
	var data := TestHelpers.create_basic_enemy_data()
	_game_state.register_enemy_data(data)
	_game_state.start_wave(1)
	_game_state.spawn_queue.clear()
	_game_state.enemies.clear()

	assert_true(_game_state.is_wave_complete())


func test_is_wave_complete_enemies_remaining() -> void:
	var data := TestHelpers.create_basic_enemy_data()
	_game_state.register_enemy_data(data)
	_game_state.start_wave(1)
	_spawn_enemy()
	_game_state.spawn_queue.clear()

	assert_false(_game_state.is_wave_complete())


func test_is_game_over_shrine_destroyed() -> void:
	_game_state.shrine.hp = 0

	assert_true(_game_state.is_game_over())


func test_is_game_over_shrine_healthy() -> void:
	_game_state.shrine.hp = 50

	assert_false(_game_state.is_game_over())


func test_is_victory() -> void:
	var data := TestHelpers.create_basic_enemy_data()
	_game_state.register_enemy_data(data)
	_game_state.current_wave = _game_state.wave_data.get_total_waves()
	_game_state.wave_in_progress = true
	_game_state.spawn_queue.clear()
	_game_state.enemies.clear()

	assert_true(_game_state.is_victory())


# ============================================
# Upgrade tests
# ============================================


func test_can_upgrade_tower() -> void:
	_game_state.gold = 500
	var data := TestHelpers.create_basic_tower_data()
	var upgrade := TestHelpers.create_upgrade_data(2, "A")
	data.upgrades = [upgrade]
	_game_state.register_tower_data(data)

	var tower := _game_state.place_tower(Vector2i(5, 5), "archer")

	assert_true(_game_state.can_upgrade_tower(tower, "test_upgrade_2_A"))


func test_upgrade_tower_applies() -> void:
	_game_state.gold = 500
	var data := TestHelpers.create_basic_tower_data()
	var upgrade := TestHelpers.create_upgrade_data(2, "A")
	data.upgrades = [upgrade]
	_game_state.register_tower_data(data)

	var tower := _game_state.place_tower(Vector2i(5, 5), "archer")
	_game_state.upgrade_tower(tower, "test_upgrade_2_A")

	assert_eq(tower.tier, 2)


func test_upgrade_tower_deducts_gold() -> void:
	_game_state.gold = 500
	var data := TestHelpers.create_basic_tower_data()
	data.upgrade_cost_t2 = 60
	var upgrade := TestHelpers.create_upgrade_data(2, "A")
	data.upgrades = [upgrade]
	_game_state.register_tower_data(data)

	var tower := _game_state.place_tower(Vector2i(5, 5), "archer")
	var gold_after_place := _game_state.gold

	_game_state.upgrade_tower(tower, "test_upgrade_2_A")

	assert_eq(_game_state.gold, gold_after_place - 60)


# ============================================
# Economy wiring: wave bonuses + sell
# ============================================


func test_start_wave_resets_wave_economy_tracking() -> void:
	_game_state.wave_gold_earned = 50
	_game_state.wave_shrine_damaged = true
	_game_state.wave_seconds_early = 12.0

	_game_state.start_wave(1, 10.0)

	assert_eq(_game_state.wave_gold_earned, 0)
	assert_false(_game_state.wave_shrine_damaged)
	assert_eq(_game_state.wave_seconds_early, 10.0)


func test_remove_enemy_tracks_wave_gold_earned() -> void:
	var enemy := _spawn_enemy()

	_game_state.remove_enemy(enemy, true)

	assert_eq(_game_state.wave_gold_earned, enemy.gold_value)


func test_damage_shrine_marks_wave_damaged() -> void:
	_game_state.damage_shrine(1)

	assert_true(_game_state.wave_shrine_damaged)


func test_complete_wave_applies_perfect_wave_bonus() -> void:
	_game_state.wave_in_progress = true
	_game_state.current_wave = 1
	_game_state.wave_gold_earned = 100
	_game_state.wave_shrine_damaged = false
	_game_state.gold = 200
	var earned_before := _game_state.total_gold_earned

	_game_state.complete_wave()

	# 25% of 100 = 25
	assert_eq(_game_state.gold, 225)
	assert_eq(_game_state.total_gold_earned, earned_before + 25)


func test_complete_wave_skips_perfect_bonus_when_damaged() -> void:
	_game_state.wave_in_progress = true
	_game_state.current_wave = 1
	_game_state.wave_gold_earned = 100
	_game_state.wave_shrine_damaged = true
	_game_state.gold = 200

	_game_state.complete_wave()

	assert_eq(_game_state.gold, 200)


func test_complete_wave_applies_early_start_bonus() -> void:
	_game_state.wave_in_progress = true
	_game_state.current_wave = 1
	_game_state.wave_gold_earned = 100
	_game_state.wave_shrine_damaged = true
	_game_state.wave_seconds_early = 10.0
	_game_state.gold = 200

	_game_state.complete_wave()

	# 20% early (10s / 5s * 10%) of 100 = 20
	assert_eq(_game_state.gold, 220)


func test_complete_wave_applies_interest_when_unlocked() -> void:
	_game_state.balance_config.interest_unlocked = true
	_game_state.wave_in_progress = true
	_game_state.current_wave = 1
	_game_state.wave_gold_earned = 0
	_game_state.wave_shrine_damaged = true
	_game_state.gold = 200

	_game_state.complete_wave()

	# 5% of 200 = 10
	assert_eq(_game_state.gold, 210)


func test_complete_wave_skips_interest_when_locked() -> void:
	_game_state.balance_config.interest_unlocked = false
	_game_state.wave_in_progress = true
	_game_state.current_wave = 1
	_game_state.wave_gold_earned = 0
	_game_state.wave_shrine_damaged = true
	_game_state.gold = 200

	_game_state.complete_wave()

	assert_eq(_game_state.gold, 200)


func test_complete_wave_applies_bonus_then_interest() -> void:
	_game_state.balance_config.interest_unlocked = true
	_game_state.wave_in_progress = true
	_game_state.current_wave = 1
	_game_state.wave_gold_earned = 100
	_game_state.wave_shrine_damaged = false
	_game_state.gold = 200

	_game_state.complete_wave()

	# Perfect 25 -> gold 225; interest 5% of 225 = 11
	assert_eq(_game_state.gold, 236)


func test_sell_tower_refunds_gold_and_removes() -> void:
	_game_state.gold = 200
	var data := TestHelpers.create_basic_tower_data()
	data.base_cost = 100
	_game_state.register_tower_data(data)
	var tower := _game_state.place_tower(Vector2i(5, 5), "archer")
	var earned_before := _game_state.total_gold_earned

	var refund := _game_state.sell_tower(tower)

	assert_eq(refund, 90)
	assert_eq(_game_state.gold, 190)  # 200 - 100 + 90
	assert_eq(_game_state.towers.size(), 0)
	assert_eq(_game_state.total_gold_earned, earned_before)
	assert_false(_game_state.pathfinding.is_blocked(Vector2i(5, 5)))


func test_sell_tower_uses_balance_sell_rate() -> void:
	_game_state.balance_config.sell_rate_percent = 50
	_game_state.gold = 200
	var data := TestHelpers.create_basic_tower_data()
	data.base_cost = 100
	_game_state.register_tower_data(data)
	var tower := _game_state.place_tower(Vector2i(5, 5), "archer")

	var refund := _game_state.sell_tower(tower)

	assert_eq(refund, 50)
	assert_eq(_game_state.gold, 150)


func test_sell_tower_refuses_during_wave() -> void:
	_game_state.gold = 200
	var data := TestHelpers.create_basic_tower_data()
	_game_state.register_tower_data(data)
	var tower := _game_state.place_tower(Vector2i(5, 5), "archer")
	_game_state.wave_in_progress = true
	var gold_before := _game_state.gold

	var refund := _game_state.sell_tower(tower)

	assert_eq(refund, 0)
	assert_eq(_game_state.gold, gold_before)
	assert_eq(_game_state.towers.size(), 1)


func test_sell_tower_refuses_unknown_tower() -> void:
	var data := TestHelpers.create_basic_tower_data()
	var orphan := SimTower.new()
	orphan.initialize(data, Vector2i(5, 5))

	var refund := _game_state.sell_tower(orphan)

	assert_eq(refund, 0)


# ============================================
# Helpers
# ============================================


func _spawn_enemy() -> SimEnemy:
	var data := TestHelpers.create_basic_enemy_data()
	var enemy := SimEnemy.new()
	enemy.initialize(data, Vector2i(0, 10), _game_state.pathfinding)
	_game_state.enemies.append(enemy)
	return enemy
