class_name TestMap
extends RefCounted

## Hardcoded 10x10 test map
##
## Layout:
## . . S . . . . S . .   (row 0 - spawn points at 2,0 and 7,0)
## . . . . . . . . . .   (row 1)
## . . . . . . . . . .   (row 2)
## . . . . . . . . . .   (row 3)
## . . . . X X . . . .   (row 4 - shrine zone starts)
## . . . . X X . . . .   (row 5 - shrine zone ends)
## . . . . . . . . . .   (row 6)
## . . . . . . . . . .   (row 7)
## . . . . . . . . . .   (row 8)
## . . . . . . . . . .   (row 9)


static func create() -> MapData:
	var map := MapData.new()
	map.id = "test_10x10"
	map.display_name = "Test Map (10x10)"
	map.width = 10
	map.height = 10
	
	# Spawn points at top edge
	map.spawn_points = [
		Vector2i(2, 0),
		Vector2i(7, 0)
	]
	
	# Shrine zone in center (2x2 area)
	map.shrine_zone_start = Vector2i(4, 4)
	map.shrine_zone_end = Vector2i(5, 5)
	
	# No blocked tiles or pre-placed walls for this simple test map
	map.blocked_tiles = []
	map.pre_placed_walls = []
	
	return map
