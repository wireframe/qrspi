# Comparison: old vs new `/qrspi:implement`
Date: 2026-11-01
Plan: [plan.md](plan.md) Task 5.3 · Decisions: D4, D15

This note is for reviewers of the model-selection change. It records one replay of the same completed plan under the old and the new `/qrspi:implement`, and what the numbers say about where the cost goes.

## Setup

- **Replayed plan:** `docs/plans/2026-08-25-qrspi-gate-revisions` (4 phases, 15 tasks, edits to 5 `commands/*.md` files plus `plugin.json` and `README.md`), copied from `bc4b238` with every checkbox reset, on a clone at `e46ce3d` with no git remote (so each run stops at the PR step).
- **Arms:** old = plugin at `02e7cb8`; new = plugin at `f1e3893`. Each run: `claude -p "/qrspi:implement …" --plugin-dir <arm> --settings '{"enabledPlugins":{"qrspi@qrspi":false}}' --model opus --permission-mode bypassPermissions --output-format json`.
- **Runs:** one per arm, so treat differences as indicative, not statistically meaningful.

## Results

| Arm | Cost | Wall time | Main-thread dispatches | Commits | Plan checks | Diff vs original commit (`bc4b238`, `commands/`) |
|---|---|---|---|---|---|---|
| Old | $6.70 (Opus $6.70) | 13.7 min | 12 general-purpose | 2 | 18/18 | +31 / −11 |
| New | $10.23 (Opus $8.59, Sonnet $1.61, Haiku $0.02) | 19.8 min | 20 implementer, 13 spec-reviewer, 13 quality-reviewer, 4 quality-gate | 6 | 18/18 | +5 / −5 |

Escalation did not trigger in either run (no task failed verification).

## Findings

- **The new implement costs more on this plan: about 53% more money and 45% more time.** The old arm took a shortcut. It merged Phases 2–4 into one implementation step with one quality gate and one commit, so it made 12 dispatches where the new arm made 50. The comparison mostly measures how closely each arm follows the process, not a model swap on equal work.
- **The pinned per-task roles are cheap.** 20 Sonnet implementers and 26 reviewers cost $1.63 together, 16% of the run.
- **Opus is still 84% of the new run's cost.** It comes from three places:
  - the Opus orchestrator, whose context is re-read on each of its 64 turns: 8.9M cache-read tokens, against 6.5M in the old run
  - four `quality-gate` subagents on the session model
  - their `/simplify` and `/code-review` forks, which also inherit Opus
- **The new arm stayed closer to the plan.** Both arms pass every check. The new arm's diff is nearly the size of the human-approved original. Its final gate reverted five review edits that contradicted earlier decisions. The old arm added an unplanned feature: recording Open-decision answers from gates.

## Levers this suggests (not done here)

- Run phase gates on Sonnet and keep only the final pass on the session model. The gates and their skill forks are the largest share of Opus spend outside the orchestrator.
- Shrink the orchestrator's per-dispatch overhead. Every review round-trip re-reads its growing context on Opus.
- Merge the final pass into the last phase's gate on one-phase plans. On larger plans, skip the last phase's `/code-review medium`, since the final `high` pass covers it.
- Skip per-task reviews for check-only tasks. The new orchestrator already did this on its own for Tasks 2.6 and 4.6.

## Related Documents

- [decisions.md](decisions.md): D2 (quality bar), D4 and D15 (this comparison)
- [plan.md](plan.md): Task 5.3
