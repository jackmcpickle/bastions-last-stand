#!/usr/bin/env python3
"""
AI Balance Optimizer for Bastion's Last Stand
Uses Claude Haiku to iteratively tune game balance.

Usage:
  python optimizer.py --goal "Your optimization goal here"
  python optimizer.py --goal "..." --max-iterations 5 --runs 500
  python optimizer.py --goal "..." --dry-run
"""

import argparse
import sys
from pathlib import Path
from typing import Dict, Any, Tuple

from haiku_client import HaikuClient
from simulation_runner import SimulationRunner
from config_manager import ConfigManager
from logger import Logger

MAX_ITERATIONS = 10
RUNS_PER_STRATEGY = 1000

# Target metrics
TARGETS: Dict[str, Tuple[float, float]] = {
    "win_rate": (0.95, 1.0),  # 95-100%
    "shrine_hp": (85, 100),  # 85-100 avg
    "gold_remaining": (0, 20),  # 0-20 avg
    "enemies_leaked": (0, 5),  # 0-5 avg
}


def check_targets_met(
    results: Dict[str, Any], targets: Dict[str, Tuple[float, float]]
) -> bool:
    """Check if best strategy meets all targets."""
    strategies = results.get("strategies", {})
    if not strategies:
        return False

    # Find best strategy
    best = max(strategies.values(), key=lambda s: s.get("win_rate", 0))

    win_rate = best.get("win_rate", 0)
    shrine_hp = best.get("avg_shrine_hp", 0)
    gold = best.get("avg_gold", 0)
    leaked = best.get("avg_leaked", float("inf"))

    return (
        targets["win_rate"][0] <= win_rate <= targets["win_rate"][1]
        and targets["shrine_hp"][0] <= shrine_hp <= targets["shrine_hp"][1]
        and targets["gold_remaining"][0] <= gold <= targets["gold_remaining"][1]
        and targets["enemies_leaked"][0] <= leaked <= targets["enemies_leaked"][1]
    )


def filter_changes(changes: Dict[str, Any]) -> Dict[str, Any]:
    """Filter out null changes."""
    return {k: v for k, v in changes.items() if v is not None}


def main():
    parser = argparse.ArgumentParser(
        description="AI Balance Optimizer for Bastion's Last Stand"
    )
    parser.add_argument(
        "--goal", type=str, required=True, help="Optimization goal description"
    )
    parser.add_argument(
        "--max-iterations",
        type=int,
        default=MAX_ITERATIONS,
        help=f"Maximum iterations (default: {MAX_ITERATIONS})",
    )
    parser.add_argument(
        "--runs",
        type=int,
        default=RUNS_PER_STRATEGY,
        help=f"Simulations per strategy (default: {RUNS_PER_STRATEGY})",
    )
    parser.add_argument(
        "--dry-run", action="store_true", help="Don't apply changes, just analyze"
    )
    args = parser.parse_args()

    # Initialize components
    logger = Logger()
    config_mgr = ConfigManager()
    sim_runner = SimulationRunner()

    try:
        haiku = HaikuClient()
    except ValueError as e:
        print(f"ERROR: {e}")
        print("Please create a .env file with your ANTHROPIC_API_KEY")
        sys.exit(1)

    logger.log_start(args.goal, TARGETS)

    for iteration in range(args.max_iterations):
        logger.log_iteration_start(iteration)

        # 1. Get current config
        config = config_mgr.read_config()
        logger.log_config(config)

        # 2. Run simulations
        try:
            results = sim_runner.run_simulations(count=args.runs, strategy="all")
        except Exception as e:
            logger._log(f"ERROR running simulations: {e}")
            break

        logger.log_results(results)

        # 3. Check if targets met
        if check_targets_met(results, TARGETS):
            logger.log_success(iteration)
            logger.save_iteration(iteration, config, results, {"converged": True})
            break

        # 4. Ask Haiku for recommendations
        try:
            recommendations = haiku.analyze(config, results, TARGETS, args.goal)
        except Exception as e:
            logger._log(f"ERROR calling Haiku: {e}")
            break

        logger.log_recommendations(recommendations)
        logger.save_iteration(iteration, config, results, recommendations)

        # 5. Apply changes (unless dry-run)
        changes = filter_changes(recommendations.get("changes", {}))
        if not args.dry_run and changes:
            config_mgr.apply_changes(changes)
            logger.log_changes_applied(changes)
        elif args.dry_run:
            logger._log("DRY RUN - changes not applied")

        # 6. Check if Haiku says converged
        if recommendations.get("converged"):
            logger.log_converged(iteration)
            break

        # Check if no changes recommended (stuck)
        if not changes:
            logger._log("WARNING: No changes recommended, may be stuck")
    else:
        logger.log_max_iterations()

    logger.log_summary()


if __name__ == "__main__":
    main()
