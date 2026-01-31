# Bastion's Last Stand
## Simulation & Balance Testing System

---

## 1. System Overview

### 1.1 Goals

1. **Rapid iteration** - Test balance changes in minutes, not hours
2. **Data-driven decisions** - Graphs and metrics, not gut feelings
3. **Regression testing** - Ensure changes don't break existing balance
4. **AI strategies** - Test multiple playstyles automatically
5. **Edge case discovery** - Find exploits and broken combos

### 1.2 Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                    BALANCE TESTING PIPELINE                      │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐       │
│  │   CONFIG     │    │  SIMULATION  │    │   ANALYSIS   │       │
│  │              │───▶│    ENGINE    │───▶│              │       │
│  │ - Tower stats│    │              │    │ - Win rates  │       │
│  │ - Enemy stats│    │ - Headless   │    │ - Economy    │       │
│  │ - Wave data  │    │ - Or Visual  │    │ - Tower picks│       │
│  │ - AI profiles│    │              │    │ - Difficulty │       │
│  └──────────────┘    └──────────────┘    └──────────────┘       │
│         │                   │                   │                │
│         │                   ▼                   │                │
│         │           ┌──────────────┐            │                │
│         │           │   AI PLAYER  │            │                │
│         │           │              │            │                │
│         │           │ - Strategies │            │                │
│         │           │ - Decisions  │            │                │
│         │           └──────────────┘            │                │
│         │                                       │                │
│         └───────────────────────────────────────┘                │
│                    FEEDBACK LOOP                                 │
│            (Auto-adjust based on results)                        │
└─────────────────────────────────────────────────────────────────┘
```

---

## 2. Headless Simulation Engine

### 2.1 Core Concept

Strip the game down to pure math. No rendering, no physics engine - just:
- Enemy spawning and movement (simple pathfinding on grid)
- Tower targeting and damage calculations
- Economy tracking
- Win/loss conditions

### 2.2 Simplified Game State

```gdscript
# simulation/game_state.gd
class_name SimGameState

var wave: int = 0
var gold: int = 200
var shrine_hp: int = 100
var towers: Array[SimTower] = []
var walls: Array[Vector2i] = []
var enemies: Array[SimEnemy] = []
var path_cache: Dictionary = {}  # spawn_point -> path array

# Simulation tick (represents ~0.1 seconds of game time)
func tick(delta: float = 0.1):
    # 1. Enemies move along cached paths
    for enemy in enemies:
        enemy.move(delta, path_cache)
        if enemy.reached_shrine():
            shrine_hp -= enemy.damage
            enemy.queue_free()
    
    # 2. Towers attack
    for tower in towers:
        tower.cooldown -= delta
        if tower.cooldown <= 0:
            var target = tower.find_target(enemies)
            if target:
                tower.attack(target)
                tower.cooldown = tower.attack_speed
    
    # 3. Process enemy deaths
    for enemy in enemies:
        if enemy.hp <= 0:
            gold += enemy.gold_value
            enemies.erase(enemy)
    
    # 4. Check win/loss
    if shrine_hp <= 0:
        return SimResult.LOSS
    if enemies.is_empty() and wave_complete:
        return SimResult.WAVE_CLEAR
    
    return SimResult.ONGOING
```

### 2.3 Simplified Pathfinding

For headless simulation, use a simplified A* that pre-computes paths:

```gdscript
# simulation/pathfinding.gd
class_name SimPathfinding

var grid: Array[Array]  # 2D array of bools (true = walkable)
var width: int
var height: int

func find_path(start: Vector2i, goal: Vector2i) -> Array[Vector2i]:
    # Standard A* implementation
    var open_set = [start]
    var came_from = {}
    var g_score = {start: 0}
    var f_score = {start: heuristic(start, goal)}
    
    while not open_set.is_empty():
        var current = get_lowest_f(open_set, f_score)
        
        if current == goal:
            return reconstruct_path(came_from, current)
        
        open_set.erase(current)
        
        for neighbor in get_neighbors(current):
            var tentative_g = g_score[current] + 1
            
            if tentative_g < g_score.get(neighbor, INF):
                came_from[neighbor] = current
                g_score[neighbor] = tentative_g
                f_score[neighbor] = tentative_g + heuristic(neighbor, goal)
                
                if neighbor not in open_set:
                    open_set.append(neighbor)
    
    return []  # No path found - enemies will attack walls

func heuristic(a: Vector2i, b: Vector2i) -> float:
    return abs(a.x - b.x) + abs(a.y - b.y)  # Manhattan distance
```

### 2.4 Data Structures

```gdscript
# simulation/sim_tower.gd
class_name SimTower

var position: Vector2i
var type: String  # "archer", "cannon", etc.
var tier: int = 1
var branch: String = ""  # "A", "B", "A1", "A2", etc.

# Stats (loaded from config)
var damage: float
var attack_speed: float
var range_tiles: int
var aoe_radius: float = 0
var special: Dictionary = {}

var cooldown: float = 0
var total_damage_dealt: float = 0  # For analytics

func find_target(enemies: Array[SimEnemy]) -> SimEnemy:
    var in_range = enemies.filter(func(e): 
        return position.distance_to(e.grid_pos) <= range_tiles
    )
    if in_range.is_empty():
        return null
    # Default: First (furthest along path)
    return in_range.reduce(func(a, b): 
        return a if a.path_progress > b.path_progress else b
    )

func attack(target: SimEnemy):
    if aoe_radius > 0:
        # AOE damage
        for enemy in get_enemies_in_radius(target.position, aoe_radius):
            enemy.take_damage(damage)
            total_damage_dealt += damage
    else:
        target.take_damage(damage)
        total_damage_dealt += damage
```

```gdscript
# simulation/sim_enemy.gd
class_name SimEnemy

var type: String
var hp: float
var max_hp: float
var speed: float
var armor: float
var gold_value: int
var grid_pos: Vector2
var path_index: int = 0
var path_progress: float = 0  # 0-1 along total path

func move(delta: float, path: Array[Vector2i]):
    if path_index >= path.size():
        return  # Reached shrine
    
    var target = Vector2(path[path_index])
    var direction = (target - grid_pos).normalized()
    grid_pos += direction * speed * delta
    
    if grid_pos.distance_to(target) < 0.1:
        path_index += 1
        path_progress = float(path_index) / path.size()

func take_damage(amount: float):
    var effective_damage = amount * (1.0 - armor)
    hp -= effective_damage

func reached_shrine() -> bool:
    return path_index >= path.size() - 1
```

### 2.5 Running Simulations

```gdscript
# simulation/simulation_runner.gd
class_name SimulationRunner

signal simulation_complete(results: SimulationResults)

var config: SimulationConfig
var ai_player: AIPlayer

func run_batch(num_games: int, config: SimulationConfig) -> Array[SimulationResults]:
    var all_results = []
    
    for i in range(num_games):
        var game = SimGameState.new()
        game.load_config(config)
        
        var ai = ai_player.duplicate()
        var result = run_single_game(game, ai)
        all_results.append(result)
        
        # Progress callback
        if i % 100 == 0:
            print("Completed %d / %d simulations" % [i, num_games])
    
    return all_results

func run_single_game(game: SimGameState, ai: AIPlayer) -> SimulationResults:
    var results = SimulationResults.new()
    results.start_time = Time.get_ticks_msec()
    
    for wave in range(1, 31):  # 30 waves
        game.start_wave(wave)
        
        # AI makes decisions at wave start
        ai.make_decisions(game)
        
        # Run wave until complete
        while true:
            var tick_result = game.tick(0.1)
            
            if tick_result == SimResult.LOSS:
                results.outcome = "loss"
                results.final_wave = wave
                results.shrine_hp = game.shrine_hp
                break
            elif tick_result == SimResult.WAVE_CLEAR:
                break
        
        if results.outcome == "loss":
            break
        
        # Record wave stats
        results.wave_stats.append({
            "wave": wave,
            "gold": game.gold,
            "shrine_hp": game.shrine_hp,
            "towers": game.towers.size(),
            "tower_types": get_tower_breakdown(game.towers)
        })
    
    if results.outcome != "loss":
        results.outcome = "win"
        results.final_wave = 30
    
    results.end_time = Time.get_ticks_msec()
    results.total_damage_dealt = game.towers.reduce(func(sum, t): 
        return sum + t.total_damage_dealt, 0
    )
    
    return results
```

---

## 3. AI Player System

### 3.1 AI Strategy Profiles

Different AI profiles test different playstyles:

```gdscript
# simulation/ai_player.gd
class_name AIPlayer

enum Strategy {
    BALANCED,      # Mix of everything
    RUSH_DEFENSE,  # Lots of cheap towers early
    ECONOMY,       # Banks gold, interest, late power spike
    AOE_FOCUS,     # Prioritizes splash damage
    SINGLE_TARGET, # Prioritizes DPS towers
    MAZE_BUILDER,  # Heavy wall investment
    MINIMAL_WALLS, # Open field, tower DPS only
    RANDOM,        # Random valid choices (baseline)
    OPTIMAL,       # Uses heuristics for "best" plays
}

var strategy: Strategy
var aggression: float = 0.5  # 0 = passive, 1 = aggressive spending

func make_decisions(game: SimGameState):
    match strategy:
        Strategy.BALANCED:
            balanced_decision(game)
        Strategy.AOE_FOCUS:
            aoe_focus_decision(game)
        Strategy.OPTIMAL:
            optimal_decision(game)
        # ... etc
```

### 3.2 Example AI Strategies

```gdscript
# Balanced AI - tries to maintain good coverage
func balanced_decision(game: SimGameState):
    var gold = game.gold
    
    # Priority 1: Ensure path exists (walls)
    if should_build_walls(game):
        var wall_pos = find_optimal_wall_position(game)
        if wall_pos and gold >= 25:
            game.place_wall(wall_pos)
            gold -= 25
    
    # Priority 2: Build towers for coverage
    var uncovered = find_uncovered_path_sections(game)
    if not uncovered.is_empty() and gold >= 100:
        var tower_type = pick_tower_for_situation(game, uncovered[0])
        var pos = find_tower_position_near(game, uncovered[0])
        if pos:
            game.place_tower(pos, tower_type)
            gold -= get_tower_cost(tower_type)
    
    # Priority 3: Upgrade existing towers
    if gold >= 150:
        var best_upgrade = find_best_upgrade(game)
        if best_upgrade:
            game.upgrade_tower(best_upgrade.tower, best_upgrade.branch)

# AOE Focus AI - prioritizes splash damage
func aoe_focus_decision(game: SimGameState):
    var gold = game.gold
    var tower_priority = ["cannon", "lightning", "flame", "frost", "archer"]
    
    # Always try to build/upgrade AOE towers first
    for tower_type in tower_priority:
        if can_afford(tower_type, gold):
            var pos = find_choke_point(game)  # AOE loves choke points
            if pos:
                game.place_tower(pos, tower_type)
                return

# Optimal AI - uses scoring heuristics
func optimal_decision(game: SimGameState):
    var all_actions = generate_all_valid_actions(game)
    var best_action = null
    var best_score = -INF
    
    for action in all_actions:
        var score = evaluate_action(game, action)
        if score > best_score:
            best_score = score
            best_action = action
    
    if best_action:
        execute_action(game, best_action)

func evaluate_action(game: SimGameState, action: Dictionary) -> float:
    var score = 0.0
    
    match action.type:
        "place_tower":
            # Score based on: coverage, synergy, cost efficiency
            score += coverage_score(game, action.position, action.tower_type)
            score += synergy_score(game, action.position, action.tower_type)
            score -= action.cost / 100.0  # Penalize expensive options slightly
        
        "upgrade_tower":
            # Score based on: DPS increase per gold
            var dps_increase = calculate_dps_increase(action.tower, action.branch)
            score += dps_increase / action.cost * 100
        
        "place_wall":
            # Score based on: path length increase
            var path_increase = calculate_path_increase(game, action.position)
            score += path_increase * 10
    
    return score
```

### 3.3 AI Decision Points

The AI makes decisions at specific moments:

| Trigger | AI Action |
|---------|-----------|
| Wave start (build phase) | Place towers, walls, upgrades |
| Gold threshold reached | Consider purchases mid-wave |
| Tower destroyed | Rebuild or adapt |
| Wall breached | Emergency response |

---

## 4. Metrics & Analysis

### 4.1 Data Collection

```gdscript
# simulation/simulation_results.gd
class_name SimulationResults

# Outcome
var outcome: String  # "win" or "loss"
var final_wave: int
var shrine_hp: int

# Timing
var start_time: int
var end_time: int
var total_ticks: int

# Economy
var total_gold_earned: int
var total_gold_spent: int
var gold_efficiency: float  # damage dealt per gold spent

# Towers
var towers_built: Dictionary  # {type: count}
var towers_upgraded: Dictionary  # {type_tier: count}
var tower_damage_breakdown: Dictionary  # {tower_id: damage}
var most_effective_tower: String

# Enemies
var enemies_killed: int
var enemies_leaked: int
var damage_taken_by_type: Dictionary  # {enemy_type: damage}

# Waves
var wave_stats: Array[Dictionary]
var hardest_wave: int  # Wave with most damage taken
var closest_call: int  # Lowest shrine HP reached

# Per-wave breakdown
var per_wave_data: Array[Dictionary]
# Each entry: {wave, gold, towers, enemies_spawned, enemies_killed, damage_taken}
```

### 4.2 Aggregate Analysis

```gdscript
# simulation/analysis.gd
class_name SimulationAnalysis

static func analyze_batch(results: Array[SimulationResults]) -> Dictionary:
    var analysis = {}
    
    # Win rate
    var wins = results.filter(func(r): return r.outcome == "win")
    analysis["win_rate"] = float(wins.size()) / results.size()
    
    # Average final wave (for losses)
    var losses = results.filter(func(r): return r.outcome == "loss")
    if not losses.is_empty():
        analysis["avg_loss_wave"] = losses.reduce(func(sum, r): 
            return sum + r.final_wave, 0) / losses.size()
    
    # Tower popularity
    var tower_counts = {}
    for result in results:
        for tower_type in result.towers_built:
            tower_counts[tower_type] = tower_counts.get(tower_type, 0) + result.towers_built[tower_type]
    analysis["tower_popularity"] = tower_counts
    
    # Tower effectiveness (damage per gold)
    var tower_efficiency = {}
    for result in results:
        for tower_id in result.tower_damage_breakdown:
            var tower = get_tower_from_id(tower_id)
            var efficiency = result.tower_damage_breakdown[tower_id] / tower.total_cost
            var key = tower.type + "_" + tower.tier
            if key not in tower_efficiency:
                tower_efficiency[key] = []
            tower_efficiency[key].append(efficiency)
    
    # Average efficiency per tower type
    for key in tower_efficiency:
        analysis["tower_efficiency_" + key] = average(tower_efficiency[key])
    
    # Difficulty curve (damage taken per wave)
    var wave_difficulty = {}
    for result in results:
        for wave_stat in result.wave_stats:
            var wave = wave_stat.wave
            if wave not in wave_difficulty:
                wave_difficulty[wave] = []
            wave_difficulty[wave].append(100 - wave_stat.shrine_hp)
    
    analysis["difficulty_curve"] = {}
    for wave in wave_difficulty:
        analysis["difficulty_curve"][wave] = average(wave_difficulty[wave])
    
    return analysis
```

### 4.3 Key Metrics to Track

| Metric | Target | Warning Signs |
|--------|--------|---------------|
| **Win Rate (Optimal AI)** | 85-95% | <70% = too hard, >98% = too easy |
| **Win Rate (Random AI)** | 10-30% | <5% = too hard, >50% = too easy |
| **Average Loss Wave** | 20-25 | <15 = early spike, >28 = only final boss hard |
| **Tower Type Usage** | Even spread | Any tower <5% = weak, >40% = OP |
| **Upgrade Path Usage** | Even per branch | One branch dominant = imbalanced |
| **Gold at Win** | 0-200 | >500 = economy too generous |
| **Hardest Wave** | Varied | Same wave always = spike |
| **Shrine HP at Win** | 30-70 avg | <20 = barely surviving, >90 = too easy |

---

## 5. Visual Simulation Mode

### 5.1 Accelerated Playback

For debugging and validation, run the actual game at high speed:

```gdscript
# game/debug/accelerated_simulation.gd
extends Node

var ai_player: AIPlayer
var speed_multiplier: float = 20.0
var is_simulating: bool = false

func _ready():
    if OS.has_feature("simulation"):
        start_simulation()

func start_simulation():
    is_simulating = true
    Engine.time_scale = speed_multiplier
    ai_player = AIPlayer.new()
    ai_player.strategy = AIPlayer.Strategy.OPTIMAL

func _process(_delta):
    if not is_simulating:
        return
    
    # AI makes decisions during build phase
    if GameManager.phase == GameManager.Phase.BUILD:
        ai_player.make_decisions(GameManager.get_state())
        
        # Auto-start wave
        await get_tree().create_timer(0.1).timeout  # Brief pause
        GameManager.start_wave()

func _on_game_over(won: bool):
    Engine.time_scale = 1.0
    is_simulating = false
    
    # Log results
    var results = collect_results()
    save_results(results)
```

### 5.2 Replay Recording

Record games for later analysis:

```gdscript
# game/debug/replay_recorder.gd
class_name ReplayRecorder

var recording: Array[Dictionary] = []
var current_tick: int = 0

func record_action(action: Dictionary):
    recording.append({
        "tick": current_tick,
        "action": action
    })

func record_state(state: Dictionary):
    recording.append({
        "tick": current_tick,
        "state": state
    })

func save_replay(filename: String):
    var file = FileAccess.open("user://replays/" + filename, FileAccess.WRITE)
    file.store_var(recording)
    file.close()

func load_replay(filename: String) -> Array[Dictionary]:
    var file = FileAccess.open("user://replays/" + filename, FileAccess.READ)
    var data = file.get_var()
    file.close()
    return data
```

---

## 6. Balance Testing Workflows

### 6.1 New Tower Testing

When adding or changing a tower:

```
1. Update tower config (stats, costs)
2. Run 1000 headless simulations with OPTIMAL AI
3. Check metrics:
   - Is the tower being used? (>10% of games)
   - Is it dominant? (<35% of total damage)
   - Are both upgrade branches viable? (within 20% usage)
4. Run 100 visual simulations to check edge cases
5. Adjust and repeat
```

### 6.2 Wave Difficulty Tuning

```
1. Run 1000 simulations, collect per-wave damage
2. Plot difficulty curve
3. Identify spikes (waves with >2x average damage)
4. Adjust enemy composition for smooth curve
5. Verify Rush/Smash rounds are challenging but fair
```

### 6.3 Economy Balance

```
1. Run simulations with different starting gold (100, 200, 300)
2. Run with different kill rewards (±20%)
3. Find sweet spot where:
   - Players can afford 2-3 towers by wave 5
   - Players feel resource pressure waves 10-20
   - Late game has meaningful upgrade choices
```

### 6.4 Automated Regression Testing

```gdscript
# tests/balance_regression.gd
extends GutTest

func test_optimal_ai_win_rate():
    var results = SimulationRunner.run_batch(1000, default_config, AIPlayer.Strategy.OPTIMAL)
    var analysis = SimulationAnalysis.analyze_batch(results)
    
    assert_between(analysis.win_rate, 0.85, 0.95, 
        "Optimal AI win rate should be 85-95%")

func test_tower_balance():
    var results = SimulationRunner.run_batch(1000, default_config, AIPlayer.Strategy.OPTIMAL)
    var analysis = SimulationAnalysis.analyze_batch(results)
    
    for tower_type in ["archer", "cannon", "frost", "lightning", "flame", "support"]:
        var usage = analysis.tower_popularity.get(tower_type, 0)
        assert_gt(usage, 50, "Tower %s should be used in >5%% of games" % tower_type)
        assert_lt(usage, 400, "Tower %s should not dominate (>40%%)" % tower_type)

func test_no_impossible_waves():
    var results = SimulationRunner.run_batch(100, default_config, AIPlayer.Strategy.OPTIMAL)
    
    for result in results:
        if result.outcome == "loss":
            assert_gt(result.final_wave, 5, 
                "Optimal AI should never lose before wave 5")
```

---

## 7. External Tools Integration

### 7.1 Export to CSV for Spreadsheet Analysis

```gdscript
func export_results_csv(results: Array[SimulationResults], filename: String):
    var file = FileAccess.open(filename, FileAccess.WRITE)
    
    # Header
    file.store_line("game_id,outcome,final_wave,shrine_hp,gold_earned,gold_spent,towers_built,damage_dealt")
    
    # Data
    for i in range(results.size()):
        var r = results[i]
        file.store_line("%d,%s,%d,%d,%d,%d,%d,%d" % [
            i, r.outcome, r.final_wave, r.shrine_hp,
            r.total_gold_earned, r.total_gold_spent,
            r.towers_built.values().reduce(func(a,b): return a+b, 0),
            r.total_damage_dealt
        ])
    
    file.close()
```

### 7.2 Visualization with Python

```python
# analysis/visualize_balance.py
import pandas as pd
import matplotlib.pyplot as plt

# Load simulation results
df = pd.read_csv('simulation_results.csv')

# Win rate by AI strategy
win_rates = df.groupby('ai_strategy')['outcome'].apply(
    lambda x: (x == 'win').mean()
)
win_rates.plot(kind='bar', title='Win Rate by AI Strategy')
plt.savefig('win_rates.png')

# Difficulty curve
wave_damage = df.groupby('final_wave')['damage_taken'].mean()
wave_damage.plot(title='Average Damage Taken by Wave')
plt.savefig('difficulty_curve.png')

# Tower popularity
tower_cols = [c for c in df.columns if c.startswith('tower_')]
tower_usage = df[tower_cols].sum()
tower_usage.plot(kind='pie', title='Tower Usage Distribution')
plt.savefig('tower_popularity.png')
```

### 7.3 CI/CD Integration

```yaml
# .github/workflows/balance_test.yml
name: Balance Regression Tests

on:
  push:
    paths:
      - 'resources/tower_data/**'
      - 'resources/enemy_data/**'
      - 'resources/wave_data/**'

jobs:
  balance-test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Setup Godot
        uses: chickensoft-games/setup-godot@v1
        with:
          version: 4.6
      
      - name: Run Balance Tests
        run: godot --headless --script tests/run_balance_tests.gd
      
      - name: Upload Results
        uses: actions/upload-artifact@v3
        with:
          name: balance-results
          path: test_results/
```

---

## 8. Quick Start Guide

### 8.1 Running Your First Simulation

```gdscript
# In Godot editor, create a new scene with this script:

extends Node

func _ready():
    print("Starting balance simulation...")
    
    # Load default config
    var config = SimulationConfig.new()
    config.load_defaults()
    
    # Create AI player
    var ai = AIPlayer.new()
    ai.strategy = AIPlayer.Strategy.BALANCED
    
    # Run simulations
    var runner = SimulationRunner.new()
    var results = runner.run_batch(100, config)
    
    # Analyze
    var analysis = SimulationAnalysis.analyze_batch(results)
    
    # Print summary
    print("=== SIMULATION RESULTS ===")
    print("Win Rate: %.1f%%" % [analysis.win_rate * 100])
    print("Avg Loss Wave: %.1f" % [analysis.get("avg_loss_wave", 0)])
    print("Tower Popularity: ", analysis.tower_popularity)
    print("========================")
```

### 8.2 Testing a Specific Change

```gdscript
# Example: Testing if buffing Archer damage by 20% breaks balance

func test_archer_buff():
    var base_config = SimulationConfig.new()
    base_config.load_defaults()
    
    var buffed_config = base_config.duplicate()
    buffed_config.tower_stats["archer"]["damage"] *= 1.2
    
    var base_results = SimulationRunner.run_batch(500, base_config)
    var buffed_results = SimulationRunner.run_batch(500, buffed_config)
    
    var base_analysis = SimulationAnalysis.analyze_batch(base_results)
    var buffed_analysis = SimulationAnalysis.analyze_batch(buffed_results)
    
    print("Base win rate: %.1f%%" % [base_analysis.win_rate * 100])
    print("Buffed win rate: %.1f%%" % [buffed_analysis.win_rate * 100])
    print("Archer usage base: %d" % base_analysis.tower_popularity.get("archer", 0))
    print("Archer usage buffed: %d" % buffed_analysis.tower_popularity.get("archer", 0))
```

---

## 9. Advanced: Machine Learning Integration (Future)

### 9.1 Reinforcement Learning AI

For even more sophisticated testing, train an RL agent:

```python
# ml/train_agent.py (using stable-baselines3)
from stable_baselines3 import PPO
from godot_gym_env import TowerDefenseEnv

env = TowerDefenseEnv()
model = PPO("MlpPolicy", env, verbose=1)
model.learn(total_timesteps=1_000_000)
model.save("tower_defense_agent")
```

### 9.2 Genetic Algorithm for Balance

Automatically find balanced parameters:

```python
# ml/genetic_balance.py
def fitness(params):
    """Run simulations with params, return fitness score"""
    config = create_config(params)
    results = run_simulations(config, n=100)
    
    # Fitness = close to 85% win rate + even tower usage
    win_rate_score = 1.0 - abs(results.win_rate - 0.85)
    balance_score = calculate_tower_balance(results)
    
    return win_rate_score * 0.7 + balance_score * 0.3

# Evolve parameters over generations
best_params = genetic_algorithm(
    fitness_fn=fitness,
    param_ranges=TOWER_STAT_RANGES,
    generations=100,
    population=50
)
```

---

*Simulation System Document v1.0 - January 2026*
*For use with Bastion's Last Stand*
