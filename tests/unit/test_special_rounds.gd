extends GutTest

## Special-round Rush/Smash combat + spawn coverage

const SiegeGolemData = preload("res://resources/enemies/siege_golem.tres")
const BatteringRamData = preload("res://resources/enemies/battering_ram.tres")

var _game_state: GameState
var _pathfinding: SimPathfinding


func before_each() -> void:
	_game_state = TestHelpers.create_test_game_state()
	_pathfinding = _game_state.pathfinding


func test_siege_golem_slow_immune() -> void:
	var enemy := SimEnemy.new()
	enemy.initialize(SiegeGolemData, Vector2i(4, 10), _pathfinding)

	enemy.apply_slow(400, 2000)

	assert_eq(enemy.slow_amount, 0)
	assert_true(enemy.slow_immune)


func test_siege_golem_destroys_t1_wall_in_two_hits() -> void:
	var wall := SimWall.new()
	wall.position = Vector2i(5, 10)
	wall.hp = 100
	wall.max_hp = 100
	_game_state.walls.append(wall)

	var golem := SimEnemy.new()
	golem.initialize(SiegeGolemData, Vector2i(4, 10), _pathfinding)
	golem.grid_pos = Vector2(4, 10)
	_game_state.enemies.append(golem)

	Combat.process_wall_breaker_attacks(_game_state, 0)
	assert_eq(wall.hp, 50)
	assert_true(wall in _game_state.walls)

	# Wait out attack interval (1000ms)
	Combat.process_wall_breaker_attacks(_game_state, 1000)
	assert_false(wall in _game_state.walls)


func test_battering_ram_charge_deals_triple_impact() -> void:
	var wall := SimWall.new()
	wall.position = Vector2i(5, 10)
	wall.hp = 200
	wall.max_hp = 200
	_game_state.walls.append(wall)

	var ram := SimEnemy.new()
	ram.initialize(BatteringRamData, Vector2i(4, 10), _pathfinding)
	ram.grid_pos = Vector2(4, 10)
	_game_state.enemies.append(ram)

	Combat.process_wall_breaker_attacks(_game_state, 0)

	# Charged hit: 40 * 3 = 120
	assert_eq(wall.hp, 80)
	assert_false(ram.is_charging)
	assert_gt(ram.charge_cooldown_remaining_ms, 0)


func test_battering_ram_cooldown_blocks_immediate_recharge() -> void:
	var wall := SimWall.new()
	wall.position = Vector2i(5, 10)
	wall.hp = 500
	wall.max_hp = 500
	_game_state.walls.append(wall)

	var ram := SimEnemy.new()
	ram.initialize(BatteringRamData, Vector2i(4, 10), _pathfinding)
	ram.grid_pos = Vector2(4, 10)
	_game_state.enemies.append(ram)

	Combat.process_wall_breaker_attacks(_game_state, 0)
	var hp_after_charge := wall.hp

	# Next attack after interval but still on charge cooldown → base 40
	Combat.process_wall_breaker_attacks(_game_state, 800)
	assert_eq(wall.hp, hp_after_charge - 40)
	assert_false(ram.is_charging)


func test_wall_breaker_damages_adjacent_tower() -> void:
	_game_state.gold = 500
	var tower := _game_state.place_tower(Vector2i(5, 9), "archer")
	assert_not_null(tower)
	var initial_hp := tower.hp

	var data := TestHelpers.create_wall_breaker_enemy_data()
	var breaker := SimEnemy.new()
	breaker.initialize(data, Vector2i(4, 10), _pathfinding)
	breaker.grid_pos = Vector2(4, 10)
	_game_state.enemies.append(breaker)

	Combat.process_wall_breaker_attacks(_game_state, 0)

	assert_lt(tower.hp, initial_hp)


func test_destroyed_smash_wall_stays_removed() -> void:
	var wall := SimWall.new()
	wall.position = Vector2i(5, 10)
	wall.hp = 25
	wall.max_hp = 100
	_game_state.walls.append(wall)
	_pathfinding.set_blocked(wall.position, true)

	var data := TestHelpers.create_wall_breaker_enemy_data()
	var breaker := SimEnemy.new()
	breaker.initialize(data, Vector2i(4, 10), _pathfinding)
	breaker.grid_pos = Vector2(4, 10)
	_game_state.enemies.append(breaker)

	Combat.process_wall_breaker_attacks(_game_state, 0)

	assert_false(wall in _game_state.walls)
	assert_false(_pathfinding.is_blocked(Vector2i(5, 10)))

	# Simulate further ticks — wall must not auto-respawn
	Combat.process_wall_breaker_attacks(_game_state, 1000)
	assert_eq(_game_state.walls.size(), 0)


func test_smash_wave_spawns_golem_and_ram() -> void:
	var state := _make_full_roster_state()
	assert_true(state.start_wave(18))
	_drain_spawns(state, 60000)

	var counts := {}
	for enemy in state.enemies:
		counts[enemy.id] = counts.get(enemy.id, 0) + 1
	assert_eq(counts.get("siege_golem", 0), 1)
	assert_eq(counts.get("battering_ram", 0), 2)


func _make_full_roster_state() -> GameState:
	var map := TestHelpers.create_basic_map_data()
	var waves := Waves1To10.create_full()
	var state := GameState.new()
	state.initialize(map, waves, 12345)
	for path in [
		"res://resources/enemies/grunt.tres",
		"res://resources/enemies/runner.tres",
		"res://resources/enemies/tank.tres",
		"res://resources/enemies/flyer.tres",
		"res://resources/enemies/swarm.tres",
		"res://resources/enemies/stealth.tres",
		"res://resources/enemies/breaker.tres",
		"res://resources/enemies/siege_golem.tres",
		"res://resources/enemies/battering_ram.tres",
		"res://resources/enemies/healer.tres",
		"res://resources/enemies/shielded.tres",
		"res://resources/enemies/splitter.tres",
		"res://resources/enemies/regen.tres",
		"res://resources/enemies/mini.tres",
		"res://resources/enemies/boss_golem.tres",
		"res://resources/enemies/swarm_queen.tres",
		"res://resources/enemies/frost_wyrm.tres",
		"res://resources/enemies/phase_phantom.tres",
		"res://resources/enemies/necromancer.tres",
		"res://resources/enemies/iron_colossus.tres",
	]:
		state.register_enemy_data(load(path))
	return state


func _drain_spawns(state: GameState, max_ms: int) -> void:
	var elapsed := 0
	while not state.spawn_queue.is_empty() and elapsed < max_ms:
		state.process_spawns(100)
		elapsed += 100
