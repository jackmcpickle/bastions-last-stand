class_name VisualTower
extends Node3D

## 3D visual for tower entity

var sim_tower: SimTower
var faction: String
var cube: MeshInstance3D


func initialize(tower: SimTower, p_faction: String) -> void:
	sim_tower = tower
	faction = p_faction
	position = GridToWorld.to_world(tower.position)
	_create_placeholder()


func _create_placeholder() -> void:
	# Create 2x2 colored cube
	cube = MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(1.8, 1.5, 1.8)
	cube.mesh = box
	cube.position = Vector3(1, 0.75, 1)  # Center on 2x2 footprint

	var mat := StandardMaterial3D.new()
	mat.albedo_color = _get_faction_color()
	cube.material_override = mat
	add_child(cube)


func _get_faction_color() -> Color:
	if faction == "light":
		return Color("#FFD700")  # Gold
	else:
		return Color("#8B00FF")  # Purple


func play_attack() -> void:
	# Simple scale pulse for attack feedback
	var tween := create_tween()
	tween.tween_property(cube, "scale", Vector3(1.1, 1.1, 1.1), 0.05)
	tween.tween_property(cube, "scale", Vector3.ONE, 0.1)
