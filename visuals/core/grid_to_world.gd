class_name GridToWorld
extends RefCounted

## Utility for converting grid coords to 3D world coords


static func to_world(grid: Vector2i) -> Vector3:
	return Vector3(grid.x, 0, grid.y)


static func to_world_v2(grid: Vector2) -> Vector3:
	return Vector3(grid.x, 0, grid.y)
