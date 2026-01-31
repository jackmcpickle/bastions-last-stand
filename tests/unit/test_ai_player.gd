extends GutTest

## Tests for AI player system

const AIPlayerClass = preload("res://simulation/ai/ai_player.gd")
const BalancedAIClass = preload("res://simulation/ai/strategies/balanced_ai.gd")

var _game_state: GameState


func before_each() -> void:
	_game_state = TestHelpers.create_test_game_state()
	_game_state.register_tower_data(TestHelpers.create_basic_tower_data())
	_game_state.register_tower_data(TestHelpers.create_aoe_tower_data())
	_game_state.register_tower_data(TestHelpers.create_frost_tower_data())


# ============================================
# AIPlayerClass helper tests
# ============================================

func test_find_valid_tower_positions() -> void:
	var ai := AIPlayerClass.new(_game_state)

	var positions := ai.find_valid_tower_positions("archer")

	assert_gt(positions.size(), 0)


func test_find_valid_tower_positions_respects_gold() -> void:
	_game_state.gold = 10  # Can't afford archer (80)

	var ai := AIPlayerClass.new(_game_state)
	var positions := ai.find_valid_tower_positions("archer")

	assert_eq(positions.size(), 0)


func test_get_path_tiles() -> void:
	var ai := AIPlayerClass.new(_game_state)

	var path_tiles := ai.get_path_tiles()

	assert_gt(path_tiles.size(), 0)


func test_get_path_coverage() -> void:
	var ai := AIPlayerClass.new(_game_state)

	# Position near spawn path
	var coverage := ai.get_path_coverage(Vector2i(2, 8), 5)

	assert_gt(coverage, 0)


func test_find_uncovered_path_tiles_no_towers() -> void:
	var ai := AIPlayerClass.new(_game_state)

	var uncovered := ai.find_uncovered_path_tiles()

	# With no towers, all path tiles should be uncovered
	assert_gt(uncovered.size(), 0)


func test_find_uncovered_path_tiles_with_tower() -> void:
	# Place a tower
	_game_state.place_tower(Vector2i(2, 8), "archer")

	var ai := AIPlayerClass.new(_game_state)
	var uncovered := ai.find_uncovered_path_tiles()

	# Some tiles should now be covered
	var path_tiles := ai.get_path_tiles()
	assert_lt(uncovered.size(), path_tiles.size())


func test_get_best_tower_position_covers_path() -> void:
	var ai := AIPlayerClass.new(_game_state)

	var pos := ai.get_best_tower_position("archer")

	assert_ne(pos, Vector2i(-1, -1))
	var coverage := ai.get_path_coverage(pos, 5)
	assert_gt(coverage, 0)


# ============================================
# BalancedAIClass tests
# ============================================

func test_balanced_ai_places_tower() -> void:
	_game_state.gold = 200

	var ai := BalancedAIClass.new(_game_state)
	ai.make_decisions(1)

	# Should have placed at least one tower
	assert_gt(_game_state.towers.size(), 0)


func test_balanced_ai_respects_gold() -> void:
	_game_state.gold = 50  # Not enough for any tower

	var ai := BalancedAIClass.new(_game_state)
	ai.make_decisions(1)

	assert_eq(_game_state.towers.size(), 0)


func test_balanced_ai_builds_walls_when_shrine_low() -> void:
	_game_state.gold = 200
	_game_state.shrine.hp = 20

	var ai := BalancedAIClass.new(_game_state)
	ai.make_decisions(1)

	assert_gt(_game_state.walls.size(), 0)


func test_balanced_ai_upgrades_towers() -> void:
	# Create tower with upgrades
	var tower_data := TestHelpers.create_tower_with_upgrades()
	_game_state.register_tower_data(tower_data)

	# Place many towers to cover path (so AI won't try to place more)
	_game_state.gold = 10000
	_game_state.place_tower(Vector2i(2, 8), "upgradeable")
	_game_state.place_tower(Vector2i(6, 8), "upgradeable")
	_game_state.place_tower(Vector2i(10, 8), "upgradeable")
	_game_state.place_tower(Vector2i(14, 8), "upgradeable")

	# Give first tower some kills
	var tower := _game_state.towers[0]
	tower.kills = 10
	_game_state.gold = 200

	var ai := BalancedAIClass.new(_game_state)
	ai.make_decisions(5)

	# Should have upgraded
	assert_gt(tower.tier, 1)


func test_balanced_ai_prefers_covering_uncovered_tiles() -> void:
	# Place first tower
	_game_state.gold = 400
	_game_state.place_tower(Vector2i(2, 8), "archer")

	var ai := BalancedAIClass.new(_game_state)
	ai.make_decisions(1)

	# Second tower should be placed, not overlapping first
	if _game_state.towers.size() > 1:
		var t1_center := _game_state.towers[0].get_center()
		var t2_center := _game_state.towers[1].get_center()
		var dist := (t1_center - t2_center).length()
		# Towers shouldn't be placed right next to each other
		assert_gt(dist, 2.0)
