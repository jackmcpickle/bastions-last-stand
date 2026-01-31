"""Tests for config_manager.py"""

import json
from pathlib import Path
import pytest
from config_manager import ConfigManager


@pytest.fixture
def tmp_project(tmp_path):
    """Create temp project dir."""
    return tmp_path


@pytest.fixture
def manager(tmp_project):
    """ConfigManager with temp project."""
    return ConfigManager(tmp_project)


def test_read_config_defaults(manager):
    """read_config returns defaults when no file exists."""
    config = manager.read_config()
    assert config["starting_gold"] == 120
    assert config["archer_cost"] == 80
    assert config["grunt_hp"] == 60


def test_write_config(manager, tmp_project):
    """write_config saves JSON file."""
    config = {"starting_gold": 200, "archer_cost": 100}
    manager.write_config(config)

    with open(tmp_project / "balance_config.json") as f:
        saved = json.load(f)

    assert saved["starting_gold"] == 200
    assert saved["archer_cost"] == 100


def test_apply_changes(manager):
    """apply_changes merges changes with existing config."""
    # First write defaults
    manager.write_config(manager._get_defaults())

    # Apply partial changes
    updated = manager.apply_changes({"starting_gold": 150, "archer_cost": 90})

    assert updated["starting_gold"] == 150
    assert updated["archer_cost"] == 90
    # Unchanged values preserved
    assert updated["grunt_hp"] == 60

    # Verify persisted
    reloaded = manager.read_config()
    assert reloaded["starting_gold"] == 150
