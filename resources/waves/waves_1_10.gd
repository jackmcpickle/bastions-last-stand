class_name Waves1To10
extends RefCounted

## Factory for waves 1-10
## Wave composition from GDD:
## 1-5: Grunts only (tutorial)
## 6-10: Grunts + Runners
## Wave 8: Rush round (3x count, 300ms spawn)


static func create() -> WaveData:
	var data := WaveData.new()
	data.waves = [
		_wave_1(),
		_wave_2(),
		_wave_3(),
		_wave_4(),
		_wave_5(),
		_wave_6(),
		_wave_7(),
		_wave_8(),  # Rush
		_wave_9(),
		_wave_10(),
	]
	return data


static func _wave_1() -> SingleWaveData:
	var wave := SingleWaveData.new()
	wave.wave_number = 1
	wave.spawn_interval_ms = 800
	wave.spawns = [_spawn("grunt", 5)]
	return wave


static func _wave_2() -> SingleWaveData:
	var wave := SingleWaveData.new()
	wave.wave_number = 2
	wave.spawn_interval_ms = 800
	wave.spawns = [_spawn("grunt", 8)]
	return wave


static func _wave_3() -> SingleWaveData:
	var wave := SingleWaveData.new()
	wave.wave_number = 3
	wave.spawn_interval_ms = 700
	wave.spawns = [_spawn("grunt", 10)]
	return wave


static func _wave_4() -> SingleWaveData:
	var wave := SingleWaveData.new()
	wave.wave_number = 4
	wave.spawn_interval_ms = 700
	wave.spawns = [_spawn("grunt", 12)]
	return wave


static func _wave_5() -> SingleWaveData:
	var wave := SingleWaveData.new()
	wave.wave_number = 5
	wave.spawn_interval_ms = 600
	wave.spawns = [_spawn("grunt", 15)]
	return wave


static func _wave_6() -> SingleWaveData:
	var wave := SingleWaveData.new()
	wave.wave_number = 6
	wave.spawn_interval_ms = 700
	wave.spawns = [
		_spawn("grunt", 12),
		_spawn("runner", 3),
	]
	return wave


static func _wave_7() -> SingleWaveData:
	var wave := SingleWaveData.new()
	wave.wave_number = 7
	wave.spawn_interval_ms = 600
	wave.spawns = [
		_spawn("grunt", 10),
		_spawn("runner", 6),
	]
	return wave


static func _wave_8() -> SingleWaveData:
	## Rush round - lots of fast enemies
	var wave := SingleWaveData.new()
	wave.wave_number = 8
	wave.spawn_interval_ms = 300
	wave.is_rush = true
	wave.spawns = [
		_spawn("runner", 25),
	]
	return wave


static func _wave_9() -> SingleWaveData:
	var wave := SingleWaveData.new()
	wave.wave_number = 9
	wave.spawn_interval_ms = 600
	wave.spawns = [
		_spawn("grunt", 15),
		_spawn("runner", 8),
	]
	return wave


static func _wave_10() -> SingleWaveData:
	var wave := SingleWaveData.new()
	wave.wave_number = 10
	wave.spawn_interval_ms = 500
	wave.spawns = [
		_spawn("grunt", 18),
		_spawn("runner", 10),
	]
	return wave


static func _spawn(enemy_id: String, count: int, spawn_point: int = -1, delay_ms: int = 0) -> WaveSpawnData:
	var spawn := WaveSpawnData.new()
	spawn.enemy_id = enemy_id
	spawn.count = count
	spawn.spawn_point_index = spawn_point
	spawn.delay_ms = delay_ms
	return spawn
