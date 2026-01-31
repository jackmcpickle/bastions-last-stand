extends Control

## Main hub with tabbed interface (book-style pages)

const LEVEL_SELECT_SCENE = preload("res://ui/screens/level_select.tscn")
const TOWER_UPGRADE_SCENE = preload("res://ui/screens/tower_upgrade.tscn")
const SHRINE_UPGRADE_SCENE = preload("res://ui/screens/shrine_upgrade.tscn")
const STORY_INTRO_SCENE = preload("res://ui/screens/story_intro.tscn")
const SETTINGS_SCENE = preload("res://ui/screens/settings.tscn")

@onready var tab_container: TabContainer = %TabContainer
@onready var tab_level_select: Control = %TabLevelSelect
@onready var tab_towers: Control = %TabTowers
@onready var tab_shrine: Control = %TabShrine
@onready var tab_lore: Control = %TabLore
@onready var tab_settings: Control = %TabSettings

var _last_tab: int = 0
var _selected_level: LevelData = null
var _selected_difficulty: String = "normal"


func _ready() -> void:
	_setup_tabs()
	_apply_faction_theme()
	_connect_signals()
	_setup_level_select()
	_restore_last_tab()


func _setup_tabs() -> void:
	if not tab_container:
		return

	# Setup tab names
	tab_container.set_tab_title(0, "Level Select")
	tab_container.set_tab_title(1, "Towers")
	tab_container.set_tab_title(2, "Shrine")
	tab_container.set_tab_title(3, "Lore")
	tab_container.set_tab_title(4, "Settings")


func _apply_faction_theme() -> void:
	var faction = SceneManager.current_faction
	var theme = SceneManager.current_theme
	if theme:
		theme_overrides = theme.theme_overrides


func _connect_signals() -> void:
	if tab_container:
		tab_container.tab_changed.connect(_on_tab_changed)


func _setup_level_select() -> void:
	if not tab_level_select:
		return

	# Get the chapters container from the scene
	var chapters_container = tab_level_select.find_child("ChaptersContainer", true, false)
	if not chapters_container:
		return

	# Clear any existing children
	for child in chapters_container.get_children():
		child.queue_free()

	# Populate chapters
	for chapter in ProgressionManager.all_chapters:
		var card = ChapterCard.new()
		card.setup(chapter)
		card.level_selected.connect(_on_level_selected)
		chapters_container.add_child(card)

	# Connect start button
	var start_button = tab_level_select.find_child("StartButton", true, false)
	if start_button:
		start_button.pressed.connect(_on_start_battle_pressed)

	# Connect difficulty buttons
	var difficulty_buttons = tab_level_select.find_child("DifficultyButtons", true, false)
	if difficulty_buttons:
		for button in difficulty_buttons.get_children():
			if button is Button:
				button.pressed.connect(_on_difficulty_changed.bind(button.name.to_lower()))
				button.toggle_mode = true

	# Connect level select signal
	if tab_level_select and tab_level_select.has_method("_on_level_selected"):
		pass  # Will be connected during tab setup


func _restore_last_tab() -> void:
	if tab_container:
		tab_container.current_tab = _last_tab


func _on_tab_changed(tab: int) -> void:
	_last_tab = tab


func _on_level_selected(level: LevelData) -> void:
	_selected_level = level
	var detail_title = tab_level_select.find_child("DetailTitle", true, false)
	var detail_description = tab_level_select.find_child("DetailDescription", true, false)

	if detail_title:
		detail_title.text = level.display_name
	if detail_description:
		detail_description.text = level.description


func _on_difficulty_changed(difficulty: String) -> void:
	_selected_difficulty = difficulty


func _on_start_battle_pressed() -> void:
	if _selected_level:
		start_battle(_selected_level, _selected_difficulty)


func start_battle(level: LevelData, difficulty: String) -> void:
	ProgressionManager.current_level = level
	ProgressionManager.current_difficulty = difficulty
	SceneManager.change_scene("res://ui/screens/battle_screen.tscn")


func _on_battle_requested(level: LevelData, difficulty: String) -> void:
	start_battle(level, difficulty)
