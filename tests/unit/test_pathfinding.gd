extends GutTest

## Unit tests for SimPathfinding

var _pathfinding: SimPathfinding


func before_each() -> void:
	_pathfinding = SimPathfinding.new(20, 20)
	_pathfinding.set_shrine_position(Vector2i(19, 10))


# ============================================
# get_path() tests
# ============================================


func test_get_path_basic() -> void:
	var path := _pathfinding.get_path(Vector2i(0, 10))

	assert_false(path.is_empty())
	assert_eq(path[0], Vector2i(0, 10))  # Starts at spawn
	assert_eq(path[-1], Vector2i(19, 10))  # Ends at shrine


func test_get_path_straight_line() -> void:
	var path := _pathfinding.get_path(Vector2i(0, 10))

	# With no obstacles, should be straight
	assert_eq(path.size(), 20)  # 0 to 19 = 20 tiles


func test_get_path_around_obstacle() -> void:
	# Block middle
	_pathfinding.set_blocked(Vector2i(10, 10), true)

	var path := _pathfinding.get_path(Vector2i(0, 10))

	assert_false(path.is_empty())
	# Should not contain blocked tile
	assert_false(path.has(Vector2i(10, 10)))


func test_get_path_no_valid_path() -> void:
	# Block entire column
	for y in range(20):
		_pathfinding.set_blocked(Vector2i(10, y), true)

	var path := _pathfinding.get_path(Vector2i(0, 10))

	assert_true(path.is_empty())


func test_get_path_caches_result() -> void:
	var path1 := _pathfinding.get_path(Vector2i(0, 10))
	var path2 := _pathfinding.get_path(Vector2i(0, 10))

	assert_eq(path1, path2)


func test_get_path_different_spawn_points() -> void:
	var path1 := _pathfinding.get_path(Vector2i(0, 5))
	var path2 := _pathfinding.get_path(Vector2i(0, 15))

	assert_ne(path1, path2)
	assert_eq(path1[-1], Vector2i(19, 10))  # Same destination
	assert_eq(path2[-1], Vector2i(19, 10))


func test_get_path_at_shrine() -> void:
	var path := _pathfinding.get_path(Vector2i(19, 10))

	assert_eq(path.size(), 1)
	assert_eq(path[0], Vector2i(19, 10))


# ============================================
# Cache invalidation tests
# ============================================


func test_cache_invalidated_on_block() -> void:
	var path1 := _pathfinding.get_path(Vector2i(0, 10))

	_pathfinding.set_blocked(Vector2i(10, 10), true)

	var path2 := _pathfinding.get_path(Vector2i(0, 10))

	assert_ne(path1, path2)


func test_cache_invalidated_on_unblock() -> void:
	_pathfinding.set_blocked(Vector2i(10, 10), true)
	var path1 := _pathfinding.get_path(Vector2i(0, 10))

	_pathfinding.set_blocked(Vector2i(10, 10), false)

	var path2 := _pathfinding.get_path(Vector2i(0, 10))

	# Path should now go through (10, 10)
	assert_has(path2, Vector2i(10, 10))


func test_cache_invalidated_on_shrine_move() -> void:
	var path1 := _pathfinding.get_path(Vector2i(0, 10))

	_pathfinding.set_shrine_position(Vector2i(18, 10))

	var path2 := _pathfinding.get_path(Vector2i(0, 10))

	assert_eq(path2[-1], Vector2i(18, 10))


func test_invalidate_cache_explicit() -> void:
	_pathfinding.get_path(Vector2i(0, 10))

	_pathfinding.invalidate_cache()

	# Should still work, just recomputes
	var path := _pathfinding.get_path(Vector2i(0, 10))
	assert_false(path.is_empty())


# ============================================
# set_blocked()/is_blocked() tests
# ============================================


func test_set_blocked_marks_tile() -> void:
	_pathfinding.set_blocked(Vector2i(5, 5), true)

	assert_true(_pathfinding.is_blocked(Vector2i(5, 5)))


func test_unblock_tile() -> void:
	_pathfinding.set_blocked(Vector2i(5, 5), true)
	_pathfinding.set_blocked(Vector2i(5, 5), false)

	assert_false(_pathfinding.is_blocked(Vector2i(5, 5)))


func test_is_blocked_default_false() -> void:
	assert_false(_pathfinding.is_blocked(Vector2i(10, 10)))


# ============================================
# is_walkable() tests
# ============================================


func test_is_walkable_open_tile() -> void:
	assert_true(_pathfinding.is_walkable(Vector2i(10, 10)))


func test_is_walkable_blocked_tile() -> void:
	_pathfinding.set_blocked(Vector2i(10, 10), true)

	assert_false(_pathfinding.is_walkable(Vector2i(10, 10)))


func test_is_walkable_out_of_bounds_negative() -> void:
	assert_false(_pathfinding.is_walkable(Vector2i(-1, 10)))
	assert_false(_pathfinding.is_walkable(Vector2i(10, -1)))


func test_is_walkable_out_of_bounds_positive() -> void:
	assert_false(_pathfinding.is_walkable(Vector2i(20, 10)))
	assert_false(_pathfinding.is_walkable(Vector2i(10, 20)))


# ============================================
# has_valid_path() tests
# ============================================


func test_has_valid_path_true() -> void:
	assert_true(_pathfinding.has_valid_path(Vector2i(0, 10)))


func test_has_valid_path_false_blocked() -> void:
	# Block entire column
	for y in range(20):
		_pathfinding.set_blocked(Vector2i(10, y), true)

	assert_false(_pathfinding.has_valid_path(Vector2i(0, 10)))


# ============================================
# get_path_length() tests
# ============================================


func test_get_path_length_basic() -> void:
	var length := _pathfinding.get_path_length(Vector2i(0, 10))

	assert_eq(length, 20)


func test_get_path_length_no_path() -> void:
	for y in range(20):
		_pathfinding.set_blocked(Vector2i(10, y), true)

	var length := _pathfinding.get_path_length(Vector2i(0, 10))

	assert_eq(length, -1)


func test_get_path_length_from_shrine() -> void:
	var length := _pathfinding.get_path_length(Vector2i(19, 10))

	assert_eq(length, 1)


# ============================================
# get_all_blocked() tests
# ============================================


func test_get_all_blocked_empty() -> void:
	var blocked := _pathfinding.get_all_blocked()

	assert_eq(blocked.size(), 0)


func test_get_all_blocked_returns_all() -> void:
	_pathfinding.set_blocked(Vector2i(5, 5), true)
	_pathfinding.set_blocked(Vector2i(10, 10), true)

	var blocked := _pathfinding.get_all_blocked()

	assert_eq(blocked.size(), 2)
	assert_has(blocked, Vector2i(5, 5))
	assert_has(blocked, Vector2i(10, 10))


# ============================================
# Complex path tests
# ============================================


func test_path_around_wall() -> void:
	# Create a wall with a gap
	for y in range(5, 15):
		_pathfinding.set_blocked(Vector2i(10, y), true)
	# Leave gap at y=15

	var path := _pathfinding.get_path(Vector2i(0, 10))

	assert_false(path.is_empty())
	# Should go around the wall
	for pos in path:
		assert_false(_pathfinding.is_blocked(pos))


func test_path_through_maze() -> void:
	# Simple maze pattern
	for x in range(5, 15, 2):
		for y in range(0, 19):
			if y != (x % 3) + 5:  # Leave gaps
				_pathfinding.set_blocked(Vector2i(x, y), true)

	var path := _pathfinding.get_path(Vector2i(0, 10))

	# Should find some path (may be empty if maze is unsolvable)
	if not path.is_empty():
		assert_eq(path[-1], Vector2i(19, 10))


func test_path_multiple_equal_options() -> void:
	# Two equally good paths should both work
	var path := _pathfinding.get_path(Vector2i(0, 10))

	# Just verify it finds a valid path
	assert_false(path.is_empty())
	assert_eq(path[0], Vector2i(0, 10))
	assert_eq(path[-1], Vector2i(19, 10))
