"""Runs Godot simulations and parses output."""

import subprocess
import json
from pathlib import Path
from typing import Dict, Any, Optional

GODOT_PATH = "godot"
PROJECT_PATH = Path(__file__).parent.parent


class SimulationRunner:
    def __init__(self, godot_path: str = GODOT_PATH, project_path: Path = PROJECT_PATH):
        self.godot_path = godot_path
        self.project_path = project_path

    def run_simulations(
        self,
        count: int = 1000,
        strategy: str = "all",
        seed: int = 12345,
        config_path: str = "balance_config.json",
    ) -> Dict[str, Any]:
        """Run simulations and return parsed JSON results."""

        cmd = [
            self.godot_path,
            "--headless",
            "--path",
            str(self.project_path),
            "--",
            "--config",
            config_path,
            "--strategy",
            strategy,
            "--count",
            str(count),
            "--seed",
            str(seed),
            "--json",
        ]

        result = subprocess.run(
            cmd,
            capture_output=True,
            text=True,
            cwd=self.project_path,
            timeout=300,  # 5 minute timeout
        )

        if result.returncode != 0:
            raise RuntimeError(f"Godot failed: {result.stderr}")

        # Parse JSON from stdout (skip Godot engine header line)
        output = result.stdout
        lines = output.strip().split("\n")

        # Find the JSON line (starts with {)
        json_line = None
        for line in lines:
            if line.strip().startswith("{"):
                json_line = line
                break

        if not json_line:
            raise RuntimeError(f"No JSON output found in: {output}")

        return json.loads(json_line)

    def save_config(self, config: Dict[str, Any]) -> None:
        """Save config to balance_config.json."""
        config_path = self.project_path / "balance_config.json"
        with open(config_path, "w") as f:
            json.dump(config, f, indent=2, sort_keys=True)
