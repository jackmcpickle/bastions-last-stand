extends GutTest

## Unit tests for SimGroundEffect

var _pathfinding: SimPathfinding


func before_each() -> void:
	_pathfinding = TestHelpers.create_test_pathfinding()


# ============================================
# Ground effect damage tests
# ============================================


func test_ground_effect_damages_enemies_in_radius() -> void:
	var effect := _create_ground_effect(Vector2(10, 10), 2.0, 10000, 5000)
	var enemy := _create_enemy_at(Vector2(10, 10))
	var enemies: Array = [enemy]
	var initial_hp: int = enemy.hp

	# Process 500ms to reach first tick (next_tick_ms starts at 500)
	var damage := effect.process(500, enemies)

	assert_lt(enemy.hp, initial_hp)
	assert_gt(damage, 0)


func test_ground_effect_no_damage_outside_radius() -> void:
	var effect := _create_ground_effect(Vector2(10, 10), 1.0, 10000, 5000)
	var enemy := _create_enemy_at(Vector2(15, 15))  # Far away
	var enemies: Array = [enemy]
	var initial_hp: int = enemy.hp

	effect.process(500, enemies)
	effect.process(100, enemies)

	assert_eq(enemy.hp, initial_hp)


func test_ground_effect_ticks_at_interval() -> void:
	var effect := _create_ground_effect(Vector2(10, 10), 2.0, 10000, 5000)
	var enemies: Array = [_create_enemy_at(Vector2(10, 10))]

	# First call before tick interval - no damage
	var damage1 := effect.process(100, enemies)
	assert_eq(damage1, 0)

	# Second call after tick interval - damage
	var damage2 := effect.process(500, enemies)
	assert_gt(damage2, 0)


func test_ground_effect_expires_after_duration() -> void:
	var effect := _create_ground_effect(Vector2(10, 10), 2.0, 10000, 1000)

	effect.process(1100, [])

	assert_true(effect.is_expired())


func test_ground_effect_is_expired() -> void:
	var effect := _create_ground_effect(Vector2(10, 10), 2.0, 10000, 500)

	assert_false(effect.is_expired())

	effect.remaining_ms = 0
	assert_true(effect.is_expired())

	effect.remaining_ms = -100
	assert_true(effect.is_expired())


func test_ground_effect_damages_multiple_enemies() -> void:
	var effect := _create_ground_effect(Vector2(10, 10), 3.0, 10000, 5000)
	var e1 := _create_enemy_at(Vector2(10, 10))
	var e2 := _create_enemy_at(Vector2(11, 11))
	var e3 := _create_enemy_at(Vector2(9, 10))
	var enemies: Array = [e1, e2, e3]

	var initial_total: int = e1.hp + e2.hp + e3.hp

	# Wait for tick
	effect.process(500, enemies)
	effect.process(100, enemies)

	var final_total: int = e1.hp + e2.hp + e3.hp
	assert_lt(final_total, initial_total)


func test_ground_effect_calculates_damage_per_tick_from_dps() -> void:
	# 10000 DPS = 10 damage/sec = 5 damage per 500ms tick
	var effect := _create_ground_effect(Vector2(10, 10), 2.0, 10000, 5000)

	# damage_per_tick = dps * tick_interval_ms / 1000
	# 10000 * 500 / 1000 = 5000
	assert_eq(effect.damage_per_tick, 5000)


func test_ground_effect_multiple_ticks() -> void:
	var effect := _create_ground_effect(Vector2(10, 10), 2.0, 20000, 5000)  # 20 dps
	var enemy := _create_enemy_at(Vector2(10, 10))
	var enemies: Array = [enemy]
	var initial_hp: int = enemy.hp

	# Process 3 tick intervals
	effect.process(500, enemies)  # First tick
	effect.process(500, enemies)  # Second tick
	effect.process(500, enemies)  # Third tick

	# 20 dps * 500ms * 3 ticks = 30 damage (x1000 = 30000)
	# Each tick = 10000 damage_per_tick -> 10 HP
	assert_eq(enemy.hp, initial_hp - 30)


# ============================================
# Helpers
# ============================================


func _create_ground_effect(
	pos: Vector2, radius: float, dps: int, duration_ms: int
) -> SimGroundEffect:
	return SimGroundEffect.new(pos, radius, dps, duration_ms)


func _create_enemy_at(pos: Vector2) -> SimEnemy:
	var data := TestHelpers.create_basic_enemy_data()
	var enemy := SimEnemy.new()
	enemy.initialize(data, Vector2i(pos), _pathfinding)
	enemy.grid_pos = pos
	return enemy
