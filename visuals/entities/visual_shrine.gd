class_name VisualShrine
extends Node3D

## 3D visual for shrine entity

var cube: MeshInstance3D  # Animation target (mesh or placeholder)
var faction: String
var _model: Node3D
var _base_material: StandardMaterial3D


func set_faction(p_faction: String) -> void:
	faction = p_faction
	_create_model()


func _create_model() -> void:
	_model = ModelLoader.load_shrine_model(faction)
	add_child(_model)
	cube = ModelLoader.find_mesh_instance(_model)

	# Setup material with emission for shrine glow
	if cube:
		if not cube.material_override:
			var mat := StandardMaterial3D.new()
			mat.albedo_color = _get_faction_color()
			cube.material_override = mat
		var mat := cube.material_override as StandardMaterial3D
		if mat:
			mat.emission_enabled = true
			mat.emission = mat.albedo_color * 0.3
			mat.emission_energy_multiplier = 0.5
			_base_material = mat


func _get_faction_color() -> Color:
	if faction == "light":
		return Color("#FFD700")  # Gold
	else:
		return Color("#8B00FF")  # Purple


func play_damage() -> void:
	if not _base_material:
		return

	var original_color := _get_faction_color()
	_base_material.albedo_color = Color.RED

	var tween := create_tween()
	tween.tween_property(_base_material, "albedo_color", original_color, 0.2)
