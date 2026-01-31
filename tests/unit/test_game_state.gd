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
# Helpers
# ============================================

func _spawn_enemy() -> SimEnemy:
	var data := TestHelpers.create_basic_enemy_data()
	var enemy := SimEnemy.new()
	enemy.initialize(data, Vector2i(0, 10), _game_state.pathfinding)
	_game_state.enemies.append(enemy)
	return enemy
