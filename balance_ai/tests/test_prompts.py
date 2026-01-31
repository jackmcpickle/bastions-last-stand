"""Tests for prompts.py"""

from prompts import build_analysis_prompt


def test_build_analysis_prompt():
    """build_analysis_prompt includes all required sections."""
    config = {
        "starting_gold": 120,
        "archer_cost": 80,
        "archer_damage": 15000,
        "archer_attack_speed_ms": 800,
        "archer_range": 5,
        "grunt_hp": 60,
        "grunt_speed": 1000,
        "grunt_gold": 5,
    }
    results = {
        "strategies": {
            "a": {
                "name": "Basic",
                "win_rate": 0.75,
                "avg_shrine_hp": 80.0,
                "avg_gold": 50.0,
                "avg_killed": 100,
                "avg_leaked": 5,
            }
        }
    }
    targets = {
        "win_rate": (0.7, 0.85),
        "shrine_hp": (60, 80),
        "gold_remaining": (20, 50),
        "enemies_leaked": (0, 10),
    }
    parameter_bounds = {
        "starting_gold": {"min": 50, "max": 200, "step": 10},
        "archer_cost": {"min": 50, "max": 150, "step": 10},
    }

    prompt = build_analysis_prompt(
        config=config,
        results=results,
        targets=targets,
        goal="Balance early game",
        parameter_bounds=parameter_bounds,
    )

    # Check required sections present
    assert "Balance early game" in prompt
    assert "Strategy A (Basic)" in prompt
    assert "75.0%" in prompt
    assert "starting_gold: 50 to 200" in prompt
    assert "Output ONLY valid JSON" in prompt
