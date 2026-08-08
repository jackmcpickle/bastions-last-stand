class_name Combat
extends RefCounted

## Combat system - handles damage calculation and application

const SimGroundEffectClass = preload("res://simulation/entities/sim_ground_effect.gd")


static func process_support_auras(game_state: GameState, delta_ms: int) -> void:
	## Apply support tower auras, marks, and EMP effects for this tick

	for tower in game_state.towers:
		tower.clear_aura_buffs()
	for enemy in game_state.enemies:
		enemy.clear_mark_state()

	for support in game_state.towers:
		if not support.is_support_tower():
			continue
		_apply_support_aura(support, game_state, delta_ms)

	_apply_tower_regen(game_state, delta_ms)


static func _apply_support_aura(support: SimTower, game_state: GameState, delta_ms: int) -> void:
	var special := support.special
	var support_center := support.get_center()
	var range_sq := float(support.range_tiles * support.range_tiles)

	# Buff nearby ally towers (not self)
	for tower in game_state.towers:
		if tower == support:
			continue
		if not _is_in_aura_range(support_center, tower.get_center(), range_sq):
			continue

		var dmg_buff: int = special.get("aura_damage_buff", 0)
		if dmg_buff > tower.aura_damage_buff:
			tower.aura_damage_buff = dmg_buff

		var spd_buff: int = special.get("aura_speed_buff", 0)
		if spd_buff > tower.aura_speed_buff:
			tower.aura_speed_buff = spd_buff

		var rng_buff: int = special.get("aura_range_buff", 0)
		if rng_buff > tower.aura_bonus_range:
			tower.aura_bonus_range = rng_buff

		var regen: int = special.get("aura_tower_regen", 0)
		if regen > tower.aura_regen_per_sec:
			tower.aura_regen_per_sec = regen

	# Enemy mark / EMP / reveal
	for enemy in game_state.enemies:
		if enemy.is_dead():
			continue
		if not _is_in_aura_range(support_center, enemy.grid_pos, range_sq):
			continue

		if special.get("mark_enemies", false):
			enemy.is_marked = true
			var amp: int = special.get("mark_damage_amp", 0)
			if amp > enemy.mark_damage_amp:
				enemy.mark_damage_amp = amp
			var crit: int = special.get("mark_crit_chance", 0)
			if crit > enemy.mark_crit_chance:
				enemy.mark_crit_chance = crit

		if special.get("reveal_stealth", false) and enemy.is_stealth:
			enemy.is_revealed = true

		if special.has("emp_slow"):
			enemy.apply_slow(special.emp_slow, maxi(delta_ms * 2, 200))

		if special.get("emp_disable_shields", false):
			enemy.shield_hp = 0


static func _apply_tower_regen(game_state: GameState, delta_ms: int) -> void:
	## Heal towers that have aura regen (accumulates fractional HP/s)
	for tower in game_state.towers:
		if tower.aura_regen_per_sec <= 0:
			tower.regen_accum_ms = 0
			continue
		if tower.hp >= tower.max_hp:
			tower.regen_accum_ms = 0
			continue
		# Accumulate rate*ms; every 1000 units = 1 HP
		tower.regen_accum_ms += tower.aura_regen_per_sec * delta_ms
		var heal := tower.regen_accum_ms / 1000
		if heal <= 0:
			continue
		tower.regen_accum_ms -= heal * 1000
		tower.hp = mini(tower.hp + heal, tower.max_hp)


static func _is_in_aura_range(center: Vector2, target: Vector2, range_sq: float) -> bool:
	var dx := center.x - target.x
	var dy := center.y - target.y
	return dx * dx + dy * dy <= range_sq


static func process_tower_attacks(game_state: GameState, delta_ms: int) -> void:
	## Process all tower attacks for this tick

	for tower in game_state.towers:
		# Support towers are aura-only
		if tower.is_support_tower():
			tower.process_cooldown(delta_ms)
			continue

		# Update cooldown
		tower.process_cooldown(delta_ms)

		# Capacitor before beam — Arc Pylon→Capacitor may still have beam:true
		if tower.special.get("capacitor", false):
			_process_capacitor_tower(tower, game_state, delta_ms)
			continue

		# Handle beam mode towers
		if tower.special.has("beam"):
			_process_beam_tower(tower, game_state, delta_ms)
			continue

		if not tower.can_attack():
			continue

		# Find target
		var target := Targeting.find_target(
			tower.position, game_state.enemies, tower.get_effective_range(), tower.target_priority
		)

		if not target:
			continue

		# Perform attack
		var hit_enemies := tower.attack(target, game_state.enemies)

		# Handle pierce_line special (railgun)
		if tower.special.has("pierce_line") and tower.special.pierce_line:
			hit_enemies = _get_line_targets(tower, target, game_state.enemies)

		# Apply damage to each hit enemy
		for enemy in hit_enemies:
			var damage := _calculate_damage(tower, enemy, game_state.rng)
			enemy.take_damage(damage)
			tower.record_damage(damage)
			game_state.total_damage_dealt += damage

			# Apply special effects
			_apply_tower_effects(tower, enemy, game_state)

			# Emit signal
			game_state.tower_attacked.emit(tower, enemy, damage)

			# Check for kill (handle shatter)
			if enemy.is_dead():
				tower.record_kill()
				_handle_kill_effects(tower, enemy, game_state)

		# Handle barrage (schedule delayed damage)
		if tower.special.has("barrage") and tower.special.barrage:
			_schedule_barrage(tower, target.grid_pos, game_state)

		# Handle cluster (spawn sub-explosions)
		if tower.special.has("cluster"):
			_spawn_cluster(tower, target.grid_pos, game_state)

		# Handle ground_burn (hellfire)
		if tower.special.has("ground_burn") and tower.special.ground_burn:
			_spawn_ground_burn(tower, target.grid_pos, game_state)


static func _apply_tower_effects(tower: SimTower, enemy: SimEnemy, game_state: GameState) -> void:
	## Apply special effects from tower to enemy
	var special := tower.special
	var rng := game_state.rng

	# Slow effect
	if special.has("slow"):
		var slow_amount: int = special.slow
		var slow_duration: int = special.get("slow_duration_ms", 2000)
		enemy.apply_slow(slow_amount, slow_duration)

	# Burn effect (with optional stacking)
	if special.has("burn_dps"):
		var burn_dps: int = special.burn_dps
		var burn_duration: int = special.get("burn_duration_ms", 3000)
		var max_stacks: int = special.get("burn_stacks", 1)
		enemy.apply_burn(burn_dps, burn_duration, max_stacks)

	# Stun on hit (stun_ms)
	if special.has("stun_ms"):
		enemy.apply_stun(special.stun_ms)

	# Random stun effect (stun_chance)
	if special.has("stun_chance") and rng:
		var stun_chance: int = special.stun_chance  # x1000 (500 = 50%)
		var stun_duration: int = special.get("stun_duration_ms", 500)
		if rng.randi_range(0, 999) < stun_chance:
			enemy.apply_stun(stun_duration)

	# Freeze chance (2 second stun)
	if special.has("freeze_chance") and rng:
		var freeze_chance: int = special.freeze_chance  # x1000 (100 = 10%)
		if rng.randi_range(0, 999) < freeze_chance:
			enemy.apply_stun(2000)

	# Disable effect (prevents regen, abilities)
	if special.has("disable") and special.disable:
		enemy.is_disabled = true


static func _calculate_damage(tower: SimTower, enemy: SimEnemy, rng: RandomManager) -> int:
	## Calculate damage with all modifiers
	var special := tower.special
	var damage := tower.get_damage_for_target(enemy)

	# Support aura damage buff
	if tower.aura_damage_buff > 0:
		damage = damage * (1000 + tower.aura_damage_buff) / 1000

	# Marked enemy damage amp
	if enemy.is_marked and enemy.mark_damage_amp > 0:
		damage = damage * (1000 + enemy.mark_damage_amp) / 1000

	# Crit chance (tower crit or mark-provided crit)
	var crit_chance := 0
	if special.has("crit_chance"):
		crit_chance = special.crit_chance
	if enemy.is_marked and enemy.mark_crit_chance > crit_chance:
		crit_chance = enemy.mark_crit_chance
	if crit_chance > 0 and rng:
		if rng.randi_range(0, 999) < crit_chance:
			damage *= 2

	# Instakill threshold
	if special.has("instakill_threshold"):
		if enemy.hp <= special.instakill_threshold:
			return enemy.hp * 1000 + 1  # Deal enough damage to kill (hp is not x1000)

	# Slow damage amp (frostbite)
	if special.has("slow_damage_amp") and enemy.slow_amount > 0:
		damage = damage * (1000 + special.slow_damage_amp) / 1000

	# Breaker bonus (siege cannon)
	if special.has("breaker_bonus") and enemy.is_wall_breaker:
		damage = damage * (1000 + special.breaker_bonus) / 1000

	# Armor penetration
	if special.has("armor_pen"):
		# Reduce effective armor before damage calculation
		# armor_pen 500 = 50% armor ignored
		var armor_mult: int = 1000 - enemy.armor * (1000 - special.armor_pen) / 1000
		# Undo normal armor calculation and apply reduced armor
		var base_damage: int = damage * 1000 / (1000 - enemy.armor)
		damage = base_damage * armor_mult / 1000

	return damage


static func _process_beam_tower(tower: SimTower, game_state: GameState, delta_ms: int) -> void:
	## Handle continuous beam damage
	# Beam towers attack every tick (no cooldown)
	var target := Targeting.find_target(
		tower.position, game_state.enemies, tower.get_effective_range(), tower.target_priority
	)

	if not target:
		return

	# Calculate damage per tick (attack_speed_ms is treated as DPS multiplier for beams)
	# damage is DPS, delta_ms is tick time
	var tick_damage: int = tower.damage * delta_ms / 1000

	target.take_damage(tick_damage)
	tower.record_damage(tick_damage)
	game_state.total_damage_dealt += tick_damage

	# Apply effects
	_apply_tower_effects(tower, target, game_state)

	if target.is_dead():
		tower.record_kill()


static func _process_capacitor_tower(tower: SimTower, game_state: GameState, delta_ms: int) -> void:
	## Charge while enemies are in range, then discharge AOE from tower center
	if tower.frozen_ms > 0:
		return

	var in_range := Targeting.get_enemies_in_range(
		tower.position, game_state.enemies, tower.range_tiles
	)
	in_range = in_range.filter(func(e): return e.is_targetable())
	if in_range.is_empty():
		return

	tower.capacitor_charge_ms += delta_ms
	var charge_needed: int = tower.special.get("charge_ms", tower.attack_speed_ms)
	if charge_needed <= 0:
		charge_needed = tower.attack_speed_ms
	if tower.capacitor_charge_ms < charge_needed:
		return

	# Fully charged — discharge
	tower.capacitor_charge_ms = 0
	tower.shots_fired += 1

	var radius := float(tower.aoe_radius) / 1000.0
	if radius <= 0.0:
		radius = float(tower.range_tiles)
	var hit_enemies := Targeting.get_enemies_in_aoe(tower.get_center(), game_state.enemies, radius)

	for enemy in hit_enemies:
		if not enemy.is_targetable():
			continue
		var damage := _calculate_damage(tower, enemy, game_state.rng)
		enemy.take_damage(damage)
		tower.record_damage(damage)
		game_state.total_damage_dealt += damage
		_apply_tower_effects(tower, enemy, game_state)
		game_state.tower_attacked.emit(tower, enemy, damage)
		if enemy.is_dead():
			tower.record_kill()
			_handle_kill_effects(tower, enemy, game_state)


static func _get_line_targets(
	tower: SimTower, primary_target: SimEnemy, all_enemies: Array[SimEnemy]
) -> Array[SimEnemy]:
	## Get all enemies in a line from tower through target (for railgun)
	var result: Array[SimEnemy] = []
	var tower_pos := tower.get_center()
	var target_pos := primary_target.grid_pos

	# Direction vector
	var dir := (target_pos - tower_pos).normalized()
	var line_width := 0.5  # Half-tile width

	# Check all enemies
	for enemy in all_enemies:
		if not enemy.is_targetable():
			continue

		# Project enemy position onto line
		var to_enemy := enemy.grid_pos - tower_pos
		var proj_length := to_enemy.dot(dir)

		# Must be in front of tower
		if proj_length < 0:
			continue

		# Check perpendicular distance to line
		var proj_point := tower_pos + dir * proj_length
		var perp_dist := (enemy.grid_pos - proj_point).length()

		if perp_dist <= line_width:
			result.append(enemy)

	# Sort by distance from tower
	result.sort_custom(
		func(a: SimEnemy, b: SimEnemy) -> bool:
			var da := (a.grid_pos - tower_pos).length_squared()
			var db := (b.grid_pos - tower_pos).length_squared()
			return da < db
	)

	return result


static func _schedule_barrage(tower: SimTower, target_pos: Vector2, game_state: GameState) -> void:
	## Schedule delayed damage for howitzer barrage
	var damage: int = tower.damage
	var aoe_radius: float = float(tower.aoe_radius) / 1000.0

	# Schedule 4 hits over 3 seconds
	for i in range(4):
		var delay_ms := (i + 1) * 750  # 750, 1500, 2250, 3000ms
		# Add some randomness to position
		var offset := Vector2(
			game_state.rng.randf_range(-0.5, 0.5), game_state.rng.randf_range(-0.5, 0.5)
		)
		game_state.add_delayed_damage(delay_ms, target_pos + offset, damage, aoe_radius)


static func _spawn_cluster(tower: SimTower, target_pos: Vector2, game_state: GameState) -> void:
	## Spawn cluster sub-explosions
	var cluster_count: int = tower.special.cluster
	var damage: int = tower.damage
	var sub_radius: float = float(tower.aoe_radius) / 1000.0

	# Spawn smaller explosions around impact point
	for i in range(cluster_count):
		var angle := float(i) / float(cluster_count) * TAU
		var offset := Vector2(cos(angle), sin(angle)) * 1.0  # 1 tile away
		var sub_pos := target_pos + offset

		# Apply damage immediately to enemies in sub-explosion
		var radius_sq := sub_radius * sub_radius
		for enemy in game_state.enemies:
			var dx := enemy.grid_pos.x - sub_pos.x
			var dy := enemy.grid_pos.y - sub_pos.y
			var dist_sq := dx * dx + dy * dy
			if dist_sq <= radius_sq:
				enemy.take_damage(damage)
				game_state.total_damage_dealt += damage


static func _spawn_ground_burn(tower: SimTower, target_pos: Vector2, game_state: GameState) -> void:
	## Create ground burn effect (hellfire)
	var burn_dps: int = tower.special.get("burn_dps", 10000)
	var burn_duration: int = tower.special.get("burn_duration_ms", 3000)
	var radius := 1.5  # Tiles

	var effect = SimGroundEffectClass.new(target_pos, radius, burn_dps, burn_duration)
	effect.source_tower_id = tower.id
	game_state.add_ground_effect(effect)


static func _handle_kill_effects(tower: SimTower, enemy: SimEnemy, game_state: GameState) -> void:
	## Handle on-kill effects like shatter
	var special := tower.special

	# Shatter (frost): on kill, deal AOE damage
	if special.has("shatter_damage"):
		var shatter_damage: int = special.shatter_damage
		var shatter_radius := 1.5  # Tiles
		var radius_sq := shatter_radius * shatter_radius

		for other_enemy in game_state.enemies:
			if other_enemy == enemy:
				continue
			var dx := other_enemy.grid_pos.x - enemy.grid_pos.x
			var dy := other_enemy.grid_pos.y - enemy.grid_pos.y
			var dist_sq := dx * dx + dy * dy
			if dist_sq <= radius_sq:
				other_enemy.take_damage(shatter_damage)
				game_state.total_damage_dealt += shatter_damage


static func process_enemy_deaths(game_state: GameState) -> void:
	## Remove dead enemies and award gold
	var to_remove: Array[SimEnemy] = []

	for enemy in game_state.enemies:
		if enemy.is_dead():
			to_remove.append(enemy)

	for enemy in to_remove:
		# Handle splitter spawning before removal
		if enemy.splits_into != "" and enemy.split_count > 0:
			for i in range(enemy.split_count):
				var offset := Vector2(
					game_state.rng.randf_range(-0.3, 0.3), game_state.rng.randf_range(-0.3, 0.3)
				)
				game_state.spawn_enemy_at_position(enemy.splits_into, enemy.grid_pos + offset)

		# Track for necromancer resurrection
		game_state.track_dead_enemy(enemy)

		game_state.remove_enemy(enemy, true)


static func process_enemy_leaks(game_state: GameState) -> void:
	## Handle enemies reaching shrine
	var to_remove: Array[SimEnemy] = []

	for enemy in game_state.enemies:
		if enemy.has_reached_shrine():
			to_remove.append(enemy)

	for enemy in to_remove:
		# Damage shrine based on config
		var base_damage := 1
		if game_state.balance_config:
			base_damage = game_state.balance_config.enemy_shrine_damage

		# Scale damage for stronger enemies
		var damage := base_damage
		if enemy.max_hp > 100:
			damage = base_damage + enemy.max_hp / 50

		game_state.damage_shrine(damage)
		game_state.enemy_reached_shrine.emit(enemy, damage)
		game_state.remove_enemy(enemy, false)


static func process_status_effects(game_state: GameState, delta_ms: int) -> void:
	## Process DOTs and status effect decay
	for enemy in game_state.enemies:
		enemy.process_status_effects(delta_ms)


static func process_healer_effects(game_state: GameState, delta_ms: int) -> void:
	## Healers heal nearby allies each tick
	for enemy in game_state.enemies:
		if enemy.healer_range <= 0 or enemy.heal_per_sec <= 0:
			continue
		if enemy.is_disabled or enemy.is_stunned:
			continue

		var heal_amount := enemy.heal_per_sec * delta_ms / 1000 / 1000  # x1000 to actual HP
		var range_sq := enemy.healer_range * enemy.healer_range

		for ally in game_state.enemies:
			if ally == enemy:
				continue
			if ally.hp >= ally.max_hp:
				continue

			var dx := ally.grid_pos.x - enemy.grid_pos.x
			var dy := ally.grid_pos.y - enemy.grid_pos.y
			var dist_sq := dx * dx + dy * dy

			if dist_sq <= range_sq:
				ally.hp = mini(ally.hp + heal_amount, ally.max_hp)


static func process_boss_abilities(game_state: GameState, delta_ms: int) -> void:
	## Process boss-specific abilities
	for enemy in game_state.enemies:
		if not enemy.is_boss:
			continue
		if enemy.is_stunned:
			continue

		# Swarm Queen spawning
		if enemy.spawns_enemy != "" and enemy.spawns_remaining > 0:
			enemy.spawn_timer_ms -= delta_ms
			if enemy.spawn_timer_ms <= 0:
				enemy.spawn_timer_ms = enemy.spawn_interval_ms
				enemy.spawns_remaining -= 1
				game_state.spawn_enemy_at_position(enemy.spawns_enemy, enemy.grid_pos)

		# Phase Phantom teleport
		if enemy.teleport_interval_ms > 0:
			enemy.teleport_timer_ms -= delta_ms
			if enemy.teleport_timer_ms <= 0:
				enemy.teleport_timer_ms = enemy.teleport_interval_ms
				_teleport_enemy_forward(enemy, game_state)
				# Enter stealth after teleport
				if enemy.stealth_delay_ms > 0:
					enemy.is_stealth = true
					enemy.is_revealed = false

		# Frost Wyrm tower freeze
		if enemy.freeze_towers_range > 0:
			enemy.freeze_timer_ms -= delta_ms
			if enemy.freeze_timer_ms <= 0:
				enemy.freeze_timer_ms = enemy.freeze_interval_ms
				_freeze_nearby_towers(enemy, game_state)

		# Necromancer resurrect
		if enemy.resurrect_range > 0:
			enemy.resurrect_timer_ms -= delta_ms
			if enemy.resurrect_timer_ms <= 0:
				enemy.resurrect_timer_ms = enemy.resurrect_interval_ms
				_resurrect_nearby_dead(enemy, game_state)


static func _teleport_enemy_forward(enemy: SimEnemy, game_state: GameState) -> void:
	## Teleport enemy forward along its path
	if enemy.path.is_empty():
		return

	# Jump forward 3-5 tiles along path
	var jump_distance := 4
	var new_index := mini(enemy.path_index + jump_distance, enemy.path.size() - 1)

	if new_index > enemy.path_index:
		enemy.path_index = new_index
		enemy.grid_pos = Vector2(enemy.path[new_index])


static func _freeze_nearby_towers(enemy: SimEnemy, game_state: GameState) -> void:
	## Frost Wyrm freezes nearby towers
	var range_sq := enemy.freeze_towers_range * enemy.freeze_towers_range

	for tower in game_state.towers:
		var tower_center := tower.get_center()
		var dx := tower_center.x - enemy.grid_pos.x
		var dy := tower_center.y - enemy.grid_pos.y
		var dist_sq := dx * dx + dy * dy

		if dist_sq <= range_sq:
			tower.frozen_ms = enemy.freeze_duration_ms


static func _resurrect_nearby_dead(enemy: SimEnemy, game_state: GameState) -> void:
	## Necromancer resurrects dead enemies
	if game_state.dead_enemies.is_empty():
		return

	var range_sq := enemy.resurrect_range * enemy.resurrect_range
	var resurrected_idx := -1

	for i in range(game_state.dead_enemies.size()):
		var dead_info: Dictionary = game_state.dead_enemies[i]
		var dead_pos: Vector2 = dead_info.position
		var dx: float = dead_pos.x - enemy.grid_pos.x
		var dy: float = dead_pos.y - enemy.grid_pos.y
		var dist_sq: float = dx * dx + dy * dy

		if dist_sq <= range_sq:
			# Resurrect this enemy
			var new_enemy := game_state.spawn_enemy_at_position(dead_info.id, dead_pos)
			if new_enemy:
				new_enemy.hp = new_enemy.max_hp * enemy.resurrect_hp_percent / 100
			resurrected_idx = i
			break

	if resurrected_idx >= 0:
		game_state.dead_enemies.remove_at(resurrected_idx)


static func process_siege_attacks(game_state: GameState, _delta_ms: int) -> void:
	## Ground enemies with no path attack nearest wall or tower
	var walls_to_remove: Array[SimWall] = []
	var towers_to_remove: Array[SimTower] = []

	for enemy in game_state.enemies:
		if enemy.is_flying or enemy.is_wall_breaker:
			continue
		if not enemy.path.is_empty():
			continue

		var wall := _find_nearest_wall(enemy, game_state.walls)
		var tower := _find_nearest_tower(enemy, game_state.towers)
		if not wall and not tower:
			continue

		var wall_damage: int = enemy.data.special.get("wall_damage", 10)
		var prefer_tower := false
		if wall and tower:
			prefer_tower = _siege_tower_dist_sq(enemy, tower) < _siege_wall_dist_sq(enemy, wall)
		elif tower:
			prefer_tower = true

		if prefer_tower:
			tower.take_damage(wall_damage)
			if tower.is_destroyed() and tower not in towers_to_remove:
				towers_to_remove.append(tower)
		else:
			wall.take_damage(wall_damage)
			if wall.is_destroyed() and wall not in walls_to_remove:
				walls_to_remove.append(wall)

	for wall in walls_to_remove:
		game_state.pathfinding.set_blocked(wall.position, false)
		game_state.walls.erase(wall)
		game_state.wall_destroyed.emit(wall)

	for tower in towers_to_remove:
		game_state.destroy_tower(tower)

	if not walls_to_remove.is_empty() and towers_to_remove.is_empty():
		game_state.repath_ground_enemies()


static func _find_nearest_wall(enemy: SimEnemy, walls: Array[SimWall]) -> SimWall:
	## Returns nearest wall to enemy, or null if none
	var best: SimWall = null
	var best_dist_sq := 999999.0

	for wall in walls:
		var dist_sq := _siege_wall_dist_sq(enemy, wall)
		if dist_sq < best_dist_sq:
			best_dist_sq = dist_sq
			best = wall

	return best


static func _find_nearest_tower(enemy: SimEnemy, towers: Array[SimTower]) -> SimTower:
	## Returns nearest tower to enemy (by center), or null if none
	var best: SimTower = null
	var best_dist_sq := 999999.0

	for tower in towers:
		var dist_sq := _siege_tower_dist_sq(enemy, tower)
		if dist_sq < best_dist_sq:
			best_dist_sq = dist_sq
			best = tower

	return best


static func _siege_wall_dist_sq(enemy: SimEnemy, wall: SimWall) -> float:
	var pos := enemy.grid_pos
	var dx := float(wall.position.x) - pos.x
	var dy := float(wall.position.y) - pos.y
	return dx * dx + dy * dy


static func _siege_tower_dist_sq(enemy: SimEnemy, tower: SimTower) -> float:
	var pos := enemy.grid_pos
	var center := tower.get_center()
	var dx := center.x - pos.x
	var dy := center.y - pos.y
	return dx * dx + dy * dy


static func process_wall_breaker_attacks(game_state: GameState, delta_ms: int) -> void:
	## Wall breakers attack adjacent walls
	var walls_to_remove: Array[SimWall] = []

	for enemy in game_state.enemies:
		if not enemy.is_wall_breaker:
			continue

		# Find adjacent wall
		var wall := _find_adjacent_wall(enemy, game_state.walls)
		if not wall:
			continue

		# Attack wall
		var wall_damage: int = enemy.data.special.get("wall_damage", 10)
		wall.take_damage(wall_damage)

		if wall.is_destroyed() and wall not in walls_to_remove:
			walls_to_remove.append(wall)

	# Remove destroyed walls and update pathfinding
	for wall in walls_to_remove:
		game_state.pathfinding.set_blocked(wall.position, false)
		game_state.walls.erase(wall)
		game_state.wall_destroyed.emit(wall)

		game_state.repath_ground_enemies()


static func _find_adjacent_wall(enemy: SimEnemy, walls: Array[SimWall]) -> SimWall:
	## Returns wall adjacent to enemy position (within 1 tile)
	var pos := enemy.get_current_tile()

	for wall in walls:
		var dx := absi(wall.position.x - pos.x)
		var dy := absi(wall.position.y - pos.y)
		if dx <= 1 and dy <= 1:
			return wall

	return null
