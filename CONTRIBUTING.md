# Contributing

## Code Style

- Follow [GDScript Style Guide](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_styleguide.html)
- Use `gdformat` for formatting, `gdlint` for linting
- Max line length: 100 characters
- Use tabs for indentation

## Setup

```bash
# Install dev tools
python -m venv .venv
source .venv/bin/activate
pip install -r requirements-dev.txt

# Install pre-commit hooks
pre-commit install
```

## Before Submitting PR

1. **Format code**: `gdformat simulation/ tests/ resources/ maps/ ui/ game/ main.gd`
2. **Lint code**: `gdlint simulation/ tests/ resources/ maps/ ui/ game/ main.gd`
3. **Run tests**: `godot --headless -s addons/gut/gut_cmdln.gd -gdir=res://tests -gexit`
4. All tests must pass
5. No lint errors

## Testing Requirements

- New features need unit tests
- Bug fixes need regression tests
- Tests go in `tests/` directory
- Use GUT framework

## PR Process

1. Create feature branch: `feature/your-feature`
2. Make changes with tests
3. Run linters and tests
4. Push and create PR
5. Wait for CI to pass
6. Request review
