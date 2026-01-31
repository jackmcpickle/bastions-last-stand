extends GutTest

## Unit tests for Targeting system

var _pathfinding: SimPathfinding


func before_each() -> void:
	_pathfinding = TestHelpers.create_test_pathfinding()


# ============================================
# find_target() tests - FIRST priority
# ============================================

func test_find_target_first_returns_furthest_along_path() -> void:
	var enemies: Array[SimEnemy] = [
		_create_enemy_with_progress(0.3),
		_create_enemy_with_progress(0.8),  # Furthest
		_create_enemy_with_progress(0.5),
	]

	var target := Targeting.find_target(
		Vector2i(10, 10),
		enemies,
		20,
		Targeting.Priority.FIRST
	)

	assert_eq(target, enemies[1])


func test_find_target_first_default_priority() -> void:
	var enemies: Array[SimEnemy] = [
		_create_enemy_with_progress(0.2),
		_create_enemy_with_progress(0.9),
	]

	var target := Targeting.find_target(
		Vector2i(10, 10),
		enemies,
		20
	)

	assert_eq(target, enemies[1])


# ============================================
# find_target() tests - LAST priority
# ============================================

func test_find_target_last_returns_closest_to_spawn() -> void:
	var enemies: Array[SimEnemy] = [
		_create_enemy_with_progress(0.7),
		_create_enemy_with_progress(0.1),  # Closest to spawn
		_create_enemy_with_progress(0.5),
	]

	var target := Targeting.find_target(
		Vector2i(10, 10),
		enemies,
		20,
		Targeting.Priority.LAST
	)

	assert_eq(target, enemies[1])


# ============================================
# find_target() tests - STRONGEST priority
# ============================================

func test_find_target_strongest_returns_highest_hp() -> void:
	var enemies: Array[SimEnemy] = [
		_create_enemy_with_hp(50),
		_create_enemy_with_hp(150),  # Strongest
		_create_enemy_with_hp(80),
	]

	var target := Targeting.find_target(
		Vector2i(10, 10),
		enemies,
		20,
		Targeting.Priority.STRONGEST
	)

	assert_eq(target, enemies[1])


func test_find_target_strongest_considers_current_hp() -> void:
	var enemies: Array[SimEnemy] = [
		_create_enemy_with_hp(100),
		_create_enemy_with_hp(80),
	]
	enemies[0].hp = 30  # Damaged

	var target := Targeting.find_target(
		Vector2i(10, 10),
		enemies,
		20,
		Targeting.Priority.STRONGEST
	)

	assert_eq(target, enemies[1])


# ============================================
# find_target() tests - WEAKEST priority
# ============================================

func test_find_target_weakest_returns_lowest_hp() -> void:
	var enemies: Array[SimEnemy] = [
		_create_enemy_with_hp(100),
		_create_enemy_with_hp(20),  # Weakest
		_create_enemy_with_hp(50),
	]

	var target := Targeting.find_target(
		Vector2i(10, 10),
		enemies,
		20,
		Targeting.Priority.WEAKEST
	)

	assert_eq(target, enemies[1])


# ============================================
# find_target() tests - CLOSEST priority
# ============================================

func test_find_target_closest_returns_nearest_to_tower() -> void:
	var enemies: Array[SimEnemy] = [
		_create_enemy_at(Vector2(15, 15)),
		_create_enemy_at(Vector2(11, 11)),  # Closest to (10,10)
		_create_enemy_at(Vector2(18, 18)),
	]

	var target := Targeting.find_target(
		Vector2i(10, 10),
		enemies,
		20,
		Targeting.Priority.CLOSEST
	)

	assert_eq(target, enemies[1])


# ============================================
# find_target() range tests
# ============================================

func test_find_target_respects_range() -> void:
	var enemies: Array[SimEnemy] = [
		_create_enemy_at(Vector2(20, 20)),  # Out of range
	]

	var target := Targeting.find_target(
		Vector2i(0, 0),
		enemies,
		5,  # Range 5
		Targeting.Priority.FIRST
	)

	assert_null(target)


func test_find_target_includes_at_edge_of_range() -> void:
	var enemies: Array[SimEnemy] = [
		_create_enemy_at(Vector2(5, 0)),  # Exactly at range 5
	]

	var target := Targeting.find_target(
		Vector2i(0, 0),
		enemies,
		5,
		Targeting.Priority.FIRST
	)

	assert_eq(target, enemies[0])


func test_find_target_empty_list_returns_null() -> void:
	var enemies: Array[SimEnemy] = []

	var target := Targeting.find_target(
		Vector2i(0, 0),
		enemies,
		10,
		Targeting.Priority.FIRST
	)

	assert_null(target)


# ============================================
# find_target() stealth tests
# ============================================

func test_find_target_ignores_stealth() -> void:
	var data := TestHelpers.create_stealth_enemy_data()
	var enemy := SimEnemy.new()
	enemy.initialize(data, Vector2i(5, 5), _pathfinding)
	enemy.grid_pos = Vector2(5, 5)

	var enemies: Array[SimEnemy] = [enemy]

	var target := Targeting.find_target(
		Vector2i(0, 0),
		enemies,
		10,
		Targeting.Priority.FIRST
	)

	assert_null(target)


func test_find_target_targets_revealed_stealth() -> void:
	var data := TestHelpers.create_stealth_enemy_data()
	var enemy := SimEnemy.new()
	enemy.initialize(data, Vector2i(5, 5), _pathfinding)
	enemy.grid_pos = Vector2(5, 5)
	enemy.is_revealed = true

	var enemies: Array[SimEnemy] = [enemy]

	var target := Targeting.find_target(
		Vector2i(0, 0),
		enemies,
		10,
		Targeting.Priority.FIRST
	)

	assert_eq(target, enemy)


func test_find_target_skips_stealth_picks_visible() -> void:
	var stealth_data := TestHelpers.create_stealth_enemy_data()
	var stealth := SimEnemy.new()
	stealth.initialize(stealth_data, Vector2i(5, 5), _pathfinding)
	stealth.grid_pos = Vector2(5, 5)
	stealth.path_progress = 0.9  # Would be FIRST

	var visible := _create_enemy_with_progress(0.5)

	var enemies: Array[SimEnemy] = [stealth, visible]

	var target := Targeting.find_target(
		Vector2i(0, 0),
		enemies,
		20,
		Targeting.Priority.FIRST
	)

	assert_eq(target, visible)


# ============================================
# get_enemies_in_range() tests
# ============================================

func test_get_enemies_in_range_returns_all_in_range() -> void:
	var enemies: Array[SimEnemy] = [
		_create_enemy_at(Vector2(2, 2)),
		_create_enemy_at(Vector2(3, 3)),
		_create_enemy_at(Vector2(20, 20)),  # Out
	]

	var in_range := Targeting.get_enemies_in_range(
		Vector2i(0, 0),
		enemies,
		5
	)

	assert_eq(in_range.size(), 2)
	assert_has(in_range, enemies[0])
	assert_has(in_range, enemies[1])


func test_get_enemies_in_range_empty_when_none() -> void:
	var enemies: Array[SimEnemy] = [
		_create_enemy_at(Vector2(20, 20)),
	]

	var in_range := Targeting.get_enemies_in_range(
		Vector2i(0, 0),
		enemies,
		5
	)

	assert_eq(in_range.size(), 0)


func test_get_enemies_in_range_uses_squared_distance() -> void:
	# Enemy at (3, 4) is exactly 5 tiles from origin
	var enemies: Array[SimEnemy] = [
		_create_enemy_at(Vector2(3, 4)),
	]

	var in_range := Targeting.get_enemies_in_range(
		Vector2i(0, 0),
		enemies,
		5
	)

	assert_eq(in_range.size(), 1)


# ============================================
# get_enemies_in_aoe() tests
# ============================================

func test_get_enemies_in_aoe_basic() -> void:
	var enemies: Array[SimEnemy] = [
		_create_enemy_at(Vector2(5.5, 5.5)),
		_create_enemy_at(Vector2(6, 6)),
		_create_enemy_at(Vector2(10, 10)),  # Out
	]

	var in_aoe := Targeting.get_enemies_in_aoe(
		Vector2(5, 5),
		enemies,
		2.0
	)

	assert_eq(in_aoe.size(), 2)


func test_get_enemies_in_aoe_uses_float_center() -> void:
	var enemies: Array[SimEnemy] = [
		_create_enemy_at(Vector2(5.5, 5.5)),
	]

	var in_aoe := Targeting.get_enemies_in_aoe(
		Vector2(5.5, 5.5),  # Sub-tile center
		enemies,
		0.1
	)

	assert_eq(in_aoe.size(), 1)


func test_get_enemies_in_aoe_empty() -> void:
	var enemies: Array[SimEnemy] = [
		_create_enemy_at(Vector2(20, 20)),
	]

	var in_aoe := Targeting.get_enemies_in_aoe(
		Vector2(5, 5),
		enemies,
		1.0
	)

	assert_eq(in_aoe.size(), 0)


# ============================================
# Helpers
# ============================================

func _create_enemy_at(pos: Vector2) -> SimEnemy:
	var data := TestHelpers.create_basic_enemy_data()
	var enemy := SimEnemy.new()
	enemy.initialize(data, Vector2i(pos), _pathfinding)
	enemy.grid_pos = pos
	return enemy


func _create_enemy_with_progress(progress: float) -> SimEnemy:
	var enemy := _create_enemy_at(Vector2(10, 10))
	enemy.path_progress = progress
	return enemy


func _create_enemy_with_hp(hp: int) -> SimEnemy:
	var data := TestHelpers.create_basic_enemy_data()
	data.hp = hp
	var enemy := SimEnemy.new()
	enemy.initialize(data, Vector2i(10, 10), _pathfinding)
	enemy.grid_pos = Vector2(10, 10)
	return enemy
