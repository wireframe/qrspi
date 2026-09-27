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
