extends Control

## Level selection screen with chapter browsing

signal battle_requested(level: LevelData, difficulty: String)

@onready var chapters_container: VBoxContainer = %ChaptersContainer
@onready var level_detail_panel: PanelContainer = %LevelDetailPanel
@onready var detail_title: Label = %DetailTitle
@onready var detail_description: Label = %DetailDescription
@onready var detail_stats: VBoxContainer = %DetailStats
@onready var difficulty_buttons: HBoxContainer = %DifficultyButtons
@onready var start_button: Button = %StartButton
@onready var back_button: Button = %BackButton

var selected_level: LevelData = null
var selected_difficulty: String = "normal"


func _ready() -> void:
	_populate_chapters()
	_connect_signals()
	_setup_difficulty_buttons()


func _populate_chapters() -> void:
	for chapter in ProgressionManager.all_chapters:
		var card = ChapterCard.new()
		card.setup(chapter)
		card.level_selected.connect(_on_level_selected)
		chapters_container.add_child(card)


func _setup_difficulty_buttons() -> void:
	for child in difficulty_buttons.get_children():
		if child is Button:
			child.pressed.connect(_on_difficulty_changed.bind(child.name.to_lower()))


func _connect_signals() -> void:
	if start_button:
		start_button.pressed.connect(_on_start_pressed)
	if back_button:
		back_button.pressed.connect(_on_back_pressed)


func _on_level_selected(level: LevelData) -> void:
	selected_level = level
	_show_level_details(level)


func _show_level_details(level: LevelData) -> void:
	detail_title.text = level.display_name
	detail_description.text = level.description

	# Show best stars
	var max_stars = 0
	for diff in ["easy", "normal", "hard"]:
		var stars = ProgressionManager.get_level_stars(level.id, diff)
		max_stars = max(max_stars, stars)

	var star_text = "★" * max_stars + "☆" * (3 - max_stars)
	detail_description.text += "\n\n" + star_text if max_stars > 0 else "\n\nNo attempts yet"

	# Update difficulty display
	_update_difficulty_display()


func _on_difficulty_changed(difficulty: String) -> void:
	selected_difficulty = difficulty
	_update_difficulty_display()


func _update_difficulty_display() -> void:
	if not selected_level:
		return

	var stars = ProgressionManager.get_level_stars(selected_level.id, selected_difficulty)
	var modifier = selected_level.difficulty_modifiers[selected_difficulty]

	var star_text = "★" * stars + "☆" * (3 - stars)
	var stats_text = "%s Difficulty\nGold Reward: %d\n%s" % [
		selected_difficulty.to_upper(),
		modifier.gold,
		star_text
	]

	detail_stats.text = stats_text


func _on_start_pressed() -> void:
	if selected_level:
		battle_requested.emit(selected_level, selected_difficulty)


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://ui/screens/splash_screen.tscn")
