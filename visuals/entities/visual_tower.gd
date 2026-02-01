class_name VisualTower
extends Node3D

## 3D visual for tower entity

var sim_tower: SimTower
var faction: String
var cube: MeshInstance3D  # Animation target (mesh or placeholder)
var _model: Node3D


func initialize(tower: SimTower, p_faction: String) -> void:
	sim_tower = tower
	faction = p_faction
	position = GridToWorld.to_world(tower.position)
	_create_model()


func _create_model() -> void:
	_model = ModelLoader.load_tower_model(sim_tower.id, sim_tower.tier, sim_tower.branch, faction)
	add_child(_model)
	cube = ModelLoader.find_mesh_instance(_model)


func play_attack() -> void:
	if not cube:
		return
	var tween := create_tween()
	tween.tween_property(cube, "scale", Vector3(1.1, 1.1, 1.1), 0.05)
	tween.tween_property(cube, "scale", Vector3.ONE, 0.1)
