extends Node

## Global progression tracking and level unlocking system

signal level_unlocked(level_id: String)
signal level_completed(level_id: String, stars: int, difficulty: String)
signal chapter_unlocked(chapter_id: String)

# Progression state
var unlocked_levels: Array[String] = ["ch1_lv1"]
var completed_levels: Dictionary = {}  # {level_id: {difficulty: stars}}
var unlocked_chapters: Array[String] = ["chapter_1"]
var total_gold: int = 0
var current_faction: String = ""  # "light" or "dark"

# Current session
var current_level = null  # Will be LevelData
var current_difficulty: String = "normal"
var last_battle_result = null

# Chapter/level data cache
var all_chapters: Array = []

const SAVE_PATH = "user://progression.save"


func _ready() -> void:
	_load_chapter_data()
	load_progression()


func _load_chapter_data() -> void:
	var ch1 = load("res://resources/levels/chapter_1.tres")
	ch1.levels = [
		_create_level(
			"ch1_lv1",
			"First Steps",
			"chapter_1",
			0,
			"Face your first wave of enemies. Learn tower placement basics.",
			["archer_tower"],
			["grunt"]
		),
		_create_level(
			"ch1_lv2",
			"Speed Threat",
			"chapter_1",
			1,
			"Fast enemies require defensive positioning. Use slowing towers!",
			["archer_tower", "frost_tower"],
			["grunt", "runner"]
		),
		_create_level(
			"ch1_lv3",
			"Rush Defense",
			"chapter_1",
			2,
			"Intense waves test your tower network. Adapt and survive!",
			["archer_tower", "cannon_tower"],
			["grunt", "runner"]
		),
	]
	var ch2 = load("res://resources/levels/chapter_2.tres")
	ch2.levels = [
		_create_level(
			"ch2_lv1",
			"Heavy Units",
			"chapter_2",
			0,
			"Tanks arrive. Single-target towers struggle. Use AOE!",
			["cannon_tower", "lightning_tower"],
			["grunt", "tank"]
		),
		_create_level(
			"ch2_lv2",
			"Mixed Army",
			"chapter_2",
			1,
			"Balanced enemy composition. Adapt your tower mix.",
			["archer_tower", "cannon_tower", "frost_tower"],
			["grunt", "runner", "tank"]
		),
		_create_level(
			"ch2_lv3",
			"Air Raid",
			"chapter_2",
			2,
			"Flying enemies bypass ground defenses. Plan your towers carefully.",
			["lightning_tower", "flame_tower"],
			["flyer", "grunt"]
		),
		_create_level(
			"ch2_lv4",
			"Swarm Onslaught",
			"chapter_2",
			3,
			"Massive numbers require area control. Build wide!",
			["cannon_tower", "flame_tower"],
			["grunt", "runner"]
		),
	]
	var ch3 = load("res://resources/levels/chapter_3.tres")
	ch3.levels = [
		_create_level(
			"ch3_lv1",
			"Shadow Strike",
			"chapter_3",
			0,
			"Invisible enemies move unseen. Detection and AOE prevail.",
			["cannon_tower", "lightning_tower"],
			["stealth", "grunt"]
		),
		_create_level(
			"ch3_lv2",
			"Siege",
			"chapter_3",
			1,
			"Enemies destroy walls. Rebuild defenses strategically.",
			["cannon_tower", "frost_tower"],
			["breaker", "tank"]
		),
		_create_level(
			"ch3_lv3",
			"Boss Battle",
			"chapter_3",
			2,
			"Final confrontation. Everything you learned matters.",
			["archer_tower", "cannon_tower", "lightning_tower"],
			["boss"]
		),
	]
	all_chapters = [ch1, ch2, ch3]


func _create_level(
	level_id: String,
	display_name: String,
	chapter_id: String,
	level_in_chapter: int,
	description: String,
	recommended_towers: Array,
	enemy_types: Array
) -> LevelData:
	var level = LevelData.new()
	level.id = level_id
	level.display_name = display_name
	level.chapter_id = chapter_id
	level.level_in_chapter = level_in_chapter
	level.map_id = "test_map"
	level.wave_start = 1 + level_in_chapter * 5
	level.wave_end = level.wave_start + 4
	level.description = description
	level.recommended_towers = recommended_towers
	level.enemy_types = enemy_types
	level.difficulty_modifiers = {
		"easy": {"dmg_mult": 0.75, "gold": 80, "hp_mult": 0.75},
		"hard": {"dmg_mult": 1.5, "gold": 150, "hp_mult": 1.5},
		"normal": {"dmg_mult": 1.0, "gold": 100, "hp_mult": 1.0},
	}
	level.unlock_requirement = ""
	return level


func is_level_unlocked(level_id: String) -> bool:
	return level_id in unlocked_levels


func is_chapter_unlocked(chapter_id: String) -> bool:
	return chapter_id in unlocked_chapters


func get_level_stars(level_id: String, difficulty: String) -> int:
	if level_id not in completed_levels:
		return 0
	var level_results = completed_levels[level_id]
	return level_results.get(difficulty, 0)


func complete_level(level_id: String, difficulty: String, result) -> void:
	var stars = calculate_stars(result.final_shrine_hp, 1000)
	var gold_reward = _get_level_data(level_id).difficulty_modifiers[difficulty].gold

	# Check if this is first completion before modifying state
	var is_first_completion = level_id not in completed_levels

	if level_id not in completed_levels:
		completed_levels[level_id] = {}

	# Only update if we got more stars this difficulty
	var current_stars = completed_levels[level_id].get(difficulty, 0)
	if stars > current_stars:
		completed_levels[level_id][difficulty] = stars

	total_gold += gold_reward
	level_completed.emit(level_id, stars, difficulty)

	# Unlock next level if this is the first win at any difficulty
	if is_first_completion:
		unlock_next_level(level_id)
		# Check if chapter is now complete and unlock next chapter
		var level_data = _get_level_data(level_id)
		if level_data and is_chapter_complete(level_data.chapter_id):
			unlock_next_chapter(level_data.chapter_id)

	save_progression()


func calculate_stars(shrine_hp: int, max_hp: int) -> int:
	var hp_percent = float(shrine_hp) / float(max_hp)
	if hp_percent >= 0.75:
		return 3
	elif hp_percent >= 0.5:
		return 2
	else:
		return 1


func unlock_next_level(current_level_id: String) -> void:
	var level_data = _get_level_data(current_level_id)
	if not level_data:
		return

	# Find next level in same chapter
	var chapter = _get_chapter_by_id(level_data.chapter_id)
	if not chapter:
		return

	for i in range(level_data.level_in_chapter, chapter.levels.size()):
		var next_level = chapter.levels[i]
		if next_level.id not in unlocked_levels:
			unlocked_levels.append(next_level.id)
			level_unlocked.emit(next_level.id)
			break


func unlock_next_chapter(current_chapter_id: String) -> void:
	var current_idx = _get_chapter_index(current_chapter_id)
	if current_idx >= 0 and current_idx + 1 < all_chapters.size():
		var next_chapter = all_chapters[current_idx + 1]
		if next_chapter.id not in unlocked_chapters:
			unlocked_chapters.append(next_chapter.id)
			# Unlock first level of next chapter
			if next_chapter.levels.size() > 0:
				var first_level = next_chapter.levels[0]
				if first_level.id not in unlocked_levels:
					unlocked_levels.append(first_level.id)
					level_unlocked.emit(first_level.id)
			chapter_unlocked.emit(next_chapter.id)


func is_chapter_complete(chapter_id: String) -> bool:
	var chapter = _get_chapter_by_id(chapter_id)
	if not chapter:
		return false

	for level in chapter.levels:
		if level.id not in completed_levels:
			return false
	return true


func save_progression() -> void:
	var data = {
		"unlocked_levels": unlocked_levels,
		"completed_levels": completed_levels,
		"unlocked_chapters": unlocked_chapters,
		"total_gold": total_gold,
		"current_faction": current_faction,
		"version": 1
	}

	var json_string = JSON.stringify(data)
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(json_string)


func load_progression() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return

	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		return

	var json_string = file.get_as_text()
	var json = JSON.new()
	var error = json.parse(json_string)

	if error == OK:
		var data = json.data
		unlocked_levels = data.get("unlocked_levels", ["ch1_lv1"])
		completed_levels = data.get("completed_levels", {})
		unlocked_chapters = data.get("unlocked_chapters", ["chapter_1"])
		total_gold = data.get("total_gold", 0)
		current_faction = data.get("current_faction", "")


func _get_level_data(level_id: String):
	for chapter in all_chapters:
		for level in chapter.levels:
			if level.id == level_id:
				return level
	return null


func _get_chapter_by_id(chapter_id: String):
	for chapter in all_chapters:
		if chapter.id == chapter_id:
			return chapter
	return null


func _get_chapter_index(chapter_id: String) -> int:
	for i in range(all_chapters.size()):
		if all_chapters[i].id == chapter_id:
			return i
	return -1
