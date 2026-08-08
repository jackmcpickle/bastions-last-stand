# Economy Wiring Design

## Goal

Wire GDD economy extras into the live sim loop so wave completion and tower selling actually move gold — not just unit-tested helpers.

## Scope

1. Per-wave gold / shrine-damage tracking
2. Perfect-wave (+25%) and early-start (+10%/5s, max +50%) bonuses in `complete_wave()`
3. Interest (+5% banked, cap 50) when unlocked
4. `GameState.sell_tower()` at configurable sell rate (default 90%)
5. Kill rewards via `Economy.calculate_kill_reward`

## Out of scope

- Rush 2× early-start multiplier
- Meta progression / UI for unlocking interest
- Build-timer UI
- Wall selling
- Sell / bonus HUD polish

## Approach

Helpers already exist in `Economy`. `GameState` owns wave tracking and applies payouts at wave end.

### Wave tracking (reset in `start_wave`)

| Field | Role |
|-------|------|
| `wave_gold_earned` | Kill gold this wave (bonus base) |
| `wave_shrine_damaged` | True if shrine took any damage |
| `wave_seconds_early` | Remaining build time when wave started |

`start_wave(wave_number, seconds_early := 0.0)` stores early seconds. Headless sims default to `0`.

### `complete_wave()` payout order

1. `bonus = Economy.calculate_wave_bonus(wave_gold_earned, wave_shrine_damaged, wave_seconds_early)`
2. Add bonus to `gold` / `total_gold_earned`
3. `interest = Economy.calculate_interest(gold, balance_config.interest_unlocked)`
4. Add interest to `gold` / `total_gold_earned`
5. Emit `wave_completed` / victory check (unchanged)

Interest uses gold **after** wave bonus so banking + clean waves compound.

### Sell API

```
sell_tower(tower) -> int  # refund amount, or 0 if refused
```

- Refused while `wave_in_progress` or tower not owned
- Refund = `total_cost * sell_rate_percent / 100` (`BalanceConfig`, default 90)
- Refund is **not** counted as `total_gold_earned`
- Removal reuses `destroy_tower()` (unblock + repath + signal)

### Config

`BalanceConfig.interest_unlocked: bool = false` (GDD unlockable; sims/tests opt in).

## Rules

- Perfect wave = zero shrine damage that wave (leaks that don't damage don't break it)
- Early start floors to 5s buckets via existing `Economy` math
- Selling during combat is disallowed
