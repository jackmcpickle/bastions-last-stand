class_name FactionCard
extends Control

## Faction selection card component

signal selected

@export var faction: SceneManager.Faction = SceneManager.Faction.NONE
@export var faction_name: String = ""
@export var tagline: String = ""
@export var emblem_text: String = ""

@onready var background: ColorRect = %Background
@onready var emblem_label: Label = %EmblemLabel
@onready var name_label: Label = %NameLabel
@onready var tagline_label: Label = %TaglineLabel
@onready var select_button: Button = %SelectButton
@onready var glow_effect: ColorRect = %GlowEffect

var _is_hovered: bool = false

## Color schemes
const LIGHT_COLORS := {
	"bg": Color(0.96, 0.94, 0.9, 1),
	"accent": Color(0.85, 0.7, 0.2, 1),
	"text": Color(0.2, 0.15, 0.1, 1),
	"glow": Color(1, 0.9, 0.4, 0.3)
}

const DARK_COLORS := {
	"bg": Color(0.15, 0.13, 0.18, 1),
	"accent": Color(0.6, 0.15, 0.2, 1),
	"text": Color(0.9, 0.88, 0.85, 1),
	"glow": Color(0.8, 0.2, 0.3, 0.3)
}


func _ready() -> void:
	_apply_faction_style()
	glow_effect.modulate.a = 0.0
	select_button.pressed.connect(_on_select_pressed)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)


func setup(p_faction: SceneManager.Faction) -> void:
	faction = p_faction
	match faction:
		SceneManager.Faction.LIGHT:
			faction_name = "The Radiant Order"
			tagline = "Guardians of the Lightwell"
			emblem_text = "☀"
		SceneManager.Faction.DARK:
			faction_name = "The Shadow Covenant"
			tagline = "Keepers of the Soul Crucible"
			emblem_text = "☽"
	_apply_faction_style()


func _apply_faction_style() -> void:
	var colors: Dictionary
	match faction:
		SceneManager.Faction.LIGHT:
			colors = LIGHT_COLORS
		SceneManager.Faction.DARK:
			colors = DARK_COLORS
		_:
			return

	if background:
		background.color = colors.bg
	if emblem_label:
		emblem_label.text = emblem_text
		emblem_label.add_theme_color_override("font_color", colors.accent)
	if name_label:
		name_label.text = faction_name
		name_label.add_theme_color_override("font_color", colors.text)
	if tagline_label:
		tagline_label.text = tagline
		tagline_label.add_theme_color_override("font_color", colors.text * 0.7)
	if glow_effect:
		glow_effect.color = colors.glow
	if select_button:
		select_button.add_theme_color_override("font_color", colors.accent)
		select_button.add_theme_color_override("font_hover_color", colors.text)


func _on_select_pressed() -> void:
	selected.emit()


func _on_mouse_entered() -> void:
	_is_hovered = true
	var tween := create_tween()
	tween.tween_property(glow_effect, "modulate:a", 1.0, 0.2)


func _on_mouse_exited() -> void:
	_is_hovered = false
	var tween := create_tween()
	tween.tween_property(glow_effect, "modulate:a", 0.0, 0.2)
