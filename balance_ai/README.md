# Balance AI Optimizer

AI-powered balance tuning for Bastion's Last Stand using Claude Haiku.

## Quick Start

```bash
cd balance_ai
uv sync
cp .env.example .env  # add ANTHROPIC_API_KEY
uv run python optimizer.py --goal "Achieve 100% win rate with 85-95 shrine HP"
```

## How It Works

1. Runs Godot headless simulation with current `balance_config.json`
2. Sends results to Claude Haiku for analysis
3. Haiku recommends parameter changes
4. Applies changes and repeats until targets met or max iterations

## Current Balanced Config

```
Starting Gold: 175    Archer: 80g, 24 dmg, 600ms, 5 range
Grunt: 45 HP, 900 speed    Runner: 30 HP, 1600 speed
Shrine: 100 HP
```

## Strategy Results

| Strategy | Win Rate | Shrine HP | Leaked |
|----------|----------|-----------|--------|
| A - DualTower | 100% | 93 | 7 |
| B - TripleTower | 100% | 95 | 5 |
| C - Flanking | 100% | 92 | 8 |
| D - CentralDefense | 100% | 37 | 63 |

## Board Layouts

```
Strategy A: DualTower          Strategy B: TripleTower
  0 1 2 3 4 5 6 7 8 9            0 1 2 3 4 5 6 7 8 9
0|. . S . . . . S . .          0|. . S . . . . S . .
1|. . . . . . . . . .          1|. . . . . . . . . .
2|. . . T . . T . . .          2|. . . . T . . . . .
3|. . . . . . . . . .          3|. . . T . . T . . .
4|. . . . X X . . . .          4|. . . . X X . . . .

Strategy C: Flanking           Strategy D: CentralDefense
  0 1 2 3 4 5 6 7 8 9            0 1 2 3 4 5 6 7 8 9
0|. . S . . . . S . .          0|. . S . . . . S . .
1|. . . . . . . . . .          1|. . . . . . . . . .
2|. T . . . . . . T .          2|. . . . . . . . . .
3|. . . . . . . . . .          3|. . . . . . . . . .
4|. . . . X X . . . .          4|. . . T X X T . . .

Legend: S=Spawn T=Tower X=Shrine .=Empty
```

## Files

- `optimizer.py` - main entry point
- `haiku_client.py` - Claude API wrapper
- `simulation_runner.py` - runs Godot subprocess
- `config_manager.py` - reads/writes balance_config.json
- `logger.py` - logging with board visualization
- `prompts.py` - Haiku prompt templates
- `results/` - logs and iteration data

## CLI Options

```
--goal TEXT           Target description for Haiku
--max-iterations N    Max optimization loops (default: 10)
--runs N              Simulations per strategy (default: 1000)
--dry-run             Skip Haiku calls, just run simulations
```

## Known Issues

- Simulation is deterministic (same seed = same result), so win rate is always 0% or 100% per strategy
- Haiku sometimes outputs wrong units (e.g. `24` instead of `24000` for damage x1000 fixed-point)
- Gold remaining target (0-20) is hard to hit; economy tends to snowball
