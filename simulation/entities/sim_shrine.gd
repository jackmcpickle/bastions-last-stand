class_name SimShrine
extends RefCounted

## The shrine - player's objective to protect

var position: Vector2i
var hp: int
var max_hp: int

## Tracking
var total_damage_taken: int = 0
var hits_taken: int = 0


func take_damage(amount: int) -> void:
	total_damage_taken += amount
	hits_taken += 1
	hp -= amount
	if hp < 0:
		hp = 0


func is_destroyed() -> bool:
	return hp <= 0


func get_hp_percent() -> float:
	if max_hp <= 0:
		return 0.0
	return float(hp) / float(max_hp)
