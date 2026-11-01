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

- **The new implement costs more on this plan: about 53% more money and 45% more time.** The old arm took a shortcut. It merged Phases 2–4 into one implementation step with one quality gate and one commit, so it made 12 dispatches where the new arm made 50. The comparison mostly measures how closely each arm follows the process, not a model swap on equal work. The Fair comparison section below isolates the model swap.
- **The pinned per-task roles are cheap.** 20 Sonnet implementers and 26 reviewers cost $1.63 together, 16% of the run.
- **Opus is still 84% of the new run's cost.** It comes from three places:
  - the Opus orchestrator, whose context is re-read on each of its 64 turns: 8.9M cache-read tokens, against 6.5M in the old run
  - four `quality-gate` subagents on the session model
  - their `/simplify` and `/code-review` forks, which also inherit Opus
- **The new arm stayed closer to the plan.** Both arms pass every check. The new arm's diff is nearly the size of the human-approved original. Its final gate reverted five review edits that contradicted earlier decisions. The old arm added an unplanned feature: recording Open-decision answers from gates.

## Fair comparison: same process, every subagent on Opus

The old arm took a shortcut, so the head-to-head above mixes two effects. To isolate model pinning, I re-priced the new run's own token counts as if its Sonnet and Haiku roles had run on Opus. Gates and orchestration are unchanged.

| Tokens | Billed | Re-priced at Opus 5.5 rates |
|---|---|---|
| Sonnet roles: 19K output, 524K cache write, 1.12M cache read | $1.61 | ≈ $3.0 |
| Haiku role: 8K output, 91K cache write, 152K cache read | $0.02 | ≈ $0.65 |
| Opus (orchestrator and gates) | $8.59 | $8.59 |
| **Total** | **$10.23** | **≈ $12.2** |

- **Prices used** (per MTok): Opus $4 input, $20 output, $5 cache write, $0.20 cache read; Sonnet $2 / $10 / $2.50 / $0.20; Haiku $0.10 / $0.50 / $0.125 / $0.01. Applying these to the logged tokens reproduces each model's billed cost within about 5%.
- **Result:** pinning saves about $2 on this run, roughly **16–17%**.
- **Where the saving comes from:** cache writes and output. Opus and Sonnet charge the same for cache reads, which are most of the token volume. Every fresh subagent writes its own cache, about 615K tokens in this run.
- **Assumption:** Opus subagents would use the same tokens. Opus may write more output or need fewer fix rounds. Escalation didn't trigger, so no Opus implementer retries offset the saving.

## Speed

Timings come from the new run's transcripts. Generation time runs from the message a model responded to until its response finished, so it includes thinking.

| Model | Calls | Output tokens | Generation time | Output tokens/sec |
|---|---|---|---|---|
| Opus 5.5 | 171 | 121K | 665 s | 182 |
| Sonnet 5.5 | 60 | 19K | 69 s | 279 (≈ 1.5× Opus) |
| Haiku 5.5 | 24 | 8K | 24 s | 336 (≈ 1.8× Opus) |

Where the 19.8-minute run went (summed agent lifetimes):

| Part | Time |
|---|---|
| Quality gates, with their `/code-review` and `/simplify` reviewers | ≈ 11 min |
| Per-task loop: implementer, spec reviewer, quality reviewer | ≈ 3.5 min, of which ≈ 1.5 min is generation |
| Main-thread generation | ≈ 5 min |

- **Re-timing:** at Opus's measured speed, the Sonnet and Haiku output would add about 1 minute of generation, or 2–3 minutes if Opus also wrote more per call. Its calls here averaged about twice the output.
- **Result:** pinning saves roughly **1–3 minutes, about 5–15%**. The per-task loop is strictly sequential, so time saved there comes straight off the total.
- **Why it's small here:** this plan's tasks are one-line markdown edits checked with `grep`. On code tasks with real tests and fix rounds, the per-task loop is a bigger share of the run and Sonnet's speed matters more.
- **Caveats:** this is one run. Tokens per second vary with server load and thinking length, and the timings include time to the first token.

## Levers this suggests (not done here)

- Run phase gates on Sonnet and keep only the final pass on the session model. The gates and the reviewers they start are the largest share of Opus spend outside the orchestrator, and more than half the wall time.
- Shrink the orchestrator's per-dispatch overhead. Every review round-trip re-reads its growing context on Opus.
- Merge the final pass into the last phase's gate on one-phase plans. On larger plans, skip the last phase's `/code-review medium`, since the final `high` pass covers it.
- Skip per-task reviews for check-only tasks. The new orchestrator already did this on its own for Tasks 2.6 and 4.6.

## Related Documents

- [decisions.md](decisions.md): D2 (quality bar), D4 and D15 (this comparison)
- [plan.md](plan.md): Task 5.3
