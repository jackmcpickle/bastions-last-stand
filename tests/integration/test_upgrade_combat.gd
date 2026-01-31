extends GutTest

## Integration tests for upgraded towers in combat

var _game_state: GameState
var _pathfinding: SimPathfinding


func before_each() -> void:
	_game_state = TestHelpers.create_test_game_state()
	_pathfinding = _game_state.pathfinding


# ============================================
# Archer upgrade tests
# ============================================

func test_archer_marksman_crits_in_combat() -> void:
	var tower := _create_upgraded_tower("archer", {
		"crit_chance": 1000  # 100% crit
	})
	tower.damage = 10000
	_place_tower(tower)
	var enemy := _spawn_enemy_at(Vector2(10, 10))
	var initial_hp := enemy.hp

	Combat.process_tower_attacks(_game_state, 100)

	# With crit, should deal double damage (20 instead of 10)
	assert_eq(enemy.hp, initial_hp - 20)


func test_archer_sniper_executes_low_hp() -> void:
	var tower := _create_upgraded_tower("archer", {
		"instakill_threshold": 50
	})
	tower.damage = 5000  # 5 damage
	_place_tower(tower)
	var enemy := _spawn_enemy_at(Vector2(10, 10))
	enemy.hp = 30  # Below threshold

	Combat.process_tower_attacks(_game_state, 100)

	assert_true(enemy.is_dead())


# ============================================
# Frost upgrade tests
# ============================================

func test_frost_frostbite_amps_damage() -> void:
	var tower := _create_upgraded_tower("frost", {
		"slow": 400,
		"slow_duration_ms": 3000,
		"slow_damage_amp": 500  # +50% to slowed
	})
	tower.damage = 10000
	_place_tower(tower)

	# Pre-slow the enemy
	var enemy := _spawn_enemy_at(Vector2(10, 10))
	enemy.apply_slow(300, 5000)
	var initial_hp := enemy.hp

	Combat.process_tower_attacks(_game_state, 100)

	# 10000 damage + 50% = 15000 = 15 HP
	assert_eq(enemy.hp, initial_hp - 15)


func test_frost_glacier_freezes_enemies() -> void:
	var tower := _create_upgraded_tower("frost", {
		"freeze_chance": 1000  # 100%
	})
	_place_tower(tower)
	var enemy := _spawn_enemy_at(Vector2(10, 10))

	Combat.process_tower_attacks(_game_state, 100)

	assert_true(enemy.is_stunned)
	assert_eq(enemy.stun_duration_ms, 2000)


func test_frost_shatter_on_kill_damages_nearby() -> void:
	var tower := _create_upgraded_tower("frost", {
		"shatter_damage": 8000
	})
	tower.damage = 200000
	_place_tower(tower)

	var target := _spawn_enemy_at(Vector2(10, 10))
	target.hp = 5
	var nearby := _spawn_enemy_at(Vector2(10.5, 10.5))
	var initial_nearby_hp := nearby.hp

	Combat.process_tower_attacks(_game_state, 100)

	# Shatter should damage nearby
	assert_lt(nearby.hp, initial_nearby_hp)


# ============================================
# Lightning upgrade tests
# ============================================

func test_lightning_beam_continuous_damage() -> void:
	var tower := _create_upgraded_tower("lightning", {
		"beam": true
	})
	tower.damage = 20000  # 20 DPS
	_place_tower(tower)
	var enemy := _spawn_enemy_at(Vector2(10, 10))
	var initial_hp := enemy.hp

	# Process 500ms
	Combat.process_tower_attacks(_game_state, 500)

	# 20 DPS * 0.5s = 10 damage
	assert_eq(enemy.hp, initial_hp - 10)


func test_lightning_overcharge_chains_more() -> void:
	var tower := _create_upgraded_tower("lightning", {
		"chain": 6,
		"chain_range": 3.0
	})
	_place_tower(tower)

	# Line of enemies
	var enemies: Array[SimEnemy] = []
	for i in range(8):
		enemies.append(_spawn_enemy_at(Vector2(8 + i * 0.5, 10)))

	Combat.process_tower_attacks(_game_state, 100)

	# Count damaged enemies
	var damaged := 0
	for e in enemies:
		if e.hp < 100:
			damaged += 1

	assert_eq(damaged, 6)


# ============================================
# Flame upgrade tests
# ============================================

func test_flame_hellfire_creates_ground_effect() -> void:
	var tower := _create_upgraded_tower("flame", {
		"ground_burn": true,
		"burn_dps": 15000,
		"burn_duration_ms": 4000
	})
	tower.aoe_radius = 1500
	_place_tower(tower)
	_spawn_enemy_at(Vector2(10, 10))

	Combat.process_tower_attacks(_game_state, 100)

	assert_gt(_game_state.ground_effects.size(), 0)


func test_flame_napalm_stacks_burns() -> void:
	var tower := _create_upgraded_tower("flame", {
		"burn_dps": 8000,
		"burn_duration_ms": 3000,
		"burn_stacks": 5  # Can stack 5 burns
	})
	_place_tower(tower)
	var enemy := _spawn_enemy_at(Vector2(10, 10))

	# Attack 3 times
	for i in range(3):
		tower.cooldown_ms = 0
		Combat.process_tower_attacks(_game_state, 100)

	assert_eq(enemy.burn_stacks.size(), 3)


# ============================================
# Cannon upgrade tests
# ============================================

func test_cannon_railgun_pierces_line() -> void:
	var tower := _create_upgraded_tower("cannon", {
		"pierce_line": true
	})
	tower.position = Vector2i(0, 9)  # Center at (1, 10)
	_place_tower(tower)

	# Enemies in horizontal line at y=10
	var e1 := _spawn_enemy_at(Vector2(5, 10))
	var e2 := _spawn_enemy_at(Vector2(8, 10))
	var e3 := _spawn_enemy_at(Vector2(11, 10))
	var off_line := _spawn_enemy_at(Vector2(5, 16))  # Far off the line

	Combat.process_tower_attacks(_game_state, 100)

	# All in line should be damaged
	assert_lt(e1.hp, 100)
	assert_lt(e2.hp, 100)
	assert_lt(e3.hp, 100)
	# Off line should not
	assert_eq(off_line.hp, 100)


func test_cannon_siege_bonus_vs_breaker() -> void:
	var tower := _create_upgraded_tower("cannon", {
		"breaker_bonus": 1000  # +100%
	})
	tower.damage = 20000
	_place_tower(tower)
	var breaker := _spawn_breaker_at(Vector2(8, 8))
	var initial_hp := breaker.hp

	Combat.process_tower_attacks(_game_state, 100)

	# 20000 damage * 2 (breaker bonus) = 40000
	# After 20% armor reduction: 40000 * 0.8 = 32000 = 32 HP
	assert_eq(breaker.hp, initial_hp - 32)


func test_cannon_howitzer_barrage() -> void:
	var tower := _create_upgraded_tower("cannon", {
		"barrage": true
	})
	tower.aoe_radius = 2000
	_place_tower(tower)
	_spawn_enemy_at(Vector2(10, 10))

	Combat.process_tower_attacks(_game_state, 100)

	# Should schedule 4 delayed hits
	assert_eq(_game_state.delayed_damage_queue.size(), 4)


# ============================================
# Mixed combat scenarios
# ============================================

func test_upgraded_towers_track_stats() -> void:
	var tower := _create_upgraded_tower("archer", {"crit_chance": 500})
	tower.damage = 10000
	_place_tower(tower)

	for i in range(5):
		_spawn_enemy_at(Vector2(10 + i * 0.2, 10))

	# Multiple attacks
	for i in range(5):
		tower.cooldown_ms = 0
		Combat.process_tower_attacks(_game_state, 100)

	assert_eq(tower.shots_fired, 5)
	assert_gt(tower.total_damage_dealt, 0)


# ============================================
# Helpers
# ============================================

func _create_upgraded_tower(base_id: String, special: Dictionary) -> SimTower:
	var data := TestHelpers.create_basic_tower_data(base_id)
	data.special = special
	data.range_tiles = 10  # Ensure adequate range for tests
	var tower := SimTower.new()
	tower.initialize(data, Vector2i(5, 5))
	tower.tier = 3
	tower.branch = "A1"
	return tower


func _place_tower(tower: SimTower) -> void:
	_game_state.towers.append(tower)


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
