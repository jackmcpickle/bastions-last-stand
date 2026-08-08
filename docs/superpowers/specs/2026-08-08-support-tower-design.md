# Support Tower Design

## Goal

Add the missing sixth tower type from the GDD: Support Tower — aura-based buffs for allies and debuffs/marks for enemies. Completes Phase 2 tower roster and uses the new tower HP system (Rally Point regen).

## Approach

**Tick-time aura processing** (recommended over on-hit lookup):

1. Each tick, clear ephemeral aura/mark state on towers and enemies.
2. `Combat.process_support_auras(game_state, delta_ms)` applies effects from every tower with `special.support_aura`.
3. Combat/targeting consume those ephemeral fields when attacking.

Why: keeps buff logic in one place, supports regen/EMP/reveal without fake attacks, stacks cleanly.

Alternatives rejected:
- On-damage lookup of nearby supports — misses regen/EMP and duplicates range checks.
- Permanent buff mutation of tower.damage — hard to unwind when supports die/move out of range.

## Special keys (x1000 where noted)

| Key | Meaning |
|-----|---------|
| `support_aura` | Flag: this tower is a support aura source |
| `aura_damage_buff` | +% damage to nearby towers (150 = +15%) |
| `aura_speed_buff` | +% attack speed (reduces cooldown) |
| `aura_range_buff` | Flat +range tiles for nearby towers |
| `aura_tower_regen` | HP/s restored to nearby towers |
| `mark_enemies` | Mark enemies in range |
| `mark_damage_amp` | Marked enemies take +% damage |
| `reveal_stealth` | Reveal stealth enemies in range |
| `mark_crit_chance` | Crit chance vs marked (on attackers) |
| `emp_slow` | Slow amount applied while in range |
| `emp_disable_shields` | Zero shield HP while in range |

## Upgrade tree (GDD)

| Tier | Branch | Name | Effects |
|------|--------|------|---------|
| 1 | — | Support Tower | 3 range, +15% dmg aura |
| 2A | A | War Banner | 4 range, +20% dmg, +10% speed |
| 2B | B | Tech Relay | 4 range, mark +15% dmg taken |
| 3A1 | A1 | Command Post | 5 range, +25% dmg, +15% speed, +1 range |
| 3A2 | A2 | Rally Point | 4 range, +20% dmg, towers regen 2 HP/s |
| 3B1 | B1 | Scanner | 5 range, mark, reveal stealth, +40% crit vs marked |
| 3B2 | B2 | EMP Field | 4 range, −30% enemy speed, disable shields |

Base cost: 160g (tuned like other towers vs GDD 200). T2: 250g, T3: 500g. Base HP: 100. Damage: 0 (aura-only; skips normal attacks).

## Ephemeral state

**SimTower:** `aura_damage_buff`, `aura_speed_buff`, `aura_bonus_range`, `aura_regen_per_sec`  
**SimEnemy:** `is_marked`, `mark_damage_amp`, `mark_crit_chance`

Stacking: for each field, take the **max** from overlapping supports (no double-dip).

Aura range: distance from support `get_center()` to ally tower center / enemy `grid_pos`, compared to support `range_tiles`. Support does not buff itself.

## Integration

- Call `process_support_auras` in `TickProcessor` before tower attacks.
- `_calculate_damage` applies aura damage buff + mark amp + mark crit.
- `SimTower.attack` uses speed-adjusted cooldown; targeting uses effective range.
- Register `support_tower.tres` in battle screen + tower upgrade UI.
- Unlock support on a mid/late chapter level (ch3 stealth / siege).

## Testing

GUT unit tests for: damage aura, speed aura, range aura, tower regen, mark amp, stealth reveal, EMP slow/shields, upgrade application, no self-buff.
