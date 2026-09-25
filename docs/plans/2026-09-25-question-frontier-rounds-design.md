# Design: Frontier Rounds in `/question`

Date: 2026-09-25

Audience: maintainers of the qrspi plugin changing `commands/question.md`.

## Problem

`/qrspi:question` asks one question per turn with no recommended answer, so a
topic with a dozen decisions takes a dozen turns. Its stopping rule ("when you
have enough decisions") is vague, and `decisions.md` records decisions as a flat
list with no record of which ones depend on which.

## Inspiration

Matt Pocock's [`grilling`](https://github.com/mattpocock/skills/blob/main/skills/productivity/grilling/SKILL.md)
skill (the primitive behind `grill-me`) models decisions as a **design tree** and
asks in **rounds**. Each round is the **frontier**: every decision whose
prerequisites are settled. Each question carries a recommended answer, and the
session ends when the frontier is empty.

## Goal

Adopt frontier rounds in `/question` while keeping what already works: the
no-codebase rule, firmness inference, and the Continue Gate.

## Non-goals

- No changes to `/research`, `/structure`, `/plan`, or `/implement`. They may use
  `Depends on:` later if it proves useful.
- No glossary/terms capture, prototype handling, or Continue Gate extraction.
  These were considered and deferred.
- No fact lookups during the interview. `/question` still does not read the
  codebase.

## Design

### 1. Interview loop

Replaces "Ask ONE question at a time."

- Model the decisions as a tree. Each round asks the frontier: every open decision
  whose prerequisites are settled. A question whose answer depends on another
  question open in the same round belongs to a later round.
- A round is one `AskUserQuestion` call with at most 4 questions. Each question
  has 2–4 options, with tradeoffs in the option descriptions and the recommended
  option first, labeled "(Recommended)".
- If the frontier holds more than 4 questions, ask the most foundational 4 first
  and the rest in the next call.
- After each round, recompute the frontier. Answers unblock new questions, and a
  surprising answer can reopen an earlier branch.
- Fallback when `AskUserQuestion` is unavailable: a numbered markdown round, with
  each question as `❓ **Q1** - **<title>**: <body>` followed by a
  `➡️ <recommendation>` line, answered in free text by number.

### 2. Facts vs. decisions

If a question is a fact the codebase can answer, do not ask it. Add it to
**Research Focus Areas**. If a decision hinges on that fact, record the decision
as **Open**. The existing rule that every Open decision appears under Research
Focus Areas still applies.

### 3. Firmness

The existing firmness rules stay. Add one rule: **accepting a recommendation
records as Preference**. This covers a clicked option, even the recommended one,
and a bare "yes" or number reply to a markdown round, because neither carries a
signal of conviction. Other typed text, including "Other" answers, is inferred
with the existing rules, and the single follow-up question for unclear firmness
still applies.

### 4. When to stop

Replace "when you have enough decisions" with: stop when the frontier is empty,
meaning every branch has been visited and nothing is silently assumed. Then write
`decisions.md` automatically. The Continue Gate is the confirmation step and is
unchanged.

### 5. `decisions.md` format

Each decision gains a dependency field:

```
## D2: Over-limit behavior
**Question:** ...
**Depends on:** D1 | none
**Firmness:** ...
```

## Testing

Write these as `claude plugin eval` cases
([docs](https://code.claude.com/docs/en/plugin-evals.md)) before editing
`commands/question.md`, and confirm they fail against the current command.

A probe run on 2026-09-25 (Claude Code 2.1.283) showed two constraints:

- `AskUserQuestion` is not available inside eval runs, even when it is listed
  in `allowed_tools`. The agent falls back to plain text, so evals exercise the
  markdown fallback round. The picker rendering needs a manual check.
- `context.history_file` needs a real session transcript. A hand-written JSONL
  fails with "No conversation found". A transcript recorded by an eval run
  (kept with `--keep-temp`) loads, and it contains no personal settings,
  `CLAUDE.md`, or hook output, so it is safe to commit.

1. **`evals/question-first-round/`**: the prompt is `/qrspi:question <topic>`.
   Graders:
   - `tool_used` asserts `AskUserQuestion` was called.
   - An `llm` rubric checks that the round's questions are independent of each
     other and that each question lists a "(Recommended)" option first.
2. **`evals/question-decisions-output/`**: `context.history_file` replays the
   first round, recorded from case 1. The prompt answers it with bare "yes"
   replies plus one typed hard requirement. Graders:
   - `tool_used` asserts a `Write` to `decisions.md`.
   - `tool_used` asserts that the write contains `**Depends on:**`.
   - An `llm` rubric checks that bare "yes" answers are Preference, the typed
     hard requirement is Firm, and Research Focus Areas holds at least one
     codebase question.

This adds the repo's first `evals/` directory.

## Related Documents

- [commands/question.md](../../commands/question.md)
- [PR body generation design](2026-08-24-pr-body-generation-design.md)
