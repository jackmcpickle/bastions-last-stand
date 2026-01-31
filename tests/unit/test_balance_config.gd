extends GutTest

## Unit tests for BalanceConfig

# ============================================
# to_dict() tests
# ============================================


func test_to_dict_contains_economy() -> void:
	var config := BalanceConfig.new()

	var dict := config.to_dict()

	assert_has(dict, "starting_gold")
	assert_has(dict, "wall_cost")
	assert_has(dict, "sell_rate_percent")


func test_to_dict_contains_archer() -> void:
	var config := BalanceConfig.new()

	var dict := config.to_dict()

	assert_has(dict, "archer_cost")
	assert_has(dict, "archer_damage")
	assert_has(dict, "archer_attack_speed_ms")
	assert_has(dict, "archer_range")


func test_to_dict_contains_enemies() -> void:
	var config := BalanceConfig.new()

	var dict := config.to_dict()

	assert_has(dict, "grunt_hp")
	assert_has(dict, "tank_armor")
	assert_has(dict, "flyer_speed")


func test_to_dict_contains_shrine() -> void:
	var config := BalanceConfig.new()

	var dict := config.to_dict()

	assert_has(dict, "shrine_hp")
	assert_has(dict, "enemy_shrine_damage")


func test_to_dict_values_match() -> void:
	var config := BalanceConfig.new()
	config.starting_gold = 150
	config.archer_damage = 20000

	var dict := config.to_dict()

	assert_eq(dict.starting_gold, 150)
	assert_eq(dict.archer_damage, 20000)


# ============================================
# from_dict() tests
# ============================================


func test_from_dict_loads_economy() -> void:
	var config := BalanceConfig.new()
	var dict := {"starting_gold": 200, "wall_cost": 15}

	config.from_dict(dict)

	assert_eq(config.starting_gold, 200)
	assert_eq(config.wall_cost, 15)


func test_from_dict_loads_towers() -> void:
	var config := BalanceConfig.new()
	var dict := {"archer_damage": 25000, "cannon_aoe_radius": 2000}

	config.from_dict(dict)

	assert_eq(config.archer_damage, 25000)
	assert_eq(config.cannon_aoe_radius, 2000)


func test_from_dict_loads_enemies() -> void:
	var config := BalanceConfig.new()
	var dict := {"grunt_hp": 80, "tank_armor": 400}

	config.from_dict(dict)

	assert_eq(config.grunt_hp, 80)
	assert_eq(config.tank_armor, 400)


func test_from_dict_ignores_unknown_keys() -> void:
	var config := BalanceConfig.new()
	var original_gold := config.starting_gold
	var dict := {"unknown_key": 999}

	config.from_dict(dict)

	assert_eq(config.starting_gold, original_gold)


func test_from_dict_partial_update() -> void:
	var config := BalanceConfig.new()
	config.starting_gold = 100
	config.wall_cost = 10
	var dict := {"starting_gold": 200}

	config.from_dict(dict)

	assert_eq(config.starting_gold, 200)
	assert_eq(config.wall_cost, 10)  # Unchanged


# ============================================
# Roundtrip tests
# ============================================


func test_roundtrip_preserves_values() -> void:
	var config1 := BalanceConfig.new()
	config1.starting_gold = 150
	config1.archer_damage = 20000
	config1.grunt_hp = 75

	var dict := config1.to_dict()

	var config2 := BalanceConfig.new()
	config2.from_dict(dict)

	assert_eq(config2.starting_gold, 150)
	assert_eq(config2.archer_damage, 20000)
	assert_eq(config2.grunt_hp, 75)


func test_roundtrip_all_values() -> void:
	var config1 := BalanceConfig.new()
	var dict1 := config1.to_dict()

	var config2 := BalanceConfig.new()
	config2.from_dict(dict1)

	var dict2 := config2.to_dict()

	# All keys should match
	for key in dict1:
		assert_eq(dict2[key], dict1[key], "Mismatch for key: " + key)


# ============================================
# get_parameter_bounds() tests
# ============================================


func test_get_parameter_bounds_has_economy() -> void:
	var bounds := BalanceConfig.get_parameter_bounds()

	assert_has(bounds, "starting_gold")
	assert_has(bounds.starting_gold, "min")
	assert_has(bounds.starting_gold, "max")
	assert_has(bounds.starting_gold, "step")


func test_get_parameter_bounds_valid_ranges() -> void:
	var bounds := BalanceConfig.get_parameter_bounds()

	for key in bounds:
		var b = bounds[key]
		assert_lt(b.min, b.max, "Invalid range for " + key)
		assert_gt(b.step, 0, "Invalid step for " + key)


func test_get_parameter_bounds_matches_dict_keys() -> void:
	var config := BalanceConfig.new()
	var dict := config.to_dict()
	var bounds := BalanceConfig.get_parameter_bounds()

	# Not all dict keys need bounds, but all bounds should be valid keys
	for key in bounds:
		assert_has(dict, key, "Bounds key not in dict: " + key)


# ============================================
# Default values tests
# ============================================


func test_default_starting_gold() -> void:
	var config := BalanceConfig.new()
	assert_eq(config.starting_gold, 120)


func test_default_shrine_hp() -> void:
	var config := BalanceConfig.new()
	assert_eq(config.shrine_hp, 100)


func test_default_archer_stats() -> void:
	var config := BalanceConfig.new()
	assert_eq(config.archer_cost, 80)
	assert_eq(config.archer_damage, 15000)
	assert_eq(config.archer_attack_speed_ms, 800)
	assert_eq(config.archer_range, 5)


func test_default_grunt_stats() -> void:
	var config := BalanceConfig.new()
	assert_eq(config.grunt_hp, 60)
	assert_eq(config.grunt_speed, 1000)
	assert_eq(config.grunt_gold, 5)


# ============================================
# File I/O tests (using temp file)
# ============================================


func test_save_and_load_file() -> void:
	var config1 := BalanceConfig.new()
	config1.starting_gold = 175
	config1.archer_damage = 18000

	var temp_path := "user://test_balance_config.json"
	var save_err := config1.save_to_file(temp_path)
	assert_eq(save_err, OK)

	var config2 := BalanceConfig.new()
	var load_err := config2.load_from_file(temp_path)
	assert_eq(load_err, OK)

	assert_eq(config2.starting_gold, 175)
	assert_eq(config2.archer_damage, 18000)

	# Cleanup
	DirAccess.remove_absolute(temp_path)


func test_load_nonexistent_file() -> void:
	var config := BalanceConfig.new()

	var err := config.load_from_file("user://nonexistent_file.json")

	assert_ne(err, OK)


func test_save_creates_valid_json() -> void:
	var config := BalanceConfig.new()
	var temp_path := "user://test_balance_config2.json"

	config.save_to_file(temp_path)

	var file := FileAccess.open(temp_path, FileAccess.READ)
	var content := file.get_as_text()
	file.close()

	var json := JSON.new()
	var parse_err := json.parse(content)
	assert_eq(parse_err, OK)

	# Cleanup
	DirAccess.remove_absolute(temp_path)
