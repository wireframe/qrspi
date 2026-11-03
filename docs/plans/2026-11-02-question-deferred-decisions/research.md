# Research: make /qrspi:question less exhaustive before research
Date: 2026-11-02
Decisions: [decisions.md](decisions.md)

## Rules in question.md that drive exhaustive or implementation-level questions
**Findings:**
- The "Ask about" list includes approach, compatibility and tradeoffs: "Ask about: scope, approach, constraints, compatibility, tradeoffs, success criteria." No other file repeats this list. Reference: `commands/question.md:18`
- The stop rule requires visiting every branch: "Stop when the frontier is empty: every branch of the design tree visited, nothing silently assumed." Reference: `commands/question.md:44`
- When a recommendation hinges on an unknown, the rule routes that unknown to exactly two places: a codebase fact (recorded Open) or "a prerequisite that belongs in an earlier round". Nothing routes it to a later phase. Reference: `commands/question.md:26`
- The only way out of being asked is Open, which applies to codebase facts and to explicit "not sure" answers. Open propagates to dependents. Reference: `commands/question.md:19`, `commands/question.md:29`
- The delegation rule settles "each remaining decision" with the recommendation "until the frontier is empty", so a "wrap it up" still records every leaf decision. Reference: `commands/question.md:90`
- The decisions.md template has D-entries and Research Focus Areas, with no other bucket. Reference: `commands/question.md:100-119`
- The firmness section says every Open decision must appear under Research Focus Areas. Reference: `commands/question.md:91`

## How research.md handles Open decisions
**Findings:**
- research reads decisions.md and its "Research Focus Areas" section. Reference: `commands/research.md:11-13`, `commands/research.md:17`
- The "Own the Open decisions" rule has research gather evidence and lay out options for every `Firmness: Open` decision without picking one. Reference: `commands/research.md:25`
- The output has an `## Open Decisions (must be resolved before /structure)` section, one entry per Open decision. Reference: `commands/research.md:52-54`
- Open Decisions are printed in full despite the outline-only rule. research offers to write the user's picks back into decisions.md, flipping `Open` to `Firm`/`Preference`. Reference: `commands/research.md:59`
- The Continue Gate notes remaining Open decisions as a caveat. Reference: `commands/research.md:67`

## /question evals affected by D1/D3
**Findings:**
- There are four cases, each a `prompt.md` with `graders/`. AskUserQuestion is unavailable in eval runs, so the cases test the markdown fallback round. Reference: `evals/README.md:14-15`
- `question-first-round` (rate-limiting topic):
  - The regex grader requires at least two questions, `**Q1**…**Q2**`. Reference: `evals/question-first-round/graders/multiple-questions.md:3`
  - The LLM judge checks independence within the round, one-ask questions, unconditional recommendations and no codebase-fact questions. Reference: `evals/question-first-round/graders/round-quality.md:8-12`
- `question-decisions-output` (the same topic, with one "non-negotiable" requirement and "go with your recommendations"):
  - It requires a Write to decisions.md containing `**Depends on:**`. Reference: `evals/question-decisions-output/graders/has-depends-on.md:4`
  - Its judge requires: exactly the non-negotiable is Firm, the rest are Preference or Open, Open decisions appear in Research Focus Areas, at least one codebase question exists, and at least one Depends on names another decision. Reference: `evals/question-decisions-output/graders/firmness-and-facts.md:9-13`
- `question-examples-helpful` and `question-examples-unneeded` test boundary examples in options. They are run as a pair with an Opus judge. Reference: `evals/README.md:23-32`
- No eval checks when questioning stops, how many questions a run asks overall, or the "Ask about" list by name.
- Known flakiness:
  - `question-first-round` passed 1 of 3 runs, because "the true first frontier is often the goal question alone", which conflicts with the two-question regex. Reference: `evals/README.md:58-62`
  - `question-examples-unneeded` passed 1 of 3 runs. Reference: `evals/README.md:63-66`

## The 2026-11-01 replay comparison method
**Findings:**
- It replayed `/qrspi:implement` on one completed plan (`2026-08-25-qrspi-gate-revisions`), reset and cloned with the remote removed. Reference: `docs/plans/2026-11-01-implement-model-selection/comparison.md:9`
- Arms were loaded with `--plugin-dir <arm worktree>` and the installed plugin turned off by `--settings '{"enabledPlugins":{"qrspi@qrspi":false}}'`. The command ran headless: `claude -p "<command>" --model opus --permission-mode bypassPermissions --output-format json`. Reference: `docs/plans/2026-11-01-implement-model-selection/comparison.md:10`
- No user input was needed, because /implement runs unattended. The only input was the slash command. Each arm ran once, and the results are called "indicative". Reference: `docs/plans/2026-11-01-implement-model-selection/comparison.md:10-11`
- Metrics came from the JSON result (`total_cost_usd`, `duration_ms`, `modelUsage`) and from parsing transcripts and subagent `.meta.json` files. Reference: `docs/plans/2026-11-01-implement-model-selection/comparison.md:15-64`
- The steps were run by hand from the plan; no script was committed. The repo has no `bin/` or `scripts/`. Reference: `docs/plans/2026-11-01-implement-model-selection/plan.md:229-236`
- The usage analysis that produced this plan's evidence used a transcript extractor in the session scratchpad. It found `/qrspi:question` runs, counted rounds, questions, decisions and firmness, and tallied Recommended vs typed answers. It is not in the repo.

## Other places that document or consume decisions.md
**Findings:**
- README describes /question as frontier rounds: "each round asks every question whose prerequisites are settled". Reference: `README.md:18`
- structure reads decisions.md and weights by firmness, with Open as a blocker. Reference: `commands/structure.md:13`, `commands/structure.md:26`
- plan weights effort by firmness and treats a still-Open decision as a blocker. Reference: `commands/plan.md:13`, `commands/plan.md:28-29`
- implement:
  - It answers implementer QUESTIONs from decisions.md. Reference: `commands/implement.md:33`
  - It checks which Firm decision a dropped task served. Reference: `commands/implement.md:52`
  - The PR body links `## D<n>: <Title>` headings by GitHub slug and lists only Firm decisions, in decisions.md order. Reference: `commands/implement.md:82-83`, `commands/implement.md:95-105`
- The frontier-rounds design doc specifies the interview loop, the stop rule and the D-entry format. Reference: `docs/plans/2026-09-25-question-frontier-rounds-design.md:38-95`
- The plugin version is `0.6.0` and is bumped only in plugin.json. The frontier-rounds change bumped the minor version (0.3 → 0.4.0, commit a8dbf09). Reference: `.claude-plugin/plugin.json:3`

## Patterns Observed
- Decision lifecycle: question records Open, research lays out options in its own section, the user picks, and research writes the pick back into decisions.md. structure and plan then block on anything still Open.
- Each behavior change to a command is paired with eval cases (prompt plus regex and LLM-judge graders) and a README Commands sync.
- Version bumps are minor for behavior changes to a phase (0.4.0 for frontier rounds) and patch for refinements (0.4.1).

## Constraints Discovered
- **The first-round eval conflicts with a smaller first frontier.** `multiple-questions.md` requires at least 2 questions in round 1, and it is already flaky when the first frontier is the goal question alone. The D1 filter makes a single-question round 1 more likely.
- **The decisions-output eval may lose its dependency.** It requires at least one `Depends on:` that names another decision. With leaf decisions moving to Deferred, a rate-limiting run may record too few decisions to include a dependency.
- **Delegation conflicts with Deferred.** The delegation rule (`question.md:90`) settles every remaining frontier decision with a recommendation. Under D3, decisions that fail the filter must go to Deferred instead.
- **Deferred items don't block anything downstream.** structure and plan block only on `Open` (`structure.md:26`, `plan.md:28-29`). A Deferred item the user never picks during research passes into structure silently, unless it is written back as a D-entry or the blocker rule is extended.
- **Replay needs answers.** Unlike /implement, /question needs user answers. `claude -p` runs have no AskUserQuestion (`evals/README.md:14-15`), so a replay gets the markdown fallback round and then stops for input. A multi-round replay needs scripted or simulated answers (e.g. `--resume` with follow-up prompts).
- **The PR body won't show Deferred items.** implement's PR body links only `## D<n>:` headings, so Deferred bullets never appear there unless they are promoted to D-entries.

## Open Decisions (must be resolved before /structure)
- None. No decision in decisions.md is `Firmness: Open`.

## Deferred Decisions (must be resolved before /structure)
Resolved and written back to decisions.md as D7-D12.

- **Filter wording and the "Ask about" list (`question.md:18`):**
  - (a) Replace line 18 with the two-part test: ask a decision only if only the user can answer it AND its answer changes what research reads, otherwise list it under Deferred. Name what typically passes (goal, scope boundary, hard constraints, success criteria, facts only the user knows). This also requires editing the recommendation-hinging rule (`:26`) and the delegation rule (`:90`) so they route to Deferred.
  - (b) Keep the list without approach, compatibility and tradeoffs, and add the test as a separate rule. Smaller diff, but two rules overlap and can disagree.
- **Deferred entry format in decisions.md:**
  - (a) A `## Deferred` section of one-line bullets between the D-entries and Research Focus Areas, as this run used. structure, plan and implement need no format changes. Cost: an entry has no ID to link or reference, and implement's PR body never shows it.
  - (b) Full D-entries with `**Firmness:** Deferred`. These get IDs and `Depends on:`. Cost: structure (`:26`), plan (`:28-29`) and the PR-body Firm filter all have to learn a fourth firmness value.
- **How research presents Deferred vs Open:**
  - (a) A separate `## Deferred Decisions` section in research.md beside Open Decisions, as this file does. It is printed in full and written back to decisions.md as new D-entries (Preference) when the user picks. The two stay distinct, and the D-entry write-back makes picks visible to structure, plan and the PR body. Cost: research.md grows a section and the write-back step gets more complex.
  - (b) Fold Deferred items into the Open Decisions section with a label. Smaller change. Cost: this blurs the distinction D5 flagged as a risk.
- **Continue Gate callout:**
  - (a) No change. Step 3 already prints decisions.md in full (`question.md`, Output step 3), Deferred section included.
  - (b) Name the Deferred count in the gate question, so a misclassified decision is easier to spot (the D3 cost). Cost: one more line in the gate.
- **Replay method for D6:**
  - (a) Delegation replay: for each topic and arm, run `claude -p "/qrspi:question <original topic> … go with your recommendations, write it up"`, then compare D-entries vs Deferred bullets and the questions asked in round 1. Single-shot, like the 2026-11-01 replay. Cost: it doesn't measure multi-round question counts.
  - (b) Simulated-user replay: a subagent answers each fallback round from the user's original typed answers (taken from transcripts), resuming across rounds. It measures total questions asked. Cost: more effort, and the answers only roughly fit new questions.
  - Candidate topics, the runs with the largest counts or explicit complaints: gpa-evals (14 decisions, "too many questions"), agent-calendar (21), question-burster (18), scheduled-tasks (13).
  - The transcript extractor could be committed to `bin/` for measuring.
- **Version bump:**
  - (a) 0.7.0 (minor), since phase behavior and the decisions.md format change. This follows a8dbf09's precedent for frontier rounds.
  - (b) 0.6.1. Cost: understates a format change that downstream phases read.
