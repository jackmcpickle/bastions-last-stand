# Special Rounds Rush/Smash Design

## Goal

Honor Rush/Smash special-round rules in the live sim, add the missing smash roster (Siege Golem + Battering Ram), and exercise both via GUT coverage plus full 30-wave CLI strategies.

## Scope

1. Rush runtime: spawn spacing from `BalanceConfig.wave_spawn_interval_rush_ms`; early-start bonus ×2
2. Wave cadence: Rush on 8/14/**20**/26; move Phase Phantom **20 → 21**
3. Smash enemies: `siege_golem` + `battering_ram` full GDD kits; place on waves 18/24/28
4. Wall-breaker combat: attack interval; melee adjacent **walls and towers**; golem `slow_immune`; ram charge
5. Register new enemies in battle + CLI; update smash level `enemy_types`
6. CLI default to full 30-wave roster; add `rush_aoe` and `smash_maze` strategies
7. Unit/integration tests for the above

## Out of scope

- Retune existing Breaker HP/speed/armor/gold to GDD table values
- Haiku prompt rewrites / BalancedAI smash- or rush-awareness
- Charge/impact visuals or SFX
- Build-timer UI (battle may keep `seconds_early=0` until a timer exists; tests pass early seconds explicitly)
- Runtime ×3 enemy-count multiplier (counts stay hand-authored)
- Auto-rebuild system for non-smash waves (none exists; smash “no rebuild” is already satisfied)
- Support-tower strategy matrix entries

## Approach

Unified special-rounds pass: wave data + economy/spawn wiring + combat kits + CLI/sim coverage in one plan. Authored rush/smash compositions stay data-driven; flags drive the runtime modifiers that today are dead.

---

## Wave layout

| Waves | Role | Notes |
|-------|------|-------|
| 8, 14, **20**, 26 | Rush (`is_rush=true`) | Wave 20 becomes pure Rush (no boss) |
| 18, 24, 28 | Smash (`is_smash=true`) | Add golem/ram; keep breakers + tanks |
| 10, 15, **21**, 25, 30 | Boss milestones | Phase Phantom moves from 20 → 21 |

### Wave 20 (pure Rush)

Replace current Phase Phantom wave with a runner/swarm-heavy rush, slightly harder than wave 14:

- Spawns: `runner` ×35, `swarm` ×25 (authored; no runtime ×3)
- `is_rush = true`
- Authored `spawn_interval_ms` can stay for readability; **runtime ignores it** when `is_rush`

### Wave 21 (Phase Phantom)

- First spawn group: `phase_phantom` ×1
- Keep existing wave-21 fodder as escorts (`grunt`, `runner`, `tank`, `flyer`, `shielded`)
- Not rush, not smash

### Unchanged boss slots

10 Swarm Queen, 15 Frost Wyrm, 25 Necromancer, 30 Iron Colossus + Boss Golem.

---

## Rush runtime

### Spawn interval

In `GameState.start_wave`:

- If `wave.is_rush`: enemy spawn delays use `balance_config.wave_spawn_interval_rush_ms`
- Else: use `wave.spawn_interval_ms` (authored)

`wave_spawn_interval_base_ms` remains unused for spawning this pass (authored non-rush intervals stay).

### Early-start ×2

Extend:

```gdscript
static func calculate_wave_bonus(
	wave_gold_earned: int,
	shrine_took_damage: bool,
	seconds_early: float = 0.0,
	is_rush: bool = false
) -> int
```

Rules:

1. Perfect-wave bonus unchanged (not doubled)
2. Compute early-start multiplier as today (10% per 5s, capped at 50%)
3. If `is_rush`, multiply that early portion by 2 (effective early max +100% of wave gold)
4. `GameState.complete_wave` passes `wave_data.get_wave(current_wave).is_rush` (guard if wave missing)

Headless `TickProcessor.run_wave` may still call `start_wave(n)` with `seconds_early=0`; unit tests supply non-zero early seconds to assert the ×2 path.

---

## Smash enemies

### Resources (new)

| Field | `siege_golem` | `battering_ram` |
|-------|---------------|-----------------|
| HP | 800 | 300 |
| Speed (×1000) | 300 | 600 |
| Armor (×1000) | 500 | 200 |
| Gold | 100 | 40 |
| Pathing | wall_breaker (direct to shrine) | wall_breaker |

**Siege Golem `special`:**

```gdscript
{
	"wall_breaker": true,
	"wall_damage": 50,
	"slow_immune": true,
	"structure_attack_interval_ms": 1000
}
```

T1 wall (100 HP) dies in **2 hits** at 50 dmg / 1000ms.

**Battering Ram `special`:**

```gdscript
{
	"wall_breaker": true,
	"wall_damage": 40,
	"structure_attack_interval_ms": 800,
	"charge_impact_bonus": 2000,  # +200% => ×3 on charged hit
	"charge_range": 3,            # Chebyshev tiles
	"charge_speed_bonus": 1000,   # +100% move speed while charging
	"charge_cooldown_ms": 3000
}
```

### Registration

Load + register in:

- `ui/screens/battle_screen.gd` → `_register_data_to_state()`
- `main.gd` → CLI/sim enemy registry

### Smash wave composition

Append (do not remove existing breakers/tanks/fodder):

| Wave | Add |
|------|-----|
| 18 | `siege_golem`×1, `battering_ram`×2 |
| 24 | `siege_golem`×2, `battering_ram`×3 |
| 28 | `siege_golem`×3, `battering_ram`×4 |

### Level metadata

Append `siege_golem` / `battering_ram` to `enemy_types` on levels whose wave range includes smash waves (notably chapter 3 siege-oriented levels). Do not remove existing entries.

---

## Wall-breaker combat

Rewrite `Combat.process_wall_breaker_attacks` responsibilities:

1. **Target:** adjacent wall **or** tower (Chebyshev ≤1 from `get_current_tile()`; prefer closer; walls win ties).
2. **Attack interval:** track per-enemy cooldown from `structure_attack_interval_ms` (default **1000** if unset). Applies to Breaker, Golem, Ram.
3. **Damage path:** walls via existing `_damage_wall` (thorns/stun); towers via `tower.take_damage` + `GameState.destroy_tower` when destroyed.
4. **Repath** after any structure destruction (same as today for walls).
5. **Golem `slow_immune`:** `SimEnemy.apply_slow` returns early when `slow_immune`; stun still applies (not full `cc_immune`).
6. **Ram charge:**
   - If charge cooldown ready and a wall/tower is within `charge_range`, enter charging: effective move speed × `(1000 + charge_speed_bonus) / 1000`
   - First qualifying adjacent structure hit while charging:  
     `damage = wall_damage * (1000 + charge_impact_bonus) / 1000`
   - Clear charging; start `charge_cooldown_ms`
   - Non-charged hits use base `wall_damage` on the structure interval

### Breaker compatibility

Existing `breaker.tres` keeps current stats this pass. It gains default attack interval behavior and tower-melee. Balance retune to GDD table is out of scope.

### Smash “no auto-rebuild”

Destroyed walls never respawn today. Spec requires a regression test that a wall destroyed by a wall-breaker remains absent. No new rebuild feature.

---

## Tests

| Area | Assertions |
|------|------------|
| Rush interval | Rush `start_wave` spaces spawns by `wave_spawn_interval_rush_ms`; non-rush uses authored ms |
| Rush economy | `calculate_wave_bonus(..., is_rush=true)` doubles early portion only; perfect-wave not doubled; `complete_wave` forwards `is_rush` |
| Wave roster | Rush flags on 8/14/20/26; smash on 18/24/28; Phantom on 21 (not 20); smash counts include golem/ram |
| Golem | Slow ignored; T1 wall dies in 2 interval hits at 50 dmg |
| Ram | Charged hit deals ×3; cooldown blocks immediate re-charge |
| Wall-breaker towers | Adjacent tower takes damage / can be destroyed |
| Smash permanence | Destroyed wall stays removed |
| Spawn integration | Registered smash/rush waves spawn new ids without missing-registry errors |

Update `test_rush_and_smash_flags_unchanged` so the rush list is `[8, 14, 20, 26]`.

---

## Simulations / CLI

1. Headless default waves: `Waves1To10.create_full()` (30 waves), not `create()` (1–10).
2. New strategies in `main.gd` `_get_all_strategies()`:
   - **`rush_aoe`**: dense flame/lightning AOE placements, light walls — stress Rush density
   - **`smash_maze`**: wall maze + `cannon_siege` upgrade path — stress Smash breaches
3. Include both in `--strategy all` (and document in `--help`).
4. Register `siege_golem` / `battering_ram` in CLI enemy setup.
5. Results JSON shape unchanged.

---

## Success criteria

- Battle and CLI can spawn every smash enemy without missing-registry errors
- Rush waves use configurable rush spawn interval and doubled early-start bonus
- Wave 20 is Rush; Phase Phantom is on wave 21
- Smash waves 18/24/28 include Golem and Ram
- Wall-breakers damage adjacent towers on an attack interval
- Golem resists slow; Ram charged impacts deal +200% structure damage
- Headless `--strategy all` runs full 30 waves including `rush_aoe` and `smash_maze`
- GUT suite covers the table above
