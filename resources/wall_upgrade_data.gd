class_name WallUpgradeData
extends Resource

## Wall upgrade path data (mirrors TowerUpgradeData structure)

@export var id: String
@export var display_name: String
@export var tier: int  # 2 or 3
@export var branch: String  # "A", "B", "A1", "A2", "B1", "B2"
@export var parent_branch: String  # "" for T2, "A" or "B" for T3

## Stat overrides
@export var hp: int = 0  # Raw max HP; 0 = leave unchanged

## Special ability overrides/additions
@export var special: Dictionary = {}

@export var description: String
