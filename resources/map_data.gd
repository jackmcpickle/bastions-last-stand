class_name MapData
extends Resource

## Map configuration resource

@export var id: String
@export var display_name: String
@export var width: int
@export var height: int

## Spawn points (enemy entry points)
@export var spawn_points: Array[Vector2i] = []

## Shrine placement zone (where player can place shrine)
@export var shrine_zone_start: Vector2i
@export var shrine_zone_end: Vector2i

## Blocked tiles (obstacles, water, etc.) - cannot build
@export var blocked_tiles: Array[Vector2i] = []

## Pre-placed walls (for maze starter maps)
@export var pre_placed_walls: Array[Vector2i] = []


func is_in_bounds(pos: Vector2i) -> bool:
	return pos.x >= 0 and pos.x < width and pos.y >= 0 and pos.y < height


func is_blocked(pos: Vector2i) -> bool:
	return pos in blocked_tiles


func is_spawn_point(pos: Vector2i) -> bool:
	return pos in spawn_points


func is_in_shrine_zone(pos: Vector2i) -> bool:
	return (
		pos.x >= shrine_zone_start.x
		and pos.x <= shrine_zone_end.x
		and pos.y >= shrine_zone_start.y
		and pos.y <= shrine_zone_end.y
	)


func can_build_tower(pos: Vector2i) -> bool:
	## Towers are 2x2, check all 4 tiles
	for dx in range(2):
		for dy in range(2):
			var check_pos := Vector2i(pos.x + dx, pos.y + dy)
			if not is_in_bounds(check_pos):
				return false
			if is_blocked(check_pos):
				return false
			if is_spawn_point(check_pos):
				return false
	return true


func can_build_wall(pos: Vector2i) -> bool:
	## Walls are 1x1
	if not is_in_bounds(pos):
		return false
	if is_blocked(pos):
		return false
	if is_spawn_point(pos):
		return false
	return true
