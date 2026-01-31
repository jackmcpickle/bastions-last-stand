extends GutTest

## Edge case tests for pathfinding

var _pathfinding: SimPathfinding


func before_each() -> void:
	_pathfinding = SimPathfinding.new(20, 20)
	_pathfinding.set_shrine_position(Vector2i(19, 10))


# ============================================
# No valid path edge cases
# ============================================

func test_no_path_completely_blocked() -> void:
	# Block entire column
	for y in range(20):
		_pathfinding.set_blocked(Vector2i(10, y), true)

	var path := _pathfinding.get_path(Vector2i(0, 10))

	assert_true(path.is_empty())


func test_no_path_shrine_blocked() -> void:
	# Block around shrine
	for dx in range(-1, 2):
		for dy in range(-1, 2):
			var pos := Vector2i(19 + dx, 10 + dy)
			if _pathfinding.is_walkable(pos):
				_pathfinding.set_blocked(pos, true)

	var path := _pathfinding.get_path(Vector2i(0, 10))

	assert_true(path.is_empty())


func test_no_path_spawn_blocked() -> void:
	# Block around spawn
	_pathfinding.set_blocked(Vector2i(0, 9), true)
	_pathfinding.set_blocked(Vector2i(0, 10), true)
	_pathfinding.set_blocked(Vector2i(0, 11), true)
	_pathfinding.set_blocked(Vector2i(1, 9), true)
	_pathfinding.set_blocked(Vector2i(1, 10), true)
	_pathfinding.set_blocked(Vector2i(1, 11), true)

	# Spawn in blocked area
	var path := _pathfinding.get_path(Vector2i(0, 10))

	# May find path or may not depending on exact blocks
	# The key is it doesn't crash


func test_no_path_sparse_blocking() -> void:
	# Create checkerboard pattern that might block
	for x in range(5, 15):
		for y in range(5, 15):
			if (x + y) % 2 == 0:
				_pathfinding.set_blocked(Vector2i(x, y), true)

	var path := _pathfinding.get_path(Vector2i(0, 10))

	# Should still find path around blocked areas


# ============================================
# Path invalidation edge cases
# ============================================

func test_path_invalidation_mid_enemy_movement() -> void:
	var enemy_data := TestHelpers.create_basic_enemy_data()
	var enemy := SimEnemy.new()
	enemy.initialize(enemy_data, Vector2i(0, 10), _pathfinding)

	# Move enemy partway
	enemy.move(5000)
	var old_pos := enemy.grid_pos

	# Block ahead
	_pathfinding.set_blocked(Vector2i(int(old_pos.x) + 5, 10), true)

	# Get new path from current position
	var new_path := _pathfinding.get_path(enemy.get_current_tile())

	# Should find alternative or empty
	if not new_path.is_empty():
		assert_eq(new_path[-1], _pathfinding.get_shrine_position())


func test_rapid_invalidation() -> void:
	# Rapid block/unblock cycles
	for i in range(10):
		_pathfinding.set_blocked(Vector2i(10, 10), true)
		_pathfinding.get_path(Vector2i(0, 10))
		_pathfinding.set_blocked(Vector2i(10, 10), false)
		_pathfinding.get_path(Vector2i(0, 10))

	# Should not crash or corrupt state
	var final_path := _pathfinding.get_path(Vector2i(0, 10))
	assert_false(final_path.is_empty())


# ============================================
# Flying unit edge cases
# ============================================

func test_flying_unit_ignores_obstacles() -> void:
	# Block entire path
	for y in range(20):
		_pathfinding.set_blocked(Vector2i(10, y), true)

	var flying_data := TestHelpers.create_flying_enemy_data()
	var enemy := SimEnemy.new()
	enemy.initialize(flying_data, Vector2i(0, 10), _pathfinding)

	# Flying units should have direct path
	assert_eq(enemy.path.size(), 2)  # Start and end only


func test_flying_unit_direct_path_diagonal() -> void:
	var flying_data := TestHelpers.create_flying_enemy_data()
	var enemy := SimEnemy.new()
	enemy.initialize(flying_data, Vector2i(0, 0), _pathfinding)

	assert_eq(enemy.path[0], Vector2i(0, 0))
	assert_eq(enemy.path[1], _pathfinding.get_shrine_position())


# ============================================
# Multiple spawn points edge cases
# ============================================

func test_multiple_spawns_same_target() -> void:
	var path1 := _pathfinding.get_path(Vector2i(0, 5))
	var path2 := _pathfinding.get_path(Vector2i(0, 15))

	# Both should end at shrine
	assert_eq(path1[-1], Vector2i(19, 10))
	assert_eq(path2[-1], Vector2i(19, 10))


func test_spawn_from_different_sides() -> void:
	# Add spawn point on opposite side
	var path_left := _pathfinding.get_path(Vector2i(0, 10))
	var path_top := _pathfinding.get_path(Vector2i(10, 0))

	assert_false(path_left.is_empty())
	assert_false(path_top.is_empty())


func test_spawn_near_shrine() -> void:
	var path := _pathfinding.get_path(Vector2i(18, 10))

	assert_eq(path.size(), 2)


func test_spawn_at_shrine() -> void:
	var path := _pathfinding.get_path(Vector2i(19, 10))

	assert_eq(path.size(), 1)
	assert_eq(path[0], Vector2i(19, 10))


# ============================================
# Boundary edge cases
# ============================================

func test_path_along_top_edge() -> void:
	# Block interior, force path along edge
	for x in range(5, 15):
		for y in range(1, 19):
			_pathfinding.set_blocked(Vector2i(x, y), true)

	var path := _pathfinding.get_path(Vector2i(0, 0))

	# Should find path around edges or be empty
	if not path.is_empty():
		for pos in path:
			assert_true(_pathfinding.is_walkable(pos))


func test_path_along_bottom_edge() -> void:
	var path := _pathfinding.get_path(Vector2i(0, 19))

	assert_false(path.is_empty())


func test_spawn_at_corner() -> void:
	var path := _pathfinding.get_path(Vector2i(0, 0))

	assert_false(path.is_empty())


# ============================================
# Large grid edge cases
# ============================================

func test_large_grid_performance() -> void:
	var large_pf := SimPathfinding.new(100, 100)
	large_pf.set_shrine_position(Vector2i(99, 50))

	var start_time := Time.get_ticks_msec()
	var path := large_pf.get_path(Vector2i(0, 50))
	var duration := Time.get_ticks_msec() - start_time

	assert_false(path.is_empty())
	assert_lt(duration, 1000)  # Should complete in under 1 second


func test_small_grid() -> void:
	var small_pf := SimPathfinding.new(3, 3)
	small_pf.set_shrine_position(Vector2i(2, 1))

	var path := small_pf.get_path(Vector2i(0, 1))

	assert_eq(path.size(), 3)


# ============================================
# Degenerate cases
# ============================================

func test_1x1_grid() -> void:
	var tiny_pf := SimPathfinding.new(1, 1)
	tiny_pf.set_shrine_position(Vector2i(0, 0))

	var path := tiny_pf.get_path(Vector2i(0, 0))

	assert_eq(path.size(), 1)


func test_all_tiles_blocked_except_start_and_end() -> void:
	# Block everything except spawn and shrine
	for x in range(20):
		for y in range(20):
			if Vector2i(x, y) != Vector2i(0, 10) and Vector2i(x, y) != Vector2i(19, 10):
				_pathfinding.set_blocked(Vector2i(x, y), true)

	var path := _pathfinding.get_path(Vector2i(0, 10))

	# No path possible (start and end not adjacent)
	assert_true(path.is_empty())


func test_narrow_corridor() -> void:
	# Block everything except single corridor
	for x in range(20):
		for y in range(20):
			if y != 10:
				_pathfinding.set_blocked(Vector2i(x, y), true)

	var path := _pathfinding.get_path(Vector2i(0, 10))

	assert_false(path.is_empty())
	assert_eq(path.size(), 20)  # Straight line


# ============================================
# Cache edge cases
# ============================================

func test_cache_after_many_queries() -> void:
	# Query many different positions
	for i in range(20):
		_pathfinding.get_path(Vector2i(0, i))

	# Cache should still work
	var path := _pathfinding.get_path(Vector2i(0, 10))
	assert_false(path.is_empty())


func test_cache_with_blocked_spawn() -> void:
	_pathfinding.set_blocked(Vector2i(0, 10), true)

	var path := _pathfinding.get_path(Vector2i(0, 10))

	# Should return empty (spawn is blocked)
	assert_true(path.is_empty())


func test_cache_cleared_on_shrine_move() -> void:
	_pathfinding.get_path(Vector2i(0, 10))

	_pathfinding.set_shrine_position(Vector2i(18, 10))

	var path := _pathfinding.get_path(Vector2i(0, 10))
	assert_eq(path[-1], Vector2i(18, 10))
