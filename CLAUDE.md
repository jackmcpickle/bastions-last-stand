# GDScript Style Guide for Bastion's Last Stand

## Official Godot 4.x Guidelines

Follow [Godot GDScript Style Guide](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_styleguide.html).

Key points:
- Use tabs for indentation
- Max 100 characters per line
- snake_case for functions/variables, PascalCase for classes
- Private members prefixed with `_`

## Class Organization Order

Standard order enforced by `class-definitions-order`:

```gdscript
@tool                           # tools
class_name MyClass              # classnames
extends Node                    # extends

## Class description            # docstrings

signal my_signal                # signals

enum State { IDLE, RUNNING }    # enums

const MAX_VALUE := 100          # consts

static var instance: MyClass    # staticvars

@export var speed: float        # exports

var public_var: int             # pubvars
var _private_var: int           # prvvars

@onready var label := $Label    # onreadypubvars
@onready var _timer := $Timer   # onreadyprvvars

func _ready() -> void:          # others (lifecycle, public, private)
    pass
```

### Late-Init Pattern

For vars set after construction (via init method), use inline disable:

```gdscript
## Config set via initialize_with_config()
var balance_config: BalanceConfig  # gdlint: disable=class-definitions-order
```

## Naming Conventions

### Functions
- Public: `snake_case`
- Private: `_snake_case`
- Lifecycle: `_ready`, `_process`, `_physics_process`
- Signal handlers: `_on_<source>_<signal_name>`

```gdscript
func _on_button_pressed() -> void:
    pass

func _on_enemy_died(enemy: SimEnemy) -> void:
    pass
```

### Variables
- Public: `snake_case`
- Private: `_snake_case`
- Constants: `SCREAMING_SNAKE_CASE`
- Unused params: prefix with `_`

```gdscript
func _on_timer_timeout(_timer: Timer) -> void:
    # _timer unused but required by signal signature
    pass
```

## Linting Configuration

### Disabled Rules

| Rule | Reason |
|------|--------|
| `max-public-methods` | Test files have 20-40 methods; GameState coordinates many systems |
| `class-definitions-order` | Multiple intentional exceptions: late-init vars, grouped consts with related vars |
| `no-elif-return` | Team preference; improves readability in some cases |
| `no-else-return` | Team preference; improves readability in some cases |
| `unused-argument` | Required by test framework, signal handlers, interface methods |
| `private-method-call` | Unit tests must access private methods for coverage |

## Testing Conventions

Using [GUT](https://github.com/bitwes/Gut) framework.

### Test File Structure

```gdscript
extends GutTest

var _game_state: GameState

func before_each() -> void:
    _game_state = GameState.new()

func after_each() -> void:
    _game_state = null

func test_initial_gold_is_correct() -> void:
    assert_eq(_game_state.gold, 200)

func test_can_place_tower_returns_false_when_no_gold() -> void:
    _game_state.gold = 0
    assert_false(_game_state.can_place_tower(Vector2i(5, 5), "archer"))
```

### Testing Private Methods

Tests may call private methods directly for coverage:

```gdscript
# Testing private method - gdlint private-method-call disabled globally
func test_distance_squared_calculation() -> void:
    var result := _game_state._distance_squared(Vector2i(0, 0), Vector2(3, 4))
    assert_eq(result, 25.0)
```

### Test Naming

- Prefix: `test_`
- Describe behavior: `test_<method>_<condition>_<expected>`

```gdscript
func test_place_tower_deducts_gold() -> void:
func test_damage_shrine_emits_signal() -> void:
func test_is_wave_complete_returns_true_when_no_enemies() -> void:
```

## Running Linter

```bash
# Check all code
gdlint simulation/ tests/ ui/ game/ maps/ resources/

# Check specific file
gdlint simulation/core/game_state.gd

# Via pre-commit
pre-commit run gdlint --all-files
```

## Code Review Checklist

- [ ] Class organization follows defined order
- [ ] Private methods prefixed with `_`
- [ ] Signal handlers use `_on_<source>_<signal>` pattern
- [ ] Lines under 100 characters
- [ ] Unused params prefixed with `_`
- [ ] Inline disables documented with comment
- [ ] Tests included for new functionality
