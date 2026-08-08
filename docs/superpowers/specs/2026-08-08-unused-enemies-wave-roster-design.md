# Unused Enemies Wave Roster Design

## Goal

Wire all unused standard enemies and bosses into the 30-wave roster, and register them so battle/CLI can spawn them.

## Scope

1. Register unused enemy `.tres` files in battle and CLI runners (including `mini` for splitter deaths)
2. Add Wave 10 boss and remaining milestone bosses in waves 15/20/25/30
3. Introduce standards (`healer`, `shielded`, `splitter`, `regen`) with staggered first appearances and light reuse
4. Update level metadata `enemy_types` for levels whose wave ranges gain new types
5. Add unit test asserting the full roster includes all standards + bosses

## Out of scope

- Balance retunes of enemy HP/DPS/gold
- New visual colors / sprites for unused types
- Siege smash enemies (`siege_golem`, `battering_ram`) — not in this roster pass
- Changing Rush/Smash wave numbers (keep 8/14/26 rush, 18/24/28 smash)
- Making level `enemy_types` exhaustive of every fodder type already omitted today

## Approach

All target `.tres` files already exist under `resources/enemies/`. Mechanics are already covered by unit tests. This change is data + registration only.

### Registration

Add `load` + register calls in:

- `ui/screens/battle_screen.gd` → `_register_data_to_state()`
- `main.gd` → CLI/sim runner setup

New registrations (keep existing eight):

| id | Path | Why |
|----|------|-----|
| `healer` | `resources/enemies/healer.tres` | Wave spawns |
| `shielded` | `resources/enemies/shielded.tres` | Wave spawns |
| `splitter` | `resources/enemies/splitter.tres` | Wave spawns |
| `regen` | `resources/enemies/regen.tres` | Wave spawns |
| `mini` | `resources/enemies/mini.tres` | Splitter death spawns (`splits_into`) |
| `swarm_queen` | `resources/enemies/swarm_queen.tres` | Boss wave 10 |
| `frost_wyrm` | `resources/enemies/frost_wyrm.tres` | Boss wave 15 |
| `phase_phantom` | `resources/enemies/phase_phantom.tres` | Boss wave 20 |
| `necromancer` | `resources/enemies/necromancer.tres` | Boss wave 25 |
| `iron_colossus` | `resources/enemies/iron_colossus.tres` | Boss wave 30 |

`mini` must be registered but must **not** appear in any `WaveSpawnData`.

### Boss waves

Milestone bosses (every 5th decade-aligned slot). Replace wave-20 `boss_golem` with `phase_phantom`. Keep `boss_golem` on the final wave alongside `iron_colossus`.

| Wave | Boss spawn | Escort (keep / adjust existing) |
|------|------------|----------------------------------|
| 10 | `swarm_queen` ×1 | Keep current grunt×18, runner×10 |
| 15 | `frost_wyrm` ×1 | Keep current grunt×20, runner×10, stealth×3 |
| 20 | `phase_phantom` ×1 | Keep tank×6, grunt×20; remove `boss_golem` |
| 25 | `necromancer` ×1 | Keep grunt×35, runner×20, flyer×15, tank×6 |
| 30 | `iron_colossus` ×1 + `boss_golem` ×3 | Keep tank×15, breaker×10, grunt×30, runner×20, flyer×15 |

Boss entry is the first spawn group in each boss wave (spawned earliest).

### Standard enemy intros (staggered)

First appearance, then light remix on later waves:

| Type | Intro wave | Intro count | Reuse waves (count) |
|------|------------|-------------|---------------------|
| `healer` | 13 | 2 | 17×3, 23×4 |
| `shielded` | 16 | 3 | 21×4, 27×5 |
| `splitter` | 19 | 3 | 24×4, 29×5 |
| `regen` | 22 | 3 | 28×4 |

Append each group to the existing spawn list for that wave (do not remove current composition). `mini` never listed in wave data.

### Level metadata `enemy_types`

Append newly featured types for the listed levels. Do not remove existing entries. Do not add `mini`.

| Level | Waves | Add |
|-------|-------|-----|
| `ch1_lv2` | 6–10 | `swarm_queen` |
| `ch1_lv3` | 8–10 | `swarm_queen` |
| `ch2_lv1` | 11–15 | `healer`, `frost_wyrm` |
| `ch2_lv2` | 16–20 | `shielded`, `splitter`, `phase_phantom` |
| `ch3_lv1` | 21–25 | `shielded`, `regen`, `necromancer` |
| `ch3_lv2` | 26–29 | `shielded`, `splitter`, `regen` |
| `ch3_lv3` | 30 | `iron_colossus` |

### Tests

Create `tests/unit/test_wave_roster.gd` extending `GutTest`.

Assertions against `Waves1To10.create_full()`:

1. Collect the set of all `enemy_id` values across every wave’s spawn groups
2. Assert each standard is present: `healer`, `shielded`, `splitter`, `regen`
3. Assert each boss is present: `swarm_queen`, `frost_wyrm`, `phase_phantom`, `necromancer`, `iron_colossus`, `boss_golem`
4. Assert `mini` is **not** in the set
5. Assert milestone boss placements: wave 10 → `swarm_queen`, 15 → `frost_wyrm`, 20 → `phase_phantom` (and not `boss_golem`), 25 → `necromancer`, 30 → both `iron_colossus` and `boss_golem`

## Files

| File | Change |
|------|--------|
| `ui/screens/battle_screen.gd` | Register 10 new enemy resources |
| `main.gd` | Same registration for CLI/sim |
| `resources/waves/waves_1_10.gd` | Wave 10 boss `swarm_queen` |
| `resources/waves/waves_11_30.gd` | Standards + bosses 15/20/25/30; header comments |
| `resources/levels/ch1_lv2.tres` | `enemy_types` |
| `resources/levels/ch1_lv3.tres` | `enemy_types` |
| `resources/levels/ch2_lv1.tres` | `enemy_types` |
| `resources/levels/ch2_lv2.tres` | `enemy_types` |
| `resources/levels/ch3_lv1.tres` | `enemy_types` |
| `resources/levels/ch3_lv2.tres` | `enemy_types` |
| `resources/levels/ch3_lv3.tres` | `enemy_types` |
| `tests/unit/test_wave_roster.gd` | New roster coverage |

## Success criteria

- Battle and CLI can spawn every unused standard/boss without missing-registry errors
- Splitter deaths can spawn `mini`
- Full 30-wave dataset includes all listed standards and bosses at the specified waves
- `test_wave_roster.gd` passes under GUT
