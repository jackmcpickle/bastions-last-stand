class_name EnemyData
extends Resource

## Enemy configuration resource
## All numeric values use fixed-point x1000 for determinism where noted

@export var id: String
@export var display_name: String

## Base stats
@export var hp: int  # Raw HP value (not fixed-point)
@export var speed: int  # x1000: 1000 = 1.0 tiles/sec, 2000 = 2.0 tiles/sec
@export var armor: int  # x1000: 300 = 30% damage reduction
@export var gold_value: int  # Gold awarded on kill

## Special properties
@export var special: Dictionary = {}
# Examples:
# { "flying": true } - ignores pathing
# { "stealth": true } - invisible until attacked
# { "wall_breaker": true } - ignores pathing, attacks walls
# { "healer_range": 3, "heal_per_sec": 5000 } - heals nearby (x1000)
# { "shield_hp": 50 } - regenerating shield
# { "splits_into": "mini", "split_count": 3 } - spawns on death
# { "regen_per_sec": 8000 } - HP regen (x1000)

## For boss enemies
@export var is_boss: bool = false
@export var boss_abilities: Array[String] = []


func get_effective_hp(incoming_damage: int) -> int:
	## Returns effective HP accounting for armor
	if armor <= 0:
		return hp
	var damage_multiplier := 1000 - armor  # x1000
	if damage_multiplier <= 0:
		return hp * 1000  # Essentially invulnerable
	return hp * 1000 / damage_multiplier


func apply_armor(damage: int) -> int:
	## Returns damage after armor reduction (fixed-point)
	return damage * (1000 - armor) / 1000
