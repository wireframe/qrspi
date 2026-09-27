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

## Known issues

- `question-first-round` is flaky: 1 of 3 runs passed at `--threshold 1` on
  2026-09-27. The judge fails rounds that ask a primary-goal question next to
  questions it shapes. For this topic the true first frontier is often the goal
  question alone, which conflicts with the `multiple-questions` grader. A topic
  whose first decisions really are independent would fix the test.
