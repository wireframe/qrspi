# Plan: Model selection in /qrspi:implement
Date: 2026-11-01
Decisions: [decisions.md](decisions.md)
Research: [research.md](research.md)
Structure: [structure.md](structure.md)

> **For Claude:** Execute this plan task-by-task, phase by phase — see `/qrspi:implement`'s execution options.

**Goal:** Cut the cost and wall time of `/qrspi:implement` by pinning a model to each per-task role, escalating to Opus before blocking, pinning `/code-review` effort, and running the seam reviews in subagents.
**Architecture:** Four plugin agents in `agents/`: `implementer` (sonnet), `spec-reviewer` (haiku, read-only), `quality-reviewer` (sonnet, runs `/qrspi:code-review`) and `quality-gate` (inherit). The main thread of `commands/implement.md` dispatches all of them by name. Behavior is checked by new `claude plugin eval` cases that run `/qrspi:implement` against a scaffolded fixture repo, plus `grep` checks on the command text.
**Tech Stack:** Claude Code plugin markdown (commands, agents, skills), `claude plugin eval`, Bash fixture scripts, `jq`.

Shared commands used in Test lines:
- `EVAL_IMPL` = `claude plugin eval . --ablation none --no-publish --scaffold --runs 1 --allow-tools Write Edit Bash SendMessage`
- Static checks run from the repo root.

---

## Phase 1: Implement eval baseline

- [ ] Task 1.1: Fixture repo scaffold for the dispatch case
  - File: `evals/implement-dispatch/fixture.sh` (new, executable)
  - Change: A Bash script (`set -euo pipefail`) that runs in the empty workspace and does the following:
    - Runs `git init -q -b main` and sets local `user.name`/`user.email`.
    - Writes `greet.sh`: `echo "Hello, ${1}"`.
    - Writes `test.sh`, which asserts `bash greet.sh Ann` prints `Hello, Ann` and exits non-zero on mismatch.
    - Writes the plan folder `docs/plans/2026-01-01-greeting/` with minimal `decisions.md` (one Preference decision), `research.md`, `structure.md` (one phase) and `plan.md`.
    - The `plan.md` has Phase 1 "Greeting options" with two TDD tasks, each with `Test: bash test.sh`:
      - Task 1.1: `--shout` uppercases the output; add the assertion to `test.sh` first.
      - Task 1.2: no argument prints `Hello, world`; add the assertion first.
      - It ends with `- [ ] Commit Phase 1`.
    - Finishes with `git add -A && git commit -qm "fixture"`.
  - Test: `tmp=$(mktemp -d) && (cd "$tmp" && bash /Users/ryansonnek/Projects/qrspi/evals/implement-dispatch/fixture.sh && bash test.sh && git log --oneline | wc -l)` prints `1`

- [ ] Task 1.2: Dispatch case definition
  - File: `evals/implement-dispatch/case.yaml` (new), `evals/implement-dispatch/prompt.md` (new)
  - Change:
    - `case.yaml`: `schema_version: "1.1"`, `name: implement-dispatch`, `context.scaffold_script: fixture.sh`.
    - `prompt.md` frontmatter: `description` (runs implement on a 2-task fixture plan), `max_turns: 200`, `timeout_seconds: 3600`, `allowed_tools: [Read, Glob, Grep, Skill, Agent, TodoWrite, Write, Edit, Bash, SendMessage]`.
    - `prompt.md` body: `/qrspi:implement docs/plans/2026-01-01-greeting`.
  - Test: `grep -c 'scaffold_script: fixture.sh' evals/implement-dispatch/case.yaml` prints `1`

- [ ] Task 1.3: Characterization graders that pass on today's behavior
  - File: `evals/implement-dispatch/graders/tasks-ticked.md`, `graders/phase-committed.md`, `graders/dispatched-agents.md`, `graders/greeting-works.md` (all new)
  - Change:
    - `tasks-ticked`: `type: regex`, `target: { source: file, path: docs/plans/2026-01-01-greeting/plan.md }`, `pattern: '- \[x\] Task 1\.2'`.
    - `phase-committed`: `type: tool_used`, `tool: Bash`, `input_match: 'git commit'`.
    - `dispatched-agents`: `type: tool_used`, `tool: Agent`, `min: 2`.
    - `greeting-works`: `type: regex`, `target: trace`, `pattern: 'Hello, world'`. This confirms the run executed the new behavior.
  - Test: `EVAL_IMPL --case implement-dispatch` passes all four graders on the current `commands/implement.md`. Expect it to end at the Open Pull Request step with "Can't resolve the GitHub repo", because the fixture has no remote.

- [ ] Task 1.4: Spike on what graders can see, recorded as temporary graders
  - File: `evals/implement-dispatch/graders/spike-agent-input.md`, `graders/spike-sidechain.md`, `graders/spike-builtin-skills.md` (new, temporary)
  - Change:
    - `spike-agent-input`: `type: tool_used`, `tool: Agent`, `input_match: '"prompt"'`. Shows whether Agent inputs can be matched at all.
    - `spike-sidechain`: `type: tool_used`, `tool: Edit`, `input_match: 'greet\.sh'`. Only the implementer subagent edits `greet.sh`, never the main thread, so a match means subagent tool calls are visible to graders.
    - `spike-builtin-skills`: `type: tool_used`, `tool: Skill`, `input_match: '"skill"\s*:\s*"(simplify|code-review)"'`. Shows whether bundled skills are available in eval runs.
    - Run `EVAL_IMPL --case implement-dispatch`. Note each spike's pass or fail, then delete the three spike files.
  - Test: `ls evals/implement-dispatch/graders/spike-* 2>/dev/null | wc -l` prints `0` after recording results in Task 1.5

- [ ] Task 1.5: Document implement evals and spike results
  - File: `evals/README.md`
  - Change:
    - Add an "Implement cases" section with the `EVAL_IMPL` run command, and say why each flag is there: `--scaffold` for the fixture repo; Bash/Edit/SendMessage because implement runs tests, edits and relays fixes.
    - Note that runs end at the PR step because the fixture has no remote.
    - Record the three spike results as facts.
    - If `spike-sidechain` failed, state that Phase 2-4 graders can match only main-thread calls (Agent dispatches), not calls made inside subagents.
    - If `spike-builtin-skills` failed, add it under Known issues: the Quality Gate's `/simplify` and `/code-review` can't run in evals.
  - Test: `grep -c 'implement-dispatch' evals/README.md` prints at least `1`

- [ ] Commit Phase 1

## Phase 2: Role agents dispatched from the main thread

- [ ] Task 2.1: Red graders for role dispatch
  - File: `evals/implement-dispatch/graders/implementer-agent.md`, `graders/spec-reviewer-agent.md`, `graders/quality-reviewer-agent.md` (new)
  - Change:
    - Each is `type: tool_used`, `tool: Agent`, with `input_match` set to:
      - `'"subagent_type"\s*:\s*"qrspi:implementer"'` with `min: 2` (one per task)
      - `'"subagent_type"\s*:\s*"qrspi:spec-reviewer"'` with `min: 2`
      - `'"subagent_type"\s*:\s*"qrspi:quality-reviewer"'` with `min: 2`
    - If Task 1.4 showed Agent inputs can't be matched, use `type: llm`, `focus: trace` graders that state the same criteria instead.
  - Test: `EVAL_IMPL --case implement-dispatch` fails these three graders on the unchanged `commands/implement.md`, which is the red step.

- [ ] Task 2.2: Implementer agent
  - File: `agents/implementer.md` (new)
  - Change:
    - Frontmatter: `name: implementer`; a `description` ("Implements one qrspi plan task with TDD and runs its verification"); `model: sonnet`. Omit `tools` so it inherits all of them.
    - Body:
      - Implement exactly the task text it's given, test first.
      - Run the task's Test command.
      - Self-review against the task text.
      - Return `DONE` with a short summary and the verification output, or `FAILED` with the failing output and what was tried.
      - Ask questions instead of guessing when the task text is ambiguous.
  - Test: `grep -c '^model: sonnet$' agents/implementer.md` prints `1`

- [ ] Task 2.3: Spec-compliance reviewer agent
  - File: `agents/spec-reviewer.md` (new)
  - Change:
    - Frontmatter: `name: spec-reviewer`; a `description` ("Checks a task's diff against the task text: everything asked for, nothing extra"); `model: haiku`; `tools: Read, Glob, Grep, Bash`. Bash is for `git diff` only; the body says not to modify files.
    - Body: given the task text and a diff range, return `COMPLIANT`, or `GAPS` followed by a list of missing items and unrequested additions, each with `file:line`.
  - Test: `grep -c '^model: haiku$' agents/spec-reviewer.md` prints `1` and `grep -c '^tools: Read, Glob, Grep, Bash$' agents/spec-reviewer.md` prints `1`

- [ ] Task 2.4: Quality reviewer agent
  - File: `agents/quality-reviewer.md` (new)
  - Change:
    - Frontmatter: `name: quality-reviewer`; a `description` ("Runs the /qrspi:code-review checklist on one task's diff"); `model: sonnet`; `tools: Read, Glob, Grep, Bash, Skill`. `Skill` is required to run `/qrspi:code-review` (research: Constraints).
    - Body: run `/qrspi:code-review` on the given diff range, don't modify files, and return the skill's Review Response Format with an approve or request-changes summary line.
  - Test: `grep -c 'Skill' agents/quality-reviewer.md` prints at least `1` and `grep -c '^model: sonnet$' agents/quality-reviewer.md` prints `1`

- [ ] Task 2.5: Rewrite per-task dispatch in implement.md
  - File: `commands/implement.md:28-36`
  - Change: Replace steps 2-5 of Subagent-Driven Development so the main thread does all of the following:
    - Dispatches `qrspi:implementer` with the full task text and context, and answers its questions from the artifacts (existing rule kept).
    - Dispatches `qrspi:spec-reviewer` with the task text and the task's diff range.
    - On `GAPS`, sends the findings to the same implementer via `SendMessage`, then dispatches a fresh `qrspi:spec-reviewer`. Repeat until `COMPLIANT`.
    - Then dispatches `qrspi:quality-reviewer` the same way, with the same fix loop.
    - Per-task review no longer runs `/code-review`; correctness review happens at the Quality Gate and the final pass.
    - Keeps the "never in parallel" and "never move on with open issues" rules.
  - Test: `grep -c 'qrspi:implementer\|qrspi:spec-reviewer\|qrspi:quality-reviewer' commands/implement.md` prints at least `3`, and `sed -n '/### Subagent-Driven/,/### Blockers/p' commands/implement.md | grep -c '`/code-review`'` prints `1` (only the final-pass line, step 6)

- [ ] Task 2.6: Green run
  - File: none
  - Change: Run the dispatch case against the new agents and `implement.md`.
  - Test: `EVAL_IMPL --case implement-dispatch` passes every grader, including Task 2.1's three

- [ ] Commit Phase 2

## Phase 3: Escalation before blocking

- [ ] Task 3.1: Escalation fixture and red graders
  - File: `evals/implement-escalation/fixture.sh`, `case.yaml`, `prompt.md`, `graders/escalated-to-opus.md`, `graders/no-pr.md`, `graders/reports-blocker.md` (all new)
  - Change:
    - Fixture: same git setup as Task 1.1, but `plan.md` has one task: "Make `bash verify.sh` pass; do not modify verify.sh". `verify.sh` passes only if `answer.txt` equals `date +%s%N` at verification time, so it can never pass.
    - `case.yaml`: `name: implement-escalation`, `scaffold_script: fixture.sh`.
    - `prompt.md`: `max_turns: 120`, `timeout_seconds: 2400`, the same `allowed_tools` as Task 1.2, and body `/qrspi:implement docs/plans/2026-01-01-impossible`.
    - Graders:
      - `escalated-to-opus`: `tool_used`, `tool: Agent`, `input_match: '"model"\s*:\s*"opus"'`.
      - `no-pr`: `tool_used`, `tool: Bash`, `input_match: 'gh pr create'`, `min: 0`, `max: 0`.
      - `reports-blocker`: `type: llm`, focus `last_message`. PASS if the final message stops on the verification failure and asks the user for help.
  - Test: `EVAL_IMPL --case implement-escalation` fails `escalated-to-opus` on the Phase 2 `implement.md`, which is the red step.

- [ ] Task 3.2: Escalation rule in implement.md
  - File: `commands/implement.md` (Subagent-Driven Development, new step after the implementer dispatch)
  - Change: Add an escalation step to the main thread:
    - An implementer attempt fails when it returns `FAILED`, or its verification output doesn't pass.
    - After the first attempt plus two `SendMessage` fix attempts all fail, dispatch a fresh `qrspi:implementer` with `model: opus`.
    - Its prompt holds the task text plus each failed attempt's summary and failing output. A subagent keeps its model across follow-ups, so this must be a new dispatch (research: Constraints).
    - Reviews then proceed as normal against the Opus implementer.
  - Test: `grep -c 'model: opus' commands/implement.md` prints at least `1`

- [ ] Task 3.3: Quantify blockers
  - File: `commands/implement.md:43`
  - Change: Replace "a task's verification still fails after repeated fix attempts" with "a task's verification still fails after the Opus escalation (see Subagent-Driven Development)".
  - Test: `grep -c 'repeated fix attempts' commands/implement.md` prints `0`

- [ ] Task 3.4: Green run
  - File: none
  - Change: Run both cases.
  - Test: `EVAL_IMPL --case 'implement-*'` passes all graders in both cases

- [ ] Commit Phase 3

## Phase 4: Seam reviews in subagents with pinned effort

- [ ] Task 4.1: Red graders for seam dispatch
  - File: `evals/implement-dispatch/graders/gate-agent.md` (new); if Task 1.4's sidechain spike passed, also `graders/gate-effort.md` and `graders/final-effort.md` (new)
  - Change:
    - `gate-agent`: `tool_used`, `tool: Agent`, `input_match: '"subagent_type"\s*:\s*"qrspi:quality-gate"'`, `min: 2` (one phase gate plus the final pass).
    - Only if sidechain calls are visible:
      - `gate-effort`: `tool_used`, `tool: Skill`, `input_match: 'code-review[^"]*medium'`.
      - `final-effort`: same, but matching `high`.
  - Test: `EVAL_IMPL --case implement-dispatch` fails these on the Phase 3 `implement.md`, which is the red step.

- [ ] Task 4.2: Quality-gate agent
  - File: `agents/quality-gate.md` (new)
  - Change:
    - Frontmatter: `name: quality-gate`; a `description` ("Runs a qrspi seam review on a diff range and returns a summary"); `model: inherit`. This keeps it on the session model even when `CLAUDE_CODE_SUBAGENT_MODEL` is set (research: model precedence). Omit `tools`, because it needs Bash, Edit, Skill and Agent for `/code-review`'s fork.
    - Body: run exactly the review steps given in its prompt, in order. Re-run the given test command after any step that changes files. Don't commit. Return a summary of each step's fixes (what changed and why) and the final test result.
  - Test: `grep -c '^model: inherit$' agents/quality-gate.md` prints `1`

- [ ] Task 4.3: Phase gate runs in the quality-gate agent
  - File: `commands/implement.md:51-65`
  - Change: Rewrite the Quality Gate.
    - Step 1 (verify green) stays in the main thread.
    - Steps 2-6 become one dispatch of `qrspi:quality-gate` with the phase's diff range, the phase's test command, and the steps `/simplify`, `/code-review medium --fix` and `/qrspi:code-review` (fix what it flags).
    - Step 7: the main thread commits the phase and uses the returned summary for the commit message (keeps the "describe large or surprising fixes" note).
    - Add a note: the gate runs three subagent layers deep (gate → `/code-review` fork → reviewers). If dispatch fails at depth, run the same steps in the main thread and say so in the PR body's Summary.
  - Test: `grep -c '/code-review medium --fix' commands/implement.md` prints `1` and `grep -c 'qrspi:quality-gate' commands/implement.md` prints at least `1`

- [ ] Task 4.4: Final pass runs in the quality-gate agent
  - File: `commands/implement.md:37`
  - Change: Step 6 dispatches `qrspi:quality-gate` over the whole implementation's diff range. Its steps are `/code-review high --fix` then `/qrspi:code-review` (fix what it flags). The main thread commits any fixes as `Final review fixes`, using the summary in the commit message.
  - Test: `grep -c '/code-review high --fix' commands/implement.md` prints `1`

- [ ] Task 4.5: PR body draws on gate summaries
  - File: `commands/implement.md:45`, `commands/implement.md:69` (Open Pull Request intro)
  - Change: State that the Summary's notes on judgment calls and notable review fixes come from the quality-gate summaries the main thread received. It no longer sees the raw review output.
  - Test: `grep -c 'quality-gate summar' commands/implement.md` prints at least `1`

- [ ] Task 4.6: Green run
  - File: none
  - Change: Run both cases.
  - Test: `EVAL_IMPL --case 'implement-*'` passes all graders

- [ ] Commit Phase 4

## Phase 5: Docs, version, and comparison run

- [ ] Task 5.1: README describes role models
  - File: `README.md:21`, plus a new "Models" section after Commands
  - Change:
    - Update the implement bullet: per-task roles on pinned models, Opus escalation before blocking, and seam reviews at pinned `/code-review` effort in subagents.
    - The Models section has a table of the four agents and their models.
    - It notes that `CLAUDE_CODE_SUBAGENT_MODEL_FORCE=1` overrides every pin, and that the Quality Gate needs the default subagent spawn depth of 3 (`CLAUDE_CODE_MAX_SUBAGENT_SPAWN_DEPTH`).
  - Test: `grep -c 'qrspi:implementer' README.md` prints at least `1` and `grep -c 'CLAUDE_CODE_SUBAGENT_MODEL_FORCE' README.md` prints `1`

- [ ] Task 5.2: Version bump
  - File: `.claude-plugin/plugin.json:3`
  - Change: `0.5.0` → `0.6.0`.
  - Test: `jq -r .version .claude-plugin/plugin.json` prints `0.6.0`

- [ ] Task 5.3: Comparison run, old vs new implement
  - File: `docs/plans/2026-11-01-implement-model-selection/comparison.md` (new)
  - Change:
    - Plugin checkouts: in the scratchpad, `git worktree add` an old plugin checkout at `02e7cb8` and a new one at this branch's HEAD.
    - Replay copies: for each arm, clone this repo into the scratchpad at `e46ce3d` and run `git remote remove origin`. With no remote, implement stops at the PR step and opens no real PR. Copy `docs/plans/2026-08-25-qrspi-gate-revisions/` into the clone from `bc4b238`, with every checkbox reset to `- [ ]`.
    - In each clone, run `claude -p "/qrspi:implement docs/plans/2026-08-25-qrspi-gate-revisions" --plugin-dir <arm's plugin checkout> --model opus --output-format json --permission-mode bypassPermissions` in the background. Record `total_cost_usd` and `duration_ms`.
    - Run the replayed plan's own `grep -c` Test lines in each clone, and `git diff bc4b238 -- commands .claude-plugin` against the original result.
    - Write `comparison.md` with a table (arm, cost, wall time, plan checks passing, escalations, notable diff differences) and one paragraph of findings.
    - Remove the scratch worktrees.
  - Test: `grep -c 'total_cost_usd\|Cost' docs/plans/2026-11-01-implement-model-selection/comparison.md` prints at least `1` and `git worktree list | wc -l` prints `1`
  - Note: Serves Preference decisions D4/D15. It costs two full Opus-session runs, so confirm before running.

- [ ] Task 5.4: Full eval suite
  - File: none
  - Change: Run the existing question cases and the implement cases to confirm nothing regressed.
  - Test: `claude plugin eval . --ablation none --no-publish --allow-tools Write --case 'question-*' --runs 1` and `EVAL_IMPL --case 'implement-*'` both pass. Known-flaky question cases are judged against `evals/README.md` Known issues.

- [ ] Commit Phase 5
