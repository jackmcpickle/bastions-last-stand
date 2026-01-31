"""Prompt templates for Haiku analysis."""

from typing import Dict, Any


def build_analysis_prompt(
    config: Dict[str, Any],
    results: Dict[str, Any],
    targets: Dict[str, Any],
    goal: str,
    parameter_bounds: Dict[str, Any],
) -> str:
    """Build the analysis prompt for Claude Haiku."""

    # Format strategy results
    strategy_text = ""
    for strat_id in ["a", "b", "c", "d"]:
        if strat_id not in results.get("strategies", {}):
            continue
        s = results["strategies"][strat_id]
        strategy_text += f"""
Strategy {strat_id.upper()} ({s["name"]}):
- Win rate: {s["win_rate"] * 100:.1f}%
- Avg shrine HP remaining: {s["avg_shrine_hp"]:.1f}/100
- Avg gold remaining: {s["avg_gold"]:.1f}
- Avg enemies killed: {s["avg_killed"]:.0f}
- Avg enemies leaked: {s["avg_leaked"]:.0f}
"""

    # Format parameter bounds
    bounds_text = ""
    key_params = [
        # Economy
        "starting_gold",
        "wall_cost",
        "sell_rate_percent",
        # Archer
        "archer_cost",
        "archer_damage",
        "archer_attack_speed_ms",
        "archer_range",
        # Cannon
        "cannon_cost",
        "cannon_damage",
        "cannon_attack_speed_ms",
        "cannon_range",
        "cannon_aoe_radius",
        # Frost
        "frost_cost",
        "frost_damage",
        "frost_attack_speed_ms",
        "frost_range",
        "frost_slow",
        "frost_slow_duration_ms",
        # Lightning
        "lightning_cost",
        "lightning_damage",
        "lightning_attack_speed_ms",
        "lightning_range",
        "lightning_chain_count",
        "lightning_chain_range",
        # Flame
        "flame_cost",
        "flame_damage",
        "flame_attack_speed_ms",
        "flame_range",
        "flame_burn_dps",
        "flame_burn_duration_ms",
        # Grunt
        "grunt_hp",
        "grunt_speed",
        "grunt_gold",
        # Runner
        "runner_hp",
        "runner_speed",
        "runner_gold",
        # Tank
        "tank_hp",
        "tank_speed",
        "tank_armor",
        "tank_gold",
        # Flyer
        "flyer_hp",
        "flyer_speed",
        "flyer_gold",
        # Swarm
        "swarm_hp",
        "swarm_speed",
        "swarm_gold",
        # Stealth
        "stealth_hp",
        "stealth_speed",
        "stealth_gold",
        # Breaker
        "breaker_hp",
        "breaker_speed",
        "breaker_armor",
        "breaker_gold",
        "breaker_wall_damage",
        # Boss
        "boss_golem_hp",
        "boss_golem_speed",
        "boss_golem_armor",
        "boss_golem_gold",
        "boss_golem_regen",
        # Shrine
        "shrine_hp",
        "enemy_shrine_damage",
    ]
    for param in key_params:
        if param in parameter_bounds:
            b = parameter_bounds[param]
            bounds_text += f"- {param}: {b['min']} to {b['max']} (step {b['step']})\n"

    return f"""You are a game balance analyst for a tower defense game called Bastion's Last Stand.

## User's Optimization Goal
{goal}

## Current Configuration
### Economy
- Starting gold: {config.get("starting_gold", 120)}
- Wall cost: {config.get("wall_cost", 10)}g
- Sell rate: {config.get("sell_rate_percent", 90)}%

### Towers
- Archer: {config.get("archer_cost", 80)}g, {config.get("archer_damage", 15000) // 1000} dmg, {config.get("archer_attack_speed_ms", 800)}ms, {config.get("archer_range", 5)} range
- Cannon: {config.get("cannon_cost", 120)}g, {config.get("cannon_damage", 25000) // 1000} dmg, {config.get("cannon_attack_speed_ms", 1500)}ms, {config.get("cannon_range", 4)} range, {config.get("cannon_aoe_radius", 1500) / 1000:.1f} AOE
- Frost: {config.get("frost_cost", 100)}g, {config.get("frost_damage", 8000) // 1000} dmg, {config.get("frost_slow", 400) / 10:.0f}% slow for {config.get("frost_slow_duration_ms", 2500)}ms
- Lightning: {config.get("lightning_cost", 140)}g, {config.get("lightning_damage", 12000) // 1000} dmg, chains to {config.get("lightning_chain_count", 4)} targets
- Flame: {config.get("flame_cost", 90)}g, {config.get("flame_damage", 6000) // 1000} dmg, {config.get("flame_burn_dps", 10000) // 1000} burn/s for {config.get("flame_burn_duration_ms", 4000)}ms

### Enemies
- Grunt: {config.get("grunt_hp", 60)} HP, {config.get("grunt_speed", 1000) / 1000:.1f} spd, {config.get("grunt_gold", 5)}g
- Runner: {config.get("runner_hp", 40)} HP, {config.get("runner_speed", 2000) / 1000:.1f} spd, {config.get("runner_gold", 8)}g
- Tank: {config.get("tank_hp", 300)} HP, {config.get("tank_armor", 300) / 10:.0f}% armor, {config.get("tank_gold", 25)}g
- Flyer: {config.get("flyer_hp", 45)} HP, flying, {config.get("flyer_gold", 12)}g
- Swarm: {config.get("swarm_hp", 15)} HP, {config.get("swarm_speed", 1300) / 1000:.1f} spd, {config.get("swarm_gold", 2)}g
- Stealth: {config.get("stealth_hp", 50)} HP, invisible, {config.get("stealth_gold", 15)}g
- Breaker: {config.get("breaker_hp", 180)} HP, {config.get("breaker_armor", 200) / 10:.0f}% armor, {config.get("breaker_wall_damage", 25)} wall dmg, {config.get("breaker_gold", 20)}g
- Boss Golem: {config.get("boss_golem_hp", 1500)} HP, {config.get("boss_golem_armor", 400) / 10:.0f}% armor, {config.get("boss_golem_regen", 5000) // 1000} regen/s, {config.get("boss_golem_gold", 100)}g

### Shrine
- HP: {config.get("shrine_hp", 100)}
- Enemy damage: {config.get("enemy_shrine_damage", 1)} per enemy

## Simulation Results (1000 runs per strategy)
{strategy_text}

## Target Metrics (for best-performing strategy)
- Win rate: {targets["win_rate"][0] * 100:.0f}-{targets["win_rate"][1] * 100:.0f}%
- Shrine HP remaining: {targets["shrine_hp"][0]}-{targets["shrine_hp"][1]} (target avg ~{(targets["shrine_hp"][0] + targets["shrine_hp"][1]) // 2})
- Gold remaining: {targets["gold_remaining"][0]}-{targets["gold_remaining"][1]} (tight economy)
- Enemies leaked: {targets["enemies_leaked"][0]}-{targets["enemies_leaked"][1]} (minimal)

## Parameter Bounds (what you can adjust)
{bounds_text}

## Your Task
1. Analyze current results vs targets
2. Identify which metrics are off-target and why
3. Recommend specific config changes to move toward targets
4. Changes should be incremental (10-25% adjustments per iteration)
5. Consider game balance holistically - don't make one thing OP

## Key Insights
- Archer DPS = damage / attack_speed_ms * 1000 (attacks per second)
- Path length affects time enemies spend in tower range
- Current path is short (~4 tiles), enemies reach shrine quickly
- More gold means more towers/walls, but shouldn't be trivial
- Walls create longer paths, giving towers more time to shoot

Output ONLY valid JSON (no markdown, no explanation outside JSON):
{{
  "analysis": "2-3 sentence analysis of current state and main problems",
  "best_strategy": "a|b|c|d",
  "off_target_metrics": ["list of metrics not meeting targets"],
  "changes": {{
    "starting_gold": <new_value or null if no change>,
    "wall_cost": <new_value or null>,
    "sell_rate_percent": <new_value or null>,
    "archer_cost": <new_value or null>,
    "archer_damage": <new_value or null>,
    "archer_attack_speed_ms": <new_value or null>,
    "archer_range": <new_value or null>,
    "cannon_cost": <new_value or null>,
    "cannon_damage": <new_value or null>,
    "cannon_attack_speed_ms": <new_value or null>,
    "cannon_range": <new_value or null>,
    "cannon_aoe_radius": <new_value or null>,
    "frost_cost": <new_value or null>,
    "frost_damage": <new_value or null>,
    "frost_attack_speed_ms": <new_value or null>,
    "frost_range": <new_value or null>,
    "frost_slow": <new_value or null>,
    "frost_slow_duration_ms": <new_value or null>,
    "lightning_cost": <new_value or null>,
    "lightning_damage": <new_value or null>,
    "lightning_attack_speed_ms": <new_value or null>,
    "lightning_range": <new_value or null>,
    "lightning_chain_count": <new_value or null>,
    "lightning_chain_range": <new_value or null>,
    "flame_cost": <new_value or null>,
    "flame_damage": <new_value or null>,
    "flame_attack_speed_ms": <new_value or null>,
    "flame_range": <new_value or null>,
    "flame_burn_dps": <new_value or null>,
    "flame_burn_duration_ms": <new_value or null>,
    "grunt_hp": <new_value or null>,
    "grunt_speed": <new_value or null>,
    "grunt_gold": <new_value or null>,
    "runner_hp": <new_value or null>,
    "runner_speed": <new_value or null>,
    "runner_gold": <new_value or null>,
    "tank_hp": <new_value or null>,
    "tank_speed": <new_value or null>,
    "tank_armor": <new_value or null>,
    "tank_gold": <new_value or null>,
    "flyer_hp": <new_value or null>,
    "flyer_speed": <new_value or null>,
    "flyer_gold": <new_value or null>,
    "swarm_hp": <new_value or null>,
    "swarm_speed": <new_value or null>,
    "swarm_gold": <new_value or null>,
    "stealth_hp": <new_value or null>,
    "stealth_speed": <new_value or null>,
    "stealth_gold": <new_value or null>,
    "breaker_hp": <new_value or null>,
    "breaker_speed": <new_value or null>,
    "breaker_armor": <new_value or null>,
    "breaker_gold": <new_value or null>,
    "breaker_wall_damage": <new_value or null>,
    "boss_golem_hp": <new_value or null>,
    "boss_golem_speed": <new_value or null>,
    "boss_golem_armor": <new_value or null>,
    "boss_golem_gold": <new_value or null>,
    "boss_golem_regen": <new_value or null>,
    "shrine_hp": <new_value or null>,
    "enemy_shrine_damage": <new_value or null>
  }},
  "reasoning": "Why these specific changes will help achieve the targets",
  "expected_impact": "What results we expect to see next iteration",
  "confidence": <0-100>,
  "converged": <true if all targets are met by best strategy, false otherwise>
}}"""
