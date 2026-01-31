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
var archer_upgrade_t2: int = 150
var archer_upgrade_t3: int = 300

## ============================================
## CANNON TOWER
## ============================================
var cannon_cost: int = 120
var cannon_damage: int = 25000
var cannon_attack_speed_ms: int = 1500
var cannon_range: int = 4
var cannon_aoe_radius: int = 1500
var cannon_upgrade_t2: int = 200
var cannon_upgrade_t3: int = 400

## ============================================
## FROST TOWER
## ============================================
var frost_cost: int = 100
var frost_damage: int = 8000
var frost_attack_speed_ms: int = 600
var frost_range: int = 4
var frost_slow: int = 400
var frost_slow_duration_ms: int = 2500
var frost_upgrade_t2: int = 180
var frost_upgrade_t3: int = 350

## ============================================
## LIGHTNING TOWER
## ============================================
var lightning_cost: int = 140
var lightning_damage: int = 12000
var lightning_attack_speed_ms: int = 1200
var lightning_range: int = 5
var lightning_chain_count: int = 4
var lightning_chain_range: float = 2.5
var lightning_upgrade_t2: int = 220
var lightning_upgrade_t3: int = 450

## ============================================
## FLAME TOWER
## ============================================
var flame_cost: int = 90
var flame_damage: int = 6000
var flame_attack_speed_ms: int = 400
var flame_range: int = 3
var flame_burn_dps: int = 10000
var flame_burn_duration_ms: int = 4000
var flame_upgrade_t2: int = 160
var flame_upgrade_t3: int = 320

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

# Tank
var tank_hp: int = 300
var tank_speed: int = 600
var tank_armor: int = 300
var tank_gold: int = 25

# Flyer
var flyer_hp: int = 45
var flyer_speed: int = 1200
var flyer_gold: int = 12

# Swarm
var swarm_hp: int = 15
var swarm_speed: int = 1300
var swarm_gold: int = 2

# Stealth
var stealth_hp: int = 50
var stealth_speed: int = 1400
var stealth_gold: int = 15

# Breaker
var breaker_hp: int = 180
var breaker_speed: int = 700
var breaker_armor: int = 200
var breaker_gold: int = 20
var breaker_wall_damage: int = 25

# Boss - Golem
var boss_golem_hp: int = 1500
var boss_golem_speed: int = 400
var boss_golem_armor: int = 400
var boss_golem_gold: int = 100
var boss_golem_regen: int = 5000

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
		"archer_upgrade_t2": archer_upgrade_t2,
		"archer_upgrade_t3": archer_upgrade_t3,
		# Cannon
		"cannon_cost": cannon_cost,
		"cannon_damage": cannon_damage,
		"cannon_attack_speed_ms": cannon_attack_speed_ms,
		"cannon_range": cannon_range,
		"cannon_aoe_radius": cannon_aoe_radius,
		"cannon_upgrade_t2": cannon_upgrade_t2,
		"cannon_upgrade_t3": cannon_upgrade_t3,
		# Frost
		"frost_cost": frost_cost,
		"frost_damage": frost_damage,
		"frost_attack_speed_ms": frost_attack_speed_ms,
		"frost_range": frost_range,
		"frost_slow": frost_slow,
		"frost_slow_duration_ms": frost_slow_duration_ms,
		"frost_upgrade_t2": frost_upgrade_t2,
		"frost_upgrade_t3": frost_upgrade_t3,
		# Lightning
		"lightning_cost": lightning_cost,
		"lightning_damage": lightning_damage,
		"lightning_attack_speed_ms": lightning_attack_speed_ms,
		"lightning_range": lightning_range,
		"lightning_chain_count": lightning_chain_count,
		"lightning_chain_range": lightning_chain_range,
		"lightning_upgrade_t2": lightning_upgrade_t2,
		"lightning_upgrade_t3": lightning_upgrade_t3,
		# Flame
		"flame_cost": flame_cost,
		"flame_damage": flame_damage,
		"flame_attack_speed_ms": flame_attack_speed_ms,
		"flame_range": flame_range,
		"flame_burn_dps": flame_burn_dps,
		"flame_burn_duration_ms": flame_burn_duration_ms,
		"flame_upgrade_t2": flame_upgrade_t2,
		"flame_upgrade_t3": flame_upgrade_t3,
		# Grunt
		"grunt_hp": grunt_hp,
		"grunt_speed": grunt_speed,
		"grunt_gold": grunt_gold,
		# Runner
		"runner_hp": runner_hp,
		"runner_speed": runner_speed,
		"runner_gold": runner_gold,
		# Tank
		"tank_hp": tank_hp,
		"tank_speed": tank_speed,
		"tank_armor": tank_armor,
		"tank_gold": tank_gold,
		# Flyer
		"flyer_hp": flyer_hp,
		"flyer_speed": flyer_speed,
		"flyer_gold": flyer_gold,
		# Swarm
		"swarm_hp": swarm_hp,
		"swarm_speed": swarm_speed,
		"swarm_gold": swarm_gold,
		# Stealth
		"stealth_hp": stealth_hp,
		"stealth_speed": stealth_speed,
		"stealth_gold": stealth_gold,
		# Breaker
		"breaker_hp": breaker_hp,
		"breaker_speed": breaker_speed,
		"breaker_armor": breaker_armor,
		"breaker_gold": breaker_gold,
		"breaker_wall_damage": breaker_wall_damage,
		# Boss
		"boss_golem_hp": boss_golem_hp,
		"boss_golem_speed": boss_golem_speed,
		"boss_golem_armor": boss_golem_armor,
		"boss_golem_gold": boss_golem_gold,
		"boss_golem_regen": boss_golem_regen,
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


func from_dict(d: Dictionary) -> void:
	# Economy
	if d.has("starting_gold"):
		starting_gold = d.starting_gold
	if d.has("wall_cost"):
		wall_cost = d.wall_cost
	if d.has("sell_rate_percent"):
		sell_rate_percent = d.sell_rate_percent
	# Archer
	if d.has("archer_cost"):
		archer_cost = d.archer_cost
	if d.has("archer_damage"):
		archer_damage = d.archer_damage
	if d.has("archer_attack_speed_ms"):
		archer_attack_speed_ms = d.archer_attack_speed_ms
	if d.has("archer_range"):
		archer_range = d.archer_range
	if d.has("archer_upgrade_t2"):
		archer_upgrade_t2 = d.archer_upgrade_t2
	if d.has("archer_upgrade_t3"):
		archer_upgrade_t3 = d.archer_upgrade_t3
	# Cannon
	if d.has("cannon_cost"):
		cannon_cost = d.cannon_cost
	if d.has("cannon_damage"):
		cannon_damage = d.cannon_damage
	if d.has("cannon_attack_speed_ms"):
		cannon_attack_speed_ms = d.cannon_attack_speed_ms
	if d.has("cannon_range"):
		cannon_range = d.cannon_range
	if d.has("cannon_aoe_radius"):
		cannon_aoe_radius = d.cannon_aoe_radius
	if d.has("cannon_upgrade_t2"):
		cannon_upgrade_t2 = d.cannon_upgrade_t2
	if d.has("cannon_upgrade_t3"):
		cannon_upgrade_t3 = d.cannon_upgrade_t3
	# Frost
	if d.has("frost_cost"):
		frost_cost = d.frost_cost
	if d.has("frost_damage"):
		frost_damage = d.frost_damage
	if d.has("frost_attack_speed_ms"):
		frost_attack_speed_ms = d.frost_attack_speed_ms
	if d.has("frost_range"):
		frost_range = d.frost_range
	if d.has("frost_slow"):
		frost_slow = d.frost_slow
	if d.has("frost_slow_duration_ms"):
		frost_slow_duration_ms = d.frost_slow_duration_ms
	if d.has("frost_upgrade_t2"):
		frost_upgrade_t2 = d.frost_upgrade_t2
	if d.has("frost_upgrade_t3"):
		frost_upgrade_t3 = d.frost_upgrade_t3
	# Lightning
	if d.has("lightning_cost"):
		lightning_cost = d.lightning_cost
	if d.has("lightning_damage"):
		lightning_damage = d.lightning_damage
	if d.has("lightning_attack_speed_ms"):
		lightning_attack_speed_ms = d.lightning_attack_speed_ms
	if d.has("lightning_range"):
		lightning_range = d.lightning_range
	if d.has("lightning_chain_count"):
		lightning_chain_count = d.lightning_chain_count
	if d.has("lightning_chain_range"):
		lightning_chain_range = d.lightning_chain_range
	if d.has("lightning_upgrade_t2"):
		lightning_upgrade_t2 = d.lightning_upgrade_t2
	if d.has("lightning_upgrade_t3"):
		lightning_upgrade_t3 = d.lightning_upgrade_t3
	# Flame
	if d.has("flame_cost"):
		flame_cost = d.flame_cost
	if d.has("flame_damage"):
		flame_damage = d.flame_damage
	if d.has("flame_attack_speed_ms"):
		flame_attack_speed_ms = d.flame_attack_speed_ms
	if d.has("flame_range"):
		flame_range = d.flame_range
	if d.has("flame_burn_dps"):
		flame_burn_dps = d.flame_burn_dps
	if d.has("flame_burn_duration_ms"):
		flame_burn_duration_ms = d.flame_burn_duration_ms
	if d.has("flame_upgrade_t2"):
		flame_upgrade_t2 = d.flame_upgrade_t2
	if d.has("flame_upgrade_t3"):
		flame_upgrade_t3 = d.flame_upgrade_t3
	# Grunt
	if d.has("grunt_hp"):
		grunt_hp = d.grunt_hp
	if d.has("grunt_speed"):
		grunt_speed = d.grunt_speed
	if d.has("grunt_gold"):
		grunt_gold = d.grunt_gold
	# Runner
	if d.has("runner_hp"):
		runner_hp = d.runner_hp
	if d.has("runner_speed"):
		runner_speed = d.runner_speed
	if d.has("runner_gold"):
		runner_gold = d.runner_gold
	# Tank
	if d.has("tank_hp"):
		tank_hp = d.tank_hp
	if d.has("tank_speed"):
		tank_speed = d.tank_speed
	if d.has("tank_armor"):
		tank_armor = d.tank_armor
	if d.has("tank_gold"):
		tank_gold = d.tank_gold
	# Flyer
	if d.has("flyer_hp"):
		flyer_hp = d.flyer_hp
	if d.has("flyer_speed"):
		flyer_speed = d.flyer_speed
	if d.has("flyer_gold"):
		flyer_gold = d.flyer_gold
	# Swarm
	if d.has("swarm_hp"):
		swarm_hp = d.swarm_hp
	if d.has("swarm_speed"):
		swarm_speed = d.swarm_speed
	if d.has("swarm_gold"):
		swarm_gold = d.swarm_gold
	# Stealth
	if d.has("stealth_hp"):
		stealth_hp = d.stealth_hp
	if d.has("stealth_speed"):
		stealth_speed = d.stealth_speed
	if d.has("stealth_gold"):
		stealth_gold = d.stealth_gold
	# Breaker
	if d.has("breaker_hp"):
		breaker_hp = d.breaker_hp
	if d.has("breaker_speed"):
		breaker_speed = d.breaker_speed
	if d.has("breaker_armor"):
		breaker_armor = d.breaker_armor
	if d.has("breaker_gold"):
		breaker_gold = d.breaker_gold
	if d.has("breaker_wall_damage"):
		breaker_wall_damage = d.breaker_wall_damage
	# Boss
	if d.has("boss_golem_hp"):
		boss_golem_hp = d.boss_golem_hp
	if d.has("boss_golem_speed"):
		boss_golem_speed = d.boss_golem_speed
	if d.has("boss_golem_armor"):
		boss_golem_armor = d.boss_golem_armor
	if d.has("boss_golem_gold"):
		boss_golem_gold = d.boss_golem_gold
	if d.has("boss_golem_regen"):
		boss_golem_regen = d.boss_golem_regen
	# Shrine
	if d.has("shrine_hp"):
		shrine_hp = d.shrine_hp
	if d.has("enemy_shrine_damage"):
		enemy_shrine_damage = d.enemy_shrine_damage
	# Waves
	if d.has("wave_spawn_interval_base_ms"):
		wave_spawn_interval_base_ms = d.wave_spawn_interval_base_ms
	if d.has("wave_spawn_interval_rush_ms"):
		wave_spawn_interval_rush_ms = d.wave_spawn_interval_rush_ms
	if d.has("wave_1_grunts"):
		wave_1_grunts = d.wave_1_grunts
	if d.has("wave_2_grunts"):
		wave_2_grunts = d.wave_2_grunts
	if d.has("wave_3_grunts"):
		wave_3_grunts = d.wave_3_grunts
	if d.has("wave_4_grunts"):
		wave_4_grunts = d.wave_4_grunts
	if d.has("wave_5_grunts"):
		wave_5_grunts = d.wave_5_grunts
	if d.has("wave_6_grunts"):
		wave_6_grunts = d.wave_6_grunts
	if d.has("wave_6_runners"):
		wave_6_runners = d.wave_6_runners
	if d.has("wave_7_grunts"):
		wave_7_grunts = d.wave_7_grunts
	if d.has("wave_7_runners"):
		wave_7_runners = d.wave_7_runners
	if d.has("wave_8_runners"):
		wave_8_runners = d.wave_8_runners
	if d.has("wave_9_grunts"):
		wave_9_grunts = d.wave_9_grunts
	if d.has("wave_9_runners"):
		wave_9_runners = d.wave_9_runners
	if d.has("wave_10_grunts"):
		wave_10_grunts = d.wave_10_grunts
	if d.has("wave_10_runners"):
		wave_10_runners = d.wave_10_runners


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
		# Economy
		"starting_gold": {"min": 50, "max": 300, "step": 10},
		"wall_cost": {"min": 5, "max": 30, "step": 5},
		"sell_rate_percent": {"min": 50, "max": 100, "step": 5},
		# Archer
		"archer_cost": {"min": 40, "max": 150, "step": 10},
		"archer_damage": {"min": 5000, "max": 50000, "step": 1000},
		"archer_attack_speed_ms": {"min": 200, "max": 2000, "step": 100},
		"archer_range": {"min": 3, "max": 10, "step": 1},
		"archer_upgrade_t2": {"min": 80, "max": 300, "step": 10},
		"archer_upgrade_t3": {"min": 150, "max": 500, "step": 25},
		# Cannon
		"cannon_cost": {"min": 60, "max": 200, "step": 10},
		"cannon_damage": {"min": 15000, "max": 60000, "step": 1000},
		"cannon_attack_speed_ms": {"min": 800, "max": 3000, "step": 100},
		"cannon_range": {"min": 2, "max": 6, "step": 1},
		"cannon_aoe_radius": {"min": 500, "max": 3000, "step": 100},
		"cannon_upgrade_t2": {"min": 100, "max": 400, "step": 20},
		"cannon_upgrade_t3": {"min": 200, "max": 600, "step": 25},
		# Frost
		"frost_cost": {"min": 50, "max": 180, "step": 10},
		"frost_damage": {"min": 3000, "max": 20000, "step": 1000},
		"frost_attack_speed_ms": {"min": 300, "max": 1500, "step": 100},
		"frost_range": {"min": 2, "max": 7, "step": 1},
		"frost_slow": {"min": 100, "max": 700, "step": 50},
		"frost_slow_duration_ms": {"min": 1000, "max": 5000, "step": 250},
		"frost_upgrade_t2": {"min": 90, "max": 350, "step": 15},
		"frost_upgrade_t3": {"min": 175, "max": 550, "step": 25},
		# Lightning
		"lightning_cost": {"min": 80, "max": 250, "step": 10},
		"lightning_damage": {"min": 5000, "max": 30000, "step": 1000},
		"lightning_attack_speed_ms": {"min": 600, "max": 2500, "step": 100},
		"lightning_range": {"min": 3, "max": 8, "step": 1},
		"lightning_chain_count": {"min": 1, "max": 8, "step": 1},
		"lightning_chain_range": {"min": 1.0, "max": 5.0, "step": 0.5},
		"lightning_upgrade_t2": {"min": 110, "max": 400, "step": 20},
		"lightning_upgrade_t3": {"min": 225, "max": 650, "step": 25},
		# Flame
		"flame_cost": {"min": 50, "max": 160, "step": 10},
		"flame_damage": {"min": 2000, "max": 15000, "step": 1000},
		"flame_attack_speed_ms": {"min": 200, "max": 1000, "step": 50},
		"flame_range": {"min": 2, "max": 5, "step": 1},
		"flame_burn_dps": {"min": 3000, "max": 25000, "step": 1000},
		"flame_burn_duration_ms": {"min": 1000, "max": 8000, "step": 500},
		"flame_upgrade_t2": {"min": 80, "max": 320, "step": 20},
		"flame_upgrade_t3": {"min": 160, "max": 500, "step": 25},
		# Grunt
		"grunt_hp": {"min": 20, "max": 150, "step": 5},
		"grunt_speed": {"min": 500, "max": 2000, "step": 100},
		"grunt_gold": {"min": 2, "max": 15, "step": 1},
		# Runner
		"runner_hp": {"min": 15, "max": 100, "step": 5},
		"runner_speed": {"min": 1000, "max": 3000, "step": 100},
		"runner_gold": {"min": 3, "max": 20, "step": 1},
		# Tank
		"tank_hp": {"min": 150, "max": 600, "step": 25},
		"tank_speed": {"min": 300, "max": 1000, "step": 50},
		"tank_armor": {"min": 100, "max": 500, "step": 25},
		"tank_gold": {"min": 10, "max": 50, "step": 5},
		# Flyer
		"flyer_hp": {"min": 20, "max": 100, "step": 5},
		"flyer_speed": {"min": 800, "max": 2000, "step": 100},
		"flyer_gold": {"min": 5, "max": 25, "step": 1},
		# Swarm
		"swarm_hp": {"min": 5, "max": 40, "step": 5},
		"swarm_speed": {"min": 800, "max": 2000, "step": 100},
		"swarm_gold": {"min": 1, "max": 8, "step": 1},
		# Stealth
		"stealth_hp": {"min": 25, "max": 100, "step": 5},
		"stealth_speed": {"min": 1000, "max": 2200, "step": 100},
		"stealth_gold": {"min": 8, "max": 30, "step": 1},
		# Breaker
		"breaker_hp": {"min": 100, "max": 350, "step": 25},
		"breaker_speed": {"min": 400, "max": 1200, "step": 50},
		"breaker_armor": {"min": 100, "max": 400, "step": 25},
		"breaker_gold": {"min": 10, "max": 40, "step": 5},
		"breaker_wall_damage": {"min": 10, "max": 50, "step": 5},
		# Boss Golem
		"boss_golem_hp": {"min": 800, "max": 3000, "step": 100},
		"boss_golem_speed": {"min": 200, "max": 700, "step": 50},
		"boss_golem_armor": {"min": 200, "max": 600, "step": 50},
		"boss_golem_gold": {"min": 50, "max": 200, "step": 10},
		"boss_golem_regen": {"min": 2000, "max": 10000, "step": 500},
		# Shrine
		"shrine_hp": {"min": 50, "max": 200, "step": 10},
		"enemy_shrine_damage": {"min": 1, "max": 5, "step": 1},
		# Waves
		"wave_spawn_interval_base_ms": {"min": 400, "max": 1500, "step": 100},
		"wave_spawn_interval_rush_ms": {"min": 100, "max": 500, "step": 50},
	}
