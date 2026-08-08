# Upgrade Balance Simulations Design

## Goal

Exercise all major tower/wall upgrade paths in headless batch sims so `balance_ai` and humans can tune upgrade power/costs — not just T1 archers.

## Scope (approved: matrix + AI)

1. **Upgrade schedules** on `SimulationRunner.run_single` / `run_batch`
2. **Strategy matrix** in `main.gd` covering each combat tower A/B finals + wall Fortress/Tar
3. **CLI `--ai balanced`** via `run_batch_with_ai`, with smarter upgrade + wall upgrade picks
4. **Upgrade reporting** in results (`tier` / `branch` / upgrade path ids)

## Out of scope

Rewriting Haiku prompts; support tower (not on this branch); every T3 leaf (one A final + one B final per tower).
