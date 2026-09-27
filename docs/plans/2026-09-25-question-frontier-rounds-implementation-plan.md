# Frontier Rounds in `/question` Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Change `/qrspi:question` from one question per turn to frontier rounds with recommended answers, add a `Depends on:` field to `decisions.md`, and cover both with `claude plugin eval` cases.

**Architecture:** qrspi is a Claude Code plugin made of prompt files, so the "code" under change is `commands/question.md`. Tests are `claude plugin eval` cases under `evals/`: each case is a prompt plus graders that inspect the run's final message, tool calls, and trace. Case 1 checks the first round's shape. Case 2 is a single-turn prompt that gives the answers up front and checks what gets written to `decisions.md` (it originally replayed a recorded transcript; see Deviations).

**Tech Stack:** Markdown prompt files, Claude Code 2.1.283+ (`claude plugin eval`).

**Design:** [2026-09-25-question-frontier-rounds-design.md](2026-09-25-question-frontier-rounds-design.md)

---

## Deviations during execution (2026-09-27)

- **Fact rule narrowed** (Task 2 review): "Never ask the user a codebase fact", since business facts only the user knows are fair to ask.
- **`has-recommendation` tightened** (Task 2 review): Q1 and Q2 must each have their own `➡`.
- **Rounds rule added** (Task 3): one thing per question, one unconditional recommendation, recommendation only on the `➡️` line. Case 1 had failed 0/3 judge votes on hedged recommendations; afterwards it passed 3/3 runs.
- **Firmness rules refined** (Task 3 review): the picking rule is scoped to decision questions (a firmness follow-up's answer sets firmness directly), and a delegation rule covers "go with your recommendations". The picking rule itself is covered only by the manual picker check in Task 4 Step 2, because evals can't click or answer a round.
- **Case 2 is single-turn** (Task 3, user decision): a recorded `history.jsonl` freezes a copy of `question.md`, so replays test stale text. Task 3 Steps 1–7 below (recording, `case.yaml`, answering a recorded round) were replaced by a prompt that gives the answers up front. The "Re-record a history" README section was removed.

## Background the engineer needs

- **Eval docs:** https://code.claude.com/docs/en/plugin-evals.md. A case is a directory with `prompt.md` (frontmatter + prompt body), optional `case.yaml`, and `graders/*.md` (frontmatter + optional rubric body).
- **`AskUserQuestion` does not exist inside eval runs**, even when listed in `allowed_tools`. The agent falls back to plain text, so evals exercise the markdown fallback round. The picker path gets a manual check in Task 4.
- **History files must be real transcripts.** Hand-written JSONL fails with "No conversation found". Task 3 records one from an eval run.
- **Eval runs cost money** (about $0.10–$0.50 per run). Use `--runs 1` while iterating and the default 3 runs for the final check.
- **Every run command in this plan** is run from the repo root and uses `--ablation none`, because the no-plugin baseline can't run `/qrspi:question` and adds nothing but cost. It also uses `--no-publish` to keep reports local.
- **Threshold:** `--threshold 1` means every grader must pass on every run.

---

### Task 1: Eval suite scaffolding

**Files:**
- Modify: `.gitignore` (create if missing)
- Create: `evals/README.md`

**Step 1: Ignore eval results**

```bash
printf 'evals/results/\n' >> .gitignore
```

**Step 2: Write `evals/README.md`**

```markdown
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
```

**Step 3: Commit**

```bash
git add .gitignore evals/README.md
git commit -m "Add eval suite scaffolding for qrspi commands"
```

---

### Task 2: First round is a frontier round (case 1)

**Files:**
- Create: `evals/question-first-round/prompt.md`
- Create: `evals/question-first-round/graders/multiple-questions.md`
- Create: `evals/question-first-round/graders/has-recommendation.md`
- Create: `evals/question-first-round/graders/round-quality.md`
- Modify: `commands/question.md` (Your Role, Rules, new Rounds section)

**Step 1: Write the case prompt**

`evals/question-first-round/prompt.md`:

```markdown
---
description: /qrspi:question opens with a frontier round of independent questions, each with a recommendation
max_turns: 10
allowed_tools: [Read, Glob, Grep, Skill, AskUserQuestion]
---

/qrspi:question add rate limiting to our public REST API
```

**Step 2: Write the graders**

`evals/question-first-round/graders/multiple-questions.md` (at least two numbered questions in one message):

```markdown
---
type: regex
pattern: '\*\*Q1\*\*[\s\S]*\*\*Q2\*\*'
---
```

`evals/question-first-round/graders/has-recommendation.md`:

```markdown
---
type: regex
pattern: '➡'
---
```

`evals/question-first-round/graders/round-quality.md`:

```markdown
---
type: llm
---

The final message is the first round of a design interview about adding rate limiting to a REST API.

PASS if all of these hold:
- It asks two or more numbered questions in this one message.
- No question's answer depends on the answer to another question in the same message.
- Every question is followed by a recommended answer.
- No question asks the user for a fact about the existing codebase, such as which web framework, middleware, or datastore is in use.

FAIL if it asks only one question, if any question hinges on another question in the same message, if any question lacks a recommendation, or if it asks the user for a codebase fact.
```

**Step 3: Run the case and confirm it fails**

```bash
claude plugin eval . --case question-first-round --runs 1 --ablation none --no-publish --threshold 1
```

Expected: exit 1. `multiple-questions` and `has-recommendation` fail, because the current command asks one question with no `➡️` line.

**Step 4: Rewrite "Your Role" in `commands/question.md`**

Replace the current section body (lines 10–12) with:

```markdown
## Your Role

Surface design decisions by interviewing the user in **rounds**. Model the decisions as a **design tree**: a decision can depend on other decisions being settled first. Each round asks the **frontier**: every open decision whose prerequisites are already settled.
```

**Step 5: Update the Rules list**

In `## Rules`, replace

```markdown
- After each answer, decide if you need more questions or have enough to proceed.
```

with

```markdown
- **Never ask the user a fact.** If the codebase can answer a question, don't ask it. Add it to "Research Focus Areas" instead. If a decision hinges on that fact, record the decision as **Open**.
```

and replace

```markdown
- When you have enough decisions, write the artifact immediately — do NOT ask for permission to write.
```

with

```markdown
- When the frontier is empty, write the artifact immediately — do NOT ask for permission to write.
```

**Step 6: Add a Rounds section**

Insert between `## Rules` and `## Firmness`:

````markdown
## Rounds

- Ask each round with one `AskUserQuestion` call of at most 4 questions. Give each question 2-4 options with their tradeoffs in the option descriptions. Put your recommended option first and end its label with "(Recommended)".
- A question whose answer depends on another question still open in the same round belongs to a later round.
- If the frontier has more than 4 questions, ask the 4 most foundational first and the rest in the next call.
- After each round, recompute the frontier. Answers unblock new questions, and a surprising answer can reopen an earlier branch.
- If `AskUserQuestion` isn't available in this session, ask the round as numbered markdown in this format, then end the turn and wait for the user to answer by number:

  ```
  ❓ **Q1** - **<question title>**: <question body, with options and tradeoffs>

  ➡️ <your recommended answer>

  ---

  ❓ **Q2** - **<question title>**: ...

  ➡️ ...
  ```

- **Stop when the frontier is empty**: every branch of the design tree visited, nothing silently assumed.
````

**Step 7: Run the case and confirm it passes**

```bash
claude plugin eval . --case question-first-round --runs 1 --ablation none --no-publish --threshold 1
```

Expected: exit 0, all 3 graders pass. If `round-quality` fails, open the report path printed by the command and read the judge's explanation before changing anything.

**Step 8: Commit**

```bash
git add evals/question-first-round commands/question.md
git commit -m "Ask /question in frontier rounds with recommended answers"
```

---

### Task 3: `decisions.md` records dependencies and accepted recommendations (case 2)

**Files:**
- Create: `evals/question-decisions-output/history.jsonl` (recorded)
- Create: `evals/question-decisions-output/case.yaml`
- Create: `evals/question-decisions-output/prompt.md`
- Create: `evals/question-decisions-output/graders/wrote-decisions.md`
- Create: `evals/question-decisions-output/graders/has-depends-on.md`
- Create: `evals/question-decisions-output/graders/firmness-and-facts.md`
- Modify: `commands/question.md` (Firmness section, Output format)

**Step 1: Record the history**

Run the "Re-record a history" commands from `evals/README.md`, starting with `mkdir -p evals/question-decisions-output`.

**Step 2: Check the transcript for personal data**

```bash
grep -c -i -E 'claudeMd|hook_success|@betterup|/Users/' evals/question-decisions-output/history.jsonl
```

Expected: `0`. If anything matches, stop and inspect it before committing.

**Step 3: Read the recorded round**

```bash
python3 -c "
import json
for l in open('evals/question-decisions-output/history.jsonl'):
    o = json.loads(l)
    if o.get('type') == 'assistant':
        for c in o['message']['content']:
            if c.get('type') == 'text': print(c['text'])
"
```

Note the question numbers and titles. Pick one question (call it `Qk`) whose answer you will type as a hard requirement.

**Step 4: Write `case.yaml`**

```yaml
schema_version: "1.1"
name: question-decisions-output
context:
  history_file: history.jsonl
```

**Step 5: Write the answering prompt**

`evals/question-decisions-output/prompt.md`, with `Qk` and the requirement filled in from Step 3:

```markdown
---
description: Answers to the first round become decisions.md with Depends on fields and correct firmness
max_turns: 15
allowed_tools: [Read, Glob, Grep, Skill, Write]
---

Qk: <a concrete answer to Qk>. This is non-negotiable.
Every other question: yes.

That's everything I care about. Use your recommendations for anything left and write it up.
```

**Step 6: Write the graders**

`graders/wrote-decisions.md`:

```markdown
---
type: tool_used
tool: Write
input_match: 'decisions\.md'
---
```

`graders/has-depends-on.md` (the Write input is JSON with `file_path` before `content`):

```markdown
---
type: tool_used
tool: Write
input_match: 'decisions\.md.*\*\*Depends on:\*\*'
---
```

`graders/firmness-and-facts.md`:

```markdown
---
type: llm
focus: trace
---

The user answered one question with a typed requirement marked "non-negotiable" and every other question with a bare "yes". Look at the decisions.md content Claude wrote.

PASS if all of these hold:
- The decision for the non-negotiable answer has `**Firmness:** Firm`.
- Every decision answered with a bare "yes", and every decision Claude filled in from its own recommendation, is Preference, not Firm.
- "Research Focus Areas" lists at least one question about the existing codebase (for example, what API framework or middleware exists).

FAIL otherwise.
```

**Step 7: Run the case and confirm it fails**

```bash
claude plugin eval . --case question-decisions-output --runs 1 --ablation none --no-publish --threshold 1 --allow-tools Write
```

Expected: exit 1, with `has-depends-on` failing because the output format has no `Depends on:` field yet. If the run errors with "No conversation found", the history was not recorded correctly. Redo Step 1.

**Step 8: Add the acceptance rule to Firmness**

In `## Firmness`, under "Assigning firmness:", add after the "Default to Preference" bullet:

```markdown
- **Accepting a recommendation is Preference.** A clicked option, even the recommended one, or a bare "yes"/number reply to a markdown round records as **Preference**, because it carries no signal of conviction. Infer firmness from typed text, including "Other" answers, with the rules here.
```

**Step 9: Add `Depends on:` to the output format**

In the `decisions.md` template under `## Output`, change

```
## D1: <Decision Title>
**Question:** <what was asked>
**Firmness:** Firm | Preference | Open
```

to

```
## D1: <Decision Title>
**Question:** <what was asked>
**Depends on:** D<n>[, D<m>] | none
**Firmness:** Firm | Preference | Open
```

**Step 10: Run the case and confirm it passes**

```bash
claude plugin eval . --case question-decisions-output --runs 1 --ablation none --no-publish --threshold 1 --allow-tools Write
```

Expected: exit 0, all 3 graders pass.

**Step 11: Commit**

```bash
git add evals/question-decisions-output commands/question.md
git commit -m "Record decision dependencies and treat accepted recommendations as Preference"
```

---

### Task 4: Full suite, manual picker check, docs

**Files:**
- Modify: `README.md` (Commands section, new Evals section)

**Step 1: Run the full suite at the default 3 runs**

```bash
claude plugin eval . --ablation none --no-publish --threshold 1 --allow-tools Write
```

Expected: exit 0, both cases 1.0. If a case is flaky (for example 0.67), read the failing run's judge explanation in the report. Tighten the rubric only if the judge is wrong. If the command is wrong, fix the command.

**Step 2: Manually check the picker path**

In a scratch directory, run `claude --plugin-dir <repo path>` and type `/qrspi:question add rate limiting to our public REST API`. Confirm:
- The first round is one `AskUserQuestion` picker with 2–4 questions, each with the recommended option first, labeled "(Recommended)".
- Clicking through all the recommendations and finishing produces a `decisions.md` where every decision is Preference and has a `**Depends on:**` line.

**Step 3: Update `README.md`**

In the Commands list, change the `/qrspi:question` bullet to:

```markdown
- **`/qrspi:question <topic>`** — Surface design decisions in rounds: each round asks every question whose prerequisites are settled, with a recommended answer. Writes `decisions.md`.
```

Add before `## License`:

```markdown
## Evals

Behavior tests live in `evals/` and run with `claude plugin eval`. See [evals/README.md](evals/README.md).
```

**Step 4: Commit**

```bash
git add README.md
git commit -m "Document frontier rounds and the eval suite"
```
