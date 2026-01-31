class_name ShrineDisplay
extends Control

## Animated shrine visual display

@onready var background: ColorRect = %Background
@onready var shrine_label: Label = %ShrineLabel
@onready var name_label: Label = %NameLabel
@onready var hp_bar: ProgressBar = %HPBar
@onready var hp_label: Label = %HPLabel

var _animation_timer: float = 0.0
var _glow_intensity: float = 0.0


func _ready() -> void:
	_apply_faction_theme()


func _process(delta: float) -> void:
	_animation_timer += delta
	_glow_intensity = (sin(_animation_timer * 2.0) + 1.0) * 0.5
	_update_glow()


func _apply_faction_theme() -> void:
	var faction := SceneManager.current_faction
	match faction:
		SceneManager.Faction.LIGHT:
			background.color = Color(0.95, 0.92, 0.85, 1)
			shrine_label.text = "⛲"  # Fountain/lightwell
			shrine_label.add_theme_color_override("font_color", Color(1, 0.9, 0.5, 1))
			name_label.text = "The Lightwell"
			name_label.add_theme_color_override("font_color", Color(0.2, 0.15, 0.1, 1))
			hp_bar.add_theme_stylebox_override("fill", _create_bar_style(Color(0.85, 0.7, 0.2, 1)))
		SceneManager.Faction.DARK:
			background.color = Color(0.12, 0.1, 0.15, 1)
			shrine_label.text = "🔮"  # Soul crucible
			shrine_label.add_theme_color_override("font_color", Color(0.6, 0.2, 0.8, 1))
			name_label.text = "The Soul Crucible"
			name_label.add_theme_color_override("font_color", Color(0.9, 0.88, 0.85, 1))
			hp_bar.add_theme_stylebox_override("fill", _create_bar_style(Color(0.5, 0.1, 0.6, 1)))


func _create_bar_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	return style


func _update_glow() -> void:
	var faction := SceneManager.current_faction
	var base_color: Color
	match faction:
		SceneManager.Faction.LIGHT:
			base_color = Color(1, 0.9, 0.5, 1)
		SceneManager.Faction.DARK:
			base_color = Color(0.6, 0.2, 0.8, 1)
		_:
			base_color = Color.WHITE

	var glow_color := base_color.lerp(Color.WHITE, _glow_intensity * 0.3)
	shrine_label.add_theme_color_override("font_color", glow_color)


func set_hp(current: int, maximum: int) -> void:
	hp_bar.max_value = maximum
	hp_bar.value = current
	hp_label.text = "%d / %d" % [current, maximum]
