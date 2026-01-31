class_name ChapterCard extends Control

signal level_selected(level)

var chapter
var is_expanded: bool = false

@onready var title_label: Label = %TitleLabel
@onready var expand_button: Button = %ExpandButton
@onready var levels_grid: GridContainer = %LevelsGrid


func _ready() -> void:
	if expand_button:
		expand_button.pressed.connect(_on_expand_pressed)


func setup(p_chapter) -> void:
	chapter = p_chapter
	title_label.text = chapter.display_name
	_populate_levels()
	_update_lock_state()


func _populate_levels() -> void:
	# Clear existing
	for child in levels_grid.get_children():
		child.queue_free()

	var icon_scene = load("res://ui/components/level_icon.tscn")
	for level in chapter.levels:
		var icon = icon_scene.instantiate()
		icon.setup(level)
		icon.level_selected.connect(_on_level_selected)
		levels_grid.add_child(icon)


func _update_lock_state() -> void:
	var is_unlocked = ProgressionManager.is_chapter_unlocked(chapter.id)

	# Update visual state
	modulate.a = 1.0 if is_unlocked else 0.5

	if expand_button:
		expand_button.disabled = not is_unlocked

	# Hide lock icon if not needed
	_update_title()


func _update_title() -> void:
	var is_unlocked = ProgressionManager.is_chapter_unlocked(chapter.id)
	if is_unlocked:
		title_label.text = chapter.display_name
	else:
		title_label.text = chapter.display_name + " 🔒"


func _on_expand_pressed() -> void:
	is_expanded = not is_expanded
	if expand_button:
		expand_button.text = "▼" if is_expanded else "▶"
	levels_grid.visible = is_expanded


func _on_level_selected(level) -> void:
	level_selected.emit(level)
