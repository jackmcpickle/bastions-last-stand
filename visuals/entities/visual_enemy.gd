class_name VisualEnemy
extends Node3D

## 3D visual for enemy entity

var sim_enemy: SimEnemy
var cube: MeshInstance3D  # Animation target (mesh or placeholder)
var _model: Node3D
var _base_material: StandardMaterial3D


func initialize(enemy: SimEnemy) -> void:
	sim_enemy = enemy
	position = GridToWorld.to_world_v2(enemy.grid_pos)
	_create_model()


func _create_model() -> void:
	_model = ModelLoader.load_enemy_model(sim_enemy.id, sim_enemy.is_boss)
	add_child(_model)
	cube = ModelLoader.find_mesh_instance(_model)

	# Apply enemy color and cache material for stealth updates
	if cube:
		if not cube.material_override:
			var mat := StandardMaterial3D.new()
			mat.albedo_color = _get_enemy_color()
			cube.material_override = mat
		else:
			var mat := cube.material_override as StandardMaterial3D
			if mat:
				mat.albedo_color = _get_enemy_color()
		_base_material = cube.material_override as StandardMaterial3D


func _get_enemy_color() -> Color:
	match sim_enemy.id:
		"grunt":
			return Color("#CC4444")  # Red
		"runner":
			return Color("#44CC44")  # Green
		"tank":
			return Color("#666688")  # Gray-blue
		"flyer":
			return Color("#88CCCC")  # Cyan
		"swarm":
			return Color("#CCCC44")  # Yellow
		"stealth":
			return Color("#884488")  # Purple
		"breaker":
			return Color("#CC8844")  # Orange
		_:
			if sim_enemy.is_boss:
				return Color("#FF0000")  # Bright red for bosses
			return Color("#FF4444")  # Default red


func update_from_sim(delta: float) -> void:
	if not is_instance_valid(sim_enemy):
		return

	var target := GridToWorld.to_world_v2(sim_enemy.grid_pos)

	# Flying enemies hover above ground
	if sim_enemy.is_flying:
		target.y = 1.5

	position = position.lerp(target, delta * 10.0)

	# Update stealth visual via material alpha
	if _base_material:
		if sim_enemy.is_stealth and not sim_enemy.is_revealed:
			_base_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			_base_material.albedo_color.a = 0.3
		else:
			_base_material.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
			_base_material.albedo_color.a = 1.0
