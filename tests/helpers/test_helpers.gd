extends RefCounted
class_name TestHelpers

## Common test fixtures and helper methods

static func create_basic_enemy_data(id: String = "grunt") -> EnemyData:
	var data := EnemyData.new()
	data.id = id
	data.display_name = id.capitalize()
	data.hp = 100
	data.speed = 1000  # 1 tile/sec
	data.armor = 0
	data.gold_value = 10
	return data


static func create_armored_enemy_data(armor: int = 300) -> EnemyData:
	var data := create_basic_enemy_data("tank")
	data.hp = 200
	data.armor = armor
	data.speed = 600
	data.gold_value = 25
	return data


static func create_fast_enemy_data() -> EnemyData:
	var data := create_basic_enemy_data("runner")
	data.hp = 40
	data.speed = 2000  # 2 tiles/sec
	data.gold_value = 8
	return data


static func create_stealth_enemy_data() -> EnemyData:
	var data := create_basic_enemy_data("stealth")
	data.hp = 50
	data.speed = 1400
	data.special = {"stealth": true}
	data.gold_value = 15
	return data


static func create_flying_enemy_data() -> EnemyData:
	var data := create_basic_enemy_data("flyer")
	data.hp = 45
	data.speed = 1200
	data.special = {"flying": true}
	data.gold_value = 12
	return data


static func create_wall_breaker_enemy_data() -> EnemyData:
	var data := create_basic_enemy_data("breaker")
	data.hp = 180
	data.speed = 700
	data.armor = 200
	data.special = {"wall_breaker": true, "wall_damage": 25}
	data.gold_value = 20
	return data


static func create_regen_enemy_data() -> EnemyData:
	var data := create_basic_enemy_data("boss")
	data.hp = 500
	data.speed = 400
	data.armor = 400
	data.special = {"regen_per_sec": 5000}
	data.gold_value = 100
	return data


static func create_basic_tower_data(id: String = "archer") -> TowerData:
	var data := TowerData.new()
	data.id = id
	data.display_name = id.capitalize()
	data.base_cost = 80
	data.damage = 15000  # 15 damage
	data.attack_speed_ms = 800
	data.range_tiles = 5
	data.aoe_radius = 0
	data.upgrade_cost_t2 = 60
	data.upgrade_cost_t3 = 100
	return data


static func create_aoe_tower_data() -> TowerData:
	var data := create_basic_tower_data("cannon")
	data.base_cost = 120
	data.damage = 25000
	data.attack_speed_ms = 1500
	data.range_tiles = 4
	data.aoe_radius = 1500  # 1.5 tiles
	return data


static func create_frost_tower_data() -> TowerData:
	var data := create_basic_tower_data("frost")
	data.base_cost = 100
	data.damage = 8000
	data.attack_speed_ms = 600
	data.range_tiles = 4
	data.special = {"slow": 400, "slow_duration_ms": 2500}
	return data


static func create_lightning_tower_data() -> TowerData:
	var data := create_basic_tower_data("lightning")
	data.base_cost = 140
	data.damage = 12000
	data.attack_speed_ms = 1200
	data.range_tiles = 5
	data.special = {"chain": 4, "chain_range": 2.5}
	return data


static func create_flame_tower_data() -> TowerData:
	var data := create_basic_tower_data("flame")
	data.base_cost = 90
	data.damage = 6000
	data.attack_speed_ms = 400
	data.range_tiles = 3
	data.special = {"burn_dps": 10000, "burn_duration_ms": 4000}
	return data


static func create_stun_tower_data() -> TowerData:
	var data := create_basic_tower_data("stun")
	data.damage = 5000
	data.attack_speed_ms = 1000
	data.range_tiles = 4
	data.special = {"stun_chance": 500, "stun_duration_ms": 500}
	return data


static func create_basic_map_data(width: int = 20, height: int = 20) -> MapData:
	var data := MapData.new()
	data.id = "test_map"
	data.display_name = "Test Map"
	data.width = width
	data.height = height
	data.spawn_points = [Vector2i(0, 10)]
	data.shrine_zone_start = Vector2i(18, 9)
	data.shrine_zone_end = Vector2i(19, 11)
	return data


static func create_multi_spawn_map_data() -> MapData:
	var data := create_basic_map_data()
	data.spawn_points = [Vector2i(0, 5), Vector2i(0, 15)]
	return data


static func create_basic_wave_data() -> WaveData:
	var data := WaveData.new()
	var wave := SingleWaveData.new()
	wave.wave_number = 1
	wave.spawn_interval_ms = 800

	var spawn := WaveSpawnData.new()
	spawn.enemy_id = "grunt"
	spawn.count = 5
	spawn.spawn_point_index = 0
	wave.spawns = [spawn]

	data.waves = [wave]
	return data


static func create_multi_wave_data(wave_count: int = 3) -> WaveData:
	var data := WaveData.new()
	var waves: Array[SingleWaveData] = []

	for i in range(wave_count):
		var wave := SingleWaveData.new()
		wave.wave_number = i + 1
		wave.spawn_interval_ms = 800

		var spawn := WaveSpawnData.new()
		spawn.enemy_id = "grunt"
		spawn.count = 5 + i * 2
		spawn.spawn_point_index = 0
		wave.spawns = [spawn]

		waves.append(wave)

	data.waves = waves
	return data


static func create_upgrade_data(tier: int, branch: String) -> TowerUpgradeData:
	var data := TowerUpgradeData.new()
	data.id = "test_upgrade_%d_%s" % [tier, branch]
	data.display_name = "Test Upgrade T%d %s" % [tier, branch]
	data.tier = tier
	data.branch = branch
	data.parent_branch = "" if tier == 2 else branch[0]
	data.damage = 20000 if tier == 2 else 30000
	data.attack_speed_ms = 700 if tier == 2 else 600
	data.range_tiles = 6
	data.aoe_radius = 0
	return data


static func create_test_game_state() -> GameState:
	var map := create_basic_map_data()
	var waves := create_basic_wave_data()
	var state := GameState.new()
	state.initialize(map, waves, 12345)
	state.register_enemy_data(create_basic_enemy_data())
	state.register_tower_data(create_basic_tower_data())
	return state


static func create_test_pathfinding(width: int = 20, height: int = 20) -> SimPathfinding:
	var pf := SimPathfinding.new(width, height)
	pf.set_shrine_position(Vector2i(19, 10))
	return pf


static func create_enemy_at_position(pos: Vector2, data: EnemyData = null, pathfinding: SimPathfinding = null) -> SimEnemy:
	if not data:
		data = create_basic_enemy_data()
	if not pathfinding:
		pathfinding = create_test_pathfinding()

	var enemy := SimEnemy.new()
	enemy.initialize(data, Vector2i(pos), pathfinding)
	enemy.grid_pos = pos
	return enemy


static func create_tower_at_position(pos: Vector2i, data: TowerData = null) -> SimTower:
	if not data:
		data = create_basic_tower_data()

	var tower := SimTower.new()
	tower.initialize(data, pos)
	return tower
