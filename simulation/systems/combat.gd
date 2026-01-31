class_name Combat
extends RefCounted

## Combat system - handles damage calculation and application


static func process_tower_attacks(game_state: GameState, delta_ms: int) -> void:
	## Process all tower attacks for this tick
	
	for tower in game_state.towers:
		# Update cooldown
		tower.process_cooldown(delta_ms)
		
		if not tower.can_attack():
			continue
		
		# Find target
		var target := Targeting.find_target(
			tower.position,
			game_state.enemies,
			tower.range_tiles,
			tower.target_priority
		)
		
		if not target:
			continue
		
		# Perform attack
		var hit_enemies := tower.attack(target, game_state.enemies)
		
		# Apply damage to each hit enemy
		for enemy in hit_enemies:
			var damage := tower.get_damage_for_target(enemy)
			enemy.take_damage(damage)
			tower.record_damage(damage)
			game_state.total_damage_dealt += damage
			
			# Apply special effects
			_apply_tower_effects(tower, enemy)
			
			# Emit signal
			game_state.tower_attacked.emit(tower, enemy, damage)
			
			# Check for kill
			if enemy.is_dead():
				tower.record_kill()


static func _apply_tower_effects(tower: SimTower, enemy: SimEnemy) -> void:
	## Apply special effects from tower to enemy
	var special := tower.special
	
	# Slow effect
	if special.has("slow"):
		var slow_amount: int = special.slow
		var slow_duration: int = special.get("slow_duration_ms", 2000)
		enemy.apply_slow(slow_amount, slow_duration)
	
	# Burn effect
	if special.has("burn_dps"):
		var burn_dps: int = special.burn_dps
		var burn_duration: int = special.get("burn_duration_ms", 3000)
		enemy.apply_burn(burn_dps, burn_duration)
	
	# Stun effect
	if special.has("stun_chance"):
		# TODO: Need RNG access for stun chance
		pass


static func process_enemy_deaths(game_state: GameState) -> void:
	## Remove dead enemies and award gold
	var to_remove: Array[SimEnemy] = []
	
	for enemy in game_state.enemies:
		if enemy.is_dead():
			to_remove.append(enemy)
	
	for enemy in to_remove:
		game_state.remove_enemy(enemy, true)


static func process_enemy_leaks(game_state: GameState) -> void:
	## Handle enemies reaching shrine
	var to_remove: Array[SimEnemy] = []
	
	for enemy in game_state.enemies:
		if enemy.has_reached_shrine():
			to_remove.append(enemy)
	
	for enemy in to_remove:
		# Damage shrine - enemies deal damage equal to their remaining HP percentage
		# Standard enemies deal 1 damage, stronger enemies deal more
		var damage := 1
		if enemy.max_hp > 100:
			damage = enemy.max_hp / 50  # Scale with HP
		
		game_state.damage_shrine(damage)
		game_state.enemy_reached_shrine.emit(enemy, damage)
		game_state.remove_enemy(enemy, false)


static func process_status_effects(game_state: GameState, delta_ms: int) -> void:
	## Process DOTs and status effect decay
	for enemy in game_state.enemies:
		enemy.process_status_effects(delta_ms)
