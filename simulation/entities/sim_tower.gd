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
var frozen_ms: int = 0  # Frost Wyrm freeze duration

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
	return cooldown_ms <= 0 and frozen_ms <= 0


func process_cooldown(delta_ms: int) -> void:
	if cooldown_ms > 0:
		cooldown_ms -= delta_ms
		if cooldown_ms < 0:
			cooldown_ms = 0
	if frozen_ms > 0:
		frozen_ms -= delta_ms
		if frozen_ms < 0:
			frozen_ms = 0


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
	elif special.has("chain"):
		# Chain attack - hits primary target then chains to nearby
		hit_enemies = _get_chain_targets(target, all_enemies)
	elif special.has("pierce"):
		# Pierce attack - hits multiple enemies in a line
		hit_enemies = get_pierce_targets(target, all_enemies)
	else:
		# Single target
		hit_enemies = [target]

	return hit_enemies


func _get_chain_targets(target: SimEnemy, all_enemies: Array[SimEnemy]) -> Array[SimEnemy]:
	## Returns list of chain targets starting from primary target
	var chain_count: int = special.get("chain", 1)
	var chain_range: float = special.get("chain_range", 2.0)

	var hit: Array[SimEnemy] = [target]
	var current := target

	for i in range(chain_count - 1):
		var next := _find_nearest_unchained(current, all_enemies, hit, chain_range)
		if not next:
			break
		hit.append(next)
		current = next

	return hit


func _find_nearest_unchained(from: SimEnemy, all_enemies: Array[SimEnemy], exclude: Array[SimEnemy], max_range: float) -> SimEnemy:
	var best: SimEnemy = null
	var best_dist := max_range * max_range

	for enemy in all_enemies:
		if enemy in exclude or not enemy.is_targetable():
			continue
		var dx := from.grid_pos.x - enemy.grid_pos.x
		var dy := from.grid_pos.y - enemy.grid_pos.y
		var dist_sq := dx * dx + dy * dy
		if dist_sq < best_dist:
			best_dist = dist_sq
			best = enemy

	return best


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


## Upgrade methods
func can_upgrade_to(upgrade: TowerUpgradeData) -> bool:
	## Validates if tower can take this upgrade
	if not upgrade:
		return false

	# Check tier progression
	if upgrade.tier != tier + 1:
		return false

	# Tier 2: Any branch allowed
	if upgrade.tier == 2:
		return true

	# Tier 3: Must match parent branch
	if upgrade.tier == 3:
		return upgrade.parent_branch == branch

	return false


func apply_upgrade(upgrade: TowerUpgradeData) -> void:
	## Applies upgrade stats to tower
	if not upgrade:
		return

	# Update stats
	if upgrade.damage > 0:
		damage = upgrade.damage
	if upgrade.attack_speed_ms > 0:
		attack_speed_ms = upgrade.attack_speed_ms
	if upgrade.range_tiles > 0:
		range_tiles = upgrade.range_tiles
	aoe_radius = upgrade.aoe_radius

	# Merge special abilities
	for key in upgrade.special:
		special[key] = upgrade.special[key]

	# Update upgrade state
	tier = upgrade.tier
	branch = upgrade.branch


func get_available_upgrades() -> Array[TowerUpgradeData]:
	## Returns list of valid upgrades for current state
	var result: Array[TowerUpgradeData] = []
	for upgrade in data.upgrades:
		if can_upgrade_to(upgrade):
			result.append(upgrade)
	return result


func get_pierce_targets(target: SimEnemy, all_enemies: Array[SimEnemy]) -> Array[SimEnemy]:
	## Get enemies for pierce attack (in line through target)
	var pierce_count: int = special.get("pierce", 1)
	if pierce_count <= 1:
		return [target]

	var result: Array[SimEnemy] = [target]
	var tower_pos := get_center()
	var target_pos := target.grid_pos

	# Direction from tower to target
	var dir := (target_pos - tower_pos).normalized()

	# Find enemies beyond target in same direction
	var candidates: Array[SimEnemy] = []
	for enemy in all_enemies:
		if enemy == target or not enemy.is_targetable():
			continue

		# Check if enemy is roughly in the same direction
		var to_enemy := (enemy.grid_pos - tower_pos).normalized()
		var dot := dir.dot(to_enemy)

		if dot > 0.9:  # Within ~25 degrees of target direction
			var dist := (enemy.grid_pos - tower_pos).length()
			candidates.append(enemy)

	# Sort by distance and take pierce_count - 1 additional targets
	candidates.sort_custom(func(a: SimEnemy, b: SimEnemy) -> bool:
		var da := (a.grid_pos - tower_pos).length()
		var db := (b.grid_pos - tower_pos).length()
		return da < db
	)

	for i in range(mini(pierce_count - 1, candidates.size())):
		result.append(candidates[i])

	return result
