class_name WallData
extends Resource

## Base wall configuration resource

@export var id: String = "wall"
@export var display_name: String = "Wall"
@export var base_cost: int = 10
@export var hp: int = 100

@export var upgrade_cost_t2: int = 40
@export var upgrade_cost_t3: int = 80
@export var upgrades: Array[WallUpgradeData] = []
@export var special: Dictionary = {}
