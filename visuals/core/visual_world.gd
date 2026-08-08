class_name VisualWorld
extends Node3D

## 3D visual layer subscribing to GameState signals

var game_state: GameState
var faction: String  # "light" or "dark"
var visual_towers: Dictionary = {}  # Vector2i -> VisualTower
var visual_enemies: Dictionary = {}  # SimEnemy -> VisualEnemy
var visual_map: VisualMap
var visual_shrine: VisualShrine


func initialize(p_state: GameState, p_faction: String) -> void:
	game_state = p_state
	faction = p_faction

	# Connect signals
	game_state.tower_placed.connect(_on_tower_placed)
	game_state.enemy_spawned.connect(_on_enemy_spawned)
	game_state.enemy_killed.connect(_on_enemy_killed)
	game_state.enemy_reached_shrine.connect(_on_enemy_reached_shrine)
	game_state.tower_attacked.connect(_on_tower_attacked)
	game_state.shrine_damaged.connect(_on_shrine_damaged)

	# Build terrain
	visual_map = VisualMap.new()
	add_child(visual_map)
	visual_map.build_from_map_data(game_state.map_data)

	# Create shrine
	visual_shrine = VisualShrine.new()
	add_child(visual_shrine)
	visual_shrine.position = GridToWorld.to_world(game_state.shrine.position)
	visual_shrine.set_faction(faction)

	# Create existing towers (if any pre-placed)
	for tower in game_state.towers:
		_on_tower_placed(tower)


func _on_tower_placed(tower: SimTower) -> void:
	var vtower := VisualTower.new()
	add_child(vtower)
	vtower.initialize(tower, faction)
	visual_towers[tower.position] = vtower


func _on_enemy_spawned(enemy: SimEnemy) -> void:
	var venemy := VisualEnemy.new()
	add_child(venemy)
	venemy.initialize(enemy)
	visual_enemies[enemy] = venemy


func _on_enemy_killed(enemy: SimEnemy, _gold_earned: int) -> void:
	_remove_visual_enemy(enemy)


func _on_enemy_reached_shrine(enemy: SimEnemy, _damage: int) -> void:
	_remove_visual_enemy(enemy)


func _remove_visual_enemy(enemy: SimEnemy) -> void:
	if enemy in visual_enemies:
		var venemy: Node = visual_enemies[enemy]
		visual_enemies.erase(enemy)
		venemy.queue_free()


func _on_tower_attacked(tower: SimTower, target: SimEnemy, _damage: int) -> void:
	# TODO: Spawn projectile effect
	var vtower = visual_towers.get(tower.position)
	if vtower:
		vtower.play_attack()


func _on_shrine_damaged(_damage: int, _current_hp: int) -> void:
	if visual_shrine:
		visual_shrine.play_damage()


func _process(delta: float) -> void:
	# Update enemy positions (interpolation)
	for enemy in visual_enemies:
		if is_instance_valid(visual_enemies[enemy]):
			visual_enemies[enemy].update_from_sim(delta)
