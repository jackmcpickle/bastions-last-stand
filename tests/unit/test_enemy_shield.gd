extends GutTest

## Tests for enemy shield mechanic

var _pathfinding: SimPathfinding


func before_each() -> void:
	_pathfinding = TestHelpers.create_test_pathfinding()


func test_shield_absorbs_damage_before_hp() -> void:
	var data := TestHelpers.create_shielded_enemy_data()
	var enemy := SimEnemy.new()
	enemy.initialize(data, Vector2i.ZERO, _pathfinding)

	var initial_hp := enemy.hp
	var initial_shield := enemy.shield_hp

	enemy.take_damage(30000)  # 30 damage

	assert_eq(enemy.hp, initial_hp)  # HP untouched
	assert_eq(enemy.shield_hp, initial_shield - 30)


func test_shield_overflow_damages_hp() -> void:
	var data := TestHelpers.create_shielded_enemy_data()
	var enemy := SimEnemy.new()
	enemy.initialize(data, Vector2i.ZERO, _pathfinding)

	# Shield is 50, deal 70 damage
	enemy.take_damage(70000)

	assert_eq(enemy.shield_hp, 0)
	assert_eq(enemy.hp, 80 - 20)  # 70-50=20 overflow


func test_shield_regenerates() -> void:
	var data := TestHelpers.create_shielded_enemy_data()
	var enemy := SimEnemy.new()
	enemy.initialize(data, Vector2i.ZERO, _pathfinding)
	enemy.shield_hp = 0  # Depleted

	enemy.process_status_effects(1000)  # 1 sec at 10 shield/sec

	assert_eq(enemy.shield_hp, 10)


func test_shield_regen_caps_at_max() -> void:
	var data := TestHelpers.create_shielded_enemy_data()
	var enemy := SimEnemy.new()
	enemy.initialize(data, Vector2i.ZERO, _pathfinding)
	enemy.shield_hp = 49

	enemy.process_status_effects(10000)

	assert_eq(enemy.shield_hp, enemy.max_shield_hp)


func test_shield_disabled_prevents_regen() -> void:
	var data := TestHelpers.create_shielded_enemy_data()
	var enemy := SimEnemy.new()
	enemy.initialize(data, Vector2i.ZERO, _pathfinding)
	enemy.shield_hp = 0
	enemy.is_disabled = true

	enemy.process_status_effects(1000)

	assert_eq(enemy.shield_hp, 0)


func test_no_shield_enemy_unaffected() -> void:
	var data := TestHelpers.create_basic_enemy_data()
	var enemy := SimEnemy.new()
	enemy.initialize(data, Vector2i.ZERO, _pathfinding)

	enemy.take_damage(10000)

	assert_eq(enemy.hp, 90)
	assert_eq(enemy.shield_hp, 0)
