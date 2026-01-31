class_name UpgradeSlot
extends Control

## Individual shrine upgrade option

signal upgrade_requested

@export var upgrade_id: String = ""
@export var upgrade_name: String = ""
@export var upgrade_description: String = ""
@export var upgrade_cost: int = 100
@export var current_level: int = 0
@export var max_level: int = 5

@onready var background: ColorRect = %Background
@onready var icon_label: Label = %IconLabel
@onready var name_label: Label = %NameLabel
@onready var desc_label: Label = %DescLabel
@onready var level_label: Label = %LevelLabel
@onready var cost_label: Label = %CostLabel
@onready var upgrade_button: Button = %UpgradeButton


func _ready() -> void:
	upgrade_button.pressed.connect(_on_upgrade_pressed)
	_apply_theme()
	_update_display()


func setup(p_id: String, p_name: String, p_desc: String, p_cost: int, p_level: int = 0, p_max: int = 5, p_icon: String = "⬆") -> void:
	upgrade_id = p_id
	upgrade_name = p_name
	upgrade_description = p_desc
	upgrade_cost = p_cost
	current_level = p_level
	max_level = p_max
	icon_label.text = p_icon
	_update_display()


func _update_display() -> void:
	name_label.text = upgrade_name
	desc_label.text = upgrade_description
	level_label.text = "%d/%d" % [current_level, max_level]
	cost_label.text = "%dg" % upgrade_cost

	var is_maxed := current_level >= max_level
	upgrade_button.disabled = is_maxed
	upgrade_button.text = "MAX" if is_maxed else "Upgrade"


func _apply_theme() -> void:
	var faction := SceneManager.current_faction
	match faction:
		SceneManager.Faction.LIGHT:
			background.color = Color(0.92, 0.88, 0.8, 1)
			name_label.add_theme_color_override("font_color", Color(0.2, 0.15, 0.1, 1))
			desc_label.add_theme_color_override("font_color", Color(0.4, 0.35, 0.3, 1))
			level_label.add_theme_color_override("font_color", Color(0.85, 0.7, 0.2, 1))
			cost_label.add_theme_color_override("font_color", Color(0.6, 0.5, 0.2, 1))
		SceneManager.Faction.DARK:
			background.color = Color(0.18, 0.15, 0.22, 1)
			name_label.add_theme_color_override("font_color", Color(0.9, 0.88, 0.85, 1))
			desc_label.add_theme_color_override("font_color", Color(0.6, 0.55, 0.5, 1))
			level_label.add_theme_color_override("font_color", Color(0.6, 0.15, 0.2, 1))
			cost_label.add_theme_color_override("font_color", Color(0.7, 0.5, 0.2, 1))


func _on_upgrade_pressed() -> void:
	upgrade_requested.emit()
