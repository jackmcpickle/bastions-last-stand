extends GutTest

## Unit tests for Combat system

var _game_state: GameState
var _pathfinding: SimPathfinding


func before_each() -> void:
	_game_state = TestHelpers.create_test_game_state()
	_pathfinding = _game_state.pathfinding


# ============================================
# process_tower_attacks() tests
# ============================================


func test_tower_attacks_enemy_in_range() -> void:
	var tower := _place_tower(Vector2i(8, 8))
	var enemy := _spawn_enemy_at(Vector2(10, 10))
	var initial_hp := enemy.hp

	Combat.process_tower_attacks(_game_state, 100)

	assert_lt(enemy.hp, initial_hp)


func test_tower_no_attack_on_cooldown() -> void:
	var tower := _place_tower(Vector2i(8, 8))
	tower.cooldown_ms = 1000
	var enemy := _spawn_enemy_at(Vector2(10, 10))
	var initial_hp := enemy.hp

	Combat.process_tower_attacks(_game_state, 100)

	assert_eq(enemy.hp, initial_hp)


func test_tower_no_attack_out_of_range() -> void:
	var tower := _place_tower(Vector2i(0, 0))
	tower.range_tiles = 2
	var enemy := _spawn_enemy_at(Vector2(15, 15))
	var initial_hp := enemy.hp

	Combat.process_tower_attacks(_game_state, 100)

	assert_eq(enemy.hp, initial_hp)


func test_tower_tracks_damage_dealt() -> void:
	var tower := _place_tower(Vector2i(8, 8))
	_spawn_enemy_at(Vector2(10, 10))

	Combat.process_tower_attacks(_game_state, 100)

	assert_gt(tower.total_damage_dealt, 0)


func test_tower_records_kill() -> void:
	var tower := _place_tower(Vector2i(8, 8))
	tower.damage = 200000  # Massive damage
	var data := TestHelpers.create_basic_enemy_data()
	data.hp = 10  # Low hp
	var enemy := _spawn_enemy_with_data(data, Vector2(10, 10))

	Combat.process_tower_attacks(_game_state, 100)

	assert_eq(tower.kills, 1)


func test_multiple_towers_attack() -> void:
	var tower1 := _place_tower(Vector2i(6, 6))
	var tower2 := _place_tower(Vector2i(10, 6))
	var enemy := _spawn_enemy_at(Vector2(8, 8))
	var initial_hp := enemy.hp

	Combat.process_tower_attacks(_game_state, 100)

	# Both towers should attack
	assert_lt(enemy.hp, initial_hp - tower1.damage / 1000)


func test_tower_cannot_target_stealth() -> void:
	var tower := _place_tower(Vector2i(8, 8))
	var data := TestHelpers.create_stealth_enemy_data()
	var enemy := _spawn_enemy_with_data(data, Vector2(10, 10))
	var initial_hp := enemy.hp

	Combat.process_tower_attacks(_game_state, 100)

	assert_eq(enemy.hp, initial_hp)


func test_tower_targets_revealed_stealth() -> void:
	var tower := _place_tower(Vector2i(8, 8))
	var data := TestHelpers.create_stealth_enemy_data()
	var enemy := _spawn_enemy_with_data(data, Vector2(10, 10))
	enemy.is_revealed = true
	var initial_hp := enemy.hp

	Combat.process_tower_attacks(_game_state, 100)

	assert_lt(enemy.hp, initial_hp)


# ============================================
# _apply_tower_effects() tests
# ============================================


func test_apply_slow_effect() -> void:
	var tower := _create_tower_with_special({"slow": 400, "slow_duration_ms": 2000})
	var enemy := _spawn_enemy_at(Vector2(10, 10))

	Combat._apply_tower_effects(tower, enemy, _game_state)

	assert_eq(enemy.slow_amount, 400)
	assert_eq(enemy.slow_duration_ms, 2000)


func test_apply_burn_effect() -> void:
	var tower := _create_tower_with_special({"burn_dps": 8000, "burn_duration_ms": 3000})
	var enemy := _spawn_enemy_at(Vector2(10, 10))

	Combat._apply_tower_effects(tower, enemy, _game_state)

	assert_eq(enemy.burn_dps, 8000)
	assert_eq(enemy.burn_duration_ms, 3000)


func test_apply_stun_effect_probabilistic() -> void:
	# 100% chance
	var tower := _create_tower_with_special({"stun_chance": 1000, "stun_duration_ms": 500})
	var enemy := _spawn_enemy_at(Vector2(10, 10))

	Combat._apply_tower_effects(tower, enemy, _game_state)

	assert_true(enemy.is_stunned)
	assert_eq(enemy.stun_duration_ms, 500)


func test_no_stun_when_unlucky() -> void:
	var tower := _create_tower_with_special({"stun_chance": 0, "stun_duration_ms": 500})  # 0% chance
	var enemy := _spawn_enemy_at(Vector2(10, 10))

	Combat._apply_tower_effects(tower, enemy, _game_state)

	assert_false(enemy.is_stunned)


# ============================================
# process_enemy_deaths() tests
# ============================================


func test_process_deaths_removes_dead_enemy() -> void:
	var enemy := _spawn_enemy_at(Vector2(10, 10))
	enemy.hp = 0

	Combat.process_enemy_deaths(_game_state)

	assert_eq(_game_state.enemies.size(), 0)


func test_process_deaths_awards_gold() -> void:
	var enemy := _spawn_enemy_at(Vector2(10, 10))
	enemy.hp = 0
	var initial_gold := _game_state.gold

	Combat.process_enemy_deaths(_game_state)

	assert_eq(_game_state.gold, initial_gold + enemy.gold_value)


func test_process_deaths_increments_kill_count() -> void:
	var enemy := _spawn_enemy_at(Vector2(10, 10))
	enemy.hp = 0

	Combat.process_enemy_deaths(_game_state)

	assert_eq(_game_state.enemies_killed, 1)


func test_process_deaths_leaves_alive_enemies() -> void:
	var alive := _spawn_enemy_at(Vector2(10, 10))
	var dead := _spawn_enemy_at(Vector2(12, 12))
	dead.hp = 0

	Combat.process_enemy_deaths(_game_state)

	assert_eq(_game_state.enemies.size(), 1)
	assert_eq(_game_state.enemies[0], alive)


# ============================================
# process_enemy_leaks() tests
# ============================================


func test_process_leaks_damages_shrine() -> void:
	var enemy := _spawn_enemy_at(Vector2(19, 10))
	enemy.path_index = enemy.path.size()  # At end of path
	var initial_hp := _game_state.shrine.hp

	Combat.process_enemy_leaks(_game_state)

	assert_lt(_game_state.shrine.hp, initial_hp)


func test_process_leaks_removes_enemy() -> void:
	var enemy := _spawn_enemy_at(Vector2(19, 10))
	enemy.path_index = enemy.path.size()

	Combat.process_enemy_leaks(_game_state)

	assert_eq(_game_state.enemies.size(), 0)


func test_process_leaks_increments_leak_count() -> void:
	var enemy := _spawn_enemy_at(Vector2(19, 10))
	enemy.path_index = enemy.path.size()

	Combat.process_enemy_leaks(_game_state)

	assert_eq(_game_state.enemies_leaked, 1)


func test_process_leaks_no_gold_awarded() -> void:
	var enemy := _spawn_enemy_at(Vector2(19, 10))
	enemy.path_index = enemy.path.size()
	var initial_gold := _game_state.gold

	Combat.process_enemy_leaks(_game_state)

	assert_eq(_game_state.gold, initial_gold)


func test_process_leaks_scaled_damage_for_boss() -> void:
	var data := TestHelpers.create_basic_enemy_data()
	data.hp = 500  # High HP triggers scaling
	var enemy := _spawn_enemy_with_data(data, Vector2(19, 10))
	enemy.path_index = enemy.path.size()
	var initial_hp := _game_state.shrine.hp

	Combat.process_enemy_leaks(_game_state)

	# Should do more than 1 damage
	assert_lt(_game_state.shrine.hp, initial_hp - 1)


# ============================================
# process_siege_attacks() tests
# ============================================


func test_siege_enemy_with_no_path_damages_nearest_wall() -> void:
	var wall := SimWall.new()
	wall.position = Vector2i(5, 10)
	wall.hp = 100
	wall.max_hp = 100
	_game_state.walls.append(wall)

	var enemy := _spawn_enemy_at(Vector2(4, 10))
	enemy.path.clear()

	Combat.process_siege_attacks(_game_state, 100)

	assert_lt(wall.hp, 100)


func test_siege_destroys_wall_and_unblocks() -> void:
	var wall := SimWall.new()
	wall.position = Vector2i(5, 10)
	wall.hp = 5
	wall.max_hp = 100
	_game_state.walls.append(wall)
	_pathfinding.set_blocked(wall.position, true)

	var enemy := _spawn_enemy_at(Vector2(4, 10))
	enemy.path.clear()

	Combat.process_siege_attacks(_game_state, 100)

	assert_false(_game_state.walls.has(wall))
	assert_false(_pathfinding.is_blocked(Vector2i(5, 10)))


func test_siege_destroy_repaths_ground_enemies() -> void:
	# Block a full column so path is empty, leave one weak wall as the only gap filler
	for y in range(20):
		_pathfinding.set_blocked(Vector2i(10, y), true)

	var wall := SimWall.new()
	wall.position = Vector2i(10, 10)
	wall.hp = 5
	wall.max_hp = 100
	_game_state.walls.append(wall)

	var enemy := _spawn_enemy_at(Vector2(0, 10))
	enemy.path.clear()

	Combat.process_siege_attacks(_game_state, 100)

	assert_false(enemy.path.is_empty())
	assert_eq(enemy.path[-1], _pathfinding.get_shrine_position())


func test_siege_enemy_with_no_path_damages_nearest_tower() -> void:
	var tower := _place_tower(Vector2i(5, 9))
	var initial_hp := tower.hp

	var enemy := _spawn_enemy_at(Vector2(4, 10))
	enemy.path.clear()

	Combat.process_siege_attacks(_game_state, 100)

	assert_lt(tower.hp, initial_hp)


func test_siege_prefers_closer_structure_between_wall_and_tower() -> void:
	# Tower center at (4, 10) is on the enemy; wall is farther away
	var tower := _place_tower(Vector2i(3, 9))
	var wall := SimWall.new()
	wall.position = Vector2i(8, 10)
	wall.hp = 100
	wall.max_hp = 100
	_game_state.walls.append(wall)

	var enemy := _spawn_enemy_at(Vector2(4, 10))
	enemy.path.clear()

	Combat.process_siege_attacks(_game_state, 100)

	assert_lt(tower.hp, tower.max_hp)
	assert_eq(wall.hp, 100)


func test_siege_destroys_tower_and_unblocks_2x2() -> void:
	var tower := _place_tower(Vector2i(5, 9))
	tower.hp = 5

	var enemy := _spawn_enemy_at(Vector2(4, 10))
	enemy.path.clear()

	Combat.process_siege_attacks(_game_state, 100)

	assert_false(_game_state.towers.has(tower))
	assert_false(_pathfinding.is_blocked(Vector2i(5, 9)))
	assert_false(_pathfinding.is_blocked(Vector2i(6, 9)))
	assert_false(_pathfinding.is_blocked(Vector2i(5, 10)))
	assert_false(_pathfinding.is_blocked(Vector2i(6, 10)))


func test_wall_breaker_keeps_direct_path_after_destroying_wall() -> void:
	var wall := SimWall.new()
	wall.position = Vector2i(5, 10)
	wall.hp = 5
	wall.max_hp = 100
	_game_state.walls.append(wall)
	_pathfinding.set_blocked(wall.position, true)

	var data := TestHelpers.create_wall_breaker_enemy_data()
	var breaker := SimEnemy.new()
	breaker.initialize(data, Vector2i(4, 10), _pathfinding)
	breaker.grid_pos = Vector2(4, 10)
	_game_state.enemies.append(breaker)

	var shrine := _pathfinding.get_shrine_position()
	assert_eq(breaker.path.size(), 2)

	Combat.process_wall_breaker_attacks(_game_state, 100)

	assert_eq(breaker.path.size(), 2)
	assert_eq(breaker.path[0], Vector2i(4, 10))
	assert_eq(breaker.path[1], shrine)


# ============================================
# process_status_effects() tests
# ============================================


func test_process_status_effects_applies_burn() -> void:
	var enemy := _spawn_enemy_at(Vector2(10, 10))
	enemy.apply_burn(10000, 2000)
	var initial_hp := enemy.hp

	Combat.process_status_effects(_game_state, 1000)

	assert_lt(enemy.hp, initial_hp)


func test_process_status_effects_multiple_enemies() -> void:
	var enemy1 := _spawn_enemy_at(Vector2(5, 5))
	var enemy2 := _spawn_enemy_at(Vector2(10, 10))
	enemy1.apply_burn(10000, 2000)
	enemy2.apply_burn(10000, 2000)
	var hp1 := enemy1.hp
	var hp2 := enemy2.hp

	Combat.process_status_effects(_game_state, 1000)

	assert_lt(enemy1.hp, hp1)
	assert_lt(enemy2.hp, hp2)


# ============================================
# Helpers
# ============================================


func _place_tower(pos: Vector2i) -> SimTower:
	_game_state.gold = 10000
	var data := TestHelpers.create_basic_tower_data()
	_game_state.register_tower_data(data)
	return _game_state.place_tower(pos, "archer")


func _create_tower_with_special(special: Dictionary) -> SimTower:
	var data := TestHelpers.create_basic_tower_data()
	data.special = special
	var tower := SimTower.new()
	tower.initialize(data, Vector2i(5, 5))
	return tower


func _spawn_enemy_at(pos: Vector2) -> SimEnemy:
	var data := TestHelpers.create_basic_enemy_data()
	var enemy := SimEnemy.new()
	enemy.initialize(data, Vector2i(pos), _pathfinding)
	enemy.grid_pos = pos
	_game_state.enemies.append(enemy)
	return enemy


func _spawn_enemy_with_data(data: EnemyData, pos: Vector2) -> SimEnemy:
	var enemy := SimEnemy.new()
	enemy.initialize(data, Vector2i(pos), _pathfinding)
	enemy.grid_pos = pos
	_game_state.enemies.append(enemy)
	return enemy
