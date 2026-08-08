# Unused Enemies Wave Roster Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Register unused enemies and place them in the 30-wave roster per the approved spec.

**Architecture:** Data + registration only. Wave factories own composition; battle/CLI register `.tres` by id; level metadata lists featured types; GUT asserts roster coverage.

**Tech Stack:** Godot 4 GDScript, GUT

## Global Constraints

- Follow `docs/superpowers/specs/2026-08-08-unused-enemies-wave-roster-design.md` exactly for wave/boss/counts
- Tabs for indentation; snake_case; lines ≤100 chars
- `mini` registered but never in wave spawn groups
- Keep rush/smash wave numbers unchanged

---

### Task 1: Failing roster test

**Files:**
- Create: `tests/unit/test_wave_roster.gd`

- [ ] Write test asserting standards, bosses, mini absence, milestone placements
- [ ] Run GUT on the file; confirm fail
- [ ] Commit

### Task 2: Wave composition

**Files:**
- Modify: `resources/waves/waves_1_10.gd`
- Modify: `resources/waves/waves_11_30.gd`

- [ ] Wave 10: prepend `swarm_queen`×1
- [ ] Waves 13/16/17/19/21–25/27–30 per spec counts
- [ ] Wave 20: `phase_phantom` replaces `boss_golem`
- [ ] Wave 30: prepend `iron_colossus`×1 keep `boss_golem`×3
- [ ] Run roster tests; pass
- [ ] Commit

### Task 3: Registration + level metadata

**Files:**
- Modify: `ui/screens/battle_screen.gd`
- Modify: `main.gd`
- Modify: `resources/levels/ch1_lv2.tres`, `ch1_lv3.tres`, `ch2_lv1.tres`, `ch2_lv2.tres`, `ch3_lv1.tres`, `ch3_lv2.tres`, `ch3_lv3.tres`

- [ ] Register 10 new enemy resources in both runners
- [ ] Append `enemy_types` per spec
- [ ] Lint touched GDScript
- [ ] Commit
