class_name SimTower
extends RefCounted

## Tower entity for headless simulation

var id: String
var data: TowerData
var position: Vector2i  # Top-left corner of 2x2 tower

## Stats (from data, can be upgraded)
var damage: int  # x1000
var attack_speed_ms: int
var range_tiles: int
var aoe_radius: int  # x1000, 0 = single target

## Special abilities
var special: Dictionary = {}

## Upgrade state
var tier: int = 1
var branch: String = ""  # "A", "B", "A1", etc.
var total_cost: int = 0  # For sell value calculation

## Combat state
var cooldown_ms: int = 0
var target_priority: Targeting.Priority = Targeting.Priority.FIRST

## Tracking
var total_damage_dealt: int = 0  # x1000
var kills: int = 0
var shots_fired: int = 0


func initialize(p_data: TowerData, p_position: Vector2i) -> void:
	data = p_data
	id = data.id
	position = p_position
	
	# Copy base stats
	damage = data.damage
	attack_speed_ms = data.attack_speed_ms
	range_tiles = data.range_tiles
	aoe_radius = data.aoe_radius
	special = data.special.duplicate()
	
	total_cost = data.base_cost
	tier = 1


func get_center() -> Vector2:
	## Returns center position of 2x2 tower
	return Vector2(position.x + 1.0, position.y + 1.0)


func can_attack() -> bool:
	return cooldown_ms <= 0


func process_cooldown(delta_ms: int) -> void:
	if cooldown_ms > 0:
		cooldown_ms -= delta_ms
		if cooldown_ms < 0:
			cooldown_ms = 0


func attack(target: SimEnemy, all_enemies: Array[SimEnemy]) -> Array[SimEnemy]:
	## Performs attack, returns list of enemies hit
	## Caller is responsible for applying damage
	
	if not can_attack():
		return []
	
	cooldown_ms = attack_speed_ms
	shots_fired += 1
	
	var hit_enemies: Array[SimEnemy] = []
	
	if aoe_radius > 0:
		# AOE attack centered on target
		var radius := float(aoe_radius) / 1000.0
		hit_enemies = Targeting.get_enemies_in_aoe(target.grid_pos, all_enemies, radius)
	else:
		# Single target
		hit_enemies = [target]
	
	return hit_enemies


func get_damage_for_target(target: SimEnemy) -> int:
	## Returns damage to deal to target (x1000)
	## Can be modified by specials
	var final_damage := damage
	
	# Hunter bonus vs fast enemies
	if special.has("fast_bonus") and target.speed >= 1500:  # 1.5+ tiles/sec
		final_damage = final_damage * (1000 + special.fast_bonus) / 1000
	
	return final_damage


func record_damage(amount: int) -> void:
	total_damage_dealt += amount


func record_kill() -> void:
	kills += 1


func get_sell_value() -> int:
	## 90% of total invested
	return total_cost * 90 / 100


func get_dps() -> float:
	## Returns theoretical DPS for display
	if attack_speed_ms <= 0:
		return 0.0
	return (float(damage) / 1000.0) / (float(attack_speed_ms) / 1000.0)


## Upgrade methods (to be expanded)
func can_upgrade_to(branch_id: String) -> bool:
	# TODO: Implement upgrade tree validation
	return false


func apply_upgrade(upgrade: TowerUpgradeData) -> void:
	# TODO: Implement upgrade application
	pass
