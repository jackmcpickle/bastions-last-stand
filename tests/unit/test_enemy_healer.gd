extends GutTest

## Tests for enemy healer mechanic

const CombatClass = preload("res://simulation/systems/combat.gd")

var _game_state: GameState


func before_each() -> void:
	_game_state = TestHelpers.create_test_game_state()
	_game_state.register_enemy_data(TestHelpers.create_healer_enemy_data())


func test_healer_heals_nearby_allies() -> void:
	# Spawn healer
	var healer_data := TestHelpers.create_healer_enemy_data()
	var healer := SimEnemy.new()
	healer.initialize(healer_data, Vector2i(5, 10), _game_state.pathfinding)
	_game_state.enemies.append(healer)

	# Spawn damaged ally nearby
	var ally_data := TestHelpers.create_basic_enemy_data()
	var ally := SimEnemy.new()
	ally.initialize(ally_data, Vector2i(6, 10), _game_state.pathfinding)
	ally.hp = 50  # Damaged
	_game_state.enemies.append(ally)

	CombatClass.process_healer_effects(_game_state, 1000)

	assert_gt(ally.hp, 50)


func test_healer_doesnt_heal_self() -> void:
	var healer_data := TestHelpers.create_healer_enemy_data()
	var healer := SimEnemy.new()
	healer.initialize(healer_data, Vector2i(5, 10), _game_state.pathfinding)
	healer.hp = 30  # Damaged
	_game_state.enemies.append(healer)

	CombatClass.process_healer_effects(_game_state, 1000)

	assert_eq(healer.hp, 30)  # Unchanged


func test_healer_respects_range() -> void:
	var healer_data := TestHelpers.create_healer_enemy_data()
	var healer := SimEnemy.new()
	healer.initialize(healer_data, Vector2i(0, 10), _game_state.pathfinding)
	_game_state.enemies.append(healer)

	# Spawn ally too far away (healer_range is 3)
	var ally_data := TestHelpers.create_basic_enemy_data()
	var ally := SimEnemy.new()
	ally.initialize(ally_data, Vector2i(10, 10), _game_state.pathfinding)
	ally.hp = 50
	_game_state.enemies.append(ally)

	CombatClass.process_healer_effects(_game_state, 1000)

	assert_eq(ally.hp, 50)  # Unchanged - out of range


func test_healer_doesnt_overheal() -> void:
	var healer_data := TestHelpers.create_healer_enemy_data()
	var healer := SimEnemy.new()
	healer.initialize(healer_data, Vector2i(5, 10), _game_state.pathfinding)
	_game_state.enemies.append(healer)

	var ally_data := TestHelpers.create_basic_enemy_data()
	var ally := SimEnemy.new()
	ally.initialize(ally_data, Vector2i(6, 10), _game_state.pathfinding)
	ally.hp = ally.max_hp - 1
	_game_state.enemies.append(ally)

	CombatClass.process_healer_effects(_game_state, 10000)

	assert_eq(ally.hp, ally.max_hp)


func test_healer_stunned_doesnt_heal() -> void:
	var healer_data := TestHelpers.create_healer_enemy_data()
	var healer := SimEnemy.new()
	healer.initialize(healer_data, Vector2i(5, 10), _game_state.pathfinding)
	healer.is_stunned = true
	_game_state.enemies.append(healer)

	var ally_data := TestHelpers.create_basic_enemy_data()
	var ally := SimEnemy.new()
	ally.initialize(ally_data, Vector2i(6, 10), _game_state.pathfinding)
	ally.hp = 50
	_game_state.enemies.append(ally)

	CombatClass.process_healer_effects(_game_state, 1000)

	assert_eq(ally.hp, 50)


func test_healer_disabled_doesnt_heal() -> void:
	var healer_data := TestHelpers.create_healer_enemy_data()
	var healer := SimEnemy.new()
	healer.initialize(healer_data, Vector2i(5, 10), _game_state.pathfinding)
	healer.is_disabled = true
	_game_state.enemies.append(healer)

	var ally_data := TestHelpers.create_basic_enemy_data()
	var ally := SimEnemy.new()
	ally.initialize(ally_data, Vector2i(6, 10), _game_state.pathfinding)
	ally.hp = 50
	_game_state.enemies.append(ally)

	CombatClass.process_healer_effects(_game_state, 1000)

	assert_eq(ally.hp, 50)
