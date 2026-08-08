# Lightning Capacitor Design

## Goal

Implement the unfinished Lightning T3B2 upgrade: Capacitor charges for 5s then discharges a massive AOE burst (GDD: "Charges 5s, discharges 200 AOE").

## Current gap

`lightning_capacitor` already has `damage = 200000`, `attack_speed_ms = 5000`, `aoe_radius = 3000`, but `special = {}` so it falls through to a normal slow AOE attack.

## Behavior

1. Flag: `special.capacitor = true` (optional `charge_ms`, default `attack_speed_ms`).
2. While frozen: do not charge.
3. While ≥1 targetable enemy in `range_tiles`: accumulate `capacitor_charge_ms`.
4. When charge ≥ charge time: discharge AOE centered on tower `get_center()` with radius `aoe_radius/1000`, dealing tower damage via `_calculate_damage`; reset charge to 0; increment `shots_fired`.
5. Capacitor skips the normal attack path (like beam).

## Why not cooldown AOE?

A normal 5s cooldown AOE hits around the target. Capacitor is a station burst around the tower — better for swarm clear and matches "charge then discharge."
