class_name Projectile
extends Node3D

## Visual projectile effect

var start_pos: Vector3
var end_pos: Vector3
var speed: float = 20.0
var t: float = 0.0
var cube: MeshInstance3D


func setup(p_start: Vector3, p_end: Vector3, p_speed: float = 20.0) -> void:
	start_pos = p_start
	end_pos = p_end
	speed = p_speed
	position = start_pos

	# Look at target
	if start_pos.distance_to(end_pos) > 0.01:
		look_at(end_pos)

	_create_mesh()


func _create_mesh() -> void:
	cube = MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.1, 0.1, 0.3)
	cube.mesh = box

	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color("#FFFF00")
	mat.emission_enabled = true
	mat.emission = Color("#FFFF00")
	mat.emission_energy_multiplier = 1.0
	cube.material_override = mat
	add_child(cube)


func _process(delta: float) -> void:
	var distance := start_pos.distance_to(end_pos)
	if distance > 0.01:
		t += delta * speed / distance
	else:
		t = 1.0

	t = clampf(t, 0.0, 1.0)
	position = start_pos.lerp(end_pos, t)

	if t >= 1.0:
		queue_free()
