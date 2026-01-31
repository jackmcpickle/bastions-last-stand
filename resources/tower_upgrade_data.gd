class_name TowerUpgradeData
extends Resource

## Tower upgrade path data

@export var id: String  # e.g., "archer_marksman", "archer_sniper"
@export var display_name: String
@export var tier: int  # 2 or 3
@export var branch: String  # "A", "B", "A1", "A2", "B1", "B2"
@export var parent_branch: String  # "" for T2, "A" or "B" for T3

## Stat overrides (replaces base stats)
@export var damage: int  # x1000
@export var attack_speed_ms: int
@export var range_tiles: int
@export var aoe_radius: int  # x1000

## Special ability overrides/additions
@export var special: Dictionary = {}

## Description for UI
@export var description: String
