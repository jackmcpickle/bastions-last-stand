class_name VisualMap
extends Node3D

## 3D visual for map terrain


func build_from_map_data(map_data: MapData) -> void:
	for x in range(map_data.width):
		for y in range(map_data.height):
			var pos := Vector2i(x, y)
			_place_tile(pos, _get_tile_type(map_data, pos))


func _place_tile(grid_pos: Vector2i, type: String) -> void:
	var tile := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(0.98, 0.98)  # Slight gap for grid lines
	tile.mesh = plane
	tile.position = GridToWorld.to_world(grid_pos)
	tile.position.y = -0.01  # Slightly below entities

	var mat := StandardMaterial3D.new()
	mat.albedo_color = _get_color_for_type(type)
	tile.material_override = mat
	add_child(tile)


func _get_tile_type(map_data: MapData, pos: Vector2i) -> String:
	if map_data.is_blocked(pos):
		return "blocked"
	if map_data.is_in_shrine_zone(pos):
		return "shrine"
	if map_data.is_spawn_point(pos):
		return "spawn"
	return "grass"


func _get_color_for_type(type: String) -> Color:
	match type:
		"grass":
			return Color("#4A7C3E")  # Forest green
		"blocked":
			return Color("#2C5A8C")  # Water blue
		"shrine":
			return Color("#D4AF37")  # Gold
		"spawn":
			return Color("#8B0000")  # Dark red
		_:
			return Color.WHITE
