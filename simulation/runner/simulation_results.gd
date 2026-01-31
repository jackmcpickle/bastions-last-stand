class_name SimulationResults
extends RefCounted

## Detailed simulation results for analysis and export

var game_results: Array[TickProcessor.GameResult] = []
var analysis: Dictionary = {}
var config: Dictionary = {}


func add_result(result: TickProcessor.GameResult) -> void:
	game_results.append(result)


func compute_analysis() -> void:
	analysis = SimulationRunner.analyze_results(game_results)


func to_csv() -> String:
	## Export results to CSV format
	var lines: Array[String] = []

	# Header
	(
		lines
		. append(
			"game_id,won,final_wave,shrine_hp,gold,duration_ms,enemies_killed,enemies_leaked,damage_dealt"
		)
	)

	# Data rows
	for i in range(game_results.size()):
		var r := game_results[i]
		lines.append(
			(
				"%d,%s,%d,%d,%d,%d,%d,%d,%d"
				% [
					i,
					"true" if r.won else "false",
					r.final_wave,
					r.final_shrine_hp,
					r.final_gold,
					r.get_duration_ms(),
					r.enemies_killed,
					r.enemies_leaked,
					r.total_damage_dealt
				]
			)
		)

	return "\n".join(lines)


func save_csv(path: String) -> Error:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if not file:
		return FileAccess.get_open_error()

	file.store_string(to_csv())
	file.close()
	return OK


func to_json() -> String:
	var data := {"config": config, "analysis": analysis, "results": []}

	for result in game_results:
		data.results.append(result.to_dict())

	return JSON.stringify(data, "  ")


func save_json(path: String) -> Error:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if not file:
		return FileAccess.get_open_error()

	file.store_string(to_json())
	file.close()
	return OK
