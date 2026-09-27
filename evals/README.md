# qrspi evals

Behavior tests for the qrspi commands, run with `claude plugin eval`
([docs](https://code.claude.com/docs/en/plugin-evals.md)).

## Run

    claude plugin eval . --ablation none --no-publish --allow-tools Write

Use `--case <name> --runs 1` while iterating.

## Constraints

- `AskUserQuestion` is unavailable inside eval runs, so `/qrspi:question`
  evals exercise its markdown fallback round, not the picker.
- `context.history_file` must be a real session transcript. See
  "Re-record a history" below.

## Re-record a history

`question-decisions-output/history.jsonl` is the first round recorded from
`question-first-round`. Re-record it whenever the first round's format changes:

    REC="$(mktemp -d)/rec.json"
    claude plugin eval . --case question-first-round --runs 1 --keep-temp \
      --ablation none --no-publish --threshold 0 --json "$REC"
    TRACE=$(python3 -c "import json,sys;print(json.load(open(sys.argv[1]))['cases'][0]['arms']['with'][0]['tracePath'])" "$REC")
    RUN_DIR=$(dirname "$(dirname "$TRACE")")
    cp "$RUN_DIR"/config/projects/*/*.jsonl evals/question-decisions-output/history.jsonl
    chmod -R u+rwx "$RUN_DIR"; rm -rf "$RUN_DIR"

Then update `question-decisions-output/prompt.md` so its answers match the
recorded questions.
