class_name Economy
extends RefCounted

## Economy system - gold tracking, bonuses, interest

const WALL_COST := 10
const SELL_RATE := 90  # 90% return
const INTEREST_RATE := 50  # 5% (x1000)
const INTEREST_CAP := 50  # Max 50 gold per wave
const EARLY_START_BONUS_PER_5S := 100  # 10% (x1000)
const EARLY_START_BONUS_MAX := 500  # 50% (x1000)
const PERFECT_WAVE_BONUS := 250  # 25% (x1000)


static func calculate_kill_reward(enemy: SimEnemy, game_state: GameState) -> int:
	## Calculate gold earned from killing an enemy
	var base_reward := enemy.gold_value

	# TODO: Add bonuses from upgrades/modifiers

	return base_reward


static func calculate_wave_bonus(
	wave_gold_earned: int, shrine_took_damage: bool, seconds_early: float = 0.0
) -> int:
	## Calculate end-of-wave bonus gold
	var bonus := 0

	# Perfect wave bonus (no damage)
	if not shrine_took_damage:
		bonus += wave_gold_earned * PERFECT_WAVE_BONUS / 1000

	# Early start bonus
	if seconds_early > 0:
		var early_bonus_mult := mini(
			int(seconds_early / 5.0) * EARLY_START_BONUS_PER_5S, EARLY_START_BONUS_MAX
		)
		bonus += wave_gold_earned * early_bonus_mult / 1000

	return bonus


static func calculate_interest(current_gold: int, has_interest_unlocked: bool) -> int:
	## Calculate interest earned on banked gold
	if not has_interest_unlocked:
		return 0

	var interest := current_gold * INTEREST_RATE / 1000
	return mini(interest, INTEREST_CAP)


static func get_tower_cost(tower_id: String, game_state: GameState) -> int:
	var data := game_state.get_tower_data(tower_id)
	if data:
		return data.base_cost
	return 0


static func get_upgrade_cost(tower: SimTower, branch: String) -> int:
	## Get cost for upgrading tower to specified branch
	if tower.tier == 1:
		return tower.data.upgrade_cost_t2
	elif tower.tier == 2:
		return tower.data.upgrade_cost_t3
	return 0


static func get_sell_value(tower: SimTower) -> int:
	return tower.total_cost * SELL_RATE / 100


static func can_afford_tower(tower_id: String, game_state: GameState) -> bool:
	return game_state.gold >= get_tower_cost(tower_id, game_state)


static func can_afford_wall(game_state: GameState) -> bool:
	return game_state.gold >= WALL_COST


static func can_afford_upgrade(tower: SimTower, branch: String, game_state: GameState) -> bool:
	return game_state.gold >= get_upgrade_cost(tower, branch)
