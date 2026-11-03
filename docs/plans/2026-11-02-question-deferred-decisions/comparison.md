# Comparison: old vs new `/qrspi:question`
Date: 2026-11-03
Plan: [plan.md](plan.md) Task 4.3 · Decisions: [D6](decisions.md#d6-success-test), [D10](decisions.md#d10-replay-method)

This note is for reviewers of the Deferred-decisions change. It records one delegation replay of four real topics through the old and the new `/qrspi:question`, and what the counts say about how many decisions each arm records.

## Method

- **Topics:** four real `/qrspi:question` topics from earlier sessions, each taken from the last `/qrspi:question` start before that session wrote `decisions.md`. Topic text is kept out of the repo. Each is named below by label and a neutral paraphrase.
  - gpa-evals: assess an existing eval framework against a published agent-evaluation framework
  - agent-calendar: give the agent limited calendar write access
  - question-burster: build a collaborative web app for a structured question-brainstorming practice
  - scheduled-tasks: add proactive, scheduled actions to the agent and pick one to start with
- **Arms:** old = plugin at `498718b` (v0.6.0); new = this branch's working tree. Each run: `claude -p "<prompt>" --plugin-dir <arm> --settings '{"enabledPlugins":{"qrspi@qrspi":false}}' --model opus --output-format json --allowedTools "Read Glob Grep Skill Write Bash(mkdir:*)"`, in a fresh empty `git init` directory.
- **Prompts:**
  - (a) `/qrspi:question <topic>`. Round-1 questions are counted from the first reply.
  - (b) the same, plus "Go with your recommendations for everything. Don't ask me anything; write it up." The D-entries, Deferred bullets and firmness counts come from the `decisions.md` that run wrote.
- **Counts:** `bin/question-stats` on each run's session transcript. Round-1 questions are `markdown_questions` + `picker_questions`. `-p` mode has no question picker, so every round-1 question appeared as markdown.
- **Runs:** one per cell, so treat differences as indicative, not statistically meaningful. The answers are the model's own recommendations, not a real user's, so this measures what would be asked and recorded, not a multi-round session.

## Results

Round-1 questions come from run (a); D-entries, Deferred bullets and firmness from run (b). Cost is `total_cost_usd`, per run (a) / run (b).

| Topic | Arm | Round-1 questions | D-entries | Deferred bullets | Firmness (Firm / Preference / Open) | Cost (a / b) |
|---|---|---|---|---|---|---|
| gpa-evals | Old | 4 | 12 | 0 | 1 / 9 / 2 | $0.35 / $0.61 |
| gpa-evals | New | 3 | 3 | 4 | 0 / 2 / 1 | $0.34 / $0.49 |
| agent-calendar | Old | 4 | 13 | 0 | 2 / 10 / 1 | $0.35 / $0.64 |
| agent-calendar | New | 4 | 8 | 7 | 3 / 5 / 0 | $0.31 / $0.65 |
| question-burster | Old | 4 | 25 | 0 | 2 / 21 / 2 | $0.29 / $0.84 |
| question-burster | New | 4 | 13 | 12 | 1 / 11 / 1 | $0.30 / $0.65 |
| scheduled-tasks | Old | 4 | 20 | 0 | 1 / 18 / 1 | $0.32 / $0.98 |
| scheduled-tasks | New | 4 | 12 | 9 | 1 / 11 / 0 | $0.35 / $0.85 |

Totals across the four topics:

| Arm | Round-1 questions | D-entries | Deferred bullets | Open entries | Cost (a) | Cost (b) |
|---|---|---|---|---|---|---|
| Old | 16 | 70 | 0 | 6 | $1.31 | $3.07 |
| New | 15 | 36 | 32 | 2 | $1.30 | $2.64 |

## Findings

- **Round-1 question counts barely moved.** Both arms asked 4 questions in round 1 on every topic except gpa-evals, where the new arm asked 3. The new arm does not ask fewer questions up front on these topics.
- **The new arm records about half as many D-entries.** 36 against 70 in total; the drop is 12 to 3, 13 to 8, 25 to 13 and 20 to 12.
- **The new arm moves leaf decisions to Deferred, not out of the file.** It wrote 32 Deferred bullets where the old arm wrote none. D-entries plus Deferred bullets total 68 in the new arm against 70 in the old arm, so the new arm sorted the decisions into two buckets instead of dropping them.
- **Firmness shifted slightly.** Open entries fell from 6 to 2 in total. Preference stayed the most common level in both arms.
- **Cost is similar for round 1 and lower for the delegated write-up.** Run (a) cost $1.31 old and $1.30 new. Run (b) cost $3.07 old and $2.64 new, which is about 14% less. One run per cell cannot separate this from run-to-run variation.
- **gpa-evals new (b) stopped after writing `decisions.md`.** Its working directory held no eval framework to look at, so it recorded the framework's location as Open and left the research to the next phase. It wrote the file with a shell heredoc rather than the Write tool.
- **Whether the Deferred items are the right ones is not measured here.** The counts show how many items moved, not whether each belonged there. D11 says the Continue Gate stays unchanged unless replays show misclassified Deferred items slipping past review; this replay did not check for that.

## Tooling note

`bin/question-stats` needed two input fixes for `-p` transcripts. Both were genuine tool bugs, not replay quirks:

- It counted markdown questions with `^\*\*Q\d+\*\*`, but `commands/question.md` formats them as `❓ **Q1**`. Every round-1 count came back 0. The pattern now matches the `❓ ` prefix.
- It saw `decisions.md` writes only through the Write tool. One run wrote the file with a Bash heredoc and came back with 0 D-entries. It now also treats a Bash command that redirects into `decisions.md` as the write.
