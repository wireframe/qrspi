# Plan: make /qrspi:question less exhaustive before research
Date: 2026-11-02
Decisions: [decisions.md](decisions.md)
Research: [research.md](research.md)
Structure: [structure.md](structure.md)

> **For Claude:** Execute this plan task-by-task, phase by phase — see `/qrspi:implement`'s execution options.

**Goal:** /question asks only the decisions that are the user's to answer and that change where research looks. Every other decision goes to a Deferred list, which /research resolves. /structure stops listing files.
**Architecture:** The changes are Markdown command prompts (`commands/*.md`) tested by `claude plugin eval` cases under `evals/<case>/` (`prompt.md`, `graders/*.md`, plus `case.yaml` and `fixture.sh` for scaffolded cases). A small Python tool in `bin/` measures /question runs from transcripts for the old vs new replay.
**Tech Stack:** Markdown prompts, `claude plugin eval` (regex, `tool_used` and LLM graders), Bash fixtures, Python 3 stdlib (`unittest`).

Eval command used below:
- `EVAL` = `claude plugin eval . --ablation none --no-publish --allow-tools Write --runs 1`
- `EVAL_SCAFFOLD` = `claude plugin eval . --ablation none --no-publish --trust-plugin --scaffold --runs 1 --allow-tools Write Edit Bash`

---

## Phase 1: /question asks only what's yours to answer and defers the rest

- [x] Task 1.1: Red. Make question-decisions-output require a Deferred section
  - File: `evals/question-decisions-output/graders/has-deferred.md` (new)
  - Change: Add a `tool_used` grader with `tool: Write` and `input_match: 'decisions\.md.*## Deferred\\n- '`, so a `## Deferred` heading must be followed by at least one bullet. Copy the frontmatter shape from `evals/question-decisions-output/graders/has-depends-on.md:1-5`.
  - Test: `EVAL --case question-decisions-output` fails on `has-deferred` against the current `commands/question.md`.

- [x] Task 1.2: Red. Make the decisions-output judge check what was deferred
  - File: `evals/question-decisions-output/graders/firmness-and-facts.md:8-14`
  - Change: Add these PASS bullets:
    - "Implementation-level choices the user didn't raise appear as one-line bullets under `## Deferred`, not as D-entries. Examples: the rate-limit algorithm, response header names, the 429 body shape, the counter store."
    - "Every D-entry is a decision only the user could answer that changes what research reads, such as which clients or endpoints are limited."
    - Keep the existing `Depends on` bullet.
  - Test: `EVAL --case question-decisions-output` fails on `firmness-and-facts` against the current `commands/question.md`.

- [x] Task 1.3: Red. New case: the first round asks only user-owned questions
  - File: `evals/question-asks-only-yours/prompt.md` (new), `evals/question-asks-only-yours/graders/only-user-decisions.md` (new)
  - Change:
    - prompt.md: frontmatter `description: First round asks only what the user alone can answer`, `max_turns: 10`, `allowed_tools: [Read, Glob, Grep, Skill]`, modeled on `evals/question-first-round/prompt.md:1-5`. Body: `/qrspi:question add rate limiting to our public REST API`.
    - Grader: an `llm` grader with `focus: last_message`. PASS if every numbered question in the round asks something only the user can answer (goal, scope boundary, hard constraint, success criterion, or a fact only they know) and its answer would change what research reads. FAIL if any question asks an implementation choice: the algorithm (token bucket vs sliding window), header names, the response body, storage, or library choice.
  - Test: `EVAL --case question-asks-only-yours` fails against the current `commands/question.md`. If it passes, tighten the FAIL list using the questions the run actually asked, and re-run until it's red.

- [x] Task 1.4: Green. Replace the Ask-about list with the two-part test
  - File: `commands/question.md:18`
  - Change: Replace the "Ask about" bullet with a rule along these lines:
    - "**Ask only what's yours to ask.** Put a decision to the user only if (1) only the user can answer it (their goal, scope boundary, hard constraints, success criteria, or facts only they know: consumers, deadlines, business rules) AND (2) its answer changes what research reads."
    - "Anything else, such as implementation choices, approaches, or tradeoffs that need codebase evidence, is never asked. List it under `## Deferred` as a one-line bullet, which /research resolves."
    - Leave `:16-17` and `:19` as they are.
  - Test: `grep -n 'Ask about' commands/question.md` returns nothing.

- [x] Task 1.5: Green. Route the hinging rule and the delegation rule to Deferred
  - File: `commands/question.md:26`, `commands/question.md:90`
  - Change:
    - `:26`: the unknown is now one of three things: a codebase fact (Open), a prerequisite (an earlier round), or a decision that fails the ask test (Deferred, not asked).
    - `:90`: delegation settles each remaining decision that passes the ask test with the recommendation as Preference, or Open if it genuinely needs research. Remaining decisions that fail the test go under Deferred.
    - Leave the stop rule `:44` and Open propagation `:29` unchanged (D2, D4).
  - Test: `grep -n 'Deferred' commands/question.md` shows hits at the rules, hinging and delegation lines.

- [x] Task 1.6: Green. Add the Deferred section to the decisions.md template
  - File: `commands/question.md:100-119`
  - Change: Between the D-entries and `## Research Focus Areas`, add:
    ```
    ## Deferred
    - <a decision that isn't yours to make up front — /research lays out options for it>
    (omit this section if nothing was deferred)
    ```
  - Test: Run `EVAL --case question-decisions-output` and `EVAL --case question-asks-only-yours`; both pass. If `firmness-and-facts` fails only on the `Depends on` bullet because fewer decisions remain, relax that bullet to "every D-entry has a `**Depends on:**` field". Record the change in evals/README in Task 5.2.

- [x] Task 1.7: Check the existing question evals haven't regressed
  - File: none (verification only)
  - Change: Run `EVAL --case question-first-round --runs 3`. The baseline is 1 of 3 (`evals/README.md:58-62`). Then run `claude plugin eval . --ablation none --no-publish --case 'question-examples-*' --judge-model opus --runs 1`.
  - Test: first-round passes in at least 1 of 3 runs, and the examples cases pass. If first-round now drops to 0 of 3 because round 1 is a single goal question, change `evals/question-first-round/prompt.md` to a topic whose first decisions are independent, as the README suggests. One example: "add CSV export to our admin reports page; it's for our finance team's month-end close". Re-run.

- [x] Task 1.8: Update the README's description of /question
  - File: `README.md:18`
  - Change: "Surface the decisions only you can make, in rounds with a recommended answer. Implementation choices are listed as Deferred for research. Writes `decisions.md`."
  - Test: `grep -n 'Deferred' README.md` returns the line.

- [x] Commit Phase 1

## Phase 2: /research owns Deferred decisions

- [x] Task 2.1: Red. New scaffolded case for research and Deferred
  - File: `evals/research-deferred/case.yaml`, `evals/research-deferred/fixture.sh`, `evals/research-deferred/prompt.md`, `evals/research-deferred/graders/wrote-deferred-section.md`, `evals/research-deferred/graders/deferred-handled.md` (all new)
  - Change:
    - `case.yaml`: copy `evals/implement-dispatch/case.yaml`, with `name: research-deferred`.
    - `fixture.sh`: copy the git-init, `greet.sh` and `test.sh` setup from `evals/implement-dispatch/fixture.sh:1-25`. Write only `docs/plans/2026-01-01-greeting/decisions.md`:
      - D1 (Preference), as in that fixture.
      - No Open decisions.
      - `## Deferred` with two bullets: "How `--shout` should combine with a missing name" and "Whether options use getopts or manual parsing".
      - One Research Focus Area.
    - `prompt.md`: `max_turns: 40`, `timeout_seconds: 600`, `allowed_tools: [Read, Glob, Grep, Skill, Agent, Write, Edit]`. Body: `/qrspi:research docs/plans/2026-01-01-greeting`.
    - `wrote-deferred-section.md`: `tool_used` Write with `input_match: 'research\.md.*## Deferred Decisions'`.
    - `deferred-handled.md`: an `llm` grader with `focus: trace`. PASS if research.md has a `## Deferred Decisions` section, separate from any Open Decisions section, with one entry per Deferred bullet (both bullets), each giving at least two options with tradeoffs and not picking one. The Deferred decisions must also be printed in full in the reply.
  - Test: `EVAL_SCAFFOLD --case research-deferred` fails against the current `commands/research.md`.

- [x] Task 2.2: Green. Make research own the Deferred decisions
  - File: `commands/research.md:13`, `commands/research.md:25`
  - Change:
    - `:13`: also note the `## Deferred` section.
    - After the Own-the-Open rule at `:25`, add "**Own the Deferred decisions.**". For every bullet under decisions.md's `## Deferred`, gather the evidence and lay out the viable options with grounded tradeoffs, the same way as for Open. Don't pick one. List each under "Deferred Decisions", separate from Open Decisions, because these were never put to the user.
  - Test: `grep -n 'Deferred' commands/research.md` hits `:13` and the new rule.

- [x] Task 2.3: Green. Add the output section, printing and write-back
  - File: `commands/research.md:52-59`, `commands/research.md:67`
  - Change:
    - In the template after Open Decisions, add:
      ```
      ## Deferred Decisions (must be resolved before /structure)
      - **<Deferred bullet>:** <options with grounded tradeoffs>
      - (one entry per bullet under decisions.md's `## Deferred`; omit if there were none)
      ```
    - `:59`: print Deferred Decisions in full, like Open ones. Offer to record the user's picks back into decisions.md as new `## D<next>` entries (Preference, with `Depends on:`), and mark each resolved bullet in `## Deferred`.
    - `:67`: the gate caveat covers unresolved Open *or Deferred* decisions.
  - Test: `EVAL_SCAFFOLD --case research-deferred` passes.

- [x] Commit Phase 2

## Phase 3: /structure leaves file choices to /plan

- [x] Task 3.1: Red. New scaffolded case: structure lists no files
  - File: `evals/structure-no-files/case.yaml`, `evals/structure-no-files/fixture.sh`, `evals/structure-no-files/prompt.md`, `evals/structure-no-files/graders/wrote-structure.md`, `evals/structure-no-files/graders/no-files-field.md` (all new)
  - Change:
    - `fixture.sh`: copy `evals/implement-dispatch/fixture.sh` through its `research.md` heredoc (`:1-60`). Stop before structure.md.
    - `prompt.md`: `max_turns: 20`, `allowed_tools: [Read, Glob, Grep, Skill, Write]`. Body: `/qrspi:structure docs/plans/2026-01-01-greeting`.
    - `wrote-structure.md`: `tool_used` Write with `input_match: 'structure\.md'` and `min: 1`.
    - `no-files-field.md`: `tool_used` Write with `input_match: 'structure\.md.*Files touched'`, `min: 0` and `max: 0`. This follows the pattern of `evals/implement-escalation/graders/acceptance-not-written.md`.
  - Test: `EVAL_SCAFFOLD --case structure-no-files` fails on `no-files-field` against the current `commands/structure.md`.

- [x] Task 3.2: Green. Remove the files field from the structure template
  - File: `commands/structure.md:41`, `commands/structure.md:47`, `commands/structure.md:17`
  - Change:
    - Delete both `**Files touched:** <list of files>` lines.
    - At `:17`, add to Your Role: "Don't name files; exact file paths are /plan's job."
  - Test: `EVAL_SCAFFOLD --case structure-no-files` passes, and `grep -n 'Files touched' commands/structure.md` returns nothing.

- [x] Task 3.3: Keep the implement fixtures consistent with the new structure format
  - File: `evals/implement-dispatch/fixture.sh:68`, `evals/implement-escalation/fixture.sh:76`
  - Change: Delete the `**Files touched:**` line from each fixture's structure.md heredoc.
  - Test: `grep -rn 'Files touched' evals commands` returns nothing, and `bash -n` passes on both fixture files.

- [x] Commit Phase 3

## Phase 4: Old vs new delegation replay
Serves Preference decisions D6 and D10, so it's kept minimal.

- [x] Task 4.1: Red. Tests for a question-stats tool
  - File: `bin/test_question_stats.py` (new)
  - Change: Write `unittest` tests that build a temporary JSONL transcript and assert what `bin/question-stats` prints as JSON. The transcript has:
    - a user message with `<command-name>/qrspi:question</command-name>`;
    - an assistant `AskUserQuestion` tool_use with 2 questions;
    - an assistant text containing a markdown fallback round, `**Q1**` and `**Q2**`;
    - a `Write` to `x/decisions.md` with content holding `## D1:` and `## D2:`, Firmness Preference and Open, and a `## Deferred` list of 3 bullets.

    The expected output is `{"picker_questions": 2, "markdown_questions": 2, "decisions": 2, "deferred": 3, "firmness": {"Firm": 0, "Preference": 1, "Open": 1}}`. Add a second test where no decisions.md is written: decisions and deferred are 0.
  - Test: `python3 -m unittest bin/test_question_stats.py` fails, because the module doesn't exist.

- [x] Task 4.2: Green. Implement bin/question-stats
  - File: `bin/question-stats` (new, executable, `#!/usr/bin/env python3`, stdlib only)
  - Change: Port the counting logic from the usage-analysis extractor (scratchpad `extract.py`). It reads one transcript path and counts only up to the first decisions.md Write. It prints the JSON above. Keep functions small: `load_records`, `count_picker_questions`, `count_markdown_questions`, `decisions_stats`.
  - Test: `python3 -m unittest bin/test_question_stats.py` passes. Then `bin/question-stats ~/.claude/projects/-Users-ryansonnek--herdr-worktrees-tao-gpa-evals/07adc860-b262-4a19-be53-30af55185026.jsonl` reports `picker_questions` 12 and `decisions` 14.

- [x] Task 4.3: Run the delegation replay and record it
  - File: `docs/plans/2026-11-02-question-deferred-decisions/comparison.md` (new)
  - Change:
    - **Topics.** Take the original topic text from `bin/question-stats`-located transcripts for gpa-evals, agent-calendar, question-burster and scheduled-tasks: the first `/qrspi:question` `<command-args>` in each of `07adc860…`, `3188bb10…`, `c5f277fa…` and `2086fd9c…`.
    - **Arms.** Old arm: `git worktree add <scratchpad>/arm-old 498718b`. New arm: this branch's HEAD.
    - **Runs.** Each run happens in an empty `git init` dir under the scratchpad:
      `claude -p "<prompt>" --plugin-dir <arm> --settings '{"enabledPlugins":{"qrspi@qrspi":false}}' --model opus --output-format json`.
      Use two prompts per topic and arm:
      - (a) `/qrspi:question <topic>`, which records round-1 `markdown_questions`;
      - (b) `/qrspi:question <topic>` plus "Go with your recommendations for everything. Don't ask me anything; write it up.", which records `decisions`, `deferred` and `firmness`.
    - **Measure.** Run `bin/question-stats` on each run's session transcript.
    - **Write-up.** Write a table (topic × arm: round-1 questions, D-entries, Deferred, cost from `total_cost_usd`), the method, and a note that it's one run per cell, so the results are indicative.
  - Test: comparison.md has 8 rows with numbers that match the `bin/question-stats` outputs. Delete the old-arm worktree afterwards.

- [x] Commit Phase 4

## Phase 5: Docs and release

- [x] Task 5.1: Point the frontier-rounds design doc at this change
  - File: `docs/plans/2026-09-25-question-frontier-rounds-design.md:38`, `docs/plans/2026-09-25-question-frontier-rounds-design.md:79`
  - Change: Add a one-line note under the Interview loop and Stop-rule headings: "Narrowed by [2026-11-02 question-deferred-decisions](2026-11-02-question-deferred-decisions/decisions.md): only user-owned decisions are asked; the rest are Deferred."
  - Test: `grep -n '2026-11-02' docs/plans/2026-09-25-question-frontier-rounds-design.md` shows 2 hits.

- [x] Task 5.2: Update evals/README
  - File: `evals/README.md:34-67`
  - Change:
    - Add a "Phase cases" section covering `question-asks-only-yours`, `research-deferred` and `structure-no-files`, with the `EVAL_SCAFFOLD` command for the two scaffolded ones.
    - Update Known issues with the Task 1.7 first-round result, and with the `Depends on` relaxation if Task 1.6 needed it.
  - Test: `grep -n 'research-deferred\|structure-no-files\|question-asks-only-yours' evals/README.md` shows every case.

- [x] Task 5.3: Bump the version to 0.7.0
  - File: `.claude-plugin/plugin.json:3`
  - Change: `"version": "0.6.0"` → `"version": "0.7.0"`.
  - Test: `grep -n '"version": "0.7.0"' .claude-plugin/plugin.json`.

- [ ] Task 5.4: Run the full suite
  - File: none (verification only)
  - Change: Run the four question cases with `EVAL`, the scaffolded cases with `EVAL_SCAFFOLD --case 'research-*'`, `--case 'structure-*'` and `--case 'implement-*'`, and `python3 -m unittest bin/test_question_stats.py`.
  - Test: All pass, except the known-flaky cases, which must match their recorded baselines.

- [ ] Commit Phase 5
