class_name VisualShrine
extends Node3D

## 3D visual for shrine entity

var cube: MeshInstance3D
var faction: String


func set_faction(p_faction: String) -> void:
	faction = p_faction
	_create_placeholder()


func _create_placeholder() -> void:
	cube = MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(1.5, 2.0, 1.5)
	cube.mesh = box
	cube.position.y = 1.0

	var mat := StandardMaterial3D.new()
	mat.albedo_color = _get_faction_color()
	mat.emission_enabled = true
	mat.emission = mat.albedo_color * 0.3
	mat.emission_energy_multiplier = 0.5
	cube.material_override = mat
	add_child(cube)


func _get_faction_color() -> Color:
	if faction == "light":
		return Color("#FFD700")  # Gold
	else:
		return Color("#8B00FF")  # Purple


func play_damage() -> void:
	# Flash red on damage
	if not cube:
		return
	var mat := cube.material_override as StandardMaterial3D
	if not mat:
		return

	var original_color := _get_faction_color()
	mat.albedo_color = Color.RED

	var tween := create_tween()
	tween.tween_property(mat, "albedo_color", original_color, 0.2)
