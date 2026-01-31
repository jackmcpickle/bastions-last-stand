extends Control

## Battle screen - runs simulation and displays progress

@onready var title_label: Label = %TitleLabel
@onready var wave_label: Label = %WaveLabel
@onready var shrine_hp_label: Label = %ShrineHPLabel
@onready var progress_bar: ProgressBar = %ProgressBar

var current_level: LevelData
var current_difficulty: String


func _ready() -> void:
	current_level = ProgressionManager.current_level
	current_difficulty = ProgressionManager.current_difficulty

	if not current_level:
		push_error("No current level set in ProgressionManager")
		return

	title_label.text = current_level.display_name
	_run_battle()


func _run_battle() -> void:
	# Load map
	var map = TestMap.create()

	# Get waves data
	var waves = _create_waves_for_level()

	# Create balance config
	var config = BalanceConfig.new()
	# TODO: Apply difficulty modifiers to config
	# var diff_mods = current_level.difficulty_modifiers[current_difficulty]

	# Create simulation runner
	var runner = SimulationRunner.new()
	runner.setup(map, waves, config)

	# Register tower and enemy data
	_register_data(runner)

	# Run simulation with empty tower placements (default defense)
	var tower_placements: Array[Dictionary] = []
	var wall_placements: Array[Vector2i] = []

	var result = runner.run_single(12345, tower_placements, wall_placements)

	ProgressionManager.last_battle_result = result
	await get_tree().process_frame
	SceneManager.change_scene("res://ui/screens/battle_results.tscn")


func _create_waves_for_level() -> WaveData:
	# For now, use the full wave set. In production, slice by level.wave_start/wave_end
	var full_waves = Waves1To10.create_full()
	return full_waves


func _register_data(runner: SimulationRunner) -> void:
	# Register all towers
	runner.register_tower(load("res://resources/towers/archer_tower.tres"))
	runner.register_tower(load("res://resources/towers/cannon_tower.tres"))
	runner.register_tower(load("res://resources/towers/frost_tower.tres"))
	runner.register_tower(load("res://resources/towers/lightning_tower.tres"))
	runner.register_tower(load("res://resources/towers/flame_tower.tres"))

	# Register all enemies
	runner.register_enemy(load("res://resources/enemies/grunt.tres"))
	runner.register_enemy(load("res://resources/enemies/runner.tres"))
	runner.register_enemy(load("res://resources/enemies/tank.tres"))
	runner.register_enemy(load("res://resources/enemies/flyer.tres"))
	runner.register_enemy(load("res://resources/enemies/swarm.tres"))
	runner.register_enemy(load("res://resources/enemies/stealth.tres"))
	runner.register_enemy(load("res://resources/enemies/breaker.tres"))
	runner.register_enemy(load("res://resources/enemies/boss_golem.tres"))


func _update_display(wave: int, shrine_hp: int, max_hp: int) -> void:
	wave_label.text = "Wave: %d / %d" % [wave, current_level.wave_end]
	shrine_hp_label.text = "Shrine HP: %d / %d" % [shrine_hp, max_hp]
	progress_bar.max_value = current_level.wave_end
	progress_bar.value = wave
