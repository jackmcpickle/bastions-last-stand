extends GutTest

## Unit tests for Economy system

var _game_state: GameState


func before_each() -> void:
	_game_state = TestHelpers.create_test_game_state()


# ============================================
# calculate_kill_reward() tests
# ============================================


func test_calculate_kill_reward_basic() -> void:
	var data := TestHelpers.create_basic_enemy_data()
	data.gold_value = 15
	var enemy := SimEnemy.new()
	enemy.initialize(data, Vector2i.ZERO, _game_state.pathfinding)

	var reward := Economy.calculate_kill_reward(enemy, _game_state)

	assert_eq(reward, 15)


func test_calculate_kill_reward_high_value() -> void:
	var data := TestHelpers.create_basic_enemy_data()
	data.gold_value = 100  # Boss value
	var enemy := SimEnemy.new()
	enemy.initialize(data, Vector2i.ZERO, _game_state.pathfinding)

	var reward := Economy.calculate_kill_reward(enemy, _game_state)

	assert_eq(reward, 100)


# ============================================
# calculate_wave_bonus() tests
# ============================================


func test_calculate_wave_bonus_perfect_wave() -> void:
	var bonus := Economy.calculate_wave_bonus(100, false)

	# 25% perfect wave bonus
	assert_eq(bonus, 25)


func test_calculate_wave_bonus_took_damage() -> void:
	var bonus := Economy.calculate_wave_bonus(100, true)

	assert_eq(bonus, 0)


func test_calculate_wave_bonus_early_start() -> void:
	var bonus := Economy.calculate_wave_bonus(100, true, 5.0)

	# 10% early start bonus per 5 seconds
	assert_eq(bonus, 10)


func test_calculate_wave_bonus_early_start_max() -> void:
	var bonus := Economy.calculate_wave_bonus(100, true, 100.0)

	# Capped at 50%
	assert_eq(bonus, 50)


func test_calculate_wave_bonus_perfect_plus_early() -> void:
	var bonus := Economy.calculate_wave_bonus(100, false, 10.0)

	# 25% perfect + 20% early = 45%
	assert_eq(bonus, 45)


func test_calculate_wave_bonus_zero_gold() -> void:
	var bonus := Economy.calculate_wave_bonus(0, false)

	assert_eq(bonus, 0)


# ============================================
# calculate_interest() tests
# ============================================


func test_calculate_interest_basic() -> void:
	var interest := Economy.calculate_interest(100, true)

	# 5% interest
	assert_eq(interest, 5)


func test_calculate_interest_no_unlock() -> void:
	var interest := Economy.calculate_interest(100, false)

	assert_eq(interest, 0)


func test_calculate_interest_capped() -> void:
	var interest := Economy.calculate_interest(2000, true)

	# Capped at 50
	assert_eq(interest, 50)


func test_calculate_interest_zero_gold() -> void:
	var interest := Economy.calculate_interest(0, true)

	assert_eq(interest, 0)


func test_calculate_interest_rounds_down() -> void:
	var interest := Economy.calculate_interest(99, true)

	# 99 * 5% = 4.95 -> 4
	assert_eq(interest, 4)


# ============================================
# get_tower_cost() tests
# ============================================


func test_get_tower_cost_basic() -> void:
	var data := TestHelpers.create_basic_tower_data()
	data.base_cost = 80
	_game_state.register_tower_data(data)

	var cost := Economy.get_tower_cost("archer", _game_state)

	assert_eq(cost, 80)


func test_get_tower_cost_unknown_tower() -> void:
	var cost := Economy.get_tower_cost("unknown", _game_state)

	assert_eq(cost, 0)


# ============================================
# get_upgrade_cost() tests
# ============================================


func test_get_upgrade_cost_tier2() -> void:
	var data := TestHelpers.create_basic_tower_data()
	data.upgrade_cost_t2 = 60
	var tower := SimTower.new()
	tower.initialize(data, Vector2i.ZERO)
	tower.tier = 1

	var cost := Economy.get_upgrade_cost(tower, "A")

	assert_eq(cost, 60)


func test_get_upgrade_cost_tier3() -> void:
	var data := TestHelpers.create_basic_tower_data()
	data.upgrade_cost_t3 = 100
	var tower := SimTower.new()
	tower.initialize(data, Vector2i.ZERO)
	tower.tier = 2

	var cost := Economy.get_upgrade_cost(tower, "A1")

	assert_eq(cost, 100)


func test_get_upgrade_cost_max_tier() -> void:
	var data := TestHelpers.create_basic_tower_data()
	var tower := SimTower.new()
	tower.initialize(data, Vector2i.ZERO)
	tower.tier = 3

	var cost := Economy.get_upgrade_cost(tower, "A1")

	assert_eq(cost, 0)


# ============================================
# get_sell_value() tests
# ============================================


func test_get_sell_value_basic() -> void:
	var data := TestHelpers.create_basic_tower_data()
	var tower := SimTower.new()
	tower.initialize(data, Vector2i.ZERO)
	tower.total_cost = 100

	var value := Economy.get_sell_value(tower)

	# 90% return
	assert_eq(value, 90)


func test_get_sell_value_upgraded() -> void:
	var data := TestHelpers.create_basic_tower_data()
	var tower := SimTower.new()
	tower.initialize(data, Vector2i.ZERO)
	tower.total_cost = 200  # Base + upgrades

	var value := Economy.get_sell_value(tower)

	assert_eq(value, 180)


# ============================================
# can_afford_* tests
# ============================================


func test_can_afford_tower_true() -> void:
	var data := TestHelpers.create_basic_tower_data()
	data.base_cost = 50
	_game_state.register_tower_data(data)
	_game_state.gold = 100

	assert_true(Economy.can_afford_tower("archer", _game_state))


func test_can_afford_tower_false() -> void:
	var data := TestHelpers.create_basic_tower_data()
	data.base_cost = 150
	_game_state.register_tower_data(data)
	_game_state.gold = 100

	assert_false(Economy.can_afford_tower("archer", _game_state))


func test_can_afford_tower_exact() -> void:
	var data := TestHelpers.create_basic_tower_data()
	data.base_cost = 100
	_game_state.register_tower_data(data)
	_game_state.gold = 100

	assert_true(Economy.can_afford_tower("archer", _game_state))


func test_can_afford_wall_true() -> void:
	_game_state.gold = 100

	assert_true(Economy.can_afford_wall(_game_state))


func test_can_afford_wall_false() -> void:
	_game_state.gold = 5

	assert_false(Economy.can_afford_wall(_game_state))


func test_can_afford_upgrade_true() -> void:
	var data := TestHelpers.create_basic_tower_data()
	data.upgrade_cost_t2 = 50
	var tower := SimTower.new()
	tower.initialize(data, Vector2i.ZERO)
	tower.tier = 1
	_game_state.gold = 100

	assert_true(Economy.can_afford_upgrade(tower, "A", _game_state))


func test_can_afford_upgrade_false() -> void:
	var data := TestHelpers.create_basic_tower_data()
	data.upgrade_cost_t2 = 150
	var tower := SimTower.new()
	tower.initialize(data, Vector2i.ZERO)
	tower.tier = 1
	_game_state.gold = 100

	assert_false(Economy.can_afford_upgrade(tower, "A", _game_state))


# ============================================
# Constants tests
# ============================================


func test_wall_cost_constant() -> void:
	assert_eq(Economy.WALL_COST, 10)


func test_sell_rate_constant() -> void:
	assert_eq(Economy.SELL_RATE, 90)


func test_interest_rate_constant() -> void:
	assert_eq(Economy.INTEREST_RATE, 50)  # 5%


func test_interest_cap_constant() -> void:
	assert_eq(Economy.INTEREST_CAP, 50)


func test_perfect_wave_bonus_constant() -> void:
	assert_eq(Economy.PERFECT_WAVE_BONUS, 250)  # 25%
