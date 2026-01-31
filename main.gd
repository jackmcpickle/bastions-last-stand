extends Node

## Main entry point for headless simulation
## Run with: godot --headless --script main.gd

func _ready() -> void:
	if OS.has_feature("editor"):
		# Running in editor - show info
		print("Bastion's Last Stand - Simulation Engine")
		print("Run with --headless for CLI mode")
		return
	
	# Parse command line args
	var args := OS.get_cmdline_args()
	
	if "--help" in args or "-h" in args:
		_print_help()
		get_tree().quit()
		return
	
	# Default: run a test simulation
	_run_test_simulation()
	get_tree().quit()


func _print_help() -> void:
	print("""
Bastion's Last Stand - Headless Simulation Engine

Usage:
  godot --headless --script main.gd [options]

Options:
  --help, -h      Show this help
  --count N       Number of simulations to run (default: 10)
  --seed N        Base random seed (default: 12345)
  --output FILE   Output results to CSV file

Examples:
  godot --headless --script main.gd --count 100 --seed 42
  godot --headless --script main.gd --output results.csv
""")


func _run_test_simulation() -> void:
	print("=================================")
	print("BASTION'S LAST STAND")
	print("Simulation Engine Test")
	print("=================================")
	print("")
	
	# Load data
	var map := TestMap.create()
	var waves := Waves1To10.create()
	var archer_data: TowerData = load("res://resources/towers/archer_tower.tres")
	var grunt_data: EnemyData = load("res://resources/enemies/grunt.tres")
	var runner_data: EnemyData = load("res://resources/enemies/runner.tres")
	
	print("Map: %s (%dx%d)" % [map.display_name, map.width, map.height])
	print("Waves: %d" % waves.get_total_waves())
	print("Towers: %s" % archer_data.display_name)
	print("Enemies: %s, %s" % [grunt_data.display_name, runner_data.display_name])
	print("")
	
	# Setup runner
	var runner := SimulationRunner.new()
	runner.setup(map, waves)
	runner.register_tower(archer_data)
	runner.register_enemy(grunt_data)
	runner.register_enemy(runner_data)
	
	# Define tower placements for test
	# Place 2 archers near the path to shrine
	var placements: Array[Dictionary] = [
		{pos = Vector2i(2, 2), id = "archer"},  # Near spawn point 1
		{pos = Vector2i(6, 2), id = "archer"},  # Near spawn point 2
	]
	
	print("Tower placements: %d archers" % placements.size())
	print("")
	
	# Run simulations
	var count := 10
	var base_seed := 12345
	
	# Parse args for count/seed
	var args := OS.get_cmdline_args()
	for i in range(args.size()):
		if args[i] == "--count" and i + 1 < args.size():
			count = int(args[i + 1])
		elif args[i] == "--seed" and i + 1 < args.size():
			base_seed = int(args[i + 1])
	
	print("Running %d simulations with seed %d..." % [count, base_seed])
	print("")
	
	var start_time := Time.get_ticks_msec()
	var results := runner.run_batch(count, base_seed, placements)
	var end_time := Time.get_ticks_msec()
	
	print("")
	print("Completed in %dms" % (end_time - start_time))
	print("")
	
	# Analyze and print
	var analysis := SimulationRunner.analyze_results(results)
	SimulationRunner.print_analysis(analysis)
	
	# Save to CSV if requested
	for i in range(args.size()):
		if args[i] == "--output" and i + 1 < args.size():
			var output_path: String = args[i + 1]
			var sim_results := SimulationResults.new()
			sim_results.game_results = results
			sim_results.analysis = analysis
			var err := sim_results.save_csv(output_path)
			if err == OK:
				print("Results saved to: %s" % output_path)
			else:
				print("Failed to save results: %s" % error_string(err))
	
	print("")
	print("Done!")
