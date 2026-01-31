"""Detailed logging for optimization runs."""

import json
from datetime import datetime
from pathlib import Path
from typing import Dict, Any, List

# Strategy layouts - hardcoded to match main.gd
# Map: 10x10, spawns at (2,0) and (7,0), shrine at (4,4)-(5,5)
STRATEGIES = {
    "a": {
        "name": "DualTower",
        "towers": [(3, 2), (6, 2)],
        "walls": [],
    },
    "b": {
        "name": "TripleTower",
        "towers": [(3, 3), (4, 2), (6, 3)],
        "walls": [],
    },
    "c": {
        "name": "Flanking",
        "towers": [(1, 2), (8, 2)],
        "walls": [],
    },
    "d": {
        "name": "CentralDefense",
        "towers": [(3, 4), (6, 4)],
        "walls": [],
    },
}

MAP_WIDTH = 10
MAP_HEIGHT = 10
SPAWNS = [(2, 0), (7, 0)]
SHRINE_ZONE = [(4, 4), (5, 4), (4, 5), (5, 5)]


def render_board(strategy_id: str) -> str:
    """Render ASCII board for a strategy."""
    strat = STRATEGIES.get(strategy_id, {})
    towers = set(strat.get("towers", []))
    walls = set(strat.get("walls", []))

    lines = []
    lines.append(f"Strategy {strategy_id.upper()}: {strat.get('name', '?')}")
    lines.append("  " + " ".join(str(i) for i in range(MAP_WIDTH)))
    lines.append("  " + "-" * (MAP_WIDTH * 2 - 1))

    for y in range(MAP_HEIGHT):
        row = []
        for x in range(MAP_WIDTH):
            pos = (x, y)
            if pos in towers:
                row.append("T")  # Tower
            elif pos in walls:
                row.append("#")  # Wall
            elif pos in SPAWNS:
                row.append("S")  # Spawn
            elif pos in SHRINE_ZONE:
                row.append("X")  # Shrine
            else:
                row.append(".")  # Empty
        lines.append(f"{y}|" + " ".join(row))

    lines.append("")
    lines.append("Legend: S=Spawn T=Tower #=Wall X=Shrine .=Empty")
    return "\n".join(lines)


class Logger:
    def __init__(self, results_dir: str = "results"):
        self.results_dir = Path(__file__).parent / results_dir
        self.results_dir.mkdir(exist_ok=True)
        self.run_id = datetime.now().strftime("%Y%m%d_%H%M%S")
        self.log_file = self.results_dir / f"run_{self.run_id}.log"
        self.iterations: List[Dict[str, Any]] = []
        self.goal = ""
        self.targets = {}

    def _log(self, msg: str) -> None:
        """Write to console and log file."""
        timestamp = datetime.now().strftime("%H:%M:%S")
        line = f"[{timestamp}] {msg}"
        print(line)
        with open(self.log_file, "a") as f:
            f.write(line + "\n")

    def log_start(self, goal: str, targets: Dict[str, Any]) -> None:
        """Log optimization start."""
        self.goal = goal
        self.targets = targets

        self._log("=" * 60)
        self._log("AI BALANCE OPTIMIZER")
        self._log("=" * 60)
        self._log(f"Goal: {goal}")
        self._log(f"Targets:")
        for key, (min_val, max_val) in targets.items():
            self._log(f"  {key}: {min_val} - {max_val}")
        self._log("")

        # Log all strategy boards
        self._log("STRATEGY LAYOUTS:")
        self._log("")
        for strat_id in ["a", "b", "c", "d"]:
            board = render_board(strat_id)
            for line in board.split("\n"):
                self._log(line)
            self._log("")

    def log_iteration_start(self, iteration: int) -> None:
        """Log iteration start."""
        self._log("-" * 40)
        self._log(f"ITERATION {iteration + 1}")
        self._log("-" * 40)

    def log_config(self, config: Dict[str, Any]) -> None:
        """Log current config."""
        self._log("Current Config:")
        key_params = [
            "starting_gold",
            "wall_cost",
            "archer_cost",
            "archer_damage",
            "archer_attack_speed_ms",
            "archer_range",
            "grunt_hp",
            "runner_hp",
            "shrine_hp",
        ]
        for k in key_params:
            if k in config:
                self._log(f"  {k}: {config[k]}")

    def log_results(self, results: Dict[str, Any]) -> None:
        """Log simulation results."""
        self._log("Simulation Results:")
        strategies = results.get("strategies", {})
        for strat_id in ["a", "b", "c", "d"]:
            if strat_id not in strategies:
                continue
            data = strategies[strat_id]
            self._log(f"  Strategy {strat_id.upper()} ({data.get('name', '')}):")
            self._log(f"    Win rate: {data['win_rate'] * 100:.1f}%")
            self._log(f"    Shrine HP: {data['avg_shrine_hp']:.1f}")
            self._log(f"    Gold: {data['avg_gold']:.1f}")
            self._log(
                f"    Killed/Leaked: {data['avg_killed']:.0f}/{data['avg_leaked']:.0f}"
            )

    def log_recommendations(self, rec: Dict[str, Any]) -> None:
        """Log Haiku recommendations."""
        self._log("Haiku Analysis:")
        self._log(f"  {rec.get('analysis', 'No analysis')}")
        self._log(f"  Best strategy: {rec.get('best_strategy', '?')}")
        self._log(f"  Off-target: {rec.get('off_target_metrics', [])}")
        self._log(f"  Reasoning: {rec.get('reasoning', 'No reasoning')}")
        self._log(f"  Expected impact: {rec.get('expected_impact', 'Unknown')}")
        self._log(f"  Confidence: {rec.get('confidence', 0)}%")

        changes = rec.get("changes", {})
        if changes:
            self._log("  Recommended changes:")
            for k, v in changes.items():
                if v is not None:
                    self._log(f"    {k}: {v}")

    def log_changes_applied(self, changes: Dict[str, Any]) -> None:
        """Log applied changes."""
        self._log("Changes applied:")
        for k, v in changes.items():
            if v is not None:
                self._log(f"  {k} -> {v}")

    def log_success(self, iteration: int) -> None:
        """Log success."""
        self._log("")
        self._log("=" * 60)
        self._log(f"SUCCESS! Targets met after {iteration + 1} iterations")
        self._log("=" * 60)

    def log_converged(self, iteration: int) -> None:
        """Log convergence."""
        self._log("")
        self._log(f"Haiku reports convergence at iteration {iteration + 1}")

    def log_max_iterations(self) -> None:
        """Log max iterations reached."""
        self._log("")
        self._log("=" * 60)
        self._log("MAX ITERATIONS REACHED - targets not fully met")
        self._log("=" * 60)

    def log_summary(self) -> None:
        """Log final summary."""
        self._log("")
        self._log("=" * 60)
        self._log("OPTIMIZATION COMPLETE")
        self._log("=" * 60)
        self._log(f"Total iterations: {len(self.iterations)}")
        self._log(f"Log saved to: {self.log_file}")

        # Save iterations to JSON
        json_file = self.results_dir / f"run_{self.run_id}.json"
        with open(json_file, "w") as f:
            json.dump(
                {
                    "goal": self.goal,
                    "targets": {k: list(v) for k, v in self.targets.items()},
                    "iterations": self.iterations,
                },
                f,
                indent=2,
            )
        self._log(f"Data saved to: {json_file}")

    def save_iteration(
        self,
        iteration: int,
        config: Dict[str, Any],
        results: Dict[str, Any],
        recommendations: Dict[str, Any],
    ) -> None:
        """Save iteration data."""
        self.iterations.append(
            {
                "iteration": iteration,
                "config": config,
                "results": results.get("strategies", {}),
                "best_strategy": results.get("best_strategy"),
                "recommendations": recommendations,
            }
        )

        # Also save individual iteration file
        iter_file = self.results_dir / f"iteration_{self.run_id}_{iteration}.json"
        with open(iter_file, "w") as f:
            json.dump(self.iterations[-1], f, indent=2)
