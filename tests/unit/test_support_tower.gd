extends GutTest

## Unit tests for Support Tower aura / mark / EMP mechanics

const SUPPORT_TOWER_PATH := "res://resources/towers/support_tower.tres"

var _game_state: GameState
var _pathfinding: SimPathfinding
var _support_data: TowerData


func before_each() -> void:
	_game_state = TestHelpers.create_test_game_state()
	_pathfinding = _game_state.pathfinding
	_support_data = load(SUPPORT_TOWER_PATH) as TowerData


# ============================================
# Damage aura
# ============================================


func test_support_aura_buffs_nearby_tower_damage() -> void:
	var support := _place_support({"support_aura": true, "aura_damage_buff": 150}, Vector2i(5, 5))
	var archer := _place_archer(Vector2i(7, 5))  # In 3-tile range of support center
	support.range_tiles = 3

	Combat.process_support_auras(_game_state, 100)

	assert_eq(archer.aura_damage_buff, 150)


func test_support_aura_does_not_buff_self() -> void:
	var support := _place_support({"support_aura": true, "aura_damage_buff": 150}, Vector2i(5, 5))
	support.range_tiles = 5

	Combat.process_support_auras(_game_state, 100)

	assert_eq(support.aura_damage_buff, 0)


func test_support_aura_ignores_towers_out_of_range() -> void:
	var support := _place_support({"support_aura": true, "aura_damage_buff": 150}, Vector2i(2, 2))
	support.range_tiles = 3
	var far := _place_archer(Vector2i(15, 15))

	Combat.process_support_auras(_game_state, 100)

	assert_eq(far.aura_damage_buff, 0)


func test_calculate_damage_applies_aura_damage_buff() -> void:
	var archer := _place_archer(Vector2i(5, 5))
	archer.damage = 10000
	archer.aura_damage_buff = 150  # +15%
	var enemy := _spawn_enemy_at(Vector2(10, 10))

	var damage := Combat._calculate_damage(archer, enemy, _game_state.rng)

	assert_eq(damage, 11500)


# ============================================
# Speed / range auras
# ============================================


func test_support_aura_buffs_attack_speed() -> void:
	var support := _place_support({"support_aura": true, "aura_speed_buff": 100}, Vector2i(5, 5))
	support.range_tiles = 4
	var archer := _place_archer(Vector2i(7, 5))
	archer.attack_speed_ms = 1000

	Combat.process_support_auras(_game_state, 100)

	assert_eq(archer.aura_speed_buff, 100)
	assert_eq(archer.get_attack_cooldown_ms(), 909)  # 1000 * 1000 / 1100


func test_support_aura_buffs_range() -> void:
	var support := _place_support({"support_aura": true, "aura_range_buff": 1}, Vector2i(5, 5))
	support.range_tiles = 5
	var archer := _place_archer(Vector2i(7, 5))
	archer.range_tiles = 5

	Combat.process_support_auras(_game_state, 100)

	assert_eq(archer.aura_bonus_range, 1)
	assert_eq(archer.get_effective_range(), 6)


# ============================================
# Tower regen (Rally Point)
# ============================================


func test_support_aura_regens_nearby_tower_hp() -> void:
	var support := _place_support({"support_aura": true, "aura_tower_regen": 2}, Vector2i(5, 5))
	support.range_tiles = 4
	var archer := _place_archer(Vector2i(7, 5))
	archer.hp = 50
	archer.max_hp = 100

	# 1000ms at 2 HP/s => +2 HP
	Combat.process_support_auras(_game_state, 1000)

	assert_eq(archer.hp, 52)


func test_support_aura_regen_does_not_exceed_max_hp() -> void:
	var support := _place_support({"support_aura": true, "aura_tower_regen": 10}, Vector2i(5, 5))
	support.range_tiles = 4
	var archer := _place_archer(Vector2i(7, 5))
	archer.hp = 98
	archer.max_hp = 100

	Combat.process_support_auras(_game_state, 1000)

	assert_eq(archer.hp, 100)


# ============================================
# Mark enemies (Tech Relay / Scanner)
# ============================================


func test_support_marks_enemies_in_range() -> void:
	var support := _place_support(
		{"support_aura": true, "mark_enemies": true, "mark_damage_amp": 150}, Vector2i(5, 5)
	)
	support.range_tiles = 4
	var enemy := _spawn_enemy_at(Vector2(6, 6))

	Combat.process_support_auras(_game_state, 100)

	assert_true(enemy.is_marked)
	assert_eq(enemy.mark_damage_amp, 150)


func test_marked_enemy_takes_bonus_damage() -> void:
	var archer := _place_archer(Vector2i(5, 5))
	archer.damage = 10000
	var enemy := _spawn_enemy_at(Vector2(10, 10))
	enemy.is_marked = true
	enemy.mark_damage_amp = 150

	var damage := Combat._calculate_damage(archer, enemy, _game_state.rng)

	assert_eq(damage, 11500)


func test_scanner_reveals_stealth_in_range() -> void:
	var support := _place_support(
		{
			"support_aura": true,
			"mark_enemies": true,
			"mark_damage_amp": 150,
			"reveal_stealth": true,
			"mark_crit_chance": 400,
		},
		Vector2i(5, 5)
	)
	support.range_tiles = 5
	var stealth := _spawn_stealth_at(Vector2(6, 6))

	assert_false(stealth.is_targetable())

	Combat.process_support_auras(_game_state, 100)

	assert_true(stealth.is_revealed)
	assert_true(stealth.is_targetable())
	assert_eq(stealth.mark_crit_chance, 400)


func test_mark_crit_chance_can_crit() -> void:
	_game_state.rng.set_seed(1)
	var archer := _place_archer(Vector2i(5, 5))
	archer.damage = 10000
	var enemy := _spawn_enemy_at(Vector2(10, 10))
	enemy.is_marked = true
	enemy.mark_crit_chance = 1000  # 100%

	var damage := Combat._calculate_damage(archer, enemy, _game_state.rng)

	assert_eq(damage, 20000)


# ============================================
# EMP Field
# ============================================


func test_emp_slows_enemies_in_range() -> void:
	var support := _place_support(
		{"support_aura": true, "emp_slow": 300, "emp_disable_shields": true}, Vector2i(5, 5)
	)
	support.range_tiles = 4
	var enemy := _spawn_enemy_at(Vector2(6, 6))

	Combat.process_support_auras(_game_state, 100)

	assert_eq(enemy.slow_amount, 300)


func test_emp_disables_shields_in_range() -> void:
	var support := _place_support(
		{"support_aura": true, "emp_disable_shields": true}, Vector2i(5, 5)
	)
	support.range_tiles = 4
	var enemy := _spawn_shielded_at(Vector2(6, 6))
	assert_gt(enemy.shield_hp, 0)

	Combat.process_support_auras(_game_state, 100)

	assert_eq(enemy.shield_hp, 0)


# ============================================
# Stacking / clearing
# ============================================


func test_overlapping_supports_take_max_buff() -> void:
	var weak := _place_support({"support_aura": true, "aura_damage_buff": 150}, Vector2i(4, 5))
	weak.range_tiles = 5
	var strong := _place_support({"support_aura": true, "aura_damage_buff": 250}, Vector2i(6, 5))
	strong.range_tiles = 5
	var archer := _place_archer(Vector2i(5, 7))

	Combat.process_support_auras(_game_state, 100)

	assert_eq(archer.aura_damage_buff, 250)


func test_support_aura_clears_when_out_of_range() -> void:
	var archer := _place_archer(Vector2i(5, 5))
	archer.aura_damage_buff = 150

	# No supports in state
	Combat.process_support_auras(_game_state, 100)

	assert_eq(archer.aura_damage_buff, 0)


func test_support_tower_skips_normal_attacks() -> void:
	var support := _place_support({"support_aura": true, "aura_damage_buff": 150}, Vector2i(5, 5))
	support.damage = 0
	support.cooldown_ms = 0
	var enemy := _spawn_enemy_at(Vector2(6, 6))
	var hp_before := enemy.hp

	Combat.process_tower_attacks(_game_state, 100)

	assert_eq(enemy.hp, hp_before)
	assert_eq(support.shots_fired, 0)


# ============================================
# Resource / upgrades
# ============================================


func test_support_tower_resource_loads() -> void:
	assert_not_null(_support_data)
	assert_eq(_support_data.id, "support")
	assert_true(_support_data.special.get("support_aura", false))
	assert_eq(_support_data.special.get("aura_damage_buff", 0), 150)
	assert_eq(_support_data.upgrades.size(), 6)


func test_support_upgrade_applies_rally_regen() -> void:
	var tower := SimTower.new()
	tower.initialize(_support_data, Vector2i(5, 5))

	var war_banner: TowerUpgradeData = null
	var rally: TowerUpgradeData = null
	for upgrade in _support_data.upgrades:
		if upgrade.id == "support_war_banner":
			war_banner = upgrade
		elif upgrade.id == "support_rally_point":
			rally = upgrade

	assert_not_null(war_banner)
	assert_not_null(rally)
	assert_true(tower.can_upgrade_to(war_banner))
	tower.apply_upgrade(war_banner)
	assert_true(tower.can_upgrade_to(rally))
	tower.apply_upgrade(rally)
	assert_eq(tower.special.get("aura_tower_regen", 0), 2)


# ============================================
# Helpers
# ============================================


func _place_support(special: Dictionary, pos: Vector2i) -> SimTower:
	var data := TestHelpers.create_support_tower_data()
	data.special = special
	var tower := SimTower.new()
	tower.initialize(data, pos)
	_game_state.towers.append(tower)
	return tower


func _place_archer(pos: Vector2i) -> SimTower:
	var data := TestHelpers.create_basic_tower_data()
	var tower := SimTower.new()
	tower.initialize(data, pos)
	_game_state.towers.append(tower)
	return tower


func _spawn_enemy_at(pos: Vector2) -> SimEnemy:
	var data := TestHelpers.create_basic_enemy_data()
	var enemy := SimEnemy.new()
	enemy.initialize(data, Vector2i(pos), _pathfinding)
	enemy.grid_pos = pos
	_game_state.enemies.append(enemy)
	return enemy


func _spawn_stealth_at(pos: Vector2) -> SimEnemy:
	var data := TestHelpers.create_stealth_enemy_data()
	var enemy := SimEnemy.new()
	enemy.initialize(data, Vector2i(pos), _pathfinding)
	enemy.grid_pos = pos
	_game_state.enemies.append(enemy)
	return enemy


func _spawn_shielded_at(pos: Vector2) -> SimEnemy:
	var data := TestHelpers.create_shielded_enemy_data()
	var enemy := SimEnemy.new()
	enemy.initialize(data, Vector2i(pos), _pathfinding)
	enemy.grid_pos = pos
	_game_state.enemies.append(enemy)
	return enemy
