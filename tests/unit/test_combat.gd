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

	Combat._apply_tower_effects(tower, enemy, _game_state.rng)

	assert_eq(enemy.slow_amount, 400)
	assert_eq(enemy.slow_duration_ms, 2000)


func test_apply_burn_effect() -> void:
	var tower := _create_tower_with_special({"burn_dps": 8000, "burn_duration_ms": 3000})
	var enemy := _spawn_enemy_at(Vector2(10, 10))

	Combat._apply_tower_effects(tower, enemy, _game_state.rng)

	assert_eq(enemy.burn_dps, 8000)
	assert_eq(enemy.burn_duration_ms, 3000)


func test_apply_stun_effect_probabilistic() -> void:
	var tower := _create_tower_with_special({"stun_chance": 1000, "stun_duration_ms": 500})  # 100% chance
	var enemy := _spawn_enemy_at(Vector2(10, 10))

	Combat._apply_tower_effects(tower, enemy, _game_state.rng)

	assert_true(enemy.is_stunned)
	assert_eq(enemy.stun_duration_ms, 500)


func test_no_stun_when_unlucky() -> void:
	var tower := _create_tower_with_special({"stun_chance": 0, "stun_duration_ms": 500})  # 0% chance
	var enemy := _spawn_enemy_at(Vector2(10, 10))

	Combat._apply_tower_effects(tower, enemy, _game_state.rng)

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
