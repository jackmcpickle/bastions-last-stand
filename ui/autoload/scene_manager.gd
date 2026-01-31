extends Node

## Scene transition and faction state management

signal faction_selected(faction: Faction)
signal transition_started
signal transition_finished

enum Faction { NONE, LIGHT, DARK }

const LIGHT_THEME = preload("res://ui/themes/light_theme.tres")
const DARK_THEME = preload("res://ui/themes/dark_theme.tres")

var current_faction: Faction = Faction.NONE
var current_theme: Theme = null

## Audio settings
var music_volume: float = 1.0
var sfx_volume: float = 1.0
var music_muted: bool = false
var sfx_muted: bool = false

## Transition state
var _transition_rect: ColorRect
var _is_transitioning: bool = false


func _ready() -> void:
	_setup_transition_overlay()
	_load_settings()


func _setup_transition_overlay() -> void:
	_transition_rect = ColorRect.new()
	_transition_rect.color = Color.BLACK
	_transition_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_transition_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_transition_rect.modulate.a = 0.0

	var canvas := CanvasLayer.new()
	canvas.layer = 100
	canvas.add_child(_transition_rect)
	add_child(canvas)


func select_faction(faction: Faction) -> void:
	current_faction = faction
	match faction:
		Faction.LIGHT:
			current_theme = LIGHT_THEME
		Faction.DARK:
			current_theme = DARK_THEME
		_:
			current_theme = null
	faction_selected.emit(faction)


func get_faction_name() -> String:
	match current_faction:
		Faction.LIGHT:
			return "The Radiant Order"
		Faction.DARK:
			return "The Shadow Covenant"
		_:
			return ""


func get_shrine_name() -> String:
	match current_faction:
		Faction.LIGHT:
			return "The Lightwell"
		Faction.DARK:
			return "The Soul Crucible"
		_:
			return ""


func change_scene(scene_path: String, with_fade: bool = true) -> void:
	if _is_transitioning:
		return

	if with_fade:
		await _fade_out()

	get_tree().change_scene_to_file(scene_path)

	if with_fade:
		await _fade_in()


func change_scene_packed(scene: PackedScene, with_fade: bool = true) -> void:
	if _is_transitioning:
		return

	if with_fade:
		await _fade_out()

	get_tree().change_scene_to_packed(scene)

	if with_fade:
		await _fade_in()


func _fade_out(duration: float = 0.3) -> void:
	_is_transitioning = true
	transition_started.emit()

	var tween := create_tween()
	tween.tween_property(_transition_rect, "modulate:a", 1.0, duration)
	await tween.finished


func _fade_in(duration: float = 0.3) -> void:
	var tween := create_tween()
	tween.tween_property(_transition_rect, "modulate:a", 0.0, duration)
	await tween.finished

	_is_transitioning = false
	transition_finished.emit()


## Settings persistence

func _load_settings() -> void:
	var config := ConfigFile.new()
	if config.load("user://settings.cfg") == OK:
		music_volume = config.get_value("audio", "music_volume", 1.0)
		sfx_volume = config.get_value("audio", "sfx_volume", 1.0)
		music_muted = config.get_value("audio", "music_muted", false)
		sfx_muted = config.get_value("audio", "sfx_muted", false)
	_apply_audio_settings()


func save_settings() -> void:
	var config := ConfigFile.new()
	config.set_value("audio", "music_volume", music_volume)
	config.set_value("audio", "sfx_volume", sfx_volume)
	config.set_value("audio", "music_muted", music_muted)
	config.set_value("audio", "sfx_muted", sfx_muted)
	config.save("user://settings.cfg")


func _apply_audio_settings() -> void:
	var music_db := linear_to_db(music_volume if not music_muted else 0.0)
	var sfx_db := linear_to_db(sfx_volume if not sfx_muted else 0.0)

	if AudioServer.get_bus_index("Music") >= 0:
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), music_db)
	if AudioServer.get_bus_index("SFX") >= 0:
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"), sfx_db)


func set_music_volume(value: float) -> void:
	music_volume = clampf(value, 0.0, 1.0)
	_apply_audio_settings()
	save_settings()


func set_sfx_volume(value: float) -> void:
	sfx_volume = clampf(value, 0.0, 1.0)
	_apply_audio_settings()
	save_settings()


func toggle_music_mute() -> void:
	music_muted = not music_muted
	_apply_audio_settings()
	save_settings()


func toggle_sfx_mute() -> void:
	sfx_muted = not sfx_muted
	_apply_audio_settings()
	save_settings()
