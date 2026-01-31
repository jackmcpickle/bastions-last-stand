extends Control

## Battle results display screen

@onready var victory_label: Label = %VictoryLabel
@onready var shrine_hp_label: Label = %ShrineHPLabel
@onready var stars_label: Label = %StarsLabel
@onready var gold_label: Label = %GoldLabel
@onready var retry_button: Button = %RetryButton
@onready var continue_button: Button = %ContinueButton

var result = null
var level: LevelData = null
var difficulty: String = ""


func _ready() -> void:
	result = ProgressionManager.last_battle_result
	level = ProgressionManager.current_level
	difficulty = ProgressionManager.current_difficulty

	if not result or not level:
		push_error("Missing battle result or level")
		return

	_display_results()
	_connect_signals()


func _display_results() -> void:
	var is_victory = result.final_shrine_hp > 0

	if is_victory:
		victory_label.text = "VICTORY!"
		victory_label.add_theme_color_override("font_color", Color.GREEN)
	else:
		victory_label.text = "DEFEAT"
		victory_label.add_theme_color_override("font_color", Color.RED)

	shrine_hp_label.text = "Shrine HP: %d / 1000 (%.0f%%)" % [
		result.final_shrine_hp,
		(result.final_shrine_hp / 1000.0) * 100
	]

	if is_victory:
		var stars = ProgressionManager.calculate_stars(result.final_shrine_hp, 1000)
		var gold_reward = level.difficulty_modifiers[difficulty].gold

		stars_label.text = "★" * stars + "☆" * (3 - stars)
		gold_label.text = "Gold Earned: +%d" % gold_reward

		# Update progression
		ProgressionManager.complete_level(level.id, difficulty, result)
	else:
		stars_label.text = "No stars earned"
		gold_label.text = "Gold Earned: +0"


func _connect_signals() -> void:
	if retry_button:
		retry_button.pressed.connect(_on_retry_pressed)
	if continue_button:
		continue_button.pressed.connect(_on_continue_pressed)


func _on_retry_pressed() -> void:
	SceneManager.change_scene("res://ui/screens/battle_screen.tscn")


func _on_continue_pressed() -> void:
	SceneManager.change_scene("res://ui/screens/main_hub.tscn")
