extends GutTest

## Unit tests for SimEnemy

var _pathfinding: SimPathfinding


func before_each() -> void:
	_pathfinding = TestHelpers.create_test_pathfinding()


# ============================================
# take_damage() tests
# ============================================


func test_take_damage_basic() -> void:
	var enemy := _create_enemy(100, 0)

	enemy.take_damage(10000)  # 10 damage (x1000)

	assert_eq(enemy.hp, 90)
	assert_eq(enemy.total_damage_taken, 10000)


func test_take_damage_with_armor_reduces_damage() -> void:
	var enemy := _create_enemy(100, 300)  # 30% armor

	enemy.take_damage(10000)  # 10 damage x 0.7 = 7

	assert_eq(enemy.hp, 93)
	assert_eq(enemy.total_damage_taken, 7000)


func test_take_damage_high_armor_absorbs_most() -> void:
	var enemy := _create_enemy(100, 900)  # 90% armor

	enemy.take_damage(100000)  # 100 damage x 0.1 = 10

	assert_eq(enemy.hp, 90)


func test_take_damage_max_armor_blocks_all() -> void:
	var enemy := _create_enemy(100, 1000)  # 100% armor

	enemy.take_damage(50000)

	assert_eq(enemy.hp, 100)  # No damage taken


func test_take_damage_reveals_stealth() -> void:
	var data := TestHelpers.create_stealth_enemy_data()
	var enemy := SimEnemy.new()
	enemy.initialize(data, Vector2i.ZERO, _pathfinding)

	assert_true(enemy.is_stealth)
	assert_false(enemy.is_revealed)

	enemy.take_damage(1000)

	assert_true(enemy.is_revealed)


func test_take_damage_kills_enemy() -> void:
	var enemy := _create_enemy(10, 0)

	enemy.take_damage(15000)

	assert_true(enemy.is_dead())
	assert_lt(enemy.hp, 1)


func test_take_damage_overkill() -> void:
	var enemy := _create_enemy(10, 0)

	enemy.take_damage(100000)  # Way more than hp

	assert_true(enemy.is_dead())


# ============================================
# move() tests
# ============================================


func test_move_follows_path() -> void:
	var enemy := _create_enemy_at_pos(Vector2(0, 10))

	enemy.move(1000)  # 1 second at speed 1000 (1 tile/sec)

	assert_almost_eq(enemy.grid_pos.x, 1.0, 0.01)
	assert_eq(enemy.grid_pos.y, 10.0)


func test_move_respects_speed() -> void:
	var data := TestHelpers.create_fast_enemy_data()
	var enemy := SimEnemy.new()
	enemy.initialize(data, Vector2i(0, 10), _pathfinding)

	enemy.move(1000)  # 1 second at speed 2000 (2 tiles/sec)

	assert_almost_eq(enemy.grid_pos.x, 2.0, 0.01)


func test_move_with_slow_reduces_speed() -> void:
	var enemy := _create_enemy_at_pos(Vector2(0, 10))
	enemy.apply_slow(500, 5000)  # 50% slow

	enemy.move(1000)  # 1 second at 50% speed = 0.5 tiles

	assert_almost_eq(enemy.grid_pos.x, 0.5, 0.01)


func test_move_stunned_doesnt_move() -> void:
	var enemy := _create_enemy_at_pos(Vector2(0, 10))
	enemy.apply_stun(5000)

	var start_pos := enemy.grid_pos

	enemy.move(1000)

	assert_eq(enemy.grid_pos, start_pos)


func test_move_tracks_distance() -> void:
	var enemy := _create_enemy_at_pos(Vector2(0, 10))

	enemy.move(2000)

	assert_almost_eq(enemy.distance_traveled, 2.0, 0.01)


func test_move_updates_path_progress() -> void:
	var enemy := _create_enemy_at_pos(Vector2(0, 10))

	enemy.move(5000)

	assert_gt(enemy.path_progress, 0.0)


func test_move_stops_at_shrine() -> void:
	var enemy := _create_enemy_at_pos(Vector2(18, 10))

	# Move enough to reach shrine
	for i in range(50):
		enemy.move(100)

	assert_true(enemy.has_reached_shrine())


# ============================================
# Status effects tests
# ============================================


func test_apply_slow_sets_effect() -> void:
	var enemy := _create_enemy(100, 0)

	enemy.apply_slow(300, 2000)

	assert_eq(enemy.slow_amount, 300)
	assert_eq(enemy.slow_duration_ms, 2000)


func test_apply_slow_stronger_overwrites() -> void:
	var enemy := _create_enemy(100, 0)
	enemy.apply_slow(200, 2000)

	enemy.apply_slow(400, 1000)

	assert_eq(enemy.slow_amount, 400)
	assert_eq(enemy.slow_duration_ms, 1000)


func test_apply_slow_weaker_ignored() -> void:
	var enemy := _create_enemy(100, 0)
	enemy.apply_slow(400, 2000)

	enemy.apply_slow(200, 3000)

	assert_eq(enemy.slow_amount, 400)
	assert_eq(enemy.slow_duration_ms, 2000)


func test_apply_slow_equal_refreshes_duration() -> void:
	var enemy := _create_enemy(100, 0)
	enemy.apply_slow(300, 1000)

	enemy.apply_slow(300, 3000)

	assert_eq(enemy.slow_amount, 300)
	assert_eq(enemy.slow_duration_ms, 3000)


func test_apply_burn_sets_effect() -> void:
	var enemy := _create_enemy(100, 0)

	enemy.apply_burn(5000, 3000)

	assert_eq(enemy.burn_dps, 5000)
	assert_eq(enemy.burn_duration_ms, 3000)


func test_apply_burn_stronger_overwrites() -> void:
	var enemy := _create_enemy(100, 0)
	enemy.apply_burn(3000, 2000)

	enemy.apply_burn(8000, 1500)

	assert_eq(enemy.burn_dps, 8000)


func test_apply_stun_sets_effect() -> void:
	var enemy := _create_enemy(100, 0)

	enemy.apply_stun(1000)

	assert_true(enemy.is_stunned)
	assert_eq(enemy.stun_duration_ms, 1000)


func test_apply_stun_extends_duration() -> void:
	var enemy := _create_enemy(100, 0)
	enemy.apply_stun(500)

	enemy.apply_stun(1500)

	assert_eq(enemy.stun_duration_ms, 1500)


# ============================================
# process_status_effects() tests
# ============================================


func test_process_status_burn_deals_damage() -> void:
	var enemy := _create_enemy(100, 0)
	enemy.apply_burn(10000, 3000)  # 10 dps

	enemy.process_status_effects(1000)  # 1 second = 10 damage

	assert_eq(enemy.hp, 90)


func test_process_status_burn_expires() -> void:
	var enemy := _create_enemy(100, 0)
	enemy.apply_burn(5000, 500)

	enemy.process_status_effects(600)

	assert_eq(enemy.burn_dps, 0)
	assert_eq(enemy.burn_duration_ms, 0)


func test_process_status_slow_decays() -> void:
	var enemy := _create_enemy(100, 0)
	enemy.apply_slow(300, 500)

	enemy.process_status_effects(600)

	assert_eq(enemy.slow_amount, 0)


func test_process_status_stun_decays() -> void:
	var enemy := _create_enemy(100, 0)
	enemy.apply_stun(500)

	enemy.process_status_effects(600)

	assert_false(enemy.is_stunned)


func test_process_status_regen_heals() -> void:
	var data := TestHelpers.create_regen_enemy_data()
	var enemy := SimEnemy.new()
	enemy.initialize(data, Vector2i.ZERO, _pathfinding)
	enemy.hp = 400  # Damaged

	enemy.process_status_effects(1000)

	assert_gt(enemy.hp, 400)


func test_process_status_regen_caps_at_max() -> void:
	var data := TestHelpers.create_regen_enemy_data()
	var enemy := SimEnemy.new()
	enemy.initialize(data, Vector2i.ZERO, _pathfinding)
	enemy.hp = enemy.max_hp - 1

	enemy.process_status_effects(10000)

	assert_eq(enemy.hp, enemy.max_hp)


# ============================================
# is_targetable() tests
# ============================================


func test_is_targetable_normal_enemy() -> void:
	var enemy := _create_enemy(100, 0)

	assert_true(enemy.is_targetable())


func test_is_targetable_stealth_hidden() -> void:
	var data := TestHelpers.create_stealth_enemy_data()
	var enemy := SimEnemy.new()
	enemy.initialize(data, Vector2i.ZERO, _pathfinding)

	assert_false(enemy.is_targetable())


func test_is_targetable_stealth_revealed() -> void:
	var data := TestHelpers.create_stealth_enemy_data()
	var enemy := SimEnemy.new()
	enemy.initialize(data, Vector2i.ZERO, _pathfinding)
	enemy.take_damage(1000)  # Reveals

	assert_true(enemy.is_targetable())


# ============================================
# Burn stacks tests
# ============================================


func test_apply_burn_with_stacks_accumulates() -> void:
	var enemy := _create_enemy(100, 0)

	enemy.apply_burn(5000, 3000, 5)  # max 5 stacks
	enemy.apply_burn(5000, 3000, 5)
	enemy.apply_burn(5000, 3000, 5)

	assert_eq(enemy.burn_stacks.size(), 3)


func test_burn_stacks_all_deal_damage() -> void:
	var enemy := _create_enemy(100, 0)
	enemy.apply_burn(10000, 3000, 5)  # 10 dps
	enemy.apply_burn(10000, 3000, 5)  # 10 dps
	# Total: 20 dps

	enemy.process_status_effects(1000)  # 1 second = 20 damage

	assert_eq(enemy.hp, 80)


func test_burn_stacks_expire_independently() -> void:
	var enemy := _create_enemy(100, 0)
	enemy.apply_burn(5000, 500, 5)  # Short duration
	enemy.apply_burn(5000, 3000, 5)  # Long duration

	enemy.process_status_effects(600)

	# First stack expired, second remains
	assert_eq(enemy.burn_stacks.size(), 1)


func test_burn_stacks_respects_max_limit() -> void:
	var enemy := _create_enemy(100, 0)

	for i in range(10):
		enemy.apply_burn(5000, 3000, 3)  # max 3 stacks

	assert_eq(enemy.burn_stacks.size(), 3)


func test_burn_stacks_refresh_weakest() -> void:
	var enemy := _create_enemy(100, 0)
	enemy.apply_burn(5000, 1000, 2)  # Weak (5000 dps * 1000ms = 5M value)
	enemy.apply_burn(10000, 2000, 2)  # Strong (10000 dps * 2000ms = 20M value)

	# Now at max, new burn should replace weakest
	enemy.apply_burn(8000, 3000, 2)  # Medium-strong

	# Should have replaced the weak one
	assert_eq(enemy.burn_stacks.size(), 2)
	var has_strong := false
	var has_medium := false
	for stack in enemy.burn_stacks:
		if stack.dps == 10000:
			has_strong = true
		if stack.dps == 8000:
			has_medium = true
	assert_true(has_strong)
	assert_true(has_medium)


# ============================================
# Disable flag tests
# ============================================


func test_is_disabled_prevents_regen() -> void:
	var data := TestHelpers.create_regen_enemy_data()
	var enemy := SimEnemy.new()
	enemy.initialize(data, Vector2i.ZERO, _pathfinding)
	enemy.hp = 400
	enemy.is_disabled = true

	enemy.process_status_effects(1000)

	# Should not regen when disabled
	assert_eq(enemy.hp, 400)


# ============================================
# Other tests
# ============================================


func test_is_dead() -> void:
	var enemy := _create_enemy(10, 0)

	assert_false(enemy.is_dead())

	enemy.hp = 0
	assert_true(enemy.is_dead())

	enemy.hp = -5
	assert_true(enemy.is_dead())


func test_get_current_tile() -> void:
	var enemy := _create_enemy(100, 0)
	enemy.grid_pos = Vector2(5.7, 3.2)

	var tile := enemy.get_current_tile()

	assert_eq(tile, Vector2i(6, 3))


func test_flying_enemy_direct_path() -> void:
	var data := TestHelpers.create_flying_enemy_data()
	var enemy := SimEnemy.new()
	enemy.initialize(data, Vector2i(0, 0), _pathfinding)

	# Flying enemies should have short direct path
	assert_eq(enemy.path.size(), 2)
	assert_eq(enemy.path[0], Vector2i(0, 0))
	assert_eq(enemy.path[1], _pathfinding.get_shrine_position())


# ============================================
# Helpers
# ============================================


func _create_enemy(hp: int, armor: int) -> SimEnemy:
	var data := TestHelpers.create_basic_enemy_data()
	data.hp = hp
	data.armor = armor
	var enemy := SimEnemy.new()
	enemy.initialize(data, Vector2i.ZERO, _pathfinding)
	return enemy


func _create_enemy_at_pos(pos: Vector2) -> SimEnemy:
	var data := TestHelpers.create_basic_enemy_data()
	var enemy := SimEnemy.new()
	enemy.initialize(data, Vector2i(pos), _pathfinding)
	enemy.grid_pos = pos
	return enemy
