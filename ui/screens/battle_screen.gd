extends Control

## Battle screen - runs simulation and displays progress with optional 3D visuals

@onready var title_label: Label = %TitleLabel
@onready var wave_label: Label = %WaveLabel
@onready var shrine_hp_label: Label = %ShrineHPLabel
@onready var progress_bar: ProgressBar = %ProgressBar
@onready var viewport_3d: SubViewport = %PixelViewport
@onready var viewport_container: SubViewportContainer = %ViewportContainer
@onready var toggle_3d: CheckButton = %Toggle3D
@onready var placeholder_label: Label = %PlaceholderLabel

var current_level
var current_difficulty: String

var enable_3d: bool = true
var visual_world: VisualWorld
var game_state: GameState
var tick_processor: TickProcessor
var tick_timer: Timer
var current_wave_num: int = 0
var total_waves: int = 0


func _ready() -> void:
	current_level = ProgressionManager.current_level
	current_difficulty = ProgressionManager.current_difficulty

	if not current_level:
		push_error("No current level set in ProgressionManager")
		return

	title_label.text = current_level.display_name
	toggle_3d.toggled.connect(_on_toggle_3d)

	_run_battle()


func _on_toggle_3d(pressed: bool) -> void:
	enable_3d = pressed
	viewport_container.visible = pressed
	placeholder_label.visible = not pressed


func _run_battle() -> void:
	# Load map
	var map = TestMap.create()

	# Get waves data
	var waves = _create_waves_for_level()
	total_waves = waves.get_total_waves()

	# Create balance config
	var config = BalanceConfig.new()

	# Create game state
	game_state = GameState.new()

	# Register data
	_register_data_to_state(game_state)

	# Initialize
	game_state.initialize_with_config(map, waves, config, 12345)

	# Connect signals for UI updates
	game_state.wave_started.connect(_on_wave_started)
	game_state.wave_completed.connect(_on_wave_completed)
	game_state.shrine_damaged.connect(_on_shrine_damaged)
	game_state.game_over.connect(_on_game_over)

	# Create tick processor
	tick_processor = TickProcessor.new(game_state)

	# Setup 3D visuals if enabled
	if enable_3d:
		_setup_visual_world()

	# Place towers (empty for now)
	var tower_placements: Array[Dictionary] = []
	var wall_placements: Array[Vector2i] = []

	for pos in wall_placements:
		game_state.place_wall(pos)
	for placement in tower_placements:
		game_state.place_tower(placement.pos, placement.id)

	# Create tick timer for real-time simulation
	tick_timer = Timer.new()
	tick_timer.wait_time = 0.1  # 100ms per tick
	tick_timer.timeout.connect(_on_tick)
	add_child(tick_timer)

	# Start first wave
	_start_next_wave()

	# Update display
	_update_display()


func _setup_visual_world() -> void:
	var faction := ProgressionManager.current_faction
	if faction == "":
		faction = "light"  # Default

	visual_world = VisualWorld.new()
	viewport_3d.add_child(visual_world)
	visual_world.initialize(game_state, faction)


func _start_next_wave() -> void:
	current_wave_num += 1
	if current_wave_num <= total_waves:
		game_state.start_wave(current_wave_num)
		tick_timer.start()


func _on_tick() -> void:
	if not tick_processor:
		return

	var result := tick_processor.process_tick()

	match result:
		TickProcessor.TickResult.WAVE_COMPLETE:
			tick_timer.stop()
			# Auto-start next wave after short delay
			await get_tree().create_timer(0.5).timeout
			_start_next_wave()
			_update_display()

		TickProcessor.TickResult.GAME_OVER_WIN, TickProcessor.TickResult.GAME_OVER_LOSS:
			tick_timer.stop()
			_finish_battle(result == TickProcessor.TickResult.GAME_OVER_WIN)

		_:
			_update_display()


func _on_wave_started(wave_number: int) -> void:
	wave_label.text = "Wave: %d / %d" % [wave_number, total_waves]


func _on_wave_completed(_wave_number: int) -> void:
	pass


func _on_shrine_damaged(_damage: int, current_hp: int) -> void:
	shrine_hp_label.text = "Shrine HP: %d / %d" % [current_hp, game_state.shrine.max_hp]


func _on_game_over(won: bool) -> void:
	_finish_battle(won)


func _finish_battle(won: bool) -> void:
	if tick_timer:
		tick_timer.stop()

	# Create result object matching expected format
	var result = _create_result(won)
	ProgressionManager.last_battle_result = result

	await get_tree().process_frame
	SceneManager.change_scene("res://ui/screens/battle_results.tscn")


func _create_result(won: bool):
	# Create a result object compatible with TickProcessor.GameResult
	var result := TickProcessor.GameResult.new()
	result.won = won
	result.final_wave = current_wave_num
	result.final_shrine_hp = game_state.shrine.hp
	result.final_gold = game_state.gold
	result.total_gold_earned = game_state.total_gold_earned
	result.total_gold_spent = game_state.total_gold_spent
	result.enemies_killed = game_state.enemies_killed
	result.enemies_leaked = game_state.enemies_leaked
	result.total_damage_dealt = game_state.total_damage_dealt

	for tower in game_state.towers:
		result.tower_stats[tower.id] = {
			"damage": tower.total_damage_dealt, "kills": tower.kills, "shots": tower.shots_fired
		}

	return result


func _create_waves_for_level() -> WaveData:
	var full_waves = Waves1To10.create_full()
	return full_waves


func _register_data_to_state(state: GameState) -> void:
	# Register all towers
	state.register_tower_data(load("res://resources/towers/archer_tower.tres"))
	state.register_tower_data(load("res://resources/towers/cannon_tower.tres"))
	state.register_tower_data(load("res://resources/towers/frost_tower.tres"))
	state.register_tower_data(load("res://resources/towers/lightning_tower.tres"))
	state.register_tower_data(load("res://resources/towers/flame_tower.tres"))
	state.register_wall_data(load("res://resources/walls/basic_wall.tres"))

	# Register all enemies
	state.register_enemy_data(load("res://resources/enemies/grunt.tres"))
	state.register_enemy_data(load("res://resources/enemies/runner.tres"))
	state.register_enemy_data(load("res://resources/enemies/tank.tres"))
	state.register_enemy_data(load("res://resources/enemies/flyer.tres"))
	state.register_enemy_data(load("res://resources/enemies/swarm.tres"))
	state.register_enemy_data(load("res://resources/enemies/stealth.tres"))
	state.register_enemy_data(load("res://resources/enemies/breaker.tres"))
	state.register_enemy_data(load("res://resources/enemies/boss_golem.tres"))


func _update_display() -> void:
	if not game_state:
		return

	wave_label.text = "Wave: %d / %d" % [current_wave_num, total_waves]
	shrine_hp_label.text = "Shrine HP: %d / %d" % [game_state.shrine.hp, game_state.shrine.max_hp]
	progress_bar.max_value = total_waves
	progress_bar.value = current_wave_num
