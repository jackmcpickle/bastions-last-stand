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
        "starting_gold",
        "wall_cost",
        "archer_cost",
        "archer_damage",
        "archer_attack_speed_ms",
        "archer_range",
        "grunt_hp",
        "grunt_speed",
        "grunt_gold",
        "runner_hp",
        "runner_speed",
        "runner_gold",
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
- Starting gold: {config.get("starting_gold", 120)}
- Wall cost: {config.get("wall_cost", 10)}g
- Archer tower: {config.get("archer_cost", 80)}g cost, {config.get("archer_damage", 15000) // 1000} damage, {config.get("archer_attack_speed_ms", 800)}ms attack speed, {config.get("archer_range", 5)} tile range
- Grunt enemy: {config.get("grunt_hp", 60)} HP, {config.get("grunt_speed", 1000) / 1000:.1f} tiles/sec speed, {config.get("grunt_gold", 5)}g reward
- Runner enemy: {config.get("runner_hp", 40)} HP, {config.get("runner_speed", 2000) / 1000:.1f} tiles/sec speed, {config.get("runner_gold", 8)}g reward
- Shrine: {config.get("shrine_hp", 100)} HP
- Enemy shrine damage: {config.get("enemy_shrine_damage", 1)} per enemy

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
    "archer_cost": <new_value or null>,
    "archer_damage": <new_value or null>,
    "archer_attack_speed_ms": <new_value or null>,
    "archer_range": <new_value or null>,
    "grunt_hp": <new_value or null>,
    "grunt_speed": <new_value or null>,
    "grunt_gold": <new_value or null>,
    "runner_hp": <new_value or null>,
    "runner_speed": <new_value or null>,
    "runner_gold": <new_value or null>,
    "shrine_hp": <new_value or null>,
    "enemy_shrine_damage": <new_value or null>
  }},
  "reasoning": "Why these specific changes will help achieve the targets",
  "expected_impact": "What results we expect to see next iteration",
  "confidence": <0-100>,
  "converged": <true if all targets are met by best strategy, false otherwise>
}}"""
