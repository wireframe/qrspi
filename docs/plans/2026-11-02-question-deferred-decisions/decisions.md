# Decisions: make /qrspi:question less exhaustive before research
Date: 2026-11-02

Context: 16 `/qrspi:question` runs from 2026-10-04 to 2026-11-02 averaged 9-21 decisions each. 68% of 243 answers were the clicked "(Recommended)" option, the user typed "too many questions" and "i don't have an answer yet" several times, and in 10 of the runs decisions.md was edited again after research. Likely cause: the empty-frontier stop combined with "Ask about: … approach, tradeoffs", which pulls evidence-dependent and implementation-level decisions in ahead of research.

## D1: What /question asks
**Question:** Which decisions should /question put to the user?
**Depends on:** none
**Firmness:** Preference
**Options considered:** (a) only decisions that only the user can answer AND that change where research looks; (b) keep the current breadth (scope, approach, constraints, compatibility, tradeoffs, success criteria).
**Chosen:** (a) only what only the user can answer and what changes where research looks.
**Rationale:** Accepted in conversation ("is good"). Most current questions are Claude's own defaults that the user clicks through. Would change if the filter turns out to drop decisions the user needed to make up front.

## D2: Stopping rule
**Question:** Should the interview get a hard question or round budget in place of the empty-frontier stop?
**Depends on:** none
**Firmness:** Preference
**Options considered:** (a) keep "stop when the frontier is empty"; (b) cap at about one or two rounds.
**Chosen:** (a) keep the empty-frontier stop. No budget.
**Rationale:** The user rejected the budget. D1 and D3 shrink the frontier instead of an arbitrary cap cutting it short.

## D3: Fate of decisions that fail the filter
**Question:** When a decision fails the D1 filter, is it never asked (listed under Deferred), or still asked in plainer wording?
**Depends on:** D1
**Firmness:** Preference
**Options considered:** (a) never asked, listed under a new Deferred section of decisions.md; (b) still asked, with the filter only shaping wording.
**Chosen:** (a) never asked; goes to Deferred. Example: gpa-evals' "When can a calibrated judge fail the eval run?" would be Deferred, while "Audit only, or audit + fixes?" is still asked.
**Rationale:** This is what actually cuts the question count. Cost: a decision misclassed as Deferred surfaces only when the user scans decisions.md at the Continue Gate.

## D4: Open-answer propagation
**Question:** Should a "not sure / defer / research it" answer prune that whole branch of the tree?
**Depends on:** none
**Firmness:** Preference
**Options considered:** (a) keep current Open propagation (dependents of an Open decision are recorded Open, not asked); (b) prune the whole branch.
**Chosen:** (a) keep current behavior.
**Rationale:** The user rejected branch pruning.

## D5: Who settles Deferred decisions
**Question:** Which phase settles Deferred decisions, given they should be settled before /plan?
**Depends on:** D3
**Firmness:** Preference
**Options considered:** (a) /structure asks the user with research in hand; (b) /research lays out evidence and options for each Deferred decision and the user picks before /structure.
**Chosen:** (b) /research lays out options and the user picks before /structure.
**Rationale:** The user said "probably needs to be settled before the plan", then picked research. Known risk: Deferred and Open start to look alike, so research's output has to keep them distinguishable.

## D6: Success test
**Question:** How do we know the slimmer /question worked?
**Depends on:** D1, D3
**Firmness:** Preference
**Options considered:** (a) replay real topics from the last month through the old and new /question, compare question counts and what got Deferred, and update the evals; (b) eval suite updates only.
**Chosen:** (a) replay real topics, plus eval updates.
**Rationale:** Synthetic evals alone won't show whether real sessions got shorter. Replay answers are simulated, so the comparison is directional.

## D7: Where the filter rule lives
**Question:** Should the D1 test replace the "Ask about" list, or sit beside a trimmed list?
**Depends on:** D1, D3
**Firmness:** Preference
**Options considered:** (a) replace `question.md:18` with the two-part test and name what typically passes (goal, scope boundary, hard constraints, success criteria, facts only the user knows), and also edit the recommendation-hinging rule (`:26`) and the delegation rule (`:90`) to route to Deferred; (b) trim approach, compatibility and tradeoffs from the list and add the test as a separate rule.
**Chosen:** (a) replace the list.
**Rationale:** Settled after research. One rule leaves nothing to disagree with it. Without the delegation edit, "go with your recommendations" would still record every leaf decision.

## D8: Deferred entry format in decisions.md
**Question:** How is a Deferred decision written in decisions.md?
**Depends on:** D3
**Firmness:** Preference
**Options considered:** (a) a `## Deferred` section of one-line bullets between the D-entries and Research Focus Areas; (b) D-entries with `**Firmness:** Deferred`.
**Chosen:** (a) bulleted section.
**Rationale:** Settled after research. structure (`:26`), plan (`:28-29`) and implement's PR body (`:95-105`) need no change. A Deferred item gets a D-number only when research writes the pick back (D9).

## D9: How research presents Deferred decisions
**Question:** How does /research present Deferred decisions next to Open ones?
**Depends on:** D5, D8
**Firmness:** Preference
**Options considered:** (a) a separate `## Deferred Decisions` section, printed in full, with picks written back to decisions.md as new D-entries (Preference); (b) folded into Open Decisions with a label.
**Chosen:** (a) separate section, with write-back.
**Rationale:** Settled after research. It keeps the two buckets distinct, which was D5's known risk, and the write-back makes picks visible to structure, plan and the PR body.

## D10: Replay method
**Question:** How should the old-vs-new replay run?
**Depends on:** D6
**Firmness:** Preference
**Options considered:** (a) delegation replay: about 4 real topics (gpa-evals, agent-calendar, question-burster, scheduled-tasks) through both arms with "go with your recommendations", one-shot `claude -p` like the 2026-11-01 replay, comparing D-entries vs Deferred and round-1 questions; (b) simulated-user replay answering each round from the original typed answers.
**Chosen:** (a) delegation replay.
**Rationale:** Settled after research. It is cheap and repeatable. It measures what would be asked, not the questions asked across a real multi-round session.

## D11: Continue Gate callout
**Question:** Should /question's Continue Gate name the Deferred count?
**Depends on:** D8
**Firmness:** Preference
**Options considered:** (a) no change, since decisions.md (including Deferred) is already printed in full before the gate; (b) name the Deferred count in the gate question.
**Chosen:** (a) no change.
**Rationale:** Claude's default, not asked. Would change if replays show misclassified Deferred items slipping past review.

## D12: Version bump
**Question:** What version does this ship as?
**Depends on:** none
**Firmness:** Preference
**Options considered:** (a) 0.7.0; (b) 0.6.1.
**Chosen:** (a) 0.7.0.
**Rationale:** Claude's default, not asked. A phase behavior and decisions.md format change follows the minor bump that frontier rounds got (a8dbf09).

## D13: /structure stops listing files
**Question:** Should /structure's phases name the files they touch?
**Depends on:** none
**Firmness:** Preference
**Options considered:** (a) keep the `**Files touched:**` field in every phase (`commands/structure.md:41,47`); (b) remove it and leave file choices to /plan, which already requires exact file paths per task (`commands/plan.md:22`).
**Chosen:** (b) remove it from /structure.
**Rationale:** The user pushed back during this run's structure gate ("that's the job for the plan!") and asked to fix the command itself. /plan already owns file paths, so nothing is lost.

## Deferred
All resolved after research as D7-D12.

## Research Focus Areas
- In `commands/question.md`, which rules drive the interview toward exhaustive or implementation-level questions (Rules "Ask about", Rounds stop rule, recommendation-hinging rule, Open propagation)?
- How does `commands/research.md` handle Open decisions today (section format, printing, recording answers back into decisions.md), and what would it need to also cover Deferred ones?
- Which evals in `evals/` (`question-first-round`, `question-decisions-output`, `question-examples-*`) assert behavior that D1/D3 change, and how are those evals structured and graded?
- How was the old-vs-new replay comparison in `docs/plans/2026-11-01-implement-model-selection/comparison.md` run, and can the same approach replay /question on real topics?
- Where else are /question's behavior and decisions.md format documented (README, evals/README, other commands that read decisions.md)?
