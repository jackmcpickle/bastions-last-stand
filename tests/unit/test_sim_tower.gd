extends GutTest

## Unit tests for SimTower

var _pathfinding: SimPathfinding


func before_each() -> void:
	_pathfinding = TestHelpers.create_test_pathfinding()


# ============================================
# attack() tests
# ============================================

func test_attack_single_target() -> void:
	var tower := _create_tower()
	var enemies: Array[SimEnemy] = [_create_enemy_at(Vector2(5, 5))]

	var hit := tower.attack(enemies[0], enemies)

	assert_eq(hit.size(), 1)
	assert_eq(hit[0], enemies[0])


func test_attack_sets_cooldown() -> void:
	var tower := _create_tower()
	var enemies: Array[SimEnemy] = [_create_enemy_at(Vector2(5, 5))]

	tower.attack(enemies[0], enemies)

	assert_eq(tower.cooldown_ms, tower.attack_speed_ms)


func test_attack_increments_shots_fired() -> void:
	var tower := _create_tower()
	var enemies: Array[SimEnemy] = [_create_enemy_at(Vector2(5, 5))]

	assert_eq(tower.shots_fired, 0)

	tower.attack(enemies[0], enemies)

	assert_eq(tower.shots_fired, 1)


func test_attack_on_cooldown_returns_empty() -> void:
	var tower := _create_tower()
	var enemies: Array[SimEnemy] = [_create_enemy_at(Vector2(5, 5))]

	tower.attack(enemies[0], enemies)
	var hit := tower.attack(enemies[0], enemies)

	assert_eq(hit.size(), 0)


func test_attack_aoe_hits_multiple() -> void:
	var data := TestHelpers.create_aoe_tower_data()
	var tower := SimTower.new()
	tower.initialize(data, Vector2i(5, 5))

	var enemies: Array[SimEnemy] = [
		_create_enemy_at(Vector2(6, 6)),
		_create_enemy_at(Vector2(6.5, 6.5)),
		_create_enemy_at(Vector2(7, 7)),
	]

	var hit := tower.attack(enemies[0], enemies)

	assert_gt(hit.size(), 1)


func test_attack_aoe_hits_enemies_in_radius() -> void:
	var data := TestHelpers.create_aoe_tower_data()
	data.aoe_radius = 2000  # 2 tiles
	var tower := SimTower.new()
	tower.initialize(data, Vector2i(0, 0))

	var enemies: Array[SimEnemy] = [
		_create_enemy_at(Vector2(5, 5)),  # Target
		_create_enemy_at(Vector2(5.5, 5.5)),  # In range
		_create_enemy_at(Vector2(10, 10)),  # Out of range
	]

	var hit := tower.attack(enemies[0], enemies)

	assert_eq(hit.size(), 2)
	assert_has(hit, enemies[0])
	assert_has(hit, enemies[1])


func test_attack_chain_hits_multiple() -> void:
	var data := TestHelpers.create_lightning_tower_data()
	var tower := SimTower.new()
	tower.initialize(data, Vector2i(5, 5))

	var enemies: Array[SimEnemy] = [
		_create_enemy_at(Vector2(6, 6)),
		_create_enemy_at(Vector2(7, 7)),
		_create_enemy_at(Vector2(8, 8)),
	]

	var hit := tower.attack(enemies[0], enemies)

	assert_gt(hit.size(), 1)
	assert_eq(hit[0], enemies[0])  # First target is primary


func test_attack_chain_respects_chain_count() -> void:
	var data := TestHelpers.create_lightning_tower_data()
	data.special = {"chain": 2, "chain_range": 5.0}  # Only 2 chains
	var tower := SimTower.new()
	tower.initialize(data, Vector2i(0, 0))

	var enemies: Array[SimEnemy] = [
		_create_enemy_at(Vector2(5, 5)),
		_create_enemy_at(Vector2(6, 6)),
		_create_enemy_at(Vector2(7, 7)),
		_create_enemy_at(Vector2(8, 8)),
	]

	var hit := tower.attack(enemies[0], enemies)

	assert_eq(hit.size(), 2)


func test_attack_chain_respects_range() -> void:
	var data := TestHelpers.create_lightning_tower_data()
	data.special = {"chain": 4, "chain_range": 1.0}
	var tower := SimTower.new()
	tower.initialize(data, Vector2i(0, 0))

	var enemies: Array[SimEnemy] = [
		_create_enemy_at(Vector2(5, 5)),
		_create_enemy_at(Vector2(10, 10)),  # Too far to chain
	]

	var hit := tower.attack(enemies[0], enemies)

	assert_eq(hit.size(), 1)


# ============================================
# process_cooldown() tests
# ============================================

func test_process_cooldown_reduces() -> void:
	var tower := _create_tower()
	tower.cooldown_ms = 500

	tower.process_cooldown(200)

	assert_eq(tower.cooldown_ms, 300)


func test_process_cooldown_clamps_to_zero() -> void:
	var tower := _create_tower()
	tower.cooldown_ms = 100

	tower.process_cooldown(500)

	assert_eq(tower.cooldown_ms, 0)


func test_process_cooldown_zero_stays_zero() -> void:
	var tower := _create_tower()
	tower.cooldown_ms = 0

	tower.process_cooldown(100)

	assert_eq(tower.cooldown_ms, 0)


# ============================================
# can_attack() tests
# ============================================

func test_can_attack_when_ready() -> void:
	var tower := _create_tower()
	tower.cooldown_ms = 0

	assert_true(tower.can_attack())


func test_can_attack_false_on_cooldown() -> void:
	var tower := _create_tower()
	tower.cooldown_ms = 100

	assert_false(tower.can_attack())


# ============================================
# can_upgrade_to() tests
# ============================================

func test_can_upgrade_t1_to_t2() -> void:
	var tower := _create_tower()
	var upgrade := TestHelpers.create_upgrade_data(2, "A")

	assert_true(tower.can_upgrade_to(upgrade))


func test_can_upgrade_t1_to_t2_any_branch() -> void:
	var tower := _create_tower()

	assert_true(tower.can_upgrade_to(TestHelpers.create_upgrade_data(2, "A")))
	assert_true(tower.can_upgrade_to(TestHelpers.create_upgrade_data(2, "B")))


func test_cannot_upgrade_t1_to_t3() -> void:
	var tower := _create_tower()
	var upgrade := TestHelpers.create_upgrade_data(3, "A1")

	assert_false(tower.can_upgrade_to(upgrade))


func test_can_upgrade_t2_to_t3_matching_branch() -> void:
	var tower := _create_tower()
	tower.tier = 2
	tower.branch = "A"

	var upgrade := TestHelpers.create_upgrade_data(3, "A1")
	upgrade.parent_branch = "A"

	assert_true(tower.can_upgrade_to(upgrade))


func test_cannot_upgrade_t2_to_t3_wrong_branch() -> void:
	var tower := _create_tower()
	tower.tier = 2
	tower.branch = "A"

	var upgrade := TestHelpers.create_upgrade_data(3, "B1")
	upgrade.parent_branch = "B"

	assert_false(tower.can_upgrade_to(upgrade))


func test_cannot_upgrade_null() -> void:
	var tower := _create_tower()

	assert_false(tower.can_upgrade_to(null))


# ============================================
# apply_upgrade() tests
# ============================================

func test_apply_upgrade_updates_stats() -> void:
	var tower := _create_tower()
	var upgrade := TestHelpers.create_upgrade_data(2, "A")
	upgrade.damage = 25000
	upgrade.attack_speed_ms = 600

	tower.apply_upgrade(upgrade)

	assert_eq(tower.damage, 25000)
	assert_eq(tower.attack_speed_ms, 600)
	assert_eq(tower.tier, 2)
	assert_eq(tower.branch, "A")


func test_apply_upgrade_merges_special() -> void:
	var tower := _create_tower()
	tower.special = {"slow": 100}

	var upgrade := TestHelpers.create_upgrade_data(2, "A")
	upgrade.special = {"slow": 200, "burn_dps": 5000}

	tower.apply_upgrade(upgrade)

	assert_eq(tower.special.slow, 200)
	assert_eq(tower.special.burn_dps, 5000)


# ============================================
# get_dps() tests
# ============================================

func test_get_dps_calculation() -> void:
	var tower := _create_tower()
	tower.damage = 10000  # 10 damage
	tower.attack_speed_ms = 1000  # 1 attack/sec

	var dps := tower.get_dps()

	assert_almost_eq(dps, 10.0, 0.01)


func test_get_dps_fast_attack() -> void:
	var tower := _create_tower()
	tower.damage = 5000  # 5 damage
	tower.attack_speed_ms = 500  # 2 attacks/sec

	var dps := tower.get_dps()

	assert_almost_eq(dps, 10.0, 0.01)


func test_get_dps_zero_attack_speed() -> void:
	var tower := _create_tower()
	tower.attack_speed_ms = 0

	var dps := tower.get_dps()

	assert_eq(dps, 0.0)


# ============================================
# get_damage_for_target() tests
# ============================================

func test_get_damage_for_target_basic() -> void:
	var tower := _create_tower()
	tower.damage = 15000
	var enemy := _create_enemy_at(Vector2(5, 5))

	var damage := tower.get_damage_for_target(enemy)

	assert_eq(damage, 15000)


func test_get_damage_fast_bonus() -> void:
	var tower := _create_tower()
	tower.damage = 10000
	tower.special = {"fast_bonus": 500}  # +50% vs fast enemies

	var fast_enemy := SimEnemy.new()
	var data := TestHelpers.create_fast_enemy_data()
	data.speed = 2000  # Fast
	fast_enemy.initialize(data, Vector2i.ZERO, _pathfinding)

	var damage := tower.get_damage_for_target(fast_enemy)

	assert_eq(damage, 15000)


func test_get_damage_fast_bonus_not_applied_to_slow() -> void:
	var tower := _create_tower()
	tower.damage = 10000
	tower.special = {"fast_bonus": 500}

	var slow_enemy := _create_enemy_at(Vector2(5, 5))  # Default speed 1000

	var damage := tower.get_damage_for_target(slow_enemy)

	assert_eq(damage, 10000)


# ============================================
# Record/tracking tests
# ============================================

func test_record_damage() -> void:
	var tower := _create_tower()

	tower.record_damage(5000)
	tower.record_damage(3000)

	assert_eq(tower.total_damage_dealt, 8000)


func test_record_kill() -> void:
	var tower := _create_tower()

	tower.record_kill()
	tower.record_kill()

	assert_eq(tower.kills, 2)


func test_get_sell_value() -> void:
	var tower := _create_tower()
	tower.total_cost = 100

	var sell := tower.get_sell_value()

	assert_eq(sell, 90)  # 90% return


func test_get_center() -> void:
	var tower := _create_tower()
	tower.position = Vector2i(4, 6)

	var center := tower.get_center()

	assert_eq(center, Vector2(5.0, 7.0))


# ============================================
# Helpers
# ============================================

func _create_tower() -> SimTower:
	var data := TestHelpers.create_basic_tower_data()
	var tower := SimTower.new()
	tower.initialize(data, Vector2i(5, 5))
	return tower


func _create_enemy_at(pos: Vector2) -> SimEnemy:
	var data := TestHelpers.create_basic_enemy_data()
	var enemy := SimEnemy.new()
	enemy.initialize(data, Vector2i(pos), _pathfinding)
	enemy.grid_pos = pos
	return enemy
