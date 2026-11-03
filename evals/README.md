# qrspi evals

Behavior tests for the qrspi commands, run with `claude plugin eval`
([docs](https://code.claude.com/docs/en/plugin-evals.md)).

## Run

    claude plugin eval . --ablation none --no-publish --allow-tools Write

Use `--case <name> --runs 1` while iterating.

## Constraints

- `AskUserQuestion` is unavailable inside eval runs, so `/qrspi:question`
  evals exercise its markdown fallback round, not the picker.
- Cases don't use `context.history_file`. A recorded transcript freezes a copy of
  the command's text, so a replay tests stale instructions after the command changes.
- `tool_used` with `input_match` matches Agent tool-call inputs, including the
  `subagent_type` and `prompt` fields.
- Graders see subagents' own tool calls, not just the main thread's.
- The bundled `/simplify` and `/code-review` skills run inside eval runs.

## Option examples

`question-examples-helpful` and `question-examples-unneeded` pair up: examples
are recommended, not required, so one case checks they appear where options draw
a line the user can't picture, and the other checks they're left out where the
options are already concrete. Run them with `--judge-model opus`; the
default Haiku judge failed outputs that clearly met the rubric, and Sonnet was
inconsistent on the placeholder rule; Opus gave consistent verdicts:

    claude plugin eval . --ablation none --no-publish --case 'question-examples-*' --judge-model opus

## Implement cases

`implement-dispatch` runs `/qrspi:implement` against a fixture repo that
`fixture.sh` builds. A run costs about $2 and takes about 5 minutes:

    claude plugin eval . --ablation none --no-publish --trust-plugin --scaffold --runs 1 --allow-tools Write Edit Bash SendMessage --case 'implement-*'

- `--scaffold` builds the fixture repo from `context.scaffold_script`.
- `--trust-plugin` is needed because a non-terminal run can't answer the
  trust prompt.
- `Write`, `Edit`, `Bash` and `SendMessage` are allowed because implement
  writes and edits files, runs tests and relays fixes.

`implement-escalation` is an ordinary-looking `--version` task whose
acceptance check compares against a checksum of random bytes, so it can never
pass. It checks that implement escalates to an Opus implementer and then
reports a blocker without committing or touching the acceptance files. A run
costs about $0.70, since it goes through every Sonnet and Opus attempt.

Runs end at the Open Pull Request step, because the fixture has no git remote.
Graders check the work done before that point.

## Phase cases

`question-asks-only-yours` checks that `/qrspi:question`'s first round asks only
questions that are the user's to make and that change what research reads (LLM
judge):

    claude plugin eval . --ablation none --no-publish --allow-tools Write --runs 3 --case question-asks-only-yours

`research-deferred` and `structure-no-files` are scaffolded cases (`fixture.sh`).
The first checks that `/qrspi:research` lays out options for every Deferred
bullet without recommending one. The second checks that `/qrspi:structure`
writes phases without a files field. `--case` takes one glob, so run them
separately. The scaffold flags are explained under Implement cases. Each run
costs about $0.20 and takes under a minute:

    claude plugin eval . --ablation none --no-publish --trust-plugin --scaffold --runs 1 --allow-tools Write Edit Bash --case 'research-*'
    claude plugin eval . --ablation none --no-publish --trust-plugin --scaffold --runs 1 --allow-tools Write Edit Bash --case 'structure-*'

## Measuring /qrspi:question

`bin/question-stats` prints the question-phase counts for one Claude Code
session transcript as JSON: questions asked before decisions.md was written
(`picker_questions`, `markdown_questions`), D-entries, Deferred bullets and
firmness levels. The old-vs-new replay in
[comparison.md](../docs/plans/2026-11-02-question-deferred-decisions/comparison.md)
used it. Run it on one transcript:

    bin/question-stats ~/.claude/projects/<project>/<session>.jsonl

Its tests run with `python3 -m unittest bin/test_question_stats.py`.

## Known issues

- `question-first-round` is flaky: 2 of 3 runs passed on 2026-11-02 after the
  ask-test change (1 of 3 at `--threshold 1` on 2026-09-27). The judge fails
  rounds that ask a primary-goal question next to questions it shapes. For this
  topic the true first frontier is often the goal question alone, which
  conflicts with the `multiple-questions` grader. A topic whose first decisions
  really are independent would fix the test.
- `question-asks-only-yours` has a flaky LLM judge: it passed 2 of 3 runs on
  2026-11-03 with the default judge.
- `question-decisions-output` passed 4 of 5 runs on 2026-11-03, after the
  delegation rule regained "delegation never adds decisions you wouldn't have
  asked". Without that clause it fell to 1 of 4.
- `research-deferred` passed 5 of 5 runs on 2026-11-03, after research was told
  to state tradeoffs as plain facts and the grader defined a lean. Before that,
  judges split on factual tradeoffs.
- `question-examples-unneeded` passed 1 of 3 runs on 2026-10-02 and 3 of 4 on
  2026-11-02 with the Opus judge. Failing runs add include/exclude
  restatements to the repo-scope question ("includes active service repos and
  skips archived ones") even though the description already states the rule.
  `question-examples-helpful` passed 3 of 3.
