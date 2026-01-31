extends GutTest

## Tests for enemy splitter mechanic

const CombatClass = preload("res://simulation/systems/combat.gd")

var _game_state: GameState


func before_each() -> void:
	_game_state = TestHelpers.create_test_game_state()
	_game_state.register_enemy_data(TestHelpers.create_splitter_enemy_data())
	_game_state.register_enemy_data(TestHelpers.create_mini_enemy_data())


func test_splitter_spawns_children_on_death() -> void:
	var splitter_data := TestHelpers.create_splitter_enemy_data()
	var splitter := SimEnemy.new()
	splitter.initialize(splitter_data, Vector2i(5, 10), _game_state.pathfinding)
	splitter.hp = 1
	_game_state.enemies.append(splitter)

	# Kill the splitter
	splitter.take_damage(10000)
	CombatClass.process_enemy_deaths(_game_state)

	# Should have spawned 3 minis
	assert_eq(_game_state.enemies.size(), 3)
	for enemy in _game_state.enemies:
		assert_eq(enemy.id, "mini")


func test_splitter_children_spawn_near_parent() -> void:
	var splitter_data := TestHelpers.create_splitter_enemy_data()
	var splitter := SimEnemy.new()
	splitter.initialize(splitter_data, Vector2i(5, 10), _game_state.pathfinding)
	splitter.grid_pos = Vector2(5.5, 10.5)
	splitter.hp = 1
	_game_state.enemies.append(splitter)

	splitter.take_damage(10000)
	CombatClass.process_enemy_deaths(_game_state)

	for child in _game_state.enemies:
		var dist := (child.grid_pos - Vector2(5.5, 10.5)).length()
		assert_lt(dist, 1.0)  # Within 1 tile


func test_normal_enemy_no_split() -> void:
	var grunt_data := TestHelpers.create_basic_enemy_data()
	var grunt := SimEnemy.new()
	grunt.initialize(grunt_data, Vector2i(5, 10), _game_state.pathfinding)
	grunt.hp = 1
	_game_state.enemies.append(grunt)

	grunt.take_damage(10000)
	CombatClass.process_enemy_deaths(_game_state)

	assert_eq(_game_state.enemies.size(), 0)


func test_splitter_awards_gold_before_split() -> void:
	var splitter_data := TestHelpers.create_splitter_enemy_data()
	var splitter := SimEnemy.new()
	splitter.initialize(splitter_data, Vector2i(5, 10), _game_state.pathfinding)
	splitter.hp = 1
	_game_state.enemies.append(splitter)

	var initial_gold := _game_state.gold

	splitter.take_damage(10000)
	CombatClass.process_enemy_deaths(_game_state)

	# Should have earned gold for parent
	assert_eq(_game_state.gold, initial_gold + 12)
