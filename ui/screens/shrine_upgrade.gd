extends Control

## Shrine upgrade screen

const SPLASH_SCENE = "res://ui/screens/splash_screen.tscn"  # For now, loops back
const ShrineDisplayScene = preload("res://ui/components/shrine_display.tscn")
const UpgradeSlotScene = preload("res://ui/components/upgrade_slot.tscn")

@onready var background: ColorRect = %Background
@onready var title_label: Label = %TitleLabel
@onready var gold_label: Label = %GoldLabel
@onready var shrine_container: Control = %ShrineContainer
@onready var upgrades_container: VBoxContainer = %UpgradesContainer
@onready var continue_button: Button = %ContinueButton

var _shrine_display = null
var _upgrade_slots: Array = []
var _player_gold: int = 500  # TODO: connect to game state
var _shrine_hp: int = 1000
var _shrine_max_hp: int = 1000

## Upgrade definitions
const SHRINE_UPGRADES := [
	{
		"id": "hp_boost",
		"name": "Fortify",
		"description": "Increase shrine HP by 200",
		"cost": 150,
		"icon": "❤"
	},
	{
		"id": "gold_gen",
		"name": "Prosperity",
		"description": "+5 gold per wave",
		"cost": 200,
		"icon": "💰"
	},
	{
		"id": "damage_aura",
		"name": "Retribution",
		"description": "Damage nearby enemies",
		"cost": 300,
		"icon": "⚔"
	},
	{
		"id": "heal_pulse",
		"name": "Restoration",
		"description": "Heal shrine between waves",
		"cost": 250,
		"icon": "✨"
	}
]


func _ready() -> void:
	_apply_theme()
	_setup_shrine_display()
	_setup_upgrades()
	_update_gold_display()
	continue_button.pressed.connect(_on_continue_pressed)


func _apply_theme() -> void:
	var faction := SceneManager.current_faction
	match faction:
		SceneManager.Faction.LIGHT:
			background.color = Color(0.95, 0.92, 0.87, 1)
			title_label.add_theme_color_override("font_color", Color(0.2, 0.15, 0.1, 1))
			gold_label.add_theme_color_override("font_color", Color(0.7, 0.55, 0.1, 1))
		SceneManager.Faction.DARK:
			background.color = Color(0.1, 0.08, 0.12, 1)
			title_label.add_theme_color_override("font_color", Color(0.9, 0.88, 0.85, 1))
			gold_label.add_theme_color_override("font_color", Color(0.8, 0.6, 0.2, 1))

	title_label.text = SceneManager.get_shrine_name() + " Upgrades"


func _setup_shrine_display() -> void:
	_shrine_display = ShrineDisplayScene.instantiate()
	shrine_container.add_child(_shrine_display)
	_shrine_display.set_hp(_shrine_hp, _shrine_max_hp)


func _setup_upgrades() -> void:
	for upgrade_def in SHRINE_UPGRADES:
		var slot = UpgradeSlotScene.instantiate()
		upgrades_container.add_child(slot)
		slot.setup(
			upgrade_def.id,
			upgrade_def.name,
			upgrade_def.description,
			upgrade_def.cost,
			0,
			5,
			upgrade_def.icon
		)
		slot.upgrade_requested.connect(_on_upgrade_requested.bind(slot))
		_upgrade_slots.append(slot)


func _update_gold_display() -> void:
	gold_label.text = "%d Gold" % _player_gold


func _on_upgrade_requested(slot) -> void:
	if _player_gold >= slot.upgrade_cost:
		_player_gold -= slot.upgrade_cost
		slot.current_level += 1
		slot._update_display()
		_update_gold_display()

		# Apply upgrade effect
		match slot.upgrade_id:
			"hp_boost":
				_shrine_max_hp += 200
				_shrine_hp += 200
				_shrine_display.set_hp(_shrine_hp, _shrine_max_hp)


func _on_continue_pressed() -> void:
	# For now loop back to splash
	# TODO: Start actual gameplay
	SceneManager.change_scene(SPLASH_SCENE)
