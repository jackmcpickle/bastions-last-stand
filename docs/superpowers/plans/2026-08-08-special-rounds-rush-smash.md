# Special Rounds Rush/Smash Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Honor Rush/Smash flags in sim, add Siege Golem + Battering Ram, move Phase Phantom to wave 21, and cover with GUT + full-30 CLI strategies.

**Architecture:** Wave factories own composition; `GameState.start_wave` / `Economy.calculate_wave_bonus` consume `is_rush`; `Combat.process_wall_breaker_attacks` owns structure melee + charge; CLI uses `create_full()` plus `rush_aoe` / `smash_maze`.

**Tech Stack:** Godot 4 GDScript, GUT

## Global Constraints

- Follow `docs/superpowers/specs/2026-08-08-special-rounds-rush-smash-design.md` exactly
- Tabs for indentation; snake_case; lines ≤100 chars
- Rush waves: 8/14/20/26; Smash: 18/24/28; Phantom on 21
- Do not retune Breaker base stats
- No runtime ×3 count multiplier

## File map

| File | Role |
|------|------|
| `resources/enemies/siege_golem.tres` | New enemy resource |
| `resources/enemies/battering_ram.tres` | New enemy resource |
| `resources/waves/waves_11_30.gd` | Wave 20 rush, 21 phantom, smash adds |
| `simulation/systems/economy.gd` | Rush early-start ×2 |
| `simulation/core/game_state.gd` | Rush spawn interval; forward `is_rush` |
| `simulation/entities/sim_enemy.gd` | `slow_immune`, charge/attack cooldown state |
| `simulation/systems/combat.gd` | Wall-breaker walls+towers, interval, charge |
| `ui/screens/battle_screen.gd` / `main.gd` | Register enemies; CLI full waves + strategies |
| `resources/levels/ch*.tres` | Smash `enemy_types` |
| `tests/unit/test_*.gd` | Coverage per spec |

---

### Task 1: Rush economy + spawn interval

**Files:**
- Modify: `simulation/systems/economy.gd`
- Modify: `simulation/core/game_state.gd`
- Modify: `tests/unit/test_economy.gd`
- Create/Modify: `tests/unit/test_game_state.gd` (or new `test_special_rounds.gd`)

- [ ] Add failing tests: rush doubles early portion only; perfect not doubled; rush spawn uses `wave_spawn_interval_rush_ms`
- [ ] Implement `calculate_wave_bonus(..., is_rush=false)` and `complete_wave` forwarding
- [ ] `start_wave` uses rush interval when `wave.is_rush`
- [ ] Commit

### Task 2: Wave roster reshuffle + smash composition

**Files:**
- Modify: `resources/waves/waves_11_30.gd`
- Modify: `tests/unit/test_wave_roster.gd`

- [ ] Wave 20 → rush runner×35 swarm×25; wave 21 → phantom first + escorts
- [ ] Append golem/ram counts on 18/24/28
- [ ] Update roster tests (rush list, boss on 21, smash counts)
- [ ] Commit

### Task 3: Siege enemy resources + slow_immune/charge combat

**Files:**
- Create: `resources/enemies/siege_golem.tres`, `battering_ram.tres`
- Modify: `simulation/entities/sim_enemy.gd`, `simulation/systems/combat.gd`
- Create/Modify: `tests/unit/test_combat.gd` / `test_special_rounds.gd`

- [ ] Failing tests: golem slow immune + 2-hit wall; ram ×3 charge; breaker hits tower; wall permanence
- [ ] Implement enemy state + `process_wall_breaker_attacks` rewrite
- [ ] Commit

### Task 4: Registration, levels, CLI sims

**Files:**
- Modify: `ui/screens/battle_screen.gd`, `main.gd`
- Modify: smash-range level `.tres` files
- Modify: `tests/unit/test_wave_roster.gd` level metadata expectations

- [ ] Register golem/ram in battle + CLI
- [ ] `create_full()` default; add `rush_aoe` + `smash_maze`; help text
- [ ] Append level `enemy_types`
- [ ] Lint + run full GUT unit suite for touched areas
- [ ] Commit
