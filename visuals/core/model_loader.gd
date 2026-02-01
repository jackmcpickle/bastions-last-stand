class_name ModelLoader
extends Node

## Singleton for loading 3D models with fallback to placeholders

const TOWER_PATH := "res://assets/models/towers/"
const ENEMY_PATH := "res://assets/models/enemies/"
const SHRINE_PATH := "res://assets/models/shrines/"

var _cache: Dictionary = {}  # Path -> PackedScene


func load_tower_model(tower_id: String, tier: int, branch: String, faction: String) -> Node3D:
	var model_path := _get_tower_path(tower_id, tier, branch, faction)
	return _load_with_fallback(model_path, "tower", faction)


func load_enemy_model(enemy_id: String, is_boss: bool = false) -> Node3D:
	var model_path := ENEMY_PATH + enemy_id + ".glb"
	var node := _load_with_fallback(model_path, "enemy", "")
	if is_boss:
		node.scale = Vector3(2, 2, 2)
	return node


func load_shrine_model(faction: String) -> Node3D:
	var model_path := SHRINE_PATH + "shrine_base.glb"
	return _load_with_fallback(model_path, "shrine", faction)


func _get_tower_path(id: String, tier: int, branch: String, faction: String) -> String:
	var branch_suffix := branch.to_lower() if branch else ""
	var tier_str := "t%d%s" % [tier, branch_suffix]
	# Try .tscn first (modified scene), then .glb (raw model)
	var tscn_path := "%s%s_%s_%s.tscn" % [TOWER_PATH, id, tier_str, faction]
	if ResourceLoader.exists(tscn_path):
		return tscn_path
	return "%s%s_%s.glb" % [TOWER_PATH, id, tier_str]


func _load_with_fallback(path: String, type: String, faction: String) -> Node3D:
	# Try cache
	if path in _cache:
		var instance := (_cache[path] as PackedScene).instantiate() as Node3D
		if faction:
			_apply_faction_color(instance, faction)
		return instance

	# Try disk
	if ResourceLoader.exists(path):
		var scene := load(path)
		if scene is PackedScene:
			_cache[path] = scene
			var instance := scene.instantiate() as Node3D
			if faction:
				_apply_faction_color(instance, faction)
			return instance

	# Fallback to placeholder
	push_warning("Model not found: %s, using placeholder" % path)
	return _create_placeholder(type, faction)


func _create_placeholder(type: String, faction: String) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()

	match type:
		"tower":
			box.size = Vector3(1.8, 1.5, 1.8)
			mesh.position = Vector3(1, 0.75, 1)
		"enemy":
			box.size = Vector3(0.6, 0.6, 0.6)
			mesh.position.y = 0.3
		"shrine":
			box.size = Vector3(1.5, 2.0, 1.5)
			mesh.position.y = 1.0
		_:
			box.size = Vector3(1.0, 1.0, 1.0)
			mesh.position.y = 0.5

	mesh.mesh = box

	var mat := StandardMaterial3D.new()
	if faction:
		mat.albedo_color = _get_faction_color(faction)
	else:
		mat.albedo_color = Color(0.5, 0.5, 0.5)  # Gray placeholder
	mesh.material_override = mat
	return mesh


func _get_faction_color(faction: String) -> Color:
	if faction == "light":
		return Color("#FFD700")  # Gold
	else:
		return Color("#8B00FF")  # Purple


func _apply_faction_color(node: Node3D, faction: String) -> void:
	var color := _get_faction_color(faction)
	_apply_color_recursive(node, color)


func _apply_color_recursive(node: Node, color: Color) -> void:
	if node is MeshInstance3D:
		var mesh_inst := node as MeshInstance3D
		# Check for existing override material
		if mesh_inst.material_override:
			var mat := mesh_inst.material_override
			if mat is StandardMaterial3D:
				mat.albedo_color = color
		else:
			# Check surface materials
			for i in mesh_inst.get_surface_override_material_count():
				var mat := mesh_inst.get_surface_override_material(i)
				if mat is StandardMaterial3D:
					mat.albedo_color = color

	for child in node.get_children():
		_apply_color_recursive(child, color)


## Find first MeshInstance3D in node tree (for animation targets)
func find_mesh_instance(node: Node) -> MeshInstance3D:
	if node is MeshInstance3D:
		return node
	for child in node.get_children():
		var mesh := find_mesh_instance(child)
		if mesh:
			return mesh
	return null
