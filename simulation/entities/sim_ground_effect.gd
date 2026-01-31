class_name SimGroundEffect
extends RefCounted

## Ground effect entity for persistent area damage (hellfire, etc)

var position: Vector2
var radius: float  # tiles
var damage_per_tick: int  # x1000
var remaining_ms: int
var tick_interval_ms: int = 500
var next_tick_ms: int = 0
var source_tower_id: String = ""


func _init(
	p_position: Vector2 = Vector2.ZERO,
	p_radius: float = 1.0,
	p_dps: int = 0,
	p_duration_ms: int = 0
) -> void:
	position = p_position
	radius = p_radius
	damage_per_tick = p_dps * tick_interval_ms / 1000  # Convert DPS to damage per tick
	remaining_ms = p_duration_ms
	next_tick_ms = tick_interval_ms


func is_expired() -> bool:
	return remaining_ms <= 0


func process(delta_ms: int, enemies: Array) -> int:
	## Process ground effect, returns total damage dealt this tick (x1000)
	remaining_ms -= delta_ms
	next_tick_ms -= delta_ms

	if next_tick_ms > 0:
		return 0

	# Reset tick timer
	next_tick_ms += tick_interval_ms

	# Damage enemies in radius
	var total_damage: int = 0
	var radius_sq: float = radius * radius

	for enemy in enemies:
		var dx: float = enemy.grid_pos.x - position.x
		var dy: float = enemy.grid_pos.y - position.y
		var dist_sq: float = dx * dx + dy * dy

		if dist_sq <= radius_sq:
			enemy.take_damage(damage_per_tick)
			total_damage += damage_per_tick

	return total_damage
