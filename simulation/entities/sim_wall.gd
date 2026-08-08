class_name SimWall
extends RefCounted

## Wall entity for headless simulation

var data: WallData
var position: Vector2i
var hp: int
var max_hp: int
var tier: int = 1
var branch: String = ""
var special: Dictionary = {}
var total_cost: int = 0

## Combat / repair state
var combat_idle_ms: int = 999999  # High = start "out of combat"
var stun_cooldown_remaining_ms: int = 0
var repair_accum_ms: int = 0

## Tracking
var total_damage_taken: int = 0


func initialize(p_data: WallData, p_position: Vector2i) -> void:
	data = p_data
	position = p_position
	hp = p_data.hp
	max_hp = p_data.hp
	special = p_data.special.duplicate()
	total_cost = p_data.base_cost
	tier = 1
	branch = ""
	combat_idle_ms = 999999
	stun_cooldown_remaining_ms = 0
	repair_accum_ms = 0


func take_damage(amount: int) -> void:
	total_damage_taken += amount
	hp -= amount
	if hp < 0:
		hp = 0
	combat_idle_ms = 0


func is_destroyed() -> bool:
	return hp <= 0


func get_hp_percent() -> float:
	if max_hp <= 0:
		return 0.0
	return float(hp) / float(max_hp)


func process_timers(delta_ms: int) -> void:
	combat_idle_ms += delta_ms
	if stun_cooldown_remaining_ms > 0:
		stun_cooldown_remaining_ms -= delta_ms
		if stun_cooldown_remaining_ms < 0:
			stun_cooldown_remaining_ms = 0


func can_upgrade_to(upgrade: WallUpgradeData) -> bool:
	if not upgrade:
		return false
	if upgrade.tier != tier + 1:
		return false
	if upgrade.tier == 2:
		return true
	if upgrade.tier == 3:
		return upgrade.parent_branch == branch
	return false


func apply_upgrade(upgrade: WallUpgradeData) -> void:
	if not upgrade:
		return
	if upgrade.hp > 0:
		max_hp = upgrade.hp
		if hp > max_hp:
			hp = max_hp
	for key in upgrade.special:
		special[key] = upgrade.special[key]
	tier = upgrade.tier
	branch = upgrade.branch


func get_available_upgrades() -> Array[WallUpgradeData]:
	var result: Array[WallUpgradeData] = []
	if not data:
		return result
	for upgrade in data.upgrades:
		if can_upgrade_to(upgrade):
			result.append(upgrade)
	return result


func is_out_of_combat(threshold_ms: int = 2000) -> bool:
	return combat_idle_ms >= threshold_ms
