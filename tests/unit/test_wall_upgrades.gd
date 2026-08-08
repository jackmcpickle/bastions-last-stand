extends GutTest

## Unit tests for wall upgrade tree and specials

const WALL_PATH := "res://resources/walls/basic_wall.tres"

var _game_state: GameState
var _pathfinding: SimPathfinding
var _wall_data: WallData


func before_each() -> void:
	_game_state = TestHelpers.create_test_game_state()
	_pathfinding = _game_state.pathfinding
	_wall_data = load(WALL_PATH) as WallData
	_game_state.register_wall_data(_wall_data)


# ============================================
# Resource / upgrade path
# ============================================


func test_wall_resource_loads_full_tree() -> void:
	assert_not_null(_wall_data)
	assert_eq(_wall_data.id, "wall")
	assert_eq(_wall_data.upgrades.size(), 6)
	assert_eq(_wall_data.upgrade_cost_t2, 40)
	assert_eq(_wall_data.upgrade_cost_t3, 80)


func test_place_wall_uses_wall_data_hp() -> void:
	var wall := _game_state.place_wall(Vector2i(5, 5))
	assert_not_null(wall)
	assert_eq(wall.hp, 100)
	assert_eq(wall.max_hp, 100)
	assert_eq(wall.tier, 1)
	assert_not_null(wall.data)


func test_upgrade_wall_to_reinforced() -> void:
	var wall := _game_state.place_wall(Vector2i(5, 5))
	_game_state.gold = 100

	assert_true(_game_state.can_upgrade_wall(wall, "wall_reinforced"))
	assert_true(_game_state.upgrade_wall(wall, "wall_reinforced"))
	assert_eq(wall.tier, 2)
	assert_eq(wall.branch, "A")
	assert_eq(wall.max_hp, 250)
	assert_eq(wall.special.get("self_repair", 0), 5)
	assert_eq(_game_state.gold, 60)  # 100 - 40


func test_upgrade_wall_keeps_current_hp() -> void:
	var wall := _game_state.place_wall(Vector2i(5, 5))
	wall.hp = 40
	_game_state.gold = 100

	_game_state.upgrade_wall(wall, "wall_reinforced")

	assert_eq(wall.max_hp, 250)
	assert_eq(wall.hp, 40)


func test_cannot_upgrade_to_wrong_branch_t3() -> void:
	var wall := _game_state.place_wall(Vector2i(5, 5))
	_game_state.gold = 200
	_game_state.upgrade_wall(wall, "wall_reinforced")

	assert_false(_game_state.can_upgrade_wall(wall, "wall_shock"))
	assert_true(_game_state.can_upgrade_wall(wall, "wall_fortress"))


func test_fortress_upgrade_path() -> void:
	var wall := _game_state.place_wall(Vector2i(5, 5))
	_game_state.gold = 200
	_game_state.upgrade_wall(wall, "wall_reinforced")
	_game_state.upgrade_wall(wall, "wall_fortress")

	assert_eq(wall.tier, 3)
	assert_eq(wall.max_hp, 500)
	assert_eq(wall.special.get("self_repair", 0), 10)
	assert_false(wall.special.get("repair_out_of_combat", true))


# ============================================
# Self-repair
# ============================================


func test_reinforced_repairs_out_of_combat() -> void:
	var wall := _place_upgraded("wall_reinforced")
	wall.hp = 100
	wall.max_hp = 250
	wall.combat_idle_ms = 3000

	Combat.process_wall_effects(_game_state, 1000)

	assert_eq(wall.hp, 105)


func test_reinforced_does_not_repair_in_combat() -> void:
	var wall := _place_upgraded("wall_reinforced")
	wall.hp = 100
	wall.max_hp = 250
	wall.combat_idle_ms = 0

	Combat.process_wall_effects(_game_state, 1000)

	assert_eq(wall.hp, 100)


func test_fortress_repairs_in_combat() -> void:
	var wall := _place_upgraded("wall_reinforced")
	_game_state.gold = 200
	_game_state.upgrade_wall(wall, "wall_fortress")
	wall.hp = 100
	wall.combat_idle_ms = 0

	Combat.process_wall_effects(_game_state, 1000)

	assert_eq(wall.hp, 110)


func test_repair_does_not_exceed_max_hp() -> void:
	var wall := _place_upgraded("wall_reinforced")
	wall.hp = 248
	wall.max_hp = 250
	wall.combat_idle_ms = 5000

	Combat.process_wall_effects(_game_state, 1000)

	assert_eq(wall.hp, 250)


# ============================================
# Thorns / stun on hit
# ============================================


func test_thorned_reflects_damage_to_attacker() -> void:
	var wall := _place_upgraded("wall_reinforced")
	_game_state.gold = 200
	_game_state.upgrade_wall(wall, "wall_thorned")
	wall.hp = 300

	# Unarmored attacker so reflect math is exact
	var enemy := _spawn_enemy_at(Vector2(5, 5))
	enemy.hp = 100
	var enemy_hp_before := enemy.hp

	Combat._damage_wall(wall, 10, enemy, _game_state)

	# 20% of 10 = 2 HP => 2000 x1000 damage
	assert_eq(enemy.hp, enemy_hp_before - 2)
	assert_eq(wall.hp, 290)


func test_shock_stuns_attacker() -> void:
	var wall := _place_upgraded("wall_reactive")
	_game_state.gold = 200
	_game_state.upgrade_wall(wall, "wall_shock")

	var enemy := _spawn_breaker_at(Vector2(5, 5))
	Combat._damage_wall(wall, 10, enemy, _game_state)

	assert_true(enemy.is_stunned)
	assert_eq(enemy.stun_duration_ms, 1000)
	assert_eq(wall.stun_cooldown_remaining_ms, 5000)


func test_shock_respects_stun_cooldown() -> void:
	var wall := _place_upgraded("wall_reactive")
	_game_state.gold = 200
	_game_state.upgrade_wall(wall, "wall_shock")

	var enemy := _spawn_breaker_at(Vector2(5, 5))
	Combat._damage_wall(wall, 10, enemy, _game_state)
	enemy.is_stunned = false
	enemy.stun_duration_ms = 0

	Combat._damage_wall(wall, 10, enemy, _game_state)

	assert_false(enemy.is_stunned)


func test_reactive_stuns_with_shorter_duration() -> void:
	var wall := _place_upgraded("wall_reactive")
	var enemy := _spawn_breaker_at(Vector2(5, 5))

	Combat._damage_wall(wall, 10, enemy, _game_state)

	assert_true(enemy.is_stunned)
	assert_eq(enemy.stun_duration_ms, 500)
	assert_eq(wall.stun_cooldown_remaining_ms, 8000)


# ============================================
# Tar aura
# ============================================


func test_tar_wall_slows_nearby_enemies() -> void:
	var wall := _place_upgraded("wall_reactive")
	_game_state.gold = 200
	_game_state.upgrade_wall(wall, "wall_tar")

	var near := _spawn_enemy_at(Vector2(6, 5))
	var far := _spawn_enemy_at(Vector2(15, 15))

	Combat.process_wall_effects(_game_state, 100)

	assert_eq(near.slow_amount, 400)
	assert_eq(far.slow_amount, 0)


func test_siege_attack_triggers_wall_specials() -> void:
	var wall := _place_upgraded("wall_reactive")
	var enemy := _spawn_enemy_at(Vector2(4, 5))
	enemy.path.clear()

	Combat.process_siege_attacks(_game_state, 100)

	assert_lt(wall.hp, wall.max_hp)
	assert_true(enemy.is_stunned)
	assert_eq(wall.combat_idle_ms, 0)


# ============================================
# Helpers
# ============================================


func _place_upgraded(upgrade_id: String) -> SimWall:
	var wall := _game_state.place_wall(Vector2i(5, 5))
	_game_state.gold = 200
	_game_state.upgrade_wall(wall, upgrade_id)
	return wall


func _spawn_enemy_at(pos: Vector2) -> SimEnemy:
	var data := TestHelpers.create_basic_enemy_data()
	var enemy := SimEnemy.new()
	enemy.initialize(data, Vector2i(pos), _pathfinding)
	enemy.grid_pos = pos
	_game_state.enemies.append(enemy)
	return enemy


func _spawn_breaker_at(pos: Vector2) -> SimEnemy:
	var data := TestHelpers.create_wall_breaker_enemy_data()
	var enemy := SimEnemy.new()
	enemy.initialize(data, Vector2i(pos), _pathfinding)
	enemy.grid_pos = pos
	_game_state.enemies.append(enemy)
	return enemy
