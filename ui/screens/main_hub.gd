extends Control

## Main hub with tabbed interface (book-style pages)

@onready var tab_container: TabContainer = %TabContainer
@onready var tab_level_select: Control = %LevelSelectTab
@onready var tab_towers: Control = %TowersTab
@onready var tab_shrine: Control = %ShrineTab
@onready var tab_lore: Control = %LoreTab
@onready var tab_settings: Control = %SettingsTab

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
		add_theme_overrides_from(theme)


func _connect_signals() -> void:
	if tab_container:
		tab_container.tab_changed.connect(_on_tab_changed)


func _setup_level_select() -> void:
	# Level select is already embedded in main_hub.tscn as LevelSelectTab
	# and has level_select.gd script handling its logic
	pass


func _restore_last_tab() -> void:
	if tab_container:
		tab_container.current_tab = _last_tab


func _on_tab_changed(tab: int) -> void:
	_last_tab = tab


func _on_level_selected(level) -> void:
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


func start_battle(level, difficulty: String) -> void:
	ProgressionManager.current_level = level
	ProgressionManager.current_difficulty = difficulty
	SceneManager.change_scene("res://ui/screens/battle_screen.tscn")


func _on_battle_requested(level, difficulty: String) -> void:
	start_battle(level, difficulty)
