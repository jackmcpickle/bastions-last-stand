class_name VisualEnemy
extends Node3D

## 3D visual for enemy entity

var sim_enemy: SimEnemy
var cube: MeshInstance3D


func initialize(enemy: SimEnemy) -> void:
	sim_enemy = enemy
	position = GridToWorld.to_world_v2(enemy.grid_pos)
	_create_placeholder()


func _create_placeholder() -> void:
	cube = MeshInstance3D.new()
	var box := BoxMesh.new()

	# Bosses are bigger
	if sim_enemy.is_boss:
		box.size = Vector3(1.2, 1.2, 1.2)
		cube.position.y = 0.6
	else:
		box.size = Vector3(0.6, 0.6, 0.6)
		cube.position.y = 0.3

	cube.mesh = box

	var mat := StandardMaterial3D.new()
	mat.albedo_color = _get_enemy_color()
	cube.material_override = mat
	add_child(cube)


func _get_enemy_color() -> Color:
	# Color based on enemy type
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
	if cube and cube.material_override:
		var mat := cube.material_override as StandardMaterial3D
		if mat:
			if sim_enemy.is_stealth and not sim_enemy.is_revealed:
				mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
				mat.albedo_color.a = 0.3
			else:
				mat.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
				mat.albedo_color.a = 1.0
