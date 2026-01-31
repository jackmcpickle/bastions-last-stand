"""Reads and writes balance config JSON files."""

import json
from pathlib import Path
from typing import Dict, Any, Optional

PROJECT_PATH = Path(__file__).parent.parent


class ConfigManager:
    def __init__(self, project_path: Path = PROJECT_PATH):
        self.project_path = project_path
        self.config_file = project_path / "balance_config.json"

    def read_config(self) -> Dict[str, Any]:
        """Read current config from JSON file."""
        if not self.config_file.exists():
            return self._get_defaults()

        with open(self.config_file) as f:
            return json.load(f)

    def write_config(self, config: Dict[str, Any]) -> None:
        """Write config to JSON file."""
        with open(self.config_file, "w") as f:
            json.dump(config, f, indent=2, sort_keys=True)

    def apply_changes(self, changes: Dict[str, Any]) -> Dict[str, Any]:
        """Apply changes to config and save. Returns updated config."""
        config = self.read_config()

        for key, value in changes.items():
            if value is not None and key in config:
                config[key] = value

        self.write_config(config)
        return config

    def _get_defaults(self) -> Dict[str, Any]:
        """Default config values."""
        return {
            # Economy
            "starting_gold": 120,
            "wall_cost": 10,
            "sell_rate_percent": 90,
            # Archer
            "archer_cost": 80,
            "archer_damage": 15000,
            "archer_attack_speed_ms": 800,
            "archer_range": 5,
            # Cannon
            "cannon_cost": 120,
            "cannon_damage": 25000,
            "cannon_attack_speed_ms": 1500,
            "cannon_range": 4,
            "cannon_aoe_radius": 1500,
            # Frost
            "frost_cost": 100,
            "frost_damage": 8000,
            "frost_attack_speed_ms": 600,
            "frost_range": 4,
            "frost_slow": 400,
            "frost_slow_duration_ms": 2500,
            # Lightning
            "lightning_cost": 140,
            "lightning_damage": 12000,
            "lightning_attack_speed_ms": 1200,
            "lightning_range": 5,
            "lightning_chain_count": 4,
            "lightning_chain_range": 2.5,
            # Flame
            "flame_cost": 90,
            "flame_damage": 6000,
            "flame_attack_speed_ms": 400,
            "flame_range": 3,
            "flame_burn_dps": 10000,
            "flame_burn_duration_ms": 4000,
            # Grunt
            "grunt_hp": 60,
            "grunt_speed": 1000,
            "grunt_gold": 5,
            # Runner
            "runner_hp": 40,
            "runner_speed": 2000,
            "runner_gold": 8,
            # Tank
            "tank_hp": 300,
            "tank_speed": 600,
            "tank_armor": 300,
            "tank_gold": 25,
            # Flyer
            "flyer_hp": 45,
            "flyer_speed": 1200,
            "flyer_gold": 12,
            # Swarm
            "swarm_hp": 15,
            "swarm_speed": 1300,
            "swarm_gold": 2,
            # Stealth
            "stealth_hp": 50,
            "stealth_speed": 1400,
            "stealth_gold": 15,
            # Breaker
            "breaker_hp": 180,
            "breaker_speed": 700,
            "breaker_armor": 200,
            "breaker_gold": 20,
            "breaker_wall_damage": 25,
            # Boss Golem
            "boss_golem_hp": 1500,
            "boss_golem_speed": 400,
            "boss_golem_armor": 400,
            "boss_golem_gold": 100,
            "boss_golem_regen": 5000,
            # Shrine
            "shrine_hp": 100,
            "enemy_shrine_damage": 1,
            # Waves
            "wave_spawn_interval_base_ms": 800,
            "wave_spawn_interval_rush_ms": 300,
            "wave_1_grunts": 5,
            "wave_2_grunts": 8,
            "wave_3_grunts": 10,
            "wave_4_grunts": 12,
            "wave_5_grunts": 15,
            "wave_6_grunts": 12,
            "wave_6_runners": 3,
            "wave_7_grunts": 10,
            "wave_7_runners": 6,
            "wave_8_runners": 25,
            "wave_9_grunts": 15,
            "wave_9_runners": 8,
            "wave_10_grunts": 18,
            "wave_10_runners": 10,
        }
