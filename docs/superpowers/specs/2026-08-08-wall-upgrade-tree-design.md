# Wall Upgrade Tree Design

## Goal

Add the GDD Wall Block upgrade tree so walls are more than Tier-1 blockers — durability (repair/thorns) and utility (shock/tar) branches.

## Approach

Mirror towers: `WallData` + `WallUpgradeData` resources, `SimWall.apply_upgrade`, `GameState.upgrade_wall`, tick/on-hit combat specials.

## Tree

| Tier | Branch | Name | HP | Special keys |
|------|--------|------|-----|--------------|
| 1 | — | Wall | 100 | — |
| 2A | A | Reinforced | 250 | `self_repair: 5`, `repair_out_of_combat: true` |
| 2B | B | Reactive | 100 | `stun_on_hit_ms: 500`, `stun_cooldown_ms: 8000` |
| 3A1 | A1 | Fortress Wall | 500 | `self_repair: 10` (always) |
| 3A2 | A2 | Thorned Wall | 300 | `reflect_pct: 200` (20% x1000) |
| 3B1 | B1 | Shock Wall | 150 | `stun_on_hit_ms: 1000`, `stun_cooldown_ms: 5000` |
| 3B2 | B2 | Tar Wall | 150 | `tar_slow: 400`, `tar_radius: 2` |

Costs: place uses `balance_config.wall_cost` (10); T2 40g; T3 80g.

## Rules

- Upgrade raises `max_hp`; keep current HP (clamp if above new max).
- Out of combat = `combat_idle_ms >= 2000` (no damage taken for 2s).
- Thorns/stun fire when wall takes melee structure damage (siege + wall-breakers).
- Tar: each tick, slow enemies within radius of wall position.
- Repair accumulates fractional HP/s like tower aura regen.
- Reactive fills GDD “utility effects” as a weaker on-hit stun.

## Out of scope

Wall upgrade UI / 3D variants — sim + GameState API + tests only.
