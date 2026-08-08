extends GutTest

## Asserts unused standards/bosses appear correctly in the full 30-wave roster

const ProgressionManagerScript = preload("res://game/progression_manager.gd")


func test_full_roster_includes_all_standards_and_bosses() -> void:
	var wave_data: WaveData = Waves1To10.create_full()
	var enemy_ids := _collect_enemy_ids(wave_data)

	for enemy_id in ["healer", "shielded", "splitter", "regen"]:
		assert_true(enemy_ids.has(enemy_id), "Expected standard enemy '%s' in roster" % enemy_id)

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


func test_full_roster_has_thirty_numbered_waves() -> void:
	var wave_data: WaveData = Waves1To10.create_full()
	assert_eq(wave_data.waves.size(), 30)
	for i in range(30):
		assert_eq(wave_data.waves[i].wave_number, i + 1)


func test_standard_intro_waves_and_counts() -> void:
	var wave_data: WaveData = Waves1To10.create_full()
	var counts := _spawn_counts_by_wave(wave_data)

	assert_eq(counts[13].get("healer", 0), 2)
	assert_eq(counts[16].get("shielded", 0), 3)
	assert_eq(counts[19].get("splitter", 0), 3)
	assert_eq(counts[22].get("regen", 0), 3)

	# First appearance before intro wave must be absent
	assert_eq(counts[12].get("healer", 0), 0)
	assert_eq(counts[15].get("shielded", 0), 0)
	assert_eq(counts[18].get("splitter", 0), 0)
	assert_eq(counts[21].get("regen", 0), 0)


func test_standard_reuse_waves_and_counts() -> void:
	var wave_data: WaveData = Waves1To10.create_full()
	var counts := _spawn_counts_by_wave(wave_data)

	assert_eq(counts[17].get("healer", 0), 3)
	assert_eq(counts[23].get("healer", 0), 4)
	assert_eq(counts[21].get("shielded", 0), 4)
	assert_eq(counts[27].get("shielded", 0), 5)
	assert_eq(counts[24].get("splitter", 0), 4)
	assert_eq(counts[29].get("splitter", 0), 5)
	assert_eq(counts[28].get("regen", 0), 4)


func test_boss_is_first_spawn_group_on_milestone_waves() -> void:
	var wave_data: WaveData = Waves1To10.create_full()
	var expected := {
		10: "swarm_queen",
		15: "frost_wyrm",
		20: "phase_phantom",
		25: "necromancer",
		30: "iron_colossus",
	}
	for wave_number in expected.keys():
		var wave := wave_data.get_wave(wave_number)
		assert_gt(wave.spawns.size(), 0, "Wave %d should have spawns" % wave_number)
		assert_eq(
			wave.spawns[0].enemy_id,
			expected[wave_number],
			"Wave %d boss should spawn first" % wave_number
		)
		assert_eq(wave.spawns[0].count, 1)


func test_final_wave_keeps_boss_golem_after_iron_colossus() -> void:
	var wave := Waves1To10.create_full().get_wave(30)
	assert_eq(wave.spawns[0].enemy_id, "iron_colossus")
	assert_eq(wave.spawns[1].enemy_id, "boss_golem")
	assert_eq(wave.spawns[1].count, 3)


func test_rush_and_smash_flags_unchanged() -> void:
	var wave_data: WaveData = Waves1To10.create_full()
	var rush_waves := [8, 14, 26]
	var smash_waves := [18, 24, 28]

	for wave_number in rush_waves:
		assert_true(wave_data.get_wave(wave_number).is_rush, "Wave %d rush" % wave_number)
		assert_false(wave_data.get_wave(wave_number).is_smash)

	for wave_number in smash_waves:
		assert_true(wave_data.get_wave(wave_number).is_smash, "Wave %d smash" % wave_number)
		assert_false(wave_data.get_wave(wave_number).is_rush)

	# Boss milestones are neither rush nor smash
	for wave_number in [10, 15, 20, 25, 30]:
		var wave := wave_data.get_wave(wave_number)
		assert_false(wave.is_rush)
		assert_false(wave.is_smash)


func test_boss_wave_escorts_preserved() -> void:
	var counts := _spawn_counts_by_wave(Waves1To10.create_full())

	assert_eq(counts[10].get("grunt", 0), 18)
	assert_eq(counts[10].get("runner", 0), 10)
	assert_eq(counts[15].get("stealth", 0), 3)
	assert_eq(counts[20].get("tank", 0), 6)
	assert_eq(counts[20].get("grunt", 0), 20)
	assert_eq(counts[25].get("flyer", 0), 15)
	assert_eq(counts[30].get("breaker", 0), 10)


func test_level_metadata_includes_new_enemy_types() -> void:
	var expectations := {
		"res://resources/levels/ch1_lv2.tres": ["swarm_queen"],
		"res://resources/levels/ch1_lv3.tres": ["swarm_queen"],
		"res://resources/levels/ch2_lv1.tres": ["healer", "frost_wyrm"],
		"res://resources/levels/ch2_lv2.tres": ["shielded", "splitter", "phase_phantom"],
		"res://resources/levels/ch3_lv1.tres": ["shielded", "regen", "necromancer"],
		"res://resources/levels/ch3_lv2.tres": ["shielded", "splitter", "regen"],
		"res://resources/levels/ch3_lv3.tres": ["iron_colossus"],
	}

	for path in expectations.keys():
		var level: LevelData = load(path)
		assert_not_null(level, "Failed to load %s" % path)
		for enemy_id in expectations[path]:
			assert_true(
				enemy_id in level.enemy_types,
				"%s missing enemy_types entry '%s'" % [path, enemy_id]
			)
		assert_false("mini" in level.enemy_types, "%s should not list mini" % path)


func test_progression_manager_level_enemy_types_match_roster() -> void:
	var pm = ProgressionManagerScript.new()
	add_child_autofree(pm)
	pm._load_chapter_data()

	var by_id := {}
	for chapter in pm.all_chapters:
		assert_true(chapter is ChapterData)
		assert_gt(chapter.levels.size(), 0)
		for level in chapter.levels:
			by_id[level.id] = level

	assert_true("swarm_queen" in by_id["ch1_lv2"].enemy_types)
	assert_true("swarm_queen" in by_id["ch1_lv3"].enemy_types)
	assert_true("healer" in by_id["ch2_lv1"].enemy_types)
	assert_true("frost_wyrm" in by_id["ch2_lv1"].enemy_types)
	assert_true("phase_phantom" in by_id["ch2_lv2"].enemy_types)
	assert_true("necromancer" in by_id["ch3_lv1"].enemy_types)
	assert_true("splitter" in by_id["ch3_lv2"].enemy_types)
	assert_true("iron_colossus" in by_id["ch3_lv3"].enemy_types)
	assert_true("boss_golem" in by_id["ch3_lv3"].enemy_types)
	assert_false("mini" in by_id["ch3_lv3"].enemy_types)


func test_wave_10_spawns_swarm_queen_from_roster() -> void:
	var state := _make_roster_game_state()
	assert_true(state.start_wave(10))
	_drain_spawns(state, 20000)

	var ids := _alive_enemy_ids(state)
	assert_true(ids.has("swarm_queen"), "Wave 10 should spawn swarm_queen")
	assert_true(ids.has("grunt"))
	assert_true(ids.has("runner"))


func test_wave_13_spawns_healer_intro() -> void:
	var state := _make_roster_game_state()
	assert_true(state.start_wave(13))
	_drain_spawns(state, 30000)

	var counts := _alive_enemy_counts(state)
	assert_eq(counts.get("healer", 0), 2)
	assert_gt(counts.get("tank", 0), 0)


func test_wave_19_spawns_splitter_without_prelisting_mini() -> void:
	var state := _make_roster_game_state()
	assert_true(state.start_wave(19))

	# Queue should include splitter but never mini (minis only on death)
	var queued_ids := {}
	for entry in state.spawn_queue:
		queued_ids[entry.enemy_id] = true
	assert_true(queued_ids.has("splitter"))
	assert_false(queued_ids.has("mini"))

	_drain_spawns(state, 40000)
	var counts := _alive_enemy_counts(state)
	assert_eq(counts.get("splitter", 0), 3)
	assert_eq(counts.get("mini", 0), 0)


func test_wave_20_spawns_phase_phantom_not_golem() -> void:
	var state := _make_roster_game_state()
	assert_true(state.start_wave(20))
	_drain_spawns(state, 20000)

	var ids := _alive_enemy_ids(state)
	assert_true(ids.has("phase_phantom"))
	assert_false(ids.has("boss_golem"))


func test_wave_30_spawns_both_final_bosses() -> void:
	var state := _make_roster_game_state()
	assert_true(state.start_wave(30))
	_drain_spawns(state, 60000)

	var counts := _alive_enemy_counts(state)
	assert_eq(counts.get("iron_colossus", 0), 1)
	assert_eq(counts.get("boss_golem", 0), 3)


func test_unregistered_boss_does_not_spawn() -> void:
	# Guard: missing registry must not create enemies for unknown ids
	var map := TestHelpers.create_basic_map_data()
	var waves := Waves1To10.create_full()
	var state := GameState.new()
	state.initialize(map, waves, 12345)
	# Deliberately do not register swarm_queen
	state.register_enemy_data(load("res://resources/enemies/grunt.tres"))
	state.register_enemy_data(load("res://resources/enemies/runner.tres"))

	assert_true(state.start_wave(10))
	_drain_spawns(state, 20000)

	var ids := _alive_enemy_ids(state)
	assert_false(ids.has("swarm_queen"))
	assert_true(ids.has("grunt") or ids.has("runner"))


func _make_roster_game_state() -> GameState:
	var map := TestHelpers.create_basic_map_data()
	var waves := Waves1To10.create_full()
	var state := GameState.new()
	state.initialize(map, waves, 12345)
	for path in [
		"res://resources/enemies/grunt.tres",
		"res://resources/enemies/runner.tres",
		"res://resources/enemies/tank.tres",
		"res://resources/enemies/flyer.tres",
		"res://resources/enemies/swarm.tres",
		"res://resources/enemies/stealth.tres",
		"res://resources/enemies/breaker.tres",
		"res://resources/enemies/healer.tres",
		"res://resources/enemies/shielded.tres",
		"res://resources/enemies/splitter.tres",
		"res://resources/enemies/regen.tres",
		"res://resources/enemies/mini.tres",
		"res://resources/enemies/boss_golem.tres",
		"res://resources/enemies/swarm_queen.tres",
		"res://resources/enemies/frost_wyrm.tres",
		"res://resources/enemies/phase_phantom.tres",
		"res://resources/enemies/necromancer.tres",
		"res://resources/enemies/iron_colossus.tres",
	]:
		state.register_enemy_data(load(path))
	return state


func _drain_spawns(state: GameState, max_ms: int) -> void:
	var elapsed := 0
	while not state.spawn_queue.is_empty() and elapsed < max_ms:
		state.process_spawns(100)
		elapsed += 100


func _alive_enemy_ids(state: GameState) -> Dictionary:
	var ids := {}
	for enemy in state.enemies:
		ids[enemy.id] = true
	return ids


func _alive_enemy_counts(state: GameState) -> Dictionary:
	var counts := {}
	for enemy in state.enemies:
		counts[enemy.id] = counts.get(enemy.id, 0) + 1
	return counts


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


func _spawn_counts_by_wave(wave_data: WaveData) -> Dictionary:
	var by_wave := {}
	for wave in wave_data.waves:
		var counts := {}
		for spawn in wave.spawns:
			counts[spawn.enemy_id] = counts.get(spawn.enemy_id, 0) + spawn.count
		by_wave[wave.wave_number] = counts
	return by_wave
