extends GutTest

## Asserts unused standards/bosses appear in the full 30-wave roster


func test_full_roster_includes_all_standards_and_bosses() -> void:
	var wave_data: WaveData = Waves1To10.create_full()
	var enemy_ids := _collect_enemy_ids(wave_data)

	for enemy_id in ["healer", "shielded", "splitter", "regen"]:
		assert_true(
			enemy_ids.has(enemy_id), "Expected standard enemy '%s' in roster" % enemy_id
		)

	for enemy_id in [
		"swarm_queen",
		"frost_wyrm",
		"phase_phantom",
		"necromancer",
		"iron_colossus",
		"boss_golem",
	]:
		assert_true(enemy_ids.has(enemy_id), "Expected boss '%s' in roster" % enemy_id)

	assert_false(enemy_ids.has("mini"), "mini must not appear in wave spawn groups")


func test_milestone_boss_placements() -> void:
	var wave_data: WaveData = Waves1To10.create_full()
	var by_wave := _enemy_ids_by_wave(wave_data)

	assert_true(by_wave[10].has("swarm_queen"))
	assert_true(by_wave[15].has("frost_wyrm"))
	assert_true(by_wave[20].has("phase_phantom"))
	assert_false(by_wave[20].has("boss_golem"))
	assert_true(by_wave[25].has("necromancer"))
	assert_true(by_wave[30].has("iron_colossus"))
	assert_true(by_wave[30].has("boss_golem"))


func _collect_enemy_ids(wave_data: WaveData) -> Dictionary:
	var ids := {}
	for wave in wave_data.waves:
		for spawn in wave.spawns:
			ids[spawn.enemy_id] = true
	return ids


func _enemy_ids_by_wave(wave_data: WaveData) -> Dictionary:
	var by_wave := {}
	for wave in wave_data.waves:
		var ids := {}
		for spawn in wave.spawns:
			ids[spawn.enemy_id] = true
		by_wave[wave.wave_number] = ids
	return by_wave
