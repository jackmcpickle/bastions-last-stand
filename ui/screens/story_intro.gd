extends Control

## Story introduction with typewriter effect

const TOWER_UPGRADE_SCENE = "res://ui/screens/tower_upgrade.tscn"

const LIGHT_STORY := """For centuries, the Lightwell has protected these lands. Its holy radiance kept the darkness at bay, its waters healed the sick, its light guided the lost home.

Now the corruption spreads. Twisted creatures pour from the shadows, drawn to the Lightwell's power. They seek to extinguish its light forever.

You are the last defender. Marshal your towers. Hold the line. The Lightwell must not fall."""

const DARK_STORY := """They called us heretics. Exiled us to the wastes. Left us to die.

But in the darkness, we found power. The Soul Crucible burns with forbidden energy—souls freely given by those who chose survival over salvation.

Now the crusaders come. They call us evil. They would destroy everything we've built.

Let them come. We did not survive exile to fall now. Defend the Crucible. Show them the strength of the shadows."""

@export var chars_per_second: float = 40.0
@export var skip_to_end_on_input: bool = true

@onready var background: ColorRect = %Background
@onready var story_label: RichTextLabel = %StoryLabel
@onready var continue_button: Button = %ContinueButton

var _full_text: String = ""
var _displayed_chars: int = 0
var _char_timer: float = 0.0
var _is_complete: bool = false


func _ready() -> void:
	continue_button.visible = false
	continue_button.pressed.connect(_on_continue_pressed)
	_apply_faction_theme()
	_start_typewriter()


func _apply_faction_theme() -> void:
	var faction := SceneManager.current_faction
	match faction:
		SceneManager.Faction.LIGHT:
			background.color = Color(0.96, 0.94, 0.9, 1)
			story_label.add_theme_color_override("default_color", Color(0.2, 0.15, 0.1, 1))
			continue_button.add_theme_color_override("font_color", Color(0.85, 0.7, 0.2, 1))
			_full_text = LIGHT_STORY
		SceneManager.Faction.DARK:
			background.color = Color(0.12, 0.1, 0.14, 1)
			story_label.add_theme_color_override("default_color", Color(0.9, 0.88, 0.85, 1))
			continue_button.add_theme_color_override("font_color", Color(0.6, 0.15, 0.2, 1))
			_full_text = DARK_STORY
		_:
			_full_text = "No faction selected."


func _start_typewriter() -> void:
	story_label.text = ""
	_displayed_chars = 0
	_char_timer = 0.0
	_is_complete = false


func _process(delta: float) -> void:
	if _is_complete:
		return

	_char_timer += delta
	var chars_to_show := int(_char_timer * chars_per_second)

	if chars_to_show > _displayed_chars:
		_displayed_chars = mini(chars_to_show, _full_text.length())
		story_label.text = _full_text.substr(0, _displayed_chars)

		if _displayed_chars >= _full_text.length():
			_complete_typewriter()


func _complete_typewriter() -> void:
	_is_complete = true
	story_label.text = _full_text
	continue_button.visible = true

	var tween := create_tween()
	continue_button.modulate.a = 0.0
	tween.tween_property(continue_button, "modulate:a", 1.0, 0.3)


func _input(event: InputEvent) -> void:
	if not skip_to_end_on_input:
		return

	if event is InputEventKey or event is InputEventMouseButton or event is InputEventScreenTouch:
		if event.is_pressed() and not _is_complete:
			_complete_typewriter()


func _on_continue_pressed() -> void:
	SceneManager.change_scene(TOWER_UPGRADE_SCENE)
