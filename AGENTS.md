# AGENTS.md

## Cursor Cloud specific instructions

This is a **Godot 4.3** tower-defense game ("Bastion's Last Stand") with a Python
`balance_ai` sidecar. Standard commands live in `README.md` and `CONTRIBUTING.md`;
the notes below only cover non-obvious, environment-specific gotchas.

### Toolchain locations / PATH
- Godot 4.3 engine: `/usr/local/bin/godot` (on PATH).
- `gdformat`, `gdlint`, `uv`, `pre-commit` live in `~/.local/bin`, which is **not** on
  the default non-login PATH. Before running them, add it:
  `export PATH="$HOME/.local/bin:$PATH"` (interactive shells pick this up via `~/.bashrc`).
- GUT (test framework) is git-ignored (`addons/gut/`) and installed by the update script,
  not committed. Do not commit it.

### Running things (see README/CONTRIBUTING for the canonical commands)
- Lint (matches CI): `gdformat --check simulation/ tests/ resources/ maps/ ui/ game/ main.gd`
  and `gdlint simulation/ tests/ resources/ maps/ ui/ game/ main.gd`.
- GUT tests (headless): `godot --headless -s addons/gut/gut_cmdln.gd -gdir=res://tests -gexit`.
  A fresh checkout must be imported once first: `godot --headless --import`.
- Python sidecar tests: `uv sync --project balance_ai` then `uv run --project balance_ai pytest`.
- Headless simulation engine (a first-class run mode): `godot --headless -- --help`, e.g.
  `godot --headless -- --strategy all --count 5`. This exercises the full tower-defense
  engine (tower placement, 30 waves, combat, pathfinding, shrine damage) without a display.

### GUI: no Vulkan GPU on this VM
The project's default renderer is Forward+ (Vulkan) but the VM has **no Vulkan-capable GPU**
— only Mesa software rasterizers. To run the game window (`godot --path .`):
- Preferred (intended renderer): install software Vulkan once with
  `sudo apt-get install -y mesa-vulkan-drivers`, then launch with lavapipe:
  `XDG_RUNTIME_DIR=/tmp/xdg VK_ICD_FILENAMES=/usr/share/vulkan/icd.d/lvp_icd.json DISPLAY=:1 godot --path /workspace`
  (create `/tmp/xdg` with mode 700 first). This renders the UI correctly with Forward+.
- Fallback: `godot --path /workspace --rendering-method gl_compatibility --rendering-driver opengl3`
  runs on Mesa llvmpipe, but many UI panels render black/incorrectly under `gl_compatibility`;
  prefer the lavapipe/Forward+ path for any GUI testing.
- ALSA audio warnings ("All audio drivers failed, falling back to the dummy driver") are
  expected/harmless — there is no audio device.

### Known pre-existing app bugs (not environment issues)
These exist in committed game code and are unrelated to setup:
- Level Select → Battle is broken: `ui/screens/level_select.gd` calls `card.setup(chapter)`
  before `add_child(card)`, so `chapter_card.gd`'s `@onready` `title_label` is `null` and
  `setup()` crashes. This blocks reaching the Battle screen through the normal UI.
- `game/progression_manager.gd` `load_progression()` can throw a type error assigning an
  untyped JSON `Array` to a typed `Array[String]` when a save file is present; deleting
  `~/.local/share/godot/app_userdata/Bastion's Last Stand/progression.save` gives a clean
  first-run.
Because the UI battle path is blocked, verify battle/game-logic changes via the headless
simulation engine, which runs the same `GameState`/`TickProcessor` core.
