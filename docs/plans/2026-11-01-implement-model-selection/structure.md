# Structure: Model selection in /qrspi:implement
Date: 2026-11-01
Decisions: [decisions.md](decisions.md)
Research: [research.md](research.md)

Every decision behind this plan is `Preference`, so no phase is a fixed requirement. The phases flagged below are the ones most worth confirming before building.

## Phase 1: Implement eval baseline
**Goal:** Add the first `/qrspi:implement` eval: a scaffolded fixture git repo with a tiny one-phase plan, plus characterization graders that pass on today's behavior (plan checkboxes ticked, phase committed). Also find out whether a `tool_used` grader can match `Agent` inputs (`subagent_type`, `model`), and whether subagent tool calls appear in `trace`. Later phases add red-then-green graders to this case.
**Files touched:** `evals/implement-*/case.yaml`, `evals/implement-*/prompt.md`, `evals/implement-*/graders/*.md`, the fixture scaffold script, `evals/README.md`
**Depends on:** nothing
**Verification:** `claude plugin eval . --case implement-<name> --scaffold --runs 1` passes on the current `implement.md`. The README records whether Agent-input and sidechain matching work.
**Flag:** Serves Preference decision D4. If Agent inputs can't be matched, later phases fall back to `llm` graders with `focus: trace`, or to the comparison run alone.

## Phase 2: Role agents dispatched from the main thread
**Goal:** Ship `qrspi:implementer` (sonnet), `qrspi:spec-reviewer` (haiku, read-only) and `qrspi:quality-reviewer` (sonnet, runs `/qrspi:code-review`, so `Skill` is in its tools). `implement.md` dispatches them by name from the main thread and relays fixes to the implementer. Per-task review drops `/code-review`; only spec review and the `/qrspi:code-review` checklist remain.
**Files touched:** `agents/implementer.md`, `agents/spec-reviewer.md`, `agents/quality-reviewer.md`, `commands/implement.md` (Subagent-Driven Development section)
**Depends on:** Phase 1
**Verification:** New graders in the Phase 1 case go red on the old `implement.md`, then green: each role is dispatched by its agent name, and no per-task `/code-review` runs.
**Decisions:** D3, D5, D6, D7, D10, D12, D16

## Phase 3: Escalation before blocking
**Goal:** Define "repeated fix attempts" as the first try plus two fixes. After that, the main thread dispatches a fresh `qrspi:implementer` with `model: opus` and the failure history. If Opus also fails, the task is a blocker.
**Files touched:** `commands/implement.md` (Subagent-Driven Development and Blockers sections), a second eval fixture or case whose task can never pass verification
**Depends on:** Phase 2
**Verification:** In an eval whose verify command always fails, the trace shows an Agent dispatch with `model: opus` after the Sonnet attempts, and the run ends with a blocker message instead of a PR.
**Decisions:** D8, D9

## Phase 4: Seam reviews in subagents with pinned effort
**Goal:** The phase Quality Gate and the final whole-diff pass each run in a fresh subagent on the session model. They call `/code-review medium --fix` (gate) and `/code-review high` (final), and return a summary that the main thread uses for commit messages and the PR body.
**Files touched:** `commands/implement.md` (Quality Gate, final pass, Open Pull Request sections); possibly a session-model gate agent under `agents/`
**Depends on:** Phase 1. Lands after Phase 3, since both edit `implement.md`.
**Verification:** Phase 1 case graders: the gate and final pass appear as Agent dispatches, the effort level is passed explicitly, and the commit and PR text still describe gate fixes. Whether the effort arguments can be graded depends on Phase 1's sidechain finding.
**Flag:** Serves Preference decision D13 and uses all three nesting layers (gate → `/code-review` fork → reviewers). If the gate fails at depth during verification, fall back to pinned effort levels with the gate kept in the main thread, and say so in the PR.
**Decisions:** D11, D13

## Phase 5: Docs, version, and comparison run
**Goal:** Update the README's implement entry for role models, escalation and offloaded seams. Bump `plugin.json` to `0.6.0`. Replay `2026-08-25-qrspi-gate-revisions` (start `e46ce3d`, plan files copied from `bc4b238`) once with the old and once with the new `implement.md` on scratch branches. Record cost, wall time and diff quality in `comparison.md`.
**Files touched:** `README.md`, `.claude-plugin/plugin.json`, `docs/plans/2026-11-01-implement-model-selection/comparison.md`
**Depends on:** Phases 2-4
**Verification:** `jq .version .claude-plugin/plugin.json` prints `0.6.0`. The README names the role models. `comparison.md` shows both runs' numbers, and the scratch branches and PRs are cleaned up.
**Flag:** The comparison run serves Preference decisions D4/D15 and costs two full runs. Confirm it's worth doing. Because the replayed plan has no executable tests, it measures cost, time and diff quality only.
**Decisions:** D4, D14, D15

## Out of Scope
- Opt-out switch back to inherited models (D14, Preference). Easy to add if someone asks.
- Per-task model tags in `plan.md` or changes to `/qrspi:plan` (the alternative rejected for D3).
- Model choice for `/qrspi:research`'s Explore agents.
- Guarding against `CLAUDE_CODE_SUBAGENT_MODEL_FORCE` or a lowered `CLAUDE_CODE_MAX_SUBAGENT_SPAWN_DEPTH`. The plugin can't prevent either, so the README documents them.
