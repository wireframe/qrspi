# qrspi

A five-phase workflow — **Q**uestion, **R**esearch, **S**tructure, **P**lan, **I**mplement — for scoping and executing software changes with [Claude Code](https://code.claude.com).

Each phase writes a markdown artifact that the next phase reads, so a change goes from a vague request to a reviewed, executed plan with a clear paper trail at every step. When a phase finishes, it asks a quick continue/stop question — one click gets you the next command to run — and folds revisions into that same question: type your changes as a free-text reply (`AskUserQuestion`'s built-in "Other" option) instead of picking a button, and they're applied in place without a separate follow-up turn.

[![QRSPI walkthrough](https://img.youtube.com/vi/YwZR6tc7qYg/0.jpg)](https://www.youtube.com/watch?v=YwZR6tc7qYg)

## Install

```
/plugin marketplace add wireframe/qrspi
/plugin install qrspi@qrspi
```

## Commands

- **`/qrspi:question <topic>`** — Surface the decisions only you can make, in rounds with a recommended answer. Implementation choices are listed as Deferred for research. Writes `decisions.md`.
- **`/qrspi:research <plans-folder>`** — Research the codebase based on scoped questions from `/qrspi:question`'s decisions, and lay out options for each Deferred decision (without recommending one) for you to pick before structuring. Writes `research.md`.
- **`/qrspi:structure <plans-folder>`** — Break the work into 3-5 independently testable phases based on research findings, shaped as vertical slices: each phase ships one behavior end to end, with its docs. Phases describe goals, dependencies and verification; file paths are left to `/qrspi:plan`. Writes `structure.md`.
- **`/qrspi:plan <plans-folder>`** — Create a detailed implementation plan with bite-sized tasks grouped by structure phases. Writes `plan.md`.
- **`/qrspi:implement <plans-folder>`** — Execute the plan, dispatching each task's implementer and reviewers as subagents on pinned models (see [Models](#models)). A quality gate runs in a subagent after each phase, then a final whole-diff pass before the PR. Once the plan is done, drafts a pull request body from the plan's artifacts and opens it with `gh pr create`. Runs unattended from start to PR — review happens on the PR — stopping early only if a task is blocked.

Run them in order on a new folder under `docs/plans/YYYY-MM-DD-<topic>/`:

```
/qrspi:question add rate limiting to the API
/qrspi:research docs/plans/2026-01-01-rate-limiting
/qrspi:structure docs/plans/2026-01-01-rate-limiting
/qrspi:plan docs/plans/2026-01-01-rate-limiting
/qrspi:implement docs/plans/2026-01-01-rate-limiting
```

## Models

`/qrspi:implement` dispatches each role as a plugin agent with a pinned model:

| Agent | Role | Model |
| --- | --- | --- |
| `qrspi:implementer` | Implements a task; a stuck one is retried once on Opus before the task blocks | Sonnet (Opus on escalation) |
| `qrspi:spec-reviewer` | Read-only check of a task against its spec | Haiku |
| `qrspi:quality-reviewer` | Runs `/qrspi:code-review` on a task | Sonnet |
| `qrspi:quality-gate` | Runs the phase Quality Gate and the final pass | Session model (`inherit`) |

- Model precedence: the Agent call's `model` parameter, then the agent file's `model:` frontmatter, then `CLAUDE_CODE_SUBAGENT_MODEL`, then the session model.
- `CLAUDE_CODE_SUBAGENT_MODEL_FORCE=1` overrides every pin.
- To change one role, edit `model:` in its `agents/<name>.md`; the escalation model is the `model: opus` in `commands/implement.md`.
- The quality gate nests three subagent layers, so keep `CLAUDE_CODE_MAX_SUBAGENT_SPAWN_DEPTH` at its default of 3 or higher.

## Evals

Behavior tests live in `evals/` and run with `claude plugin eval`. See [evals/README.md](evals/README.md).

## License

MIT
