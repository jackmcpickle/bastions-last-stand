class_name Waves11To30
extends RefCounted

## Factory for waves 11-30
## Wave composition:
## 10: Boss wave (Golem)
## 11-14: Introduce Tank, Flyer
## 14: Rush round
## 15-18: Introduce Swarm, Stealth
## 18: Smash round (Breakers)
## 19-20: Boss wave (Golem)
## 21-24: Mixed compositions
## 24: Smash round
## 25-28: Increased difficulty
## 26: Rush round
## 28: Smash round
## 29-30: Boss wave + everything


static func create() -> Array[SingleWaveData]:
	return [
		_wave_11(),
		_wave_12(),
		_wave_13(),
		_wave_14(),  # Rush
		_wave_15(),
		_wave_16(),
		_wave_17(),
		_wave_18(),  # Smash
		_wave_19(),
		_wave_20(),  # Boss
		_wave_21(),
		_wave_22(),
		_wave_23(),
		_wave_24(),  # Smash
		_wave_25(),
		_wave_26(),  # Rush
		_wave_27(),
		_wave_28(),  # Smash
		_wave_29(),
		_wave_30(),  # Final boss
	]


static func _wave_11() -> SingleWaveData:
	var wave := SingleWaveData.new()
	wave.wave_number = 11
	wave.spawn_interval_ms = 600
	wave.spawns = [
		_spawn("grunt", 15),
		_spawn("runner", 8),
		_spawn("tank", 2),
	]
	return wave


static func _wave_12() -> SingleWaveData:
	var wave := SingleWaveData.new()
	wave.wave_number = 12
	wave.spawn_interval_ms = 600
	wave.spawns = [
		_spawn("grunt", 12),
		_spawn("runner", 6),
		_spawn("flyer", 5),
	]
	return wave


static func _wave_13() -> SingleWaveData:
	var wave := SingleWaveData.new()
	wave.wave_number = 13
	wave.spawn_interval_ms = 500
	wave.spawns = [
		_spawn("grunt", 18),
		_spawn("tank", 4),
		_spawn("flyer", 6),
	]
	return wave


static func _wave_14() -> SingleWaveData:
	## Rush round
	var wave := SingleWaveData.new()
	wave.wave_number = 14
	wave.spawn_interval_ms = 250
	wave.is_rush = true
	wave.spawns = [
		_spawn("runner", 30),
		_spawn("swarm", 20),
	]
	return wave


static func _wave_15() -> SingleWaveData:
	var wave := SingleWaveData.new()
	wave.wave_number = 15
	wave.spawn_interval_ms = 500
	wave.spawns = [
		_spawn("grunt", 20),
		_spawn("runner", 10),
		_spawn("stealth", 3),
	]
	return wave


static func _wave_16() -> SingleWaveData:
	var wave := SingleWaveData.new()
	wave.wave_number = 16
	wave.spawn_interval_ms = 500
	wave.spawns = [
		_spawn("tank", 5),
		_spawn("flyer", 8),
		_spawn("stealth", 5),
	]
	return wave


static func _wave_17() -> SingleWaveData:
	var wave := SingleWaveData.new()
	wave.wave_number = 17
	wave.spawn_interval_ms = 450
	wave.spawns = [
		_spawn("grunt", 25),
		_spawn("runner", 12),
		_spawn("swarm", 15),
	]
	return wave


static func _wave_18() -> SingleWaveData:
	## Smash round - wall breakers
	var wave := SingleWaveData.new()
	wave.wave_number = 18
	wave.spawn_interval_ms = 600
	wave.is_smash = true
	wave.spawns = [
		_spawn("breaker", 8),
		_spawn("tank", 4),
		_spawn("grunt", 15),
	]
	return wave


static func _wave_19() -> SingleWaveData:
	var wave := SingleWaveData.new()
	wave.wave_number = 19
	wave.spawn_interval_ms = 450
	wave.spawns = [
		_spawn("grunt", 22),
		_spawn("runner", 15),
		_spawn("flyer", 10),
		_spawn("stealth", 4),
	]
	return wave


static func _wave_20() -> SingleWaveData:
	## Boss wave
	var wave := SingleWaveData.new()
	wave.wave_number = 20
	wave.spawn_interval_ms = 500
	wave.spawns = [
		_spawn("boss_golem", 1),
		_spawn("tank", 6),
		_spawn("grunt", 20),
	]
	return wave


static func _wave_21() -> SingleWaveData:
	var wave := SingleWaveData.new()
	wave.wave_number = 21
	wave.spawn_interval_ms = 400
	wave.spawns = [
		_spawn("grunt", 25),
		_spawn("runner", 18),
		_spawn("tank", 5),
		_spawn("flyer", 8),
	]
	return wave


static func _wave_22() -> SingleWaveData:
	var wave := SingleWaveData.new()
	wave.wave_number = 22
	wave.spawn_interval_ms = 400
	wave.spawns = [
		_spawn("swarm", 30),
		_spawn("stealth", 8),
		_spawn("flyer", 12),
	]
	return wave


static func _wave_23() -> SingleWaveData:
	var wave := SingleWaveData.new()
	wave.wave_number = 23
	wave.spawn_interval_ms = 400
	wave.spawns = [
		_spawn("grunt", 30),
		_spawn("runner", 15),
		_spawn("tank", 8),
		_spawn("stealth", 5),
	]
	return wave


static func _wave_24() -> SingleWaveData:
	## Smash round
	var wave := SingleWaveData.new()
	wave.wave_number = 24
	wave.spawn_interval_ms = 500
	wave.is_smash = true
	wave.spawns = [
		_spawn("breaker", 12),
		_spawn("tank", 6),
		_spawn("runner", 20),
	]
	return wave


static func _wave_25() -> SingleWaveData:
	var wave := SingleWaveData.new()
	wave.wave_number = 25
	wave.spawn_interval_ms = 350
	wave.spawns = [
		_spawn("grunt", 35),
		_spawn("runner", 20),
		_spawn("flyer", 15),
		_spawn("tank", 6),
	]
	return wave


static func _wave_26() -> SingleWaveData:
	## Rush round
	var wave := SingleWaveData.new()
	wave.wave_number = 26
	wave.spawn_interval_ms = 200
	wave.is_rush = true
	wave.spawns = [
		_spawn("runner", 50),
		_spawn("swarm", 40),
		_spawn("flyer", 20),
	]
	return wave


static func _wave_27() -> SingleWaveData:
	var wave := SingleWaveData.new()
	wave.wave_number = 27
	wave.spawn_interval_ms = 350
	wave.spawns = [
		_spawn("grunt", 30),
		_spawn("tank", 10),
		_spawn("stealth", 10),
		_spawn("flyer", 12),
	]
	return wave


static func _wave_28() -> SingleWaveData:
	## Smash round
	var wave := SingleWaveData.new()
	wave.wave_number = 28
	wave.spawn_interval_ms = 400
	wave.is_smash = true
	wave.spawns = [
		_spawn("breaker", 15),
		_spawn("tank", 10),
		_spawn("grunt", 25),
		_spawn("runner", 15),
	]
	return wave


static func _wave_29() -> SingleWaveData:
	var wave := SingleWaveData.new()
	wave.wave_number = 29
	wave.spawn_interval_ms = 300
	wave.spawns = [
		_spawn("grunt", 40),
		_spawn("runner", 25),
		_spawn("tank", 12),
		_spawn("flyer", 18),
		_spawn("stealth", 8),
		_spawn("swarm", 30),
	]
	return wave


static func _wave_30() -> SingleWaveData:
	## Final boss wave
	var wave := SingleWaveData.new()
	wave.wave_number = 30
	wave.spawn_interval_ms = 400
	wave.spawns = [
		_spawn("boss_golem", 3),
		_spawn("tank", 15),
		_spawn("breaker", 10),
		_spawn("grunt", 30),
		_spawn("runner", 20),
		_spawn("flyer", 15),
	]
	return wave


static func _spawn(enemy_id: String, count: int, spawn_point: int = -1, delay_ms: int = 0) -> WaveSpawnData:
	var spawn := WaveSpawnData.new()
	spawn.enemy_id = enemy_id
	spawn.count = count
	spawn.spawn_point_index = spawn_point
	spawn.delay_ms = delay_ms
	return spawn
