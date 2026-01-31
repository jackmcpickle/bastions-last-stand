class_name LevelIcon extends Button

signal level_selected(level)

var level

@onready var star_display: HBoxContainer = %StarDisplay
@onready var lock_icon: Control = %LockIcon


func _ready() -> void:
	pressed.connect(_on_pressed)


func setup(p_level) -> void:
	level = p_level
	_update_display()


func _update_display() -> void:
	var is_unlocked = ProgressionManager.is_level_unlocked(level.id)
	disabled = not is_unlocked

	if lock_icon:
		lock_icon.visible = not is_unlocked

	if is_unlocked:
		_show_best_stars()
	else:
		_show_locked()


func _show_best_stars() -> void:
	if not star_display:
		return

	# Show max stars across all difficulties
	var max_stars = 0
	for diff in ["easy", "normal", "hard"]:
		var stars = ProgressionManager.get_level_stars(level.id, diff)
		max_stars = max(max_stars, stars)
	_display_stars(max_stars)


func _show_locked() -> void:
	if not star_display:
		return
	star_display.clear()


func _display_stars(count: int) -> void:
	if not star_display:
		return

	# Clear existing
	for child in star_display.get_children():
		child.queue_free()

	# Add star labels
	for i in range(count):
		var star_label = Label.new()
		star_label.text = "★"
		star_label.add_theme_font_size_override("font_size", 14)
		star_display.add_child(star_label)


func _on_pressed() -> void:
	if not disabled:
		level_selected.emit(level)
