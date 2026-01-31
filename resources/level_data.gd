class_name LevelData extends Resource

@export var id: String  # "ch1_lv1"
@export var display_name: String  # "First Steps"
@export var chapter_id: String
@export var level_in_chapter: int

# Gameplay
@export var map_id: String  # "test_map"
@export var wave_start: int  # 1
@export var wave_end: int  # 5
@export var difficulty_modifiers: Dictionary = {
	"easy": {"hp_mult": 0.75, "dmg_mult": 0.75, "gold": 80},
	"normal": {"hp_mult": 1.0, "dmg_mult": 1.0, "gold": 100},
	"hard": {"hp_mult": 1.5, "dmg_mult": 1.5, "gold": 150}
}

# Unlock & metadata
@export var unlock_requirement: String  # "" or "ch1_lv1"
@export var description: String
@export var recommended_towers: Array[String]
@export var enemy_types: Array[String]
