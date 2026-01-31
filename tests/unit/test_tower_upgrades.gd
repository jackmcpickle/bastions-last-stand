extends GutTest

## Unit tests for tower upgrade mechanics

var _pathfinding: SimPathfinding


func before_each() -> void:
	_pathfinding = TestHelpers.create_test_pathfinding()


# ============================================
# Upgrade path tests
# ============================================

func test_can_upgrade_t1_to_t2_branch_a() -> void:
	var tower := _create_tower()
	var upgrade := _create_tier2_upgrade("A")

	assert_true(tower.can_upgrade_to(upgrade))


func test_can_upgrade_t1_to_t2_branch_b() -> void:
	var tower := _create_tower()
	var upgrade := _create_tier2_upgrade("B")

	assert_true(tower.can_upgrade_to(upgrade))


func test_can_upgrade_t2_to_t3_matching_branch() -> void:
	var tower := _create_tower()
	tower.tier = 2
	tower.branch = "A"
	var upgrade := _create_tier3_upgrade("A1", "A")

	assert_true(tower.can_upgrade_to(upgrade))


func test_cannot_upgrade_t2a_to_t3b() -> void:
	var tower := _create_tower()
	tower.tier = 2
	tower.branch = "A"
	var upgrade := _create_tier3_upgrade("B1", "B")

	assert_false(tower.can_upgrade_to(upgrade))


func test_cannot_upgrade_t1_to_t3() -> void:
	var tower := _create_tower()
	var upgrade := _create_tier3_upgrade("A1", "A")

	assert_false(tower.can_upgrade_to(upgrade))


func test_apply_upgrade_changes_stats() -> void:
	var tower := _create_tower()
	var upgrade := _create_tier2_upgrade("A")
	upgrade.damage = 30000
	upgrade.attack_speed_ms = 500
	upgrade.range_tiles = 7

	tower.apply_upgrade(upgrade)

	assert_eq(tower.damage, 30000)
	assert_eq(tower.attack_speed_ms, 500)
	assert_eq(tower.range_tiles, 7)
	assert_eq(tower.tier, 2)
	assert_eq(tower.branch, "A")


func test_apply_upgrade_merges_special() -> void:
	var tower := _create_tower()
	tower.special = {"slow": 200}
	var upgrade := _create_tier2_upgrade("A")
	upgrade.special = {"crit_chance": 250, "slow": 400}

	tower.apply_upgrade(upgrade)

	assert_eq(tower.special.crit_chance, 250)
	assert_eq(tower.special.slow, 400)  # Overwritten


func test_get_available_upgrades_returns_valid_options() -> void:
	var tower := _create_tower_with_upgrades()

	var upgrades := tower.get_available_upgrades()

	# T1 tower should get T2 upgrades
	assert_eq(upgrades.size(), 2)
	for u in upgrades:
		assert_eq(u.tier, 2)


func test_get_available_upgrades_empty_at_t3() -> void:
	var tower := _create_tower_with_upgrades()
	tower.tier = 3
	tower.branch = "A1"

	var upgrades := tower.get_available_upgrades()

	assert_eq(upgrades.size(), 0)


func test_get_available_upgrades_filters_by_branch_at_t2() -> void:
	var tower := _create_tower_with_upgrades()
	tower.tier = 2
	tower.branch = "A"

	var upgrades := tower.get_available_upgrades()

	# Should only get A-branch T3 upgrades
	for u in upgrades:
		assert_eq(u.tier, 3)
		assert_eq(u.parent_branch, "A")


func test_upgrade_preserves_existing_special_not_overwritten() -> void:
	var tower := _create_tower()
	tower.special = {"chain": 4, "chain_range": 2.5}
	var upgrade := _create_tier2_upgrade("A")
	upgrade.special = {"crit_chance": 300}

	tower.apply_upgrade(upgrade)

	# Both old and new specials should exist
	assert_eq(tower.special.chain, 4)
	assert_eq(tower.special.chain_range, 2.5)
	assert_eq(tower.special.crit_chance, 300)


# ============================================
# Helpers
# ============================================

func _create_tower() -> SimTower:
	var data := TestHelpers.create_basic_tower_data()
	var tower := SimTower.new()
	tower.initialize(data, Vector2i(5, 5))
	return tower


func _create_tower_with_upgrades() -> SimTower:
	var data := TestHelpers.create_basic_tower_data()

	# Add upgrades
	var t2a := _create_tier2_upgrade("A")
	var t2b := _create_tier2_upgrade("B")
	var t3a1 := _create_tier3_upgrade("A1", "A")
	var t3a2 := _create_tier3_upgrade("A2", "A")
	var t3b1 := _create_tier3_upgrade("B1", "B")
	var t3b2 := _create_tier3_upgrade("B2", "B")

	data.upgrades = [t2a, t2b, t3a1, t3a2, t3b1, t3b2]

	var tower := SimTower.new()
	tower.initialize(data, Vector2i(5, 5))
	return tower


func _create_tier2_upgrade(branch: String, special: Dictionary = {}) -> TowerUpgradeData:
	var data := TowerUpgradeData.new()
	data.id = "test_t2_%s" % branch
	data.display_name = "Test T2 %s" % branch
	data.tier = 2
	data.branch = branch
	data.parent_branch = ""
	data.damage = 20000
	data.attack_speed_ms = 700
	data.range_tiles = 6
	data.aoe_radius = 0
	data.special = special
	return data


func _create_tier3_upgrade(branch: String, parent: String, special: Dictionary = {}) -> TowerUpgradeData:
	var data := TowerUpgradeData.new()
	data.id = "test_t3_%s" % branch
	data.display_name = "Test T3 %s" % branch
	data.tier = 3
	data.branch = branch
	data.parent_branch = parent
	data.damage = 35000
	data.attack_speed_ms = 600
	data.range_tiles = 7
	data.aoe_radius = 0
	data.special = special
	return data
