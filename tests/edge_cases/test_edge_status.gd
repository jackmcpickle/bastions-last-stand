extends GutTest

## Edge case tests for status effects

var _pathfinding: SimPathfinding


func before_each() -> void:
	_pathfinding = TestHelpers.create_test_pathfinding()


# ============================================
# Multiple slows stacking
# ============================================


func test_multiple_slows_takes_strongest() -> void:
	var enemy := _create_enemy()

	enemy.apply_slow(300, 2000)  # 30% slow
	enemy.apply_slow(500, 1000)  # 50% slow (stronger)

	assert_eq(enemy.slow_amount, 500)


func test_multiple_slows_from_different_sources() -> void:
	var enemy := _create_enemy()

	# First slow
	enemy.apply_slow(400, 3000)

	# Second weaker slow
	enemy.apply_slow(200, 5000)

	# Should keep stronger
	assert_eq(enemy.slow_amount, 400)
	assert_eq(enemy.slow_duration_ms, 3000)


func test_slow_refresh_same_strength() -> void:
	var enemy := _create_enemy()

	enemy.apply_slow(400, 1000)
	enemy.apply_slow(400, 3000)  # Same strength, longer duration

	assert_eq(enemy.slow_amount, 400)
	assert_eq(enemy.slow_duration_ms, 3000)


func test_slow_no_refresh_shorter_duration() -> void:
	var enemy := _create_enemy()

	enemy.apply_slow(400, 3000)
	enemy.apply_slow(400, 1000)  # Same strength, shorter duration

	assert_eq(enemy.slow_duration_ms, 3000)  # Keeps longer


# ============================================
# Burn + regen interaction
# ============================================


func test_burn_and_regen_simultaneous() -> void:
	var data := TestHelpers.create_regen_enemy_data()
	data.special["regen_per_sec"] = 5000  # 5 hp/sec
	var enemy := SimEnemy.new()
	enemy.initialize(data, Vector2i.ZERO, _pathfinding)
	enemy.hp = 400

	# Apply burn stronger than regen
	enemy.apply_burn(20000, 5000)  # 20 dps

	enemy.process_status_effects(1000)

	# Net damage = 20 - 5 = 15 per second
	assert_lt(enemy.hp, 400)


func test_regen_stronger_than_burn() -> void:
	var data := TestHelpers.create_regen_enemy_data()
	data.special["regen_per_sec"] = 50000  # 50 hp/sec
	var enemy := SimEnemy.new()
	enemy.initialize(data, Vector2i.ZERO, _pathfinding)
	enemy.hp = 400

	enemy.apply_burn(10000, 5000)  # 10 dps

	enemy.process_status_effects(1000)

	# 50 regen vs 10 burn = net +40 HP/sec
	assert_gt(enemy.hp, 400, "Regen (50/s) should outpace burn (10/s)")


func test_burn_kills_before_regen() -> void:
	var data := TestHelpers.create_regen_enemy_data()
	var enemy := SimEnemy.new()
	enemy.initialize(data, Vector2i.ZERO, _pathfinding)
	enemy.hp = 10

	enemy.apply_burn(100000, 5000)  # Very high burn

	enemy.process_status_effects(1000)

	assert_true(enemy.is_dead())


# ============================================
# Stun during attack animation
# ============================================


func test_stun_prevents_movement() -> void:
	var enemy := _create_enemy()
	var start_pos := enemy.grid_pos

	enemy.apply_stun(5000)
	enemy.move(1000)

	assert_eq(enemy.grid_pos, start_pos)


func test_stun_wears_off_enemy_moves() -> void:
	var enemy := _create_enemy()
	enemy.apply_stun(500)

	# Process stun decay
	enemy.process_status_effects(600)

	assert_false(enemy.is_stunned)

	var start_pos := enemy.grid_pos
	enemy.move(1000)

	assert_ne(enemy.grid_pos, start_pos)


func test_stun_extended_during_stun() -> void:
	var enemy := _create_enemy()

	enemy.apply_stun(500)
	enemy.apply_stun(1500)  # Longer stun

	assert_eq(enemy.stun_duration_ms, 1500)


func test_stun_not_shortened() -> void:
	var enemy := _create_enemy()

	enemy.apply_stun(1500)
	enemy.apply_stun(500)  # Shorter stun

	assert_eq(enemy.stun_duration_ms, 1500)


# ============================================
# Effect expiry same tick as death
# ============================================


func test_burn_kills_same_tick_as_expiry() -> void:
	var enemy := _create_enemy()
	enemy.hp = 1

	enemy.apply_burn(10000, 100)  # Short burn

	enemy.process_status_effects(100)

	assert_true(enemy.is_dead())


func test_slow_expires_same_tick_enemy_dies() -> void:
	var enemy := _create_enemy()
	enemy.hp = 0  # Already dead
	enemy.apply_slow(500, 100)

	enemy.process_status_effects(100)

	assert_eq(enemy.slow_amount, 0)


func test_stun_expires_same_tick_enemy_dies() -> void:
	var enemy := _create_enemy()
	enemy.hp = 0
	enemy.apply_stun(100)

	enemy.process_status_effects(100)

	assert_false(enemy.is_stunned)


# ============================================
# Multiple effect interactions
# ============================================


func test_all_effects_simultaneously() -> void:
	var enemy := _create_enemy()
	enemy.hp = 100

	enemy.apply_slow(500, 2000)
	enemy.apply_burn(5000, 2000)
	enemy.apply_stun(500)

	assert_eq(enemy.slow_amount, 500)
	assert_eq(enemy.burn_dps, 5000)
	assert_true(enemy.is_stunned)

	enemy.process_status_effects(600)

	assert_false(enemy.is_stunned)  # Stun expired
	assert_gt(enemy.slow_amount, 0)  # Slow still active
	assert_gt(enemy.burn_dps, 0)  # Burn still active


func test_effects_decay_independently() -> void:
	var enemy := _create_enemy()

	enemy.apply_slow(500, 1000)
	enemy.apply_burn(5000, 2000)
	enemy.apply_stun(500)

	enemy.process_status_effects(1500)

	assert_eq(enemy.slow_amount, 0)  # Expired
	assert_gt(enemy.burn_dps, 0)  # Still active
	assert_false(enemy.is_stunned)  # Expired


# ============================================
# Zero/negative duration edge cases
# ============================================


func test_zero_duration_slow() -> void:
	var enemy := _create_enemy()

	enemy.apply_slow(500, 0)

	enemy.process_status_effects(1)

	assert_eq(enemy.slow_amount, 0)


func test_zero_duration_burn() -> void:
	var enemy := _create_enemy()

	enemy.apply_burn(10000, 0)

	enemy.process_status_effects(1)

	assert_eq(enemy.burn_dps, 0)


func test_zero_duration_stun() -> void:
	var enemy := _create_enemy()

	enemy.apply_stun(0)

	enemy.process_status_effects(1)

	assert_false(enemy.is_stunned)


# ============================================
# Very long durations
# ============================================


func test_very_long_slow() -> void:
	var enemy := _create_enemy()

	enemy.apply_slow(500, 1000000)  # Very long

	enemy.process_status_effects(100)

	assert_eq(enemy.slow_amount, 500)


func test_very_long_burn() -> void:
	var enemy := _create_enemy()
	enemy.hp = 1000

	enemy.apply_burn(1000, 1000000)  # 1 dps for very long

	enemy.process_status_effects(1000)  # 1 second to accumulate 1 HP damage

	assert_lt(enemy.hp, 1000)


# ============================================
# Status effects on special enemies
# ============================================


func test_slow_on_fast_enemy() -> void:
	var data := TestHelpers.create_fast_enemy_data()
	var enemy := SimEnemy.new()
	enemy.initialize(data, Vector2i(0, 10), _pathfinding)

	enemy.apply_slow(500, 2000)  # 50% slow

	var start_pos := enemy.grid_pos
	enemy.move(1000)

	# Should move half normal distance
	var expected_move := float(data.speed) / 1000.0 / 2.0  # Half speed
	var actual_move := enemy.grid_pos.x - start_pos.x
	assert_almost_eq(actual_move, expected_move, 0.1)


func test_burn_on_armored_enemy() -> void:
	var data := TestHelpers.create_armored_enemy_data(500)  # 50% armor
	var enemy := SimEnemy.new()
	enemy.initialize(data, Vector2i.ZERO, _pathfinding)
	var initial_hp := enemy.hp

	enemy.apply_burn(10000, 2000)  # 10 dps
	enemy.process_status_effects(1000)

	# Burn damage is reduced by armor
	assert_lt(enemy.hp, initial_hp)
	assert_gt(enemy.hp, initial_hp - 10)  # Less than full damage


func test_stun_on_boss_enemy() -> void:
	var data := TestHelpers.create_regen_enemy_data()
	var enemy := SimEnemy.new()
	enemy.initialize(data, Vector2i.ZERO, _pathfinding)

	enemy.apply_stun(1000)

	assert_true(enemy.is_stunned)


# ============================================
# Helpers
# ============================================


func _create_enemy() -> SimEnemy:
	var data := TestHelpers.create_basic_enemy_data()
	var enemy := SimEnemy.new()
	enemy.initialize(data, Vector2i(0, 10), _pathfinding)
	return enemy
