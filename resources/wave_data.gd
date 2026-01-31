class_name WaveData
extends Resource

## Wave configuration resource

@export var waves: Array[SingleWaveData] = []


func get_wave(wave_number: int) -> SingleWaveData:
	if wave_number < 1 or wave_number > waves.size():
		return null
	return waves[wave_number - 1]


func get_total_waves() -> int:
	return waves.size()
