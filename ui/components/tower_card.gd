class_name TowerCard
extends Control

## Tower display card with tier indicator

signal selected
signal upgrade_requested

@export var tower_id: String = ""
@export var current_tier: int = 1

@onready var background: ColorRect = %Background
@onready var icon_label: Label = %IconLabel
@onready var name_label: Label = %NameLabel
@onready var tier_label: Label = %TierLabel
@onready var cost_label: Label = %CostLabel
@onready var select_area: Control = %SelectArea

var tower_data: Resource = null
var _is_selected: bool = false

## Tower icons by type
const TOWER_ICONS := {
	"archer": "🏹",
	"cannon": "💣",
	"frost": "❄",
	"lightning": "⚡",
	"flame": "🔥",
}

## Light faction tower names
const LIGHT_NAMES := {
	"archer": "Lightbow Spire",
	"cannon": "Divine Ballista",
	"frost": "Crystal Sanctum",
	"lightning": "Holy Storm Tower",
	"flame": "Sacred Pyre",
}

## Dark faction tower names
const DARK_NAMES := {
	"archer": "Hex Crossbow",
	"cannon": "Doom Mortar",
	"frost": "Soul Cage",
	"lightning": "Blight Spire",
	"flame": "Infernal Brazier",
}


func _ready() -> void:
	select_area.gui_input.connect(_on_gui_input)
	_apply_theme()


func setup(p_tower_data: Resource, p_tier: int = 1) -> void:
	tower_data = p_tower_data
	tower_id = p_tower_data.id
	current_tier = p_tier
	_update_display()


func _update_display() -> void:
	if not tower_data:
		return

	var faction := SceneManager.current_faction
	var names: Dictionary
	match faction:
		SceneManager.Faction.LIGHT:
			names = LIGHT_NAMES
		SceneManager.Faction.DARK:
			names = DARK_NAMES
		_:
			names = {}

	icon_label.text = TOWER_ICONS.get(tower_id, "🗼")
	name_label.text = names.get(tower_id, tower_data.display_name)
	tier_label.text = "T%d" % current_tier
	cost_label.text = "%dg" % tower_data.base_cost


func _apply_theme() -> void:
	var faction := SceneManager.current_faction
	match faction:
		SceneManager.Faction.LIGHT:
			background.color = Color(0.95, 0.9, 0.75, 1)
			name_label.add_theme_color_override("font_color", Color(0.2, 0.15, 0.1, 1))
			tier_label.add_theme_color_override("font_color", Color(0.85, 0.7, 0.2, 1))
			cost_label.add_theme_color_override("font_color", Color(0.4, 0.35, 0.3, 1))
		SceneManager.Faction.DARK:
			background.color = Color(0.2, 0.15, 0.25, 1)
			name_label.add_theme_color_override("font_color", Color(0.9, 0.88, 0.85, 1))
			tier_label.add_theme_color_override("font_color", Color(0.6, 0.15, 0.2, 1))
			cost_label.add_theme_color_override("font_color", Color(0.6, 0.55, 0.5, 1))


func set_selected(value: bool) -> void:
	_is_selected = value
	var glow_color: Color
	match SceneManager.current_faction:
		SceneManager.Faction.LIGHT:
			glow_color = Color(1, 0.9, 0.4, 0.5) if value else Color(0, 0, 0, 0)
		SceneManager.Faction.DARK:
			glow_color = Color(0.6, 0.1, 0.3, 0.5) if value else Color(0, 0, 0, 0)
		_:
			glow_color = Color(0, 0, 0, 0)
	# Would apply glow here with shader or outline


func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			selected.emit()
