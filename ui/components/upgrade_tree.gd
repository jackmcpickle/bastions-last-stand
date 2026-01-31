class_name UpgradeTree
extends Control

## Visual branching upgrade tree for towers

signal upgrade_selected(upgrade_id: String)

@onready var tree_container: VBoxContainer = %TreeContainer

var tower_data: Resource = null
var current_tier: int = 1
var current_branch: String = ""

## Upgrade node references
var _upgrade_nodes: Dictionary = {}


func _ready() -> void:
	pass


func setup(p_tower_data: Resource, p_tier: int = 1, p_branch: String = "") -> void:
	tower_data = p_tower_data
	current_tier = p_tier
	current_branch = p_branch
	_build_tree()


func _build_tree() -> void:
	# Clear existing
	for child in tree_container.get_children():
		child.queue_free()
	_upgrade_nodes.clear()

	if not tower_data or not tower_data.upgrades:
		return

	# Tier 1 - Base tower (always unlocked)
	var tier1 := _create_tier_row(
		[
			{
				"id": tower_data.id,
				"name": tower_data.display_name,
				"tier": 1,
				"unlocked": true,
				"selected": current_tier == 1
			}
		]
	)
	tree_container.add_child(tier1)

	# Connector
	tree_container.add_child(_create_connector())

	# Tier 2 - Two branches (A and B)
	var tier2_upgrades := []
	for upgrade in tower_data.upgrades:
		if upgrade.tier == 2:
			tier2_upgrades.append(
				{
					"id": upgrade.id,
					"name": upgrade.display_name,
					"tier": 2,
					"branch": upgrade.branch,
					"unlocked": current_tier >= 2,
					"selected": current_tier == 2 and current_branch == upgrade.branch
				}
			)

	if tier2_upgrades.size() > 0:
		var tier2 := _create_tier_row(tier2_upgrades)
		tree_container.add_child(tier2)
		tree_container.add_child(_create_connector())

	# Tier 3 - Four branches (A1, A2, B1, B2)
	var tier3_upgrades := []
	for upgrade in tower_data.upgrades:
		if upgrade.tier == 3:
			tier3_upgrades.append(
				{
					"id": upgrade.id,
					"name": upgrade.display_name,
					"tier": 3,
					"branch": upgrade.branch,
					"parent_branch": upgrade.parent_branch,
					"unlocked": current_tier >= 3,
					"selected": current_tier == 3 and current_branch == upgrade.branch
				}
			)

	if tier3_upgrades.size() > 0:
		var tier3 := _create_tier_row(tier3_upgrades)
		tree_container.add_child(tier3)


func _create_tier_row(upgrades: Array) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 20)

	for upgrade in upgrades:
		var node := _create_upgrade_node(upgrade)
		row.add_child(node)
		_upgrade_nodes[upgrade.id] = node

	return row


func _create_upgrade_node(upgrade: Dictionary) -> Control:
	var container := Control.new()
	container.custom_minimum_size = Vector2(100, 60)

	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)

	var faction := SceneManager.current_faction
	if upgrade.selected:
		match faction:
			SceneManager.Faction.LIGHT:
				bg.color = Color(0.85, 0.7, 0.2, 1)
			SceneManager.Faction.DARK:
				bg.color = Color(0.6, 0.15, 0.2, 1)
			_:
				bg.color = Color(0.4, 0.4, 0.5, 1)
	elif upgrade.unlocked:
		match faction:
			SceneManager.Faction.LIGHT:
				bg.color = Color(0.9, 0.85, 0.75, 1)
			SceneManager.Faction.DARK:
				bg.color = Color(0.25, 0.2, 0.3, 1)
			_:
				bg.color = Color(0.3, 0.3, 0.35, 1)
	else:
		bg.color = Color(0.2, 0.2, 0.2, 0.5)

	container.add_child(bg)

	var label := Label.new()
	label.text = upgrade.name
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.set_anchors_preset(Control.PRESET_FULL_RECT)
	label.add_theme_font_size_override("font_size", 11)

	if upgrade.unlocked:
		match faction:
			SceneManager.Faction.LIGHT:
				label.add_theme_color_override("font_color", Color(0.2, 0.15, 0.1, 1))
			SceneManager.Faction.DARK:
				label.add_theme_color_override("font_color", Color(0.9, 0.88, 0.85, 1))
	else:
		label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5, 1))

	container.add_child(label)

	# Make clickable
	var button := Button.new()
	button.flat = true
	button.set_anchors_preset(Control.PRESET_FULL_RECT)
	button.pressed.connect(_on_upgrade_pressed.bind(upgrade.id))
	button.disabled = not upgrade.unlocked or upgrade.selected
	container.add_child(button)

	return container


func _create_connector() -> Control:
	var connector := Control.new()
	connector.custom_minimum_size = Vector2(0, 20)

	var line := ColorRect.new()
	line.color = Color(0.4, 0.4, 0.4, 0.5)
	line.custom_minimum_size = Vector2(2, 20)
	line.set_anchors_preset(Control.PRESET_CENTER)
	connector.add_child(line)

	return connector


func _on_upgrade_pressed(upgrade_id: String) -> void:
	upgrade_selected.emit(upgrade_id)
