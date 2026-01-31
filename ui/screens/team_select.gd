extends Control

## Team/Faction selection screen

const MAIN_HUB_SCENE = "res://ui/screens/main_hub.tscn"
const FactionCardScene = preload("res://ui/components/faction_card.tscn")

@onready var title_label: Label = %TitleLabel
@onready var cards_container: HBoxContainer = %CardsContainer

var _light_card
var _dark_card


func _ready() -> void:
	_setup_faction_cards()


func _setup_faction_cards() -> void:
	_light_card = FactionCardScene.instantiate()
	cards_container.add_child(_light_card)
	_light_card.setup(SceneManager.Faction.LIGHT)
	_light_card.selected.connect(_on_faction_selected.bind(SceneManager.Faction.LIGHT))

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(60, 0)
	cards_container.add_child(spacer)

	_dark_card = FactionCardScene.instantiate()
	cards_container.add_child(_dark_card)
	_dark_card.setup(SceneManager.Faction.DARK)
	_dark_card.selected.connect(_on_faction_selected.bind(SceneManager.Faction.DARK))


func _on_faction_selected(faction: SceneManager.Faction) -> void:
	SceneManager.select_faction(faction)
	SceneManager.change_scene(MAIN_HUB_SCENE)
