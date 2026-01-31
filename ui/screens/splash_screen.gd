extends Control

## Splash screen with game logo and auto-advance

const TEAM_SELECT_SCENE = "res://ui/screens/team_select.tscn"
const SETTINGS_SCENE = "res://ui/screens/settings.tscn"

@export var auto_advance_delay: float = 2.5
@export var fade_in_duration: float = 0.8

@onready var title_label: Label = %TitleLabel
@onready var subtitle_label: Label = %SubtitleLabel
@onready var prompt_label: Label = %PromptLabel
@onready var settings_button: Button = %SettingsButton
@onready var content_container: VBoxContainer = %ContentContainer

var _can_advance: bool = false
var _auto_timer: float = 0.0


func _ready() -> void:
	content_container.modulate.a = 0.0
	prompt_label.modulate.a = 0.0

	var tween := create_tween()
	tween.tween_property(content_container, "modulate:a", 1.0, fade_in_duration)
	tween.tween_callback(_enable_advance)
	tween.tween_property(prompt_label, "modulate:a", 1.0, 0.5)


func _enable_advance() -> void:
	_can_advance = true


func _process(delta: float) -> void:
	if not _can_advance:
		return

	_auto_timer += delta
	if _auto_timer >= auto_advance_delay:
		_advance_to_team_select()
		set_process(false)


func _input(event: InputEvent) -> void:
	if not _can_advance:
		return

	if event is InputEventKey or event is InputEventMouseButton or event is InputEventScreenTouch:
		if event.is_pressed():
			_advance_to_team_select()


func _advance_to_team_select() -> void:
	SceneManager.change_scene(TEAM_SELECT_SCENE)


func _on_settings_button_pressed() -> void:
	SceneManager.change_scene(SETTINGS_SCENE)
