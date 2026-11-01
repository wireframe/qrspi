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

## Known issues

- `question-first-round` is flaky: 1 of 3 runs passed at `--threshold 1` on
  2026-09-27. The judge fails rounds that ask a primary-goal question next to
  questions it shapes. For this topic the true first frontier is often the goal
  question alone, which conflicts with the `multiple-questions` grader. A topic
  whose first decisions really are independent would fix the test.
- `question-examples-unneeded` passed 1 of 3 runs on 2026-10-02 with the Opus
  judge. Failing runs add include/exclude restatements to the repo-scope
  question ("includes active service repos and skips archived ones") even
  though the description already states the rule. `question-examples-helpful`
  passed 3 of 3.
