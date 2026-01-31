class_name TickProcessor
extends RefCounted

## Main game tick processor
## Runs the simulation at discrete time steps

const TICK_MS := 100  # 0.1 seconds per tick

var game_state: GameState


func _init(p_game_state: GameState) -> void:
	game_state = p_game_state


func process_tick() -> TickResult:
	## Process one tick of game time (100ms)
	## Returns result indicating game state

	# Check for game over conditions first
	if game_state.is_game_over():
		return TickResult.GAME_OVER_LOSS

	if game_state.is_victory():
		return TickResult.GAME_OVER_WIN

	# If wave not in progress, nothing to do
	if not game_state.wave_in_progress:
		return TickResult.WAITING

	# 1. Process enemy spawns
	game_state.process_spawns(TICK_MS)

	# 2. Move enemies
	for enemy in game_state.enemies:
		enemy.move(TICK_MS)

	# 2.5. Process wall breaker attacks
	Combat.process_wall_breaker_attacks(game_state, TICK_MS)

	# 3. Process status effects (DOTs, slow decay, etc.)
	Combat.process_status_effects(game_state, TICK_MS)

	# 3.3 Process healer effects
	Combat.process_healer_effects(game_state, TICK_MS)

	# 3.4 Process boss abilities
	Combat.process_boss_abilities(game_state, TICK_MS)

	# 3.5 Process ground effects
	_process_ground_effects(TICK_MS)

	# 3.6 Process delayed damage
	_process_delayed_damage(TICK_MS)

	# 4. Tower attacks
	Combat.process_tower_attacks(game_state, TICK_MS)

	# 5. Remove dead enemies
	Combat.process_enemy_deaths(game_state)

	# 6. Handle enemies reaching shrine
	Combat.process_enemy_leaks(game_state)

	# 7. Check win/loss conditions
	if game_state.is_game_over():
		return TickResult.GAME_OVER_LOSS

	if game_state.is_wave_complete():
		game_state.complete_wave()
		return TickResult.WAVE_COMPLETE

	return TickResult.ONGOING


func run_wave(wave_number: int) -> WaveResult:
	## Runs a complete wave, returns result

	if not game_state.start_wave(wave_number):
		return WaveResult.new(false, 0, 0, 0)

	var ticks := 0
	var max_ticks := 10000  # Safety limit (1000 seconds)

	while ticks < max_ticks:
		var result := process_tick()
		ticks += 1

		match result:
			TickResult.WAVE_COMPLETE:
				return WaveResult.new(true, ticks, game_state.shrine.hp, game_state.gold)
			TickResult.GAME_OVER_LOSS:
				return WaveResult.new(false, ticks, game_state.shrine.hp, game_state.gold)
			TickResult.GAME_OVER_WIN:
				return WaveResult.new(true, ticks, game_state.shrine.hp, game_state.gold)

	# Timeout - treat as loss
	push_warning("Wave %d timed out after %d ticks" % [wave_number, max_ticks])
	return WaveResult.new(false, ticks, game_state.shrine.hp, game_state.gold)


func run_all_waves() -> GameResult:
	## Runs all waves until win or loss
	var result := GameResult.new()
	result.start_time = Time.get_ticks_msec()

	var total_waves := game_state.wave_data.get_total_waves()

	for wave_num in range(1, total_waves + 1):
		var wave_result := run_wave(wave_num)
		result.wave_results.append(wave_result)

		if not wave_result.success:
			result.won = false
			result.final_wave = wave_num
			break

		result.final_wave = wave_num

	if result.final_wave >= total_waves and game_state.shrine.hp > 0:
		result.won = true

	result.end_time = Time.get_ticks_msec()
	result.final_shrine_hp = game_state.shrine.hp
	result.final_gold = game_state.gold
	result.total_gold_earned = game_state.total_gold_earned
	result.total_gold_spent = game_state.total_gold_spent
	result.enemies_killed = game_state.enemies_killed
	result.enemies_leaked = game_state.enemies_leaked
	result.total_damage_dealt = game_state.total_damage_dealt

	# Collect tower stats
	for tower in game_state.towers:
		result.tower_stats[tower.id] = {
			"damage": tower.total_damage_dealt, "kills": tower.kills, "shots": tower.shots_fired
		}

	return result


## Result enums and classes

enum TickResult {
	ONGOING,
	WAITING,
	WAVE_COMPLETE,
	GAME_OVER_WIN,
	GAME_OVER_LOSS,
}


class WaveResult:
	var success: bool
	var ticks: int
	var shrine_hp: int
	var gold: int

	func _init(p_success: bool, p_ticks: int, p_shrine_hp: int, p_gold: int) -> void:
		success = p_success
		ticks = p_ticks
		shrine_hp = p_shrine_hp
		gold = p_gold


class GameResult:
	var won: bool = false
	var final_wave: int = 0
	var final_shrine_hp: int = 0
	var final_gold: int = 0
	var start_time: int = 0
	var end_time: int = 0
	var total_gold_earned: int = 0
	var total_gold_spent: int = 0
	var enemies_killed: int = 0
	var enemies_leaked: int = 0
	var total_damage_dealt: int = 0  # x1000
	var wave_results: Array[WaveResult] = []
	var tower_stats: Dictionary = {}  # tower_id -> {damage, kills, shots}

	func get_duration_ms() -> int:
		return end_time - start_time

	func to_dict() -> Dictionary:
		return {
			"won": won,
			"final_wave": final_wave,
			"final_shrine_hp": final_shrine_hp,
			"final_gold": final_gold,
			"duration_ms": get_duration_ms(),
			"total_gold_earned": total_gold_earned,
			"total_gold_spent": total_gold_spent,
			"enemies_killed": enemies_killed,
			"enemies_leaked": enemies_leaked,
			"total_damage_dealt": total_damage_dealt,
			"tower_stats": tower_stats,
		}


func _process_ground_effects(delta_ms: int) -> void:
	## Process all ground effects and remove expired ones
	var expired: Array[int] = []

	for i in range(game_state.ground_effects.size()):
		var effect = game_state.ground_effects[i]
		var damage: int = effect.process(delta_ms, game_state.enemies)
		game_state.total_damage_dealt += damage

		if effect.is_expired():
			expired.push_front(i)

	for idx in expired:
		game_state.ground_effects.remove_at(idx)


func _process_delayed_damage(delta_ms: int) -> void:
	## Process delayed damage queue (barrage, etc)
	var triggered: Array[int] = []

	for i in range(game_state.delayed_damage_queue.size()):
		var entry: Dictionary = game_state.delayed_damage_queue[i]
		entry.time_ms -= delta_ms

		if entry.time_ms <= 0:
			triggered.push_front(i)
			_apply_delayed_damage(entry)

	for idx in triggered:
		game_state.delayed_damage_queue.remove_at(idx)


func _apply_delayed_damage(entry: Dictionary) -> void:
	## Apply AOE damage at position
	var pos: Vector2 = entry.position
	var damage: int = entry.damage
	var radius: float = entry.aoe_radius

	if radius <= 0:
		return

	var radius_sq := radius * radius

	for enemy in game_state.enemies:
		var dx := enemy.grid_pos.x - pos.x
		var dy := enemy.grid_pos.y - pos.y
		var dist_sq := dx * dx + dy * dy

		if dist_sq <= radius_sq:
			enemy.take_damage(damage)
			game_state.total_damage_dealt += damage
