class_name TowerData
extends Resource

## Tower configuration resource
## All numeric values use fixed-point x1000 for determinism where noted

@export var id: String
@export var display_name: String
@export var base_cost: int  # Gold cost

## Combat stats (fixed-point x1000)
@export var damage: int  # x1000: 15000 = 15.0 damage
@export var attack_speed_ms: int  # Milliseconds between attacks
@export var range_tiles: int  # Tile distance
@export var aoe_radius: int  # x1000: 1500 = 1.5 tiles, 0 = single target

## Special abilities
@export var special: Dictionary = {}
# Examples:
# { "chain": 3 } - chains to 3 enemies
# { "slow": 300 } - 30% slow (x1000)
# { "burn_dps": 8000, "burn_duration_ms": 3000 } - 8 dps for 3s
# { "crit_chance": 500 } - 50% crit (x1000)

## Upgrade paths
@export var upgrade_cost_t2: int
@export var upgrade_cost_t3: int
@export var upgrades: Array[TowerUpgradeData] = []


func get_dps() -> float:
	## Returns damage per second as float for display
	if attack_speed_ms <= 0:
		return 0.0
	return (damage / 1000.0) / (attack_speed_ms / 1000.0)


func get_cost_efficiency() -> float:
	## DPS per gold spent
	if base_cost <= 0:
		return 0.0
	return get_dps() / base_cost
