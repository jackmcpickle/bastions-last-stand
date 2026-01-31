extends GutTest

## Tests for boss enemy abilities

const CombatClass = preload("res://simulation/systems/combat.gd")

var _game_state: GameState


func before_each() -> void:
	_game_state = TestHelpers.create_test_game_state()
	_game_state.register_enemy_data(TestHelpers.create_swarm_queen_data())
	_game_state.register_enemy_data(TestHelpers.create_swarm_enemy_data())
	_game_state.register_enemy_data(TestHelpers.create_cc_immune_enemy_data())


# ============================================
# Swarm Queen tests
# ============================================

func test_swarm_queen_spawns_enemy() -> void:
	var queen_data := TestHelpers.create_swarm_queen_data()
	var queen := SimEnemy.new()
	queen.initialize(queen_data, Vector2i(5, 10), _game_state.pathfinding)
	_game_state.enemies.append(queen)

	# Process enough time to trigger spawn
	queen.spawn_timer_ms = 100  # Set low for test
	CombatClass.process_boss_abilities(_game_state, 200)

	assert_eq(_game_state.enemies.size(), 2)
	assert_eq(queen.spawns_remaining, 4)


func test_swarm_queen_spawn_limit() -> void:
	var queen_data := TestHelpers.create_swarm_queen_data()
	var queen := SimEnemy.new()
	queen.initialize(queen_data, Vector2i(5, 10), _game_state.pathfinding)
	queen.spawns_remaining = 0  # Exhausted
	_game_state.enemies.append(queen)

	queen.spawn_timer_ms = 0
	CombatClass.process_boss_abilities(_game_state, 100)

	assert_eq(_game_state.enemies.size(), 1)  # Only queen


func test_swarm_queen_stunned_no_spawn() -> void:
	var queen_data := TestHelpers.create_swarm_queen_data()
	var queen := SimEnemy.new()
	queen.initialize(queen_data, Vector2i(5, 10), _game_state.pathfinding)
	queen.is_stunned = true
	queen.spawn_timer_ms = 0
	_game_state.enemies.append(queen)

	CombatClass.process_boss_abilities(_game_state, 100)

	assert_eq(_game_state.enemies.size(), 1)


# ============================================
# CC Immune tests
# ============================================

func test_cc_immune_ignores_slow() -> void:
	var colossus_data := TestHelpers.create_cc_immune_enemy_data()
	var colossus := SimEnemy.new()
	colossus.initialize(colossus_data, Vector2i(5, 10), _game_state.pathfinding)

	colossus.apply_slow(500, 5000)

	assert_eq(colossus.slow_amount, 0)


func test_cc_immune_ignores_stun() -> void:
	var colossus_data := TestHelpers.create_cc_immune_enemy_data()
	var colossus := SimEnemy.new()
	colossus.initialize(colossus_data, Vector2i(5, 10), _game_state.pathfinding)

	colossus.apply_stun(5000)

	assert_false(colossus.is_stunned)


func test_cc_immune_takes_damage() -> void:
	var colossus_data := TestHelpers.create_cc_immune_enemy_data()
	var colossus := SimEnemy.new()
	colossus.initialize(colossus_data, Vector2i(5, 10), _game_state.pathfinding)

	var initial_hp := colossus.hp
	colossus.take_damage(100000)

	assert_lt(colossus.hp, initial_hp)


# ============================================
# Tower freeze tests
# ============================================

func test_frost_wyrm_freezes_towers() -> void:
	# Create tower
	var tower_data := TestHelpers.create_basic_tower_data()
	var tower := _game_state.place_tower(Vector2i(5, 8), "archer")
	assert_not_null(tower)

	# Create frost wyrm enemy
	var wyrm_data := EnemyData.new()
	wyrm_data.id = "frost_wyrm"
	wyrm_data.hp = 1200
	wyrm_data.speed = 800
	wyrm_data.special = {"freeze_towers_range": 4, "freeze_duration_ms": 3000, "freeze_interval_ms": 8000}
	wyrm_data.is_boss = true
	_game_state.register_enemy_data(wyrm_data)

	var wyrm := SimEnemy.new()
	wyrm.initialize(wyrm_data, Vector2i(5, 10), _game_state.pathfinding)
	wyrm.freeze_timer_ms = 0  # Ready to freeze
	_game_state.enemies.append(wyrm)

	CombatClass.process_boss_abilities(_game_state, 100)

	assert_eq(tower.frozen_ms, 3000)


func test_frozen_tower_cannot_attack() -> void:
	var tower_data := TestHelpers.create_basic_tower_data()
	var tower := SimTower.new()
	tower.initialize(tower_data, Vector2i(5, 8))
	tower.frozen_ms = 1000

	assert_false(tower.can_attack())


func test_frozen_tower_thaws_over_time() -> void:
	var tower_data := TestHelpers.create_basic_tower_data()
	var tower := SimTower.new()
	tower.initialize(tower_data, Vector2i(5, 8))
	tower.frozen_ms = 500

	tower.process_cooldown(600)

	assert_eq(tower.frozen_ms, 0)
	assert_true(tower.can_attack())


# ============================================
# Dead enemy tracking tests
# ============================================

func test_dead_enemy_tracked() -> void:
	var enemy_data := TestHelpers.create_basic_enemy_data()
	var enemy := SimEnemy.new()
	enemy.initialize(enemy_data, Vector2i(5, 10), _game_state.pathfinding)
	enemy.hp = 1
	_game_state.enemies.append(enemy)

	enemy.take_damage(10000)
	CombatClass.process_enemy_deaths(_game_state)

	assert_eq(_game_state.dead_enemies.size(), 1)
	assert_eq(_game_state.dead_enemies[0].id, "grunt")


func test_mini_enemy_not_tracked() -> void:
	_game_state.register_enemy_data(TestHelpers.create_mini_enemy_data())

	var mini_data := TestHelpers.create_mini_enemy_data()
	var mini := SimEnemy.new()
	mini.initialize(mini_data, Vector2i(5, 10), _game_state.pathfinding)
	mini.hp = 1
	_game_state.enemies.append(mini)

	mini.take_damage(10000)
	CombatClass.process_enemy_deaths(_game_state)

	assert_eq(_game_state.dead_enemies.size(), 0)


func test_boss_not_tracked_for_resurrection() -> void:
	var queen_data := TestHelpers.create_swarm_queen_data()
	var queen := SimEnemy.new()
	queen.initialize(queen_data, Vector2i(5, 10), _game_state.pathfinding)
	queen.hp = 1
	_game_state.enemies.append(queen)

	queen.take_damage(100000000)
	CombatClass.process_enemy_deaths(_game_state)

	assert_eq(_game_state.dead_enemies.size(), 0)
