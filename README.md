# Bastion's Last Stand

Tower defense game with dynamic maze building and deep tower upgrade trees. Built with Godot 4.3.

## Quick Start

1. Open project in Godot 4.3+
2. Run `main.tscn`

## Development Setup

### Requirements

- Godot 4.3+
- Python 3.9+ (for linting/balance AI)

### Linting

```bash
# Install gdtoolkit
python -m venv .venv
source .venv/bin/activate  # Windows: .venv\Scripts\activate
pip install -r requirements-dev.txt

# Format GDScript
gdformat simulation/ tests/ resources/ maps/ ui/ game/ main.gd

# Lint GDScript
gdlint simulation/ tests/ resources/ maps/ ui/ game/ main.gd

# Install pre-commit hooks
pre-commit install
```

### Testing

```bash
# Run GUT tests (headless)
godot --headless -s addons/gut/gut_cmdln.gd -gdir=res://tests -gexit
```

## Project Structure

```
├── simulation/      # Core game simulation (headless, testable)
│   ├── core/        # GameState, BalanceConfig, TickProcessor
│   ├── systems/     # Combat, Economy, Pathfinding, Targeting
│   ├── entities/    # SimTower, SimEnemy, SimGroundEffect
│   ├── ai/          # AI player for balance testing
│   └── runner/      # SimulationRunner for batch testing
├── game/            # Game managers and autoloads
├── tests/           # GUT unit/integration tests
├── ui/              # UI screens and components
├── resources/       # Game data (towers, enemies, waves)
├── maps/            # Map definitions
├── balance_ai/      # Python AI for auto-balance tuning
└── addons/          # GUT testing framework
```

## Documentation

- [Game Design Document](Bastion_Last_Stand_GDD.md)
- [Art Direction](Bastion_Art_Direction.md)
- [Simulation System](Bastion_Simulation_System.md)
- [Balance AI](balance_ai/README.md)

## License

Proprietary - All rights reserved
