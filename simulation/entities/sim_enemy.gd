class_name SimEnemy
extends RefCounted

## Enemy entity for headless simulation

var id: String
var data: EnemyData

## Position (grid coordinates with sub-tile precision)
var grid_pos: Vector2
var spawn_point: Vector2i

## Stats (copied from data, can be modified by effects)
var hp: int
var max_hp: int
var speed: int  # x1000: tiles per second
var armor: int  # x1000: damage reduction
var gold_value: int

## Movement
var path: Array[Vector2i] = []
var path_index: int = 0
var path_progress: float = 0.0  # 0-1 along total path

## Status effects
var slow_amount: int = 0  # x1000: current slow %
var slow_duration_ms: int = 0
var burn_dps: int = 0  # x1000 (legacy single burn)
var burn_duration_ms: int = 0
var burn_stacks: Array = []  # [{dps: int, remaining_ms: int}]
var is_stunned: bool = false
var stun_duration_ms: int = 0
var is_disabled: bool = false  # Disruptor effect

## Tracking
var total_damage_taken: int = 0  # x1000
var distance_traveled: float = 0.0

## Special flags (from data)
var is_flying: bool = false
var is_stealth: bool = false
var is_wall_breaker: bool = false
var is_revealed: bool = false  # Stealth broken
var regen_per_sec: int = 0  # x1000: HP regen per second


func initialize(p_data: EnemyData, p_spawn_point: Vector2i, pathfinding: SimPathfinding) -> void:
	data = p_data
	id = data.id
	spawn_point = p_spawn_point
	grid_pos = Vector2(p_spawn_point)
	
	# Copy base stats
	hp = data.hp
	max_hp = data.hp
	speed = data.speed
	armor = data.armor
	gold_value = data.gold_value
	
	# Parse special flags
	is_flying = data.special.get("flying", false)
	is_stealth = data.special.get("stealth", false)
	is_wall_breaker = data.special.get("wall_breaker", false)
	regen_per_sec = data.special.get("regen_per_sec", 0)
	
	# Get path (flyers don't need one - they go direct)
	if not is_flying and not is_wall_breaker:
		path = pathfinding.get_path(spawn_point)
	else:
		# Direct path to shrine
		path = [spawn_point, pathfinding.get_shrine_position()]
	
	path_index = 0
	if not path.is_empty():
		path_progress = 0.0


func move(delta_ms: int) -> void:
	if is_stunned:
		return
	
	if path.is_empty() or path_index >= path.size():
		return
	
	# Calculate effective speed (with slow)
	var effective_speed := speed
	if slow_amount > 0:
		effective_speed = speed * (1000 - slow_amount) / 1000
	
	# Convert to distance per tick
	# speed is x1000 tiles/sec, delta_ms is milliseconds
	var move_distance := float(effective_speed) / 1000.0 * float(delta_ms) / 1000.0
	
	while move_distance > 0 and path_index < path.size():
		var target := Vector2(path[path_index])
		var to_target := target - grid_pos
		var dist_to_target := to_target.length()
		
		if dist_to_target <= move_distance:
			# Reached waypoint
			grid_pos = target
			move_distance -= dist_to_target
			distance_traveled += dist_to_target
			path_index += 1
		else:
			# Move toward waypoint
			var direction := to_target.normalized()
			grid_pos += direction * move_distance
			distance_traveled += move_distance
			move_distance = 0
	
	# Update progress
	if not path.is_empty():
		path_progress = float(path_index) / float(path.size())


func process_status_effects(delta_ms: int) -> int:
	## Process DOTs and status effects, returns damage taken this tick (x1000)
	var damage_taken := 0

	# Legacy single burn damage
	if burn_duration_ms > 0:
		damage_taken += burn_dps * delta_ms / 1000
		burn_duration_ms -= delta_ms
		if burn_duration_ms <= 0:
			burn_dps = 0
			burn_duration_ms = 0

	# Stacking burn damage
	var expired_stacks: Array[int] = []
	for i in range(burn_stacks.size()):
		var stack: Dictionary = burn_stacks[i]
		damage_taken += stack.dps * delta_ms / 1000
		stack.remaining_ms -= delta_ms
		if stack.remaining_ms <= 0:
			expired_stacks.push_front(i)  # Add to front so we remove from back
	for idx in expired_stacks:
		burn_stacks.remove_at(idx)

	# Slow decay
	if slow_duration_ms > 0:
		slow_duration_ms -= delta_ms
		if slow_duration_ms <= 0:
			slow_amount = 0

	# Stun decay
	if stun_duration_ms > 0:
		stun_duration_ms -= delta_ms
		if stun_duration_ms <= 0:
			is_stunned = false

	# HP regen (disabled enemies can't regen)
	if regen_per_sec > 0 and hp < max_hp and not is_disabled:
		var regen := regen_per_sec * delta_ms / 1000 / 1000  # Convert from x1000 to actual HP
		hp = mini(hp + regen, max_hp)

	# Apply DOT damage
	if damage_taken > 0:
		take_damage(damage_taken)

	return damage_taken


func take_damage(amount: int) -> void:
	## amount is x1000 fixed-point
	# Apply armor
	var effective_damage := amount * (1000 - armor) / 1000
	total_damage_taken += effective_damage
	
	# Convert to actual HP (HP is not fixed-point)
	var hp_damage := effective_damage / 1000
	hp -= hp_damage
	
	# Reveal stealth on damage
	if is_stealth and not is_revealed:
		is_revealed = true


func apply_slow(amount: int, duration_ms: int) -> void:
	## amount is x1000 (300 = 30% slow)
	# Take the stronger slow
	if amount > slow_amount:
		slow_amount = amount
		slow_duration_ms = duration_ms
	elif amount == slow_amount and duration_ms > slow_duration_ms:
		slow_duration_ms = duration_ms


func apply_burn(dps: int, duration_ms: int, max_stacks: int = 1) -> void:
	## dps is x1000
	## max_stacks: how many burn instances can stack (1 = no stacking)
	if max_stacks <= 1:
		# Legacy behavior - take stronger
		if dps > burn_dps:
			burn_dps = dps
			burn_duration_ms = duration_ms
		elif dps == burn_dps and duration_ms > burn_duration_ms:
			burn_duration_ms = duration_ms
	else:
		# Stacking burns
		# Check if we have room for more stacks
		if burn_stacks.size() < max_stacks:
			burn_stacks.append({"dps": dps, "remaining_ms": duration_ms})
		else:
			# Refresh weakest/shortest stack
			var weakest_idx := 0
			var weakest_value: int = burn_stacks[0].dps * burn_stacks[0].remaining_ms
			for i in range(1, burn_stacks.size()):
				var val: int = burn_stacks[i].dps * burn_stacks[i].remaining_ms
				if val < weakest_value:
					weakest_value = val
					weakest_idx = i
			burn_stacks[weakest_idx] = {"dps": dps, "remaining_ms": duration_ms}


func apply_stun(duration_ms: int) -> void:
	is_stunned = true
	if duration_ms > stun_duration_ms:
		stun_duration_ms = duration_ms


func is_dead() -> bool:
	return hp <= 0


func has_reached_shrine() -> bool:
	return path_index >= path.size()


func get_current_tile() -> Vector2i:
	return Vector2i(roundi(grid_pos.x), roundi(grid_pos.y))


func is_targetable() -> bool:
	## Can towers target this enemy?
	if is_stealth and not is_revealed:
		return false
	return true
