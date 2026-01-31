class_name BalanceConfig
extends RefCounted

## Central balance configuration
## All tunable game parameters in one place for AI optimization

## ============================================
## ECONOMY
## ============================================
var starting_gold: int = 120
var wall_cost: int = 10
var sell_rate_percent: int = 90  # % of total cost returned when selling

## ============================================
## ARCHER TOWER
## ============================================
var archer_cost: int = 80
var archer_damage: int = 15000  # x1000 fixed-point (15000 = 15 damage)
var archer_attack_speed_ms: int = 800  # milliseconds between attacks
var archer_range: int = 5  # tiles

## ============================================
## ENEMIES
## ============================================
# Grunt
var grunt_hp: int = 60
var grunt_speed: int = 1000  # x1000 tiles/sec (1000 = 1.0 tiles/sec)
var grunt_gold: int = 5

# Runner  
var runner_hp: int = 40
var runner_speed: int = 2000  # x1000 tiles/sec (2000 = 2.0 tiles/sec)
var runner_gold: int = 8

## ============================================
## SHRINE
## ============================================
var shrine_hp: int = 100
var enemy_shrine_damage: int = 1  # damage per enemy reaching shrine

## ============================================
## WAVES
## ============================================
var wave_spawn_interval_base_ms: int = 800  # base spawn interval
var wave_spawn_interval_rush_ms: int = 300  # rush wave spawn interval

# Wave enemy counts (waves 1-10)
var wave_1_grunts: int = 5
var wave_2_grunts: int = 8
var wave_3_grunts: int = 10
var wave_4_grunts: int = 12
var wave_5_grunts: int = 15
var wave_6_grunts: int = 12
var wave_6_runners: int = 3
var wave_7_grunts: int = 10
var wave_7_runners: int = 6
var wave_8_runners: int = 25  # Rush wave
var wave_9_grunts: int = 15
var wave_9_runners: int = 8
var wave_10_grunts: int = 18
var wave_10_runners: int = 10


## ============================================
## METHODS
## ============================================

func to_dict() -> Dictionary:
	return {
		# Economy
		"starting_gold": starting_gold,
		"wall_cost": wall_cost,
		"sell_rate_percent": sell_rate_percent,
		# Archer
		"archer_cost": archer_cost,
		"archer_damage": archer_damage,
		"archer_attack_speed_ms": archer_attack_speed_ms,
		"archer_range": archer_range,
		# Grunt
		"grunt_hp": grunt_hp,
		"grunt_speed": grunt_speed,
		"grunt_gold": grunt_gold,
		# Runner
		"runner_hp": runner_hp,
		"runner_speed": runner_speed,
		"runner_gold": runner_gold,
		# Shrine
		"shrine_hp": shrine_hp,
		"enemy_shrine_damage": enemy_shrine_damage,
		# Waves
		"wave_spawn_interval_base_ms": wave_spawn_interval_base_ms,
		"wave_spawn_interval_rush_ms": wave_spawn_interval_rush_ms,
		"wave_1_grunts": wave_1_grunts,
		"wave_2_grunts": wave_2_grunts,
		"wave_3_grunts": wave_3_grunts,
		"wave_4_grunts": wave_4_grunts,
		"wave_5_grunts": wave_5_grunts,
		"wave_6_grunts": wave_6_grunts,
		"wave_6_runners": wave_6_runners,
		"wave_7_grunts": wave_7_grunts,
		"wave_7_runners": wave_7_runners,
		"wave_8_runners": wave_8_runners,
		"wave_9_grunts": wave_9_grunts,
		"wave_9_runners": wave_9_runners,
		"wave_10_grunts": wave_10_grunts,
		"wave_10_runners": wave_10_runners,
	}


func from_dict(data: Dictionary) -> void:
	# Economy
	if data.has("starting_gold"): starting_gold = data.starting_gold
	if data.has("wall_cost"): wall_cost = data.wall_cost
	if data.has("sell_rate_percent"): sell_rate_percent = data.sell_rate_percent
	# Archer
	if data.has("archer_cost"): archer_cost = data.archer_cost
	if data.has("archer_damage"): archer_damage = data.archer_damage
	if data.has("archer_attack_speed_ms"): archer_attack_speed_ms = data.archer_attack_speed_ms
	if data.has("archer_range"): archer_range = data.archer_range
	# Grunt
	if data.has("grunt_hp"): grunt_hp = data.grunt_hp
	if data.has("grunt_speed"): grunt_speed = data.grunt_speed
	if data.has("grunt_gold"): grunt_gold = data.grunt_gold
	# Runner
	if data.has("runner_hp"): runner_hp = data.runner_hp
	if data.has("runner_speed"): runner_speed = data.runner_speed
	if data.has("runner_gold"): runner_gold = data.runner_gold
	# Shrine
	if data.has("shrine_hp"): shrine_hp = data.shrine_hp
	if data.has("enemy_shrine_damage"): enemy_shrine_damage = data.enemy_shrine_damage
	# Waves
	if data.has("wave_spawn_interval_base_ms"): wave_spawn_interval_base_ms = data.wave_spawn_interval_base_ms
	if data.has("wave_spawn_interval_rush_ms"): wave_spawn_interval_rush_ms = data.wave_spawn_interval_rush_ms
	if data.has("wave_1_grunts"): wave_1_grunts = data.wave_1_grunts
	if data.has("wave_2_grunts"): wave_2_grunts = data.wave_2_grunts
	if data.has("wave_3_grunts"): wave_3_grunts = data.wave_3_grunts
	if data.has("wave_4_grunts"): wave_4_grunts = data.wave_4_grunts
	if data.has("wave_5_grunts"): wave_5_grunts = data.wave_5_grunts
	if data.has("wave_6_grunts"): wave_6_grunts = data.wave_6_grunts
	if data.has("wave_6_runners"): wave_6_runners = data.wave_6_runners
	if data.has("wave_7_grunts"): wave_7_grunts = data.wave_7_grunts
	if data.has("wave_7_runners"): wave_7_runners = data.wave_7_runners
	if data.has("wave_8_runners"): wave_8_runners = data.wave_8_runners
	if data.has("wave_9_grunts"): wave_9_grunts = data.wave_9_grunts
	if data.has("wave_9_runners"): wave_9_runners = data.wave_9_runners
	if data.has("wave_10_grunts"): wave_10_grunts = data.wave_10_grunts
	if data.has("wave_10_runners"): wave_10_runners = data.wave_10_runners


func save_to_file(path: String) -> Error:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if not file:
		return FileAccess.get_open_error()
	file.store_string(JSON.stringify(to_dict(), "  "))
	file.close()
	return OK


func load_from_file(path: String) -> Error:
	var file := FileAccess.open(path, FileAccess.READ)
	if not file:
		return FileAccess.get_open_error()
	var json_str := file.get_as_text()
	file.close()
	
	var json := JSON.new()
	var err := json.parse(json_str)
	if err != OK:
		return err
	
	from_dict(json.data)
	return OK


## Get parameter bounds for AI optimization
static func get_parameter_bounds() -> Dictionary:
	return {
		"starting_gold": {"min": 50, "max": 300, "step": 10},
		"wall_cost": {"min": 5, "max": 30, "step": 5},
		"archer_cost": {"min": 40, "max": 150, "step": 10},
		"archer_damage": {"min": 5000, "max": 50000, "step": 1000},
		"archer_attack_speed_ms": {"min": 200, "max": 2000, "step": 100},
		"archer_range": {"min": 3, "max": 10, "step": 1},
		"grunt_hp": {"min": 20, "max": 150, "step": 5},
		"grunt_speed": {"min": 500, "max": 2000, "step": 100},
		"grunt_gold": {"min": 2, "max": 15, "step": 1},
		"runner_hp": {"min": 15, "max": 100, "step": 5},
		"runner_speed": {"min": 1000, "max": 3000, "step": 100},
		"runner_gold": {"min": 3, "max": 20, "step": 1},
		"shrine_hp": {"min": 50, "max": 200, "step": 10},
		"enemy_shrine_damage": {"min": 1, "max": 5, "step": 1},
		"wave_spawn_interval_base_ms": {"min": 400, "max": 1500, "step": 100},
		"wave_spawn_interval_rush_ms": {"min": 100, "max": 500, "step": 50},
	}
