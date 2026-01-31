class_name GameState
extends RefCounted

## Main game state container for headless simulation

signal enemy_spawned(enemy: SimEnemy)
signal enemy_killed(enemy: SimEnemy, gold_earned: int)
signal enemy_reached_shrine(enemy: SimEnemy, damage: int)
signal tower_placed(tower: SimTower)
signal tower_attacked(tower: SimTower, target: SimEnemy, damage: int)
signal wall_placed(wall: SimWall)
signal wall_destroyed(wall: SimWall)
signal wave_started(wave_number: int)
signal wave_completed(wave_number: int)
signal shrine_damaged(damage: int, current_hp: int)
signal game_over(won: bool)

## Configuration
var map_data: MapData
var wave_data: WaveData
var tower_registry: Dictionary = {}  # id -> TowerData
var enemy_registry: Dictionary = {}  # id -> EnemyData

## Core systems
var pathfinding: SimPathfinding
var rng: RandomManager

## Game state
var current_wave: int = 0
var gold: int = 200
var shrine: SimShrine
var towers: Array[SimTower] = []
var walls: Array[SimWall] = []
var enemies: Array[SimEnemy] = []
var ground_effects: Array = []  # Array of SimGroundEffect
var delayed_damage_queue: Array[Dictionary] = []  # {time_ms, position, damage, aoe_radius}
var dead_enemies: Array[Dictionary] = []  # {id, position} for necromancer resurrection
const MAX_DEAD_ENEMIES := 20  # Limit tracked dead enemies

## Tracking
var total_gold_earned: int = 0
var total_gold_spent: int = 0
var total_damage_dealt: int = 0  # x1000
var enemies_killed: int = 0
var enemies_leaked: int = 0

## Wave state
var wave_in_progress: bool = false
var wave_enemies_remaining: int = 0
var spawn_queue: Array[Dictionary] = []  # {enemy_id, spawn_point, delay_remaining}

## Constants
const STARTING_GOLD := 120
const SHRINE_HP := 100
const TICK_MS := 100  # 0.1 seconds per tick


func _init() -> void:
	pass


## Balance config (set via initialize_with_config)
var balance_config: BalanceConfig


func initialize(p_map_data: MapData, p_wave_data: WaveData, seed: int = 0) -> void:
	initialize_with_config(p_map_data, p_wave_data, null, seed)


func initialize_with_config(p_map_data: MapData, p_wave_data: WaveData, config: BalanceConfig, seed: int = 0) -> void:
	map_data = p_map_data
	wave_data = p_wave_data
	balance_config = config if config else BalanceConfig.new()
	rng = RandomManager.new(seed)
	
	# Initialize pathfinding
	pathfinding = SimPathfinding.new(map_data.width, map_data.height)
	
	# Place shrine in center of shrine zone
	var shrine_x := (map_data.shrine_zone_start.x + map_data.shrine_zone_end.x) / 2
	var shrine_y := (map_data.shrine_zone_start.y + map_data.shrine_zone_end.y) / 2
	var shrine_pos := Vector2i(shrine_x, shrine_y)
	
	shrine = SimShrine.new()
	shrine.position = shrine_pos
	shrine.hp = balance_config.shrine_hp
	shrine.max_hp = balance_config.shrine_hp
	
	pathfinding.set_shrine_position(shrine_pos)
	
	# Reset state
	gold = balance_config.starting_gold
	current_wave = 0
	towers.clear()
	walls.clear()
	enemies.clear()
	ground_effects.clear()
	delayed_damage_queue.clear()
	dead_enemies.clear()
	total_gold_earned = 0
	total_gold_spent = 0
	total_damage_dealt = 0
	enemies_killed = 0
	enemies_leaked = 0
	wave_in_progress = false


func register_tower_data(data: TowerData) -> void:
	tower_registry[data.id] = data


func register_enemy_data(data: EnemyData) -> void:
	enemy_registry[data.id] = data


func get_tower_data(id: String) -> TowerData:
	return tower_registry.get(id)


func get_enemy_data(id: String) -> EnemyData:
	return enemy_registry.get(id)


## Tower placement
func can_place_tower(pos: Vector2i, tower_id: String) -> bool:
	var data := get_tower_data(tower_id)
	if not data:
		return false
	if data.base_cost > gold:
		return false
	if not map_data.can_build_tower(pos):
		return false
	
	# Check tower doesn't overlap existing structures
	for dx in range(2):
		for dy in range(2):
			var check_pos := Vector2i(pos.x + dx, pos.y + dy)
			if _has_structure_at(check_pos):
				return false
			# Don't block shrine
			if check_pos == shrine.position:
				return false
	
	return true


func place_tower(pos: Vector2i, tower_id: String) -> SimTower:
	if not can_place_tower(pos, tower_id):
		return null
	
	var data := get_tower_data(tower_id)
	var tower := SimTower.new()
	tower.initialize(data, pos)
	
	gold -= data.base_cost
	total_gold_spent += data.base_cost
	towers.append(tower)
	
	# Block pathfinding for tower tiles
	for dx in range(2):
		for dy in range(2):
			pathfinding.set_blocked(Vector2i(pos.x + dx, pos.y + dy), true)
	
	tower_placed.emit(tower)
	return tower


## Wall placement
func can_place_wall(pos: Vector2i) -> bool:
	var wall_cost := balance_config.wall_cost if balance_config else 10
	if wall_cost > gold:
		return false
	if not map_data.can_build_wall(pos):
		return false
	if _has_structure_at(pos):
		return false
	if pos == shrine.position:
		return false
	return true


func place_wall(pos: Vector2i) -> SimWall:
	if not can_place_wall(pos):
		return null
	
	var wall_cost := balance_config.wall_cost if balance_config else 10
	
	var wall := SimWall.new()
	wall.position = pos
	wall.hp = 100
	wall.max_hp = 100
	
	gold -= wall_cost
	total_gold_spent += wall_cost
	walls.append(wall)
	
	pathfinding.set_blocked(pos, true)
	
	wall_placed.emit(wall)
	return wall


func _has_structure_at(pos: Vector2i) -> bool:
	for tower in towers:
		if _tower_occupies(tower, pos):
			return true
	for wall in walls:
		if wall.position == pos:
			return true
	return false


func _tower_occupies(tower: SimTower, pos: Vector2i) -> bool:
	return (pos.x >= tower.position.x and pos.x < tower.position.x + 2 and
			pos.y >= tower.position.y and pos.y < tower.position.y + 2)


## Tower upgrades
func can_upgrade_tower(tower: SimTower, upgrade_id: String) -> bool:
	var upgrade := _find_upgrade(tower.data, upgrade_id)
	if not upgrade:
		return false
	var cost := _get_upgrade_cost(tower, upgrade)
	if cost > gold:
		return false
	return tower.can_upgrade_to(upgrade)


func upgrade_tower(tower: SimTower, upgrade_id: String) -> bool:
	if not can_upgrade_tower(tower, upgrade_id):
		return false

	var upgrade := _find_upgrade(tower.data, upgrade_id)
	var cost := _get_upgrade_cost(tower, upgrade)

	gold -= cost
	total_gold_spent += cost
	tower.total_cost += cost
	tower.apply_upgrade(upgrade)
	return true


func _find_upgrade(data: TowerData, upgrade_id: String) -> TowerUpgradeData:
	for upgrade in data.upgrades:
		if upgrade.id == upgrade_id:
			return upgrade
	return null


func _get_upgrade_cost(tower: SimTower, upgrade: TowerUpgradeData) -> int:
	if upgrade.tier == 2:
		return tower.data.upgrade_cost_t2
	elif upgrade.tier == 3:
		return tower.data.upgrade_cost_t3
	return 0


## Wave management
func start_wave(wave_number: int) -> bool:
	if wave_in_progress:
		return false
	
	var wave := wave_data.get_wave(wave_number)
	if not wave:
		return false
	
	current_wave = wave_number
	wave_in_progress = true
	spawn_queue.clear()
	
	# Build spawn queue
	var spawn_delay := 0
	for spawn_group in wave.spawns:
		spawn_delay += spawn_group.delay_ms
		for i in range(spawn_group.count):
			var spawn_point_idx := spawn_group.spawn_point_index
			if spawn_point_idx < 0:
				# Alternate between spawn points
				spawn_point_idx = i % map_data.spawn_points.size()
			
			spawn_queue.append({
				"enemy_id": spawn_group.enemy_id,
				"spawn_point": map_data.spawn_points[spawn_point_idx],
				"delay_remaining": spawn_delay
			})
			spawn_delay += wave.spawn_interval_ms
	
	wave_enemies_remaining = spawn_queue.size()
	wave_started.emit(wave_number)
	return true


func is_wave_complete() -> bool:
	return wave_in_progress and spawn_queue.is_empty() and enemies.is_empty()


func is_game_over() -> bool:
	return shrine.hp <= 0


func is_victory() -> bool:
	return current_wave >= wave_data.get_total_waves() and is_wave_complete()


## Enemy spawning (called by tick processor)
func process_spawns(delta_ms: int) -> void:
	var to_remove: Array[int] = []
	
	for i in range(spawn_queue.size()):
		spawn_queue[i].delay_remaining -= delta_ms
		if spawn_queue[i].delay_remaining <= 0:
			_spawn_enemy(spawn_queue[i].enemy_id, spawn_queue[i].spawn_point)
			to_remove.push_front(i)  # Remove from back to front
	
	for idx in to_remove:
		spawn_queue.remove_at(idx)


func _spawn_enemy(enemy_id: String, spawn_point: Vector2i) -> void:
	var data := get_enemy_data(enemy_id)
	if not data:
		push_error("Unknown enemy type: " + enemy_id)
		return
	
	var enemy := SimEnemy.new()
	enemy.initialize(data, spawn_point, pathfinding)
	enemies.append(enemy)
	enemy_spawned.emit(enemy)


## Get enemies for targeting
func get_enemies_in_range(pos: Vector2i, range_tiles: int) -> Array[SimEnemy]:
	var result: Array[SimEnemy] = []
	var range_sq := range_tiles * range_tiles
	
	for enemy in enemies:
		var dist_sq := _distance_squared(pos, enemy.grid_pos)
		if dist_sq <= range_sq:
			result.append(enemy)
	
	return result


func _distance_squared(a: Vector2i, b: Vector2) -> float:
	var dx := float(a.x) - b.x
	var dy := float(a.y) - b.y
	return dx * dx + dy * dy


## Remove dead enemies
func remove_enemy(enemy: SimEnemy, killed: bool) -> void:
	var idx := enemies.find(enemy)
	if idx >= 0:
		enemies.remove_at(idx)
	
	if killed:
		gold += enemy.gold_value
		total_gold_earned += enemy.gold_value
		enemies_killed += 1
		enemy_killed.emit(enemy, enemy.gold_value)
	else:
		enemies_leaked += 1


## Damage shrine
func damage_shrine(amount: int) -> void:
	shrine.hp -= amount
	if shrine.hp < 0:
		shrine.hp = 0
	shrine_damaged.emit(amount, shrine.hp)
	
	if shrine.hp <= 0:
		wave_in_progress = false
		game_over.emit(false)


## Complete wave
func complete_wave() -> void:
	wave_in_progress = false
	wave_completed.emit(current_wave)

	if current_wave >= wave_data.get_total_waves():
		game_over.emit(true)


## Ground effects
func add_ground_effect(effect) -> void:
	ground_effects.append(effect)


func add_delayed_damage(time_ms: int, position: Vector2, damage: int, aoe_radius: float) -> void:
	delayed_damage_queue.append({
		"time_ms": time_ms,
		"position": position,
		"damage": damage,
		"aoe_radius": aoe_radius
	})


func spawn_enemy_at_position(enemy_id: String, pos: Vector2) -> SimEnemy:
	## Spawn enemy at specific grid position (for splitters, boss spawns)
	var data := get_enemy_data(enemy_id)
	if not data:
		push_error("Unknown enemy type: " + enemy_id)
		return null

	var enemy := SimEnemy.new()
	var spawn_tile := Vector2i(roundi(pos.x), roundi(pos.y))
	enemy.initialize(data, spawn_tile, pathfinding)
	enemy.grid_pos = pos  # Override to exact position

	enemies.append(enemy)
	enemy_spawned.emit(enemy)
	return enemy


func track_dead_enemy(enemy: SimEnemy) -> void:
	## Track dead enemy for necromancer resurrection
	# Don't track mini/spawned enemies or bosses
	if enemy.id == "mini" or enemy.is_boss:
		return

	dead_enemies.append({
		"id": enemy.id,
		"position": enemy.grid_pos
	})

	# Limit tracked enemies
	while dead_enemies.size() > MAX_DEAD_ENEMIES:
		dead_enemies.pop_front()
