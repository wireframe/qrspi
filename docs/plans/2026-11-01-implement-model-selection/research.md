# Research: Model selection in /qrspi:implement
Date: 2026-11-01
Decisions: [decisions.md](decisions.md)

## Current dispatch in implement.md
**Findings:**
- Subagent-driven development is described in prose only; no `subagent_type` or `model` is named anywhere, so every subagent inherits the session model.
  - Implementer: "dispatch a fresh implementer subagent, handing it the full task text" — `commands/implement.md:33`
  - Spec-compliance reviewer: "Dispatch an independent subagent to check the diff against the task's own text only" — `commands/implement.md:34`
  - Quality reviewer: "dispatch an independent subagent to run `/code-review` and `/qrspi:code-review` on the diff" — `commands/implement.md:35`
  - Fix loops: "the same implementer subagent fixes them and it re-reviews" — `commands/implement.md:34-35`; no mechanism (SendMessage, re-dispatch) is specified.
  - Serial implementers only: "never dispatch multiple implementer subagents in parallel" — `commands/implement.md:36`
- Final whole-diff pass: "run one final `/code-review` and `/qrspi:code-review` pass over the entire implementation's diff" — `commands/implement.md:37`. It runs in the orchestrator's context.
- Phase Quality Gate runs in the orchestrator's context: verify green, `/simplify`, re-test, `/code-review --fix`, `/qrspi:code-review`, re-test, commit — `commands/implement.md:51-61`.
- `/code-review` is invoked at three places, none with an effort level: per task (`:35`), final pass (`:37`), phase gate (`:58`).
- Blockers: "a task's verification still fails after repeated fix attempts" — `commands/implement.md:43`; "repeated" is not quantified.
- The Open Pull Request step reads from the orchestrator's own knowledge of the run: "note the call you made in the PR body's Summary" — `commands/implement.md:45`; "If either step's fixes are large or surprising, describe them in the commit message" — `commands/implement.md:65`.
- `/qrspi:code-review` is a plugin skill with no `disable-model-invocation` flag — `skills/code-review/SKILL.md:1-4`.

## Plugin agents: definition, naming, model precedence
**Findings:**
- Plugins auto-discover markdown agents in `agents/`; the manifest needs no `agents` key (setting one replaces the default scan) — https://code.claude.com/docs/en/plugins-reference
- Dispatch name is `<plugin>:<agent>`, e.g. `qrspi:implementer` — plugins-reference, "name".
- Frontmatter: `name`, `description` required; optional includes `tools`, `disallowedTools`, `model`, `effort`, `maxTurns`, `skills`, `memory`, `background`, `isolation`, `color`. Unknown fields are silently dropped. Plugin agents ignore `hooks`, `mcpServers`, `permissionMode`, `initialPrompt` — https://code.claude.com/docs/en/sub-agents
- `model` frontmatter accepts `sonnet`, `opus`, `haiku`, `fable`, a full model ID, or `inherit` — sub-agents, "Choose a model".
- Model resolution order: (1) Agent call's `model` parameter (aliases only), (2) frontmatter `model`, (3) `CLAUDE_CODE_SUBAGENT_MODEL`, (4) main conversation model. `CLAUDE_CODE_SUBAGENT_MODEL_FORCE=1` overrides all of them — sub-agents, "Choose a model".
- User override: plugin agents have lowest priority (managed > `--agents` > `.claude/agents/` > `~/.claude/agents/` > plugin); docs suggest copying the file into `.claude/agents/` — sub-agents page. Unconfirmed whether a project agent named `implementer` shadows the prefixed `qrspi:implementer`.
- Local examples:
  - `model: sonnet` + `tools:` allowlist — `~/.claude/plugins/.../feature-dev/agents/code-explorer.md:4-6`
  - `model: inherit` — `~/.claude/plugins/cache/superpowers-marketplace/superpowers/4.0.3/agents/code-reviewer.md:5`
  - `effort: medium`, `maxTurns: 80` — `.../math-proof/agents/math-proof-worker-deep.md:4-7`
  - `tools: ..., Agent(claude-security:explore)` — `.../claude-security/agents/scan-verifier.md:4-7`

## Skills and nested subagents inside a subagent
**Findings:**
- Subagents can invoke project, user, and plugin skills via the Skill tool; with an explicit `tools` allowlist, `Skill` must be listed — https://code.claude.com/docs/en/sub-agents, "Preload skills into subagents".
- A subagent may spawn subagents "up to three layers below the main conversation"; `CLAUDE_CODE_MAX_SUBAGENT_SPAWN_DEPTH` changes the limit and `1` disables nesting — sub-agents, "Let subagents spawn their own subagents".
- `/code-review` runs "as a forked subagent" — https://code.claude.com/docs/en/code-review-local
- `/simplify` runs "Four review agents ... in parallel" — https://code.claude.com/docs/en/commands
- Unconfirmed: explicit docs that bundled `/code-review` and `/simplify` work when invoked from a subagent, and how a fork counts against the depth limit.

## /code-review and /simplify arguments
**Findings:**
- `/code-review [low|medium|high|xhigh|max|ultra] [--fix] [--comment] [--max-findings n|all|default] [pr#|branch|path]` — https://code.claude.com/docs/en/commands
- With no level, it uses "the last level from `low` through `max` you typed, even in an earlier session"; a level in `-p` mode doesn't update the remembered level; with none ever typed, it uses the session's current effort — https://code.claude.com/docs/en/code-review-local
- `/simplify [target]` takes a path or PR reference; no effort level or `--fix` flag documented — commands page.
- Unconfirmed: whether a level passed via the Skill tool updates the remembered level.

## Escalation and continuing subagents
**Findings:**
- A per-invocation `model` "also applies when the subagent is resumed or sent a follow-up message, so the subagent stays on that model"; resumed subagents keep full history — https://code.claude.com/docs/en/sub-agents
- SendMessage's schema has `to`, `message`, `summary`, `notify_when_idle` — no `model` field.
- No documented pattern for retrying a failed task on a stronger model with failure history. Superpowers uses "Dispatch fix subagent with specific instructions" — `~/.claude/plugins/cache/superpowers-marketplace/superpowers/4.0.3/skills/subagent-driven-development/SKILL.md:225-227`
- Superpowers' "Implementer (same subagent) fixes them" is likewise prose-only — same file `:220`.

## Plugin evals
**Findings:**
- Existing evals: 4 cases, all for `/qrspi:question`, each `prompt.md` + `graders/*.md`; no `case.yaml`, fixtures, or scaffold scripts — `evals/`, `evals/README.md:1-41`
- Run command: `claude plugin eval . --ablation none --no-publish --allow-tools Write` — `evals/README.md:8`
- `prompt.md` frontmatter: `description`, `max_turns`, `allowed_tools` — e.g. `evals/question-decisions-output/prompt.md:1-7`
- Grader types in use: `llm` (optionally `focus: trace`), `tool_used` with `input_match`, `regex` — `evals/question-decisions-output/graders/firmness-and-facts.md:2-3`, `wrote-decisions.md:1-5`, `evals/question-first-round/graders/has-recommendation.md:1-4`
- Graders can see `last_message`, `trace` (regex sees all of it; LLM judge sees first and last 12 messages), `files`, one file's contents, `mock_calls`; `tool_used` matches a tool's JSON-encoded input; `tool_order` checks ordering — https://code.claude.com/docs/en/plugin-evals.md
- Each run is isolated in a temp home and empty working directory. `case.yaml` `context.scaffold_script` (needs `--scaffold`, 120 s limit, cannot supply `.claude/` config) builds fixtures or a git repo; `context.add_dirs` gives read-only fixture dirs — plugin-evals.md.
- Limits: `max_turns` ≤ 200, `timeout_seconds` ≤ 3600, `runs` default 3, `--max-cost-usd` optional ceiling — plugin-evals.md and `claude plugin eval --help`.
- Unconfirmed: whether `tool_used` on `Agent` with `input_match` on `subagent_type`/`model` works (no doc example), and whether subagent sidechain tool calls appear in `trace`.

## Replay candidates for the comparison run
**Findings:**
- `2026-08-24-pr-body-generation`: 1 phase, 2 tasks; edits `commands/implement.md`; verification by inspection. Clean replay start at `6e1566c` (plan present, boxes unticked); merged as `e594c36` (PR #1). Implementation also included review-driven rewrites (`a0b893c`, `770c080`).
- `2026-08-25-qrspi-gate-revisions`: 4 phases, 15 tasks; edits 5 `commands/*.md` + `plugin.json`; verification by `grep -c` counts and `jq .version`, plus one `diff -rq` against a machine-specific plugin cache path — `docs/plans/2026-08-25-qrspi-gate-revisions/plan.md:17-22,143-146`. Plan and implementation landed together in `bc4b238`; replay would start at `e46ce3d` with plan files copied in. Its Test lines were rewritten after execution — `plan.md:26`.
- `2026-09-25-question-frontier-rounds-implementation-plan.md` uses the older superpowers format (no checkboxes, `## Task N`) and is the only plan verified with evals — `:15`.
- The repo has no `package.json`, `Makefile`, `bin/`, `scripts/`, or test suite.

## README and version
**Findings:**
- README's implement entry: "Execute the plan, running a quality gate (`/simplify` + `/code-review`) at every phase boundary ... Runs unattended from start to PR" — `README.md:21`
- Plugin version is `0.5.0` — `.claude-plugin/plugin.json:3`
- No `agents/` directory exists in the repo.

## Patterns Observed
- Commands are prose instructions in `commands/*.md`; skills in `skills/<name>/SKILL.md`; the plugin ships no agents or scripts.
- Behavior changes ship with a `plugin.json` version bump (e.g. `9aaf2f1`, `ced2949`).
- Verification for prompt-only changes has historically been `grep` counts or evals, not executed behavior.
- Installed plugins commonly pair `model:` with a `tools:` allowlist in agent frontmatter.

## Constraints Discovered
- **Escalation can't switch a running agent's model.** A subagent stays on its model across SendMessage follow-ups, so escalating to Opus (D8) requires a fresh dispatch carrying the failure history; the Agent call's `model: opus` parameter overrides the implementer's `model: sonnet` frontmatter.
- **Nesting depth is tight for D13.** Orchestrator → gate subagent (1) → `/code-review` fork (2) → its reviewers (3) reaches the default 3-layer limit exactly; a user setting `CLAUDE_CODE_MAX_SUBAGENT_SPAWN_DEPTH` lower, or an undocumented extra fork layer, would break the offloaded gate.
- **"Pin always wins" (D12) has an environment exception.** `CLAUDE_CODE_SUBAGENT_MODEL_FORCE=1` overrides both frontmatter and per-call `model`; the plugin can't prevent it.
- **`/code-review` effort memory crosses sessions.** Unpinned calls inherit the last level typed in any session; pinning (D11) requires passing the level on every call.
- **A `tools:` allowlist on the checklist reviewer must include `Skill`** to run `/qrspi:code-review`.
- **The offloaded gate and final pass report only summaries.** The PR body and commit-message notes (`implement.md:45,65`) currently draw on the orchestrator seeing those fixes directly.
- **An implement eval needs a fixture repo and plan.** Built via `scaffold_script` (120 s limit) and run with a long `timeout_seconds`; it would be the first qrspi eval of `/qrspi:implement`.
- **Neither replay candidate has executable tests,** so the comparison run measures cost/time and diff quality, not test pass rates.
