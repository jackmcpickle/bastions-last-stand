extends Control

## Tower selection and upgrade screen

const SHRINE_UPGRADE_SCENE = "res://ui/screens/shrine_upgrade.tscn"
const TowerCardScene = preload("res://ui/components/tower_card.tscn")
const UpgradeTreeScene = preload("res://ui/components/upgrade_tree.tscn")

@onready var background: ColorRect = %Background
@onready var title_label: Label = %TitleLabel
@onready var gold_label: Label = %GoldLabel
@onready var tower_grid: GridContainer = %TowerGrid
@onready var upgrade_panel: Control = %UpgradePanel
@onready var upgrade_tree_container: Control = %UpgradeTreeContainer
@onready var continue_button: Button = %ContinueButton

var _tower_cards: Array = []
var _selected_tower = null
var _upgrade_tree = null
var _player_gold: int = 500  # TODO: connect to game state

## Tower data references
var _tower_data: Dictionary = {}


func _ready() -> void:
	_apply_theme()
	_load_tower_data()
	_setup_tower_grid()
	_update_gold_display()
	upgrade_panel.visible = false
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


func _load_tower_data() -> void:
	_tower_data["archer"] = load("res://resources/towers/archer_tower.tres")
	_tower_data["cannon"] = load("res://resources/towers/cannon_tower.tres")
	_tower_data["frost"] = load("res://resources/towers/frost_tower.tres")
	_tower_data["lightning"] = load("res://resources/towers/lightning_tower.tres")
	_tower_data["flame"] = load("res://resources/towers/flame_tower.tres")


func _setup_tower_grid() -> void:
	for tower_id in _tower_data:
		var card = TowerCardScene.instantiate()
		tower_grid.add_child(card)
		card.setup(_tower_data[tower_id])
		card.selected.connect(_on_tower_selected.bind(card))
		_tower_cards.append(card)


func _update_gold_display() -> void:
	gold_label.text = "%d Gold" % _player_gold


func _on_tower_selected(card) -> void:
	# Deselect previous
	if _selected_tower:
		_selected_tower.set_selected(false)

	# Select new
	_selected_tower = card
	card.set_selected(true)

	# Show upgrade tree
	_show_upgrade_tree(card.tower_data)


func _show_upgrade_tree(tower_data: Resource) -> void:
	# Clear existing tree
	if _upgrade_tree:
		_upgrade_tree.queue_free()

	# Create new tree
	_upgrade_tree = UpgradeTreeScene.instantiate()
	upgrade_tree_container.add_child(_upgrade_tree)
	_upgrade_tree.setup(tower_data, 1, "")
	_upgrade_tree.upgrade_selected.connect(_on_upgrade_selected)

	upgrade_panel.visible = true


func _on_upgrade_selected(upgrade_id: String) -> void:
	# TODO: Apply upgrade, deduct gold
	print("Upgrade selected: ", upgrade_id)


func _on_continue_pressed() -> void:
	SceneManager.change_scene(SHRINE_UPGRADE_SCENE)
