extends GutTest

## Unit tests for combat special effect handlers

var _game_state: GameState
var _pathfinding: SimPathfinding


func before_each() -> void:
	_game_state = TestHelpers.create_test_game_state()
	_pathfinding = _game_state.pathfinding


# ============================================
# Crit chance tests
# ============================================

func test_crit_chance_doubles_damage() -> void:
	# Use fixed RNG that always crits
	_game_state.rng.set_seed(42)
	var tower := _create_tower_with_special({"crit_chance": 1000})  # 100%
	var enemy := _spawn_enemy_at(Vector2(10, 10))

	var damage := Combat._calculate_damage(tower, enemy, _game_state.rng)

	assert_eq(damage, tower.damage * 2)


func test_crit_chance_respects_probability() -> void:
	var tower := _create_tower_with_special({"crit_chance": 0})  # 0%
	var enemy := _spawn_enemy_at(Vector2(10, 10))

	var damage := Combat._calculate_damage(tower, enemy, _game_state.rng)

	assert_eq(damage, tower.damage)  # No crit


# ============================================
# Instakill threshold tests
# ============================================

func test_instakill_threshold_kills_low_hp() -> void:
	var tower := _create_tower_with_special({"instakill_threshold": 50})
	var enemy := _spawn_enemy_at(Vector2(10, 10))
	enemy.hp = 30  # Below threshold

	var damage := Combat._calculate_damage(tower, enemy, _game_state.rng)

	# Should deal enough to kill
	assert_gt(damage, enemy.hp * 1000)


func test_instakill_threshold_no_effect_above() -> void:
	var tower := _create_tower_with_special({"instakill_threshold": 50})
	tower.damage = 15000
	var enemy := _spawn_enemy_at(Vector2(10, 10))
	enemy.hp = 100  # Above threshold

	var damage := Combat._calculate_damage(tower, enemy, _game_state.rng)

	assert_eq(damage, tower.damage)


# ============================================
# Slow damage amp tests
# ============================================

func test_slow_damage_amp_increases_damage_when_slowed() -> void:
	var tower := _create_tower_with_special({"slow_damage_amp": 500})  # +50%
	tower.damage = 10000
	var enemy := _spawn_enemy_at(Vector2(10, 10))
	enemy.apply_slow(300, 2000)

	var damage := Combat._calculate_damage(tower, enemy, _game_state.rng)

	assert_eq(damage, 15000)  # 10000 * 1.5


func test_slow_damage_amp_no_effect_unslowed() -> void:
	var tower := _create_tower_with_special({"slow_damage_amp": 500})
	tower.damage = 10000
	var enemy := _spawn_enemy_at(Vector2(10, 10))
	# No slow applied

	var damage := Combat._calculate_damage(tower, enemy, _game_state.rng)

	assert_eq(damage, 10000)


# ============================================
# Freeze chance tests
# ============================================

func test_freeze_chance_applies_stun() -> void:
	var tower := _create_tower_with_special({"freeze_chance": 1000})  # 100%
	var enemy := _spawn_enemy_at(Vector2(10, 10))

	Combat._apply_tower_effects(tower, enemy, _game_state)

	assert_true(enemy.is_stunned)


func test_freeze_chance_stun_duration_2000ms() -> void:
	var tower := _create_tower_with_special({"freeze_chance": 1000})  # 100%
	var enemy := _spawn_enemy_at(Vector2(10, 10))

	Combat._apply_tower_effects(tower, enemy, _game_state)

	assert_eq(enemy.stun_duration_ms, 2000)


# ============================================
# Stun on hit tests
# ============================================

func test_stun_ms_applies_on_every_hit() -> void:
	var tower := _create_tower_with_special({"stun_ms": 300})
	var enemy := _spawn_enemy_at(Vector2(10, 10))

	Combat._apply_tower_effects(tower, enemy, _game_state)

	assert_true(enemy.is_stunned)
	assert_eq(enemy.stun_duration_ms, 300)


# ============================================
# Armor pen tests
# ============================================

func test_armor_pen_reduces_armor_effectiveness() -> void:
	var tower := _create_tower_with_special({"armor_pen": 500})  # 50%
	tower.damage = 10000
	var enemy := _spawn_enemy_with_armor(Vector2(10, 10), 500)  # 50% armor

	var damage := Combat._calculate_damage(tower, enemy, _game_state.rng)

	# With 50% armor, normally 5000 damage
	# With 50% armor pen, effective armor = 25%, so 7500 damage
	assert_gt(damage, 5000)


func test_armor_pen_500_halves_armor() -> void:
	var tower := _create_tower_with_special({"armor_pen": 500})  # 50%
	tower.damage = 20000
	var enemy := _spawn_enemy_with_armor(Vector2(10, 10), 800)  # 80% armor

	var damage := Combat._calculate_damage(tower, enemy, _game_state.rng)

	# 80% armor with 50% pen = 40% effective armor
	# Without armor pen: 20000 * 0.2 = 4000 damage
	# With armor pen: should be higher than 4000
	assert_gt(damage, 4000)


# ============================================
# Breaker bonus tests
# ============================================

func test_breaker_bonus_increases_damage_vs_breaker() -> void:
	var tower := _create_tower_with_special({"breaker_bonus": 1000})  # +100%
	tower.damage = 10000
	var enemy := _spawn_breaker_at(Vector2(10, 10))

	var damage := Combat._calculate_damage(tower, enemy, _game_state.rng)

	assert_eq(damage, 20000)


func test_breaker_bonus_no_effect_vs_normal() -> void:
	var tower := _create_tower_with_special({"breaker_bonus": 1000})
	tower.damage = 10000
	var enemy := _spawn_enemy_at(Vector2(10, 10))

	var damage := Combat._calculate_damage(tower, enemy, _game_state.rng)

	assert_eq(damage, 10000)


# ============================================
# Beam mode tests
# ============================================

func test_beam_tower_deals_continuous_damage() -> void:
	var tower := _create_tower_with_special({"beam": true})
	tower.damage = 10000  # DPS
	tower.range_tiles = 10  # Ensure range covers enemy
	tower.position = Vector2i(5, 5)
	_place_tower_in_state(tower)
	var enemy := _spawn_enemy_at(Vector2(8, 8))  # Within range
	var initial_hp := enemy.hp

	Combat.process_tower_attacks(_game_state, 1000)  # 1 second

	# Should deal ~10 damage (10000 x1000 over 1 second)
	assert_eq(enemy.hp, initial_hp - 10)


func test_beam_tower_no_cooldown() -> void:
	var tower := _create_tower_with_special({"beam": true})
	tower.damage = 10000
	tower.range_tiles = 10
	tower.position = Vector2i(5, 5)
	_place_tower_in_state(tower)
	var enemy := _spawn_enemy_at(Vector2(8, 8))

	# Process twice
	Combat.process_tower_attacks(_game_state, 500)
	var hp_after_first := enemy.hp
	Combat.process_tower_attacks(_game_state, 500)

	# Both ticks should deal damage
	assert_lt(enemy.hp, hp_after_first)


# ============================================
# Pierce tests
# ============================================

func test_pierce_hits_multiple_enemies() -> void:
	var tower := _create_tower_with_special({"pierce": 3})
	tower.position = Vector2i(0, 0)  # Tower at origin

	# Enemies in a line from tower (diagonal direction)
	var enemies: Array[SimEnemy] = [
		_spawn_enemy_at(Vector2(6, 6)),   # First target
		_spawn_enemy_at(Vector2(8, 8)),   # Same direction
		_spawn_enemy_at(Vector2(10, 10)), # Same direction
	]

	var hit := tower.get_pierce_targets(enemies[0], enemies)

	assert_gt(hit.size(), 1)


func test_pierce_respects_count_limit() -> void:
	var tower := _create_tower_with_special({"pierce": 2})
	tower.position = Vector2i(0, 0)

	# Enemies in a line from tower
	var enemies: Array[SimEnemy] = [
		_spawn_enemy_at(Vector2(6, 6)),
		_spawn_enemy_at(Vector2(8, 8)),
		_spawn_enemy_at(Vector2(10, 10)),
		_spawn_enemy_at(Vector2(12, 12)),
	]

	var hit := tower.get_pierce_targets(enemies[0], enemies)

	assert_eq(hit.size(), 2)


# ============================================
# Line pierce (railgun) tests
# ============================================

func test_pierce_line_hits_all_in_line() -> void:
	var tower := _create_tower_with_special({"pierce_line": true})
	tower.position = Vector2i(0, 9)  # Center will be (1, 10)

	# Enemies in horizontal line at y=10 (tower center y + 0)
	var enemies: Array[SimEnemy] = [
		_spawn_enemy_at(Vector2(5, 10)),   # In line
		_spawn_enemy_at(Vector2(8, 10)),   # In line
		_spawn_enemy_at(Vector2(12, 10)),  # In line
		_spawn_enemy_at(Vector2(5, 16)),   # Off line (> 0.5 perp distance)
	]

	var hit := Combat._get_line_targets(tower, enemies[0], enemies)

	assert_eq(hit.size(), 3)  # All in line


func test_pierce_line_orders_by_distance() -> void:
	var tower := _create_tower_with_special({"pierce_line": true})
	tower.position = Vector2i(0, 9)  # Center will be (1, 10)

	var enemies: Array[SimEnemy] = [
		_spawn_enemy_at(Vector2(10, 10)),
		_spawn_enemy_at(Vector2(5, 10)),
		_spawn_enemy_at(Vector2(8, 10)),
	]

	var hit := Combat._get_line_targets(tower, enemies[1], enemies)

	# Should be ordered by distance from tower
	assert_eq(hit.size(), 3)
	assert_eq(hit[0].grid_pos.x, 5.0)
	assert_eq(hit[1].grid_pos.x, 8.0)
	assert_eq(hit[2].grid_pos.x, 10.0)


# ============================================
# Barrage tests
# ============================================

func test_barrage_schedules_delayed_damage() -> void:
	var tower := _create_tower_with_special({"barrage": true})
	tower.aoe_radius = 1500
	tower.range_tiles = 10
	tower.position = Vector2i(5, 5)
	_place_tower_in_state(tower)
	var enemy := _spawn_enemy_at(Vector2(8, 8))

	Combat.process_tower_attacks(_game_state, 100)

	# Should have scheduled delayed damage
	assert_gt(_game_state.delayed_damage_queue.size(), 0)


func test_barrage_4_hits_over_3_seconds() -> void:
	var tower := _create_tower_with_special({"barrage": true})
	tower.aoe_radius = 1500
	tower.range_tiles = 10
	tower.position = Vector2i(5, 5)
	_place_tower_in_state(tower)
	var enemy := _spawn_enemy_at(Vector2(8, 8))

	Combat.process_tower_attacks(_game_state, 100)

	# 4 scheduled hits
	assert_eq(_game_state.delayed_damage_queue.size(), 4)


# ============================================
# Cluster tests
# ============================================

func test_cluster_spawns_sub_explosions() -> void:
	var tower := _create_tower_with_special({"cluster": 4})
	tower.aoe_radius = 1000
	tower.range_tiles = 10
	tower.position = Vector2i(5, 5)
	_place_tower_in_state(tower)

	var enemies: Array[SimEnemy] = []
	# Spawn target and enemies around it (within cluster radius)
	var target := _spawn_enemy_at(Vector2(8, 8))
	enemies.append(target)
	for i in range(4):
		var angle := float(i) / 4.0 * TAU
		var pos := Vector2(8, 8) + Vector2(cos(angle), sin(angle)) * 1.0
		enemies.append(_spawn_enemy_at(pos))

	var initial_hp_sum := 0
	for e in enemies:
		initial_hp_sum += e.hp

	Combat.process_tower_attacks(_game_state, 100)

	var hp_sum := 0
	for e in enemies:
		hp_sum += e.hp

	# Should have dealt damage via cluster explosions
	assert_lt(hp_sum, initial_hp_sum)


# ============================================
# Shatter (on kill) tests
# ============================================

func test_shatter_deals_aoe_on_kill() -> void:
	var tower := _create_tower_with_special({"shatter_damage": 5000})
	tower.damage = 200000  # Guaranteed kill
	tower.range_tiles = 10
	tower.position = Vector2i(5, 5)
	_place_tower_in_state(tower)

	var target := _spawn_enemy_at(Vector2(8, 8))
	target.hp = 10  # Low HP to ensure kill
	var nearby := _spawn_enemy_at(Vector2(8.5, 8.5))
	var initial_nearby_hp := nearby.hp

	Combat.process_tower_attacks(_game_state, 100)

	assert_lt(nearby.hp, initial_nearby_hp)


func test_shatter_no_effect_if_not_killed() -> void:
	var tower := _create_tower_with_special({"shatter_damage": 5000})
	tower.damage = 1000  # Low damage, won't kill
	tower.range_tiles = 10
	tower.position = Vector2i(5, 5)
	_place_tower_in_state(tower)

	var target := _spawn_enemy_at(Vector2(8, 8))
	target.hp = 100
	var nearby := _spawn_enemy_at(Vector2(8.5, 8.5))
	var initial_nearby_hp := nearby.hp

	Combat.process_tower_attacks(_game_state, 100)

	# Nearby should not have shatter damage
	assert_eq(nearby.hp, initial_nearby_hp)


# ============================================
# Disable effect tests
# ============================================

func test_disable_prevents_regen() -> void:
	var tower := _create_tower_with_special({"disable": true})
	var enemy := _spawn_enemy_at(Vector2(10, 10))
	enemy.regen_per_sec = 5000
	enemy.hp = 50
	enemy.max_hp = 100

	Combat._apply_tower_effects(tower, enemy, _game_state)
	enemy.process_status_effects(1000)

	# Should not regen due to disable
	assert_eq(enemy.hp, 50)


# ============================================
# Helpers
# ============================================

func _create_tower_with_special(special: Dictionary) -> SimTower:
	var data := TestHelpers.create_basic_tower_data()
	data.special = special
	var tower := SimTower.new()
	tower.initialize(data, Vector2i(5, 5))
	return tower


func _place_tower_in_state(tower: SimTower) -> void:
	_game_state.towers.append(tower)


func _spawn_enemy_at(pos: Vector2) -> SimEnemy:
	var data := TestHelpers.create_basic_enemy_data()
	var enemy := SimEnemy.new()
	enemy.initialize(data, Vector2i(pos), _pathfinding)
	enemy.grid_pos = pos
	_game_state.enemies.append(enemy)
	return enemy


func _spawn_enemy_with_armor(pos: Vector2, armor: int) -> SimEnemy:
	var data := TestHelpers.create_basic_enemy_data()
	data.armor = armor
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
