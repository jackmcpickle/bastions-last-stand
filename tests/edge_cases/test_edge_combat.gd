extends GutTest

## Edge case tests for combat system

var _game_state: GameState
var _pathfinding: SimPathfinding


func before_each() -> void:
	_game_state = TestHelpers.create_test_game_state()
	_pathfinding = _game_state.pathfinding


# ============================================
# Zero/minimal damage edge cases
# ============================================

func test_zero_damage_with_full_armor() -> void:
	var enemy := _spawn_enemy_at(Vector2(10, 10))
	enemy.armor = 1000  # 100% armor
	enemy.hp = 100

	enemy.take_damage(50000)  # 50 damage

	assert_eq(enemy.hp, 100)  # No damage taken


func test_minimal_damage_with_high_armor() -> void:
	var enemy := _spawn_enemy_at(Vector2(10, 10))
	enemy.armor = 990  # 99% armor
	enemy.hp = 100

	enemy.take_damage(1000)  # 1 damage * 0.01 = 0.01 -> 0 hp damage

	assert_eq(enemy.hp, 100)  # Rounded to zero


func test_small_damage_accumulates() -> void:
	var enemy := _spawn_enemy_at(Vector2(10, 10))
	enemy.armor = 0
	enemy.hp = 100
	enemy.max_hp = 100

	# Many small hits
	for i in range(100):
		enemy.take_damage(1000)  # 1 damage each

	assert_eq(enemy.hp, 0)


# ============================================
# Overkill edge cases
# ============================================

func test_overkill_damage() -> void:
	var enemy := _spawn_enemy_at(Vector2(10, 10))
	enemy.hp = 10

	enemy.take_damage(1000000)  # Massive overkill

	assert_true(enemy.is_dead())
	assert_lt(enemy.hp, 0)


func test_overkill_still_counts_damage() -> void:
	var enemy := _spawn_enemy_at(Vector2(10, 10))
	enemy.hp = 10

	enemy.take_damage(1000000)

	# Damage tracking should still work
	assert_gt(enemy.total_damage_taken, 0)


# ============================================
# Simultaneous deaths
# ============================================

func test_multiple_enemies_die_same_tick() -> void:
	# Create multiple low-hp enemies
	for i in range(5):
		var enemy := _spawn_enemy_at(Vector2(10 + i * 0.1, 10))
		enemy.hp = 0
	var initial_count := _game_state.enemies.size()

	Combat.process_enemy_deaths(_game_state)

	assert_eq(_game_state.enemies.size(), 0)
	assert_eq(_game_state.enemies_killed, initial_count)


func test_gold_awarded_for_all_simultaneous_deaths() -> void:
	var initial_gold := _game_state.gold

	for i in range(3):
		var enemy := _spawn_enemy_at(Vector2(10 + i * 0.1, 10))
		enemy.hp = 0
		enemy.gold_value = 10

	Combat.process_enemy_deaths(_game_state)

	assert_eq(_game_state.gold, initial_gold + 30)


# ============================================
# AOE edge cases
# ============================================

func test_aoe_hitting_zero_enemies() -> void:
	var data := TestHelpers.create_aoe_tower_data()
	var tower := SimTower.new()
	tower.initialize(data, Vector2i(5, 5))

	var enemies: Array[SimEnemy] = []
	var target := _spawn_enemy_at(Vector2(6, 6))

	# AOE should still work even with only target
	var hit := tower.attack(target, enemies)

	assert_eq(hit.size(), 0)  # No enemies in AOE array


func test_aoe_target_not_in_aoe_list() -> void:
	var data := TestHelpers.create_aoe_tower_data()
	var tower := SimTower.new()
	tower.initialize(data, Vector2i(0, 0))

	var target := _spawn_enemy_at(Vector2(5, 5))
	var far_enemy := _spawn_enemy_at(Vector2(20, 20))

	var enemies: Array[SimEnemy] = [target, far_enemy]
	var hit := tower.attack(target, enemies)

	# Should hit target even if it's the only one
	assert_gt(hit.size(), 0)
	assert_has(hit, target)


func test_aoe_radius_zero() -> void:
	var data := TestHelpers.create_basic_tower_data()
	data.aoe_radius = 0  # Single target
	var tower := SimTower.new()
	tower.initialize(data, Vector2i(5, 5))

	var target := _spawn_enemy_at(Vector2(6, 6))
	var nearby := _spawn_enemy_at(Vector2(6.1, 6.1))
	var enemies: Array[SimEnemy] = [target, nearby]

	var hit := tower.attack(target, enemies)

	assert_eq(hit.size(), 1)
	assert_eq(hit[0], target)


# ============================================
# Chain attack edge cases
# ============================================

func test_chain_fewer_targets_than_chain_count() -> void:
	var data := TestHelpers.create_lightning_tower_data()
	data.special = {"chain": 10, "chain_range": 5.0}  # Want 10 chains
	var tower := SimTower.new()
	tower.initialize(data, Vector2i(0, 0))

	# Only 2 enemies
	var target := _spawn_enemy_at(Vector2(5, 5))
	var second := _spawn_enemy_at(Vector2(6, 6))
	var enemies: Array[SimEnemy] = [target, second]

	var hit := tower.attack(target, enemies)

	assert_eq(hit.size(), 2)


func test_chain_single_target() -> void:
	var data := TestHelpers.create_lightning_tower_data()
	var tower := SimTower.new()
	tower.initialize(data, Vector2i(0, 0))

	var target := _spawn_enemy_at(Vector2(5, 5))
	var enemies: Array[SimEnemy] = [target]

	var hit := tower.attack(target, enemies)

	assert_eq(hit.size(), 1)


func test_chain_targets_out_of_range() -> void:
	var data := TestHelpers.create_lightning_tower_data()
	data.special = {"chain": 4, "chain_range": 0.5}  # Very short chain range
	var tower := SimTower.new()
	tower.initialize(data, Vector2i(0, 0))

	var target := _spawn_enemy_at(Vector2(5, 5))
	var far := _spawn_enemy_at(Vector2(10, 10))  # Too far to chain
	var enemies: Array[SimEnemy] = [target, far]

	var hit := tower.attack(target, enemies)

	assert_eq(hit.size(), 1)


func test_chain_skips_stealth() -> void:
	var data := TestHelpers.create_lightning_tower_data()
	data.special = {"chain": 4, "chain_range": 5.0}
	var tower := SimTower.new()
	tower.initialize(data, Vector2i(0, 0))

	var target := _spawn_enemy_at(Vector2(5, 5))
	var stealth_data := TestHelpers.create_stealth_enemy_data()
	var stealth := SimEnemy.new()
	stealth.initialize(stealth_data, Vector2i(6, 6), _pathfinding)
	stealth.grid_pos = Vector2(6, 6)
	_game_state.enemies.append(stealth)

	var enemies: Array[SimEnemy] = [target, stealth]

	var hit := tower.attack(target, enemies)

	assert_eq(hit.size(), 1)
	assert_false(stealth in hit)


# ============================================
# Shrine damage edge cases
# ============================================

func test_enemy_leak_with_zero_shrine_hp() -> void:
	_game_state.shrine.hp = 0
	var enemy := _spawn_enemy_at(Vector2(19, 10))
	enemy.path_index = enemy.path.size()

	Combat.process_enemy_leaks(_game_state)

	assert_eq(_game_state.shrine.hp, 0)


func test_multiple_enemies_leak_same_tick() -> void:
	_game_state.shrine.hp = 10

	for i in range(3):
		var enemy := _spawn_enemy_at(Vector2(19, 10))
		enemy.path_index = enemy.path.size()

	Combat.process_enemy_leaks(_game_state)

	assert_lt(_game_state.shrine.hp, 10)


func test_boss_enemy_does_more_shrine_damage() -> void:
	_game_state.shrine.hp = 100
	var data := TestHelpers.create_basic_enemy_data()
	data.hp = 500  # High HP triggers scaling
	var enemy := _spawn_enemy_with_data(data, Vector2(19, 10))
	enemy.path_index = enemy.path.size()

	Combat.process_enemy_leaks(_game_state)

	# Should do more than base damage
	assert_lt(_game_state.shrine.hp, 99)


# ============================================
# Tower attack edge cases
# ============================================

func test_tower_attack_enemy_dies_before_attack() -> void:
	_game_state.gold = 500
	var tower := _place_tower(Vector2i(8, 8))
	var enemy := _spawn_enemy_at(Vector2(10, 10))
	enemy.hp = 0  # Already dead

	Combat.process_tower_attacks(_game_state, 100)

	# Should not crash, tower should find no valid target
	pass_test("No crash on dead enemy")


func test_tower_all_enemies_stealth() -> void:
	_game_state.gold = 500
	var tower := _place_tower(Vector2i(8, 8))
	var initial_shots := tower.shots_fired

	var stealth_data := TestHelpers.create_stealth_enemy_data()
	for i in range(3):
		var enemy := SimEnemy.new()
		enemy.initialize(stealth_data, Vector2i(10, 10), _pathfinding)
		enemy.grid_pos = Vector2(10 + i * 0.1, 10)
		_game_state.enemies.append(enemy)

	Combat.process_tower_attacks(_game_state, 100)

	assert_eq(tower.shots_fired, initial_shots)  # No shots fired


# ============================================
# Helpers
# ============================================

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


func _place_tower(pos: Vector2i) -> SimTower:
	var data := TestHelpers.create_basic_tower_data()
	_game_state.register_tower_data(data)
	_game_state.gold = 10000
	return _game_state.place_tower(pos, "archer")
