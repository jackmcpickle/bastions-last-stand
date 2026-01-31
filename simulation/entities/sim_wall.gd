class_name SimWall
extends RefCounted

## Wall entity for headless simulation

var position: Vector2i
var hp: int
var max_hp: int
var tier: int = 1

## Tracking
var total_damage_taken: int = 0


func take_damage(amount: int) -> void:
	total_damage_taken += amount
	hp -= amount
	if hp < 0:
		hp = 0


func is_destroyed() -> bool:
	return hp <= 0


func get_hp_percent() -> float:
	if max_hp <= 0:
		return 0.0
	return float(hp) / float(max_hp)
