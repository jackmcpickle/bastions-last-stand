class_name SingleWaveData
extends Resource

## Single wave configuration

@export var wave_number: int
@export var spawns: Array[WaveSpawnData] = []
@export var spawn_interval_ms: int = 800  # Time between spawns
@export var is_rush: bool = false  # Rush round (3x enemies, faster spawns)
@export var is_smash: bool = false  # Smash round (wall breakers)


func get_total_enemy_count() -> int:
	var total := 0
	for spawn in spawns:
		total += spawn.count
	return total


func get_enemy_types() -> Array[String]:
	var types: Array[String] = []
	for spawn in spawns:
		if spawn.enemy_id not in types:
			types.append(spawn.enemy_id)
	return types
