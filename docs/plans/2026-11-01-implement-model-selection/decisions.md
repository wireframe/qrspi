# Decisions: Model selection in /qrspi:implement
Date: 2026-11-01

## D1: Scope of the change
**Question:** Which of the five cost and speed levers belong in this change?
**Depends on:** none
**Firmness:** Preference
**Options considered:**
- All five levers: role agents with pinned models, escalation before blocking, pinned /code-review effort levels, dropping the redundant per-task review, moving seam reviews into subagents. Largest diff; harder to attribute a quality change to one lever.
- Model levers only (1-3): keeps the triple-review overhead and growing orchestrator context.
- Agents and escalation only (1-2): smallest; /code-review effort stays unpinned.
**Chosen:** All five levers
**Rationale:** The levers all touch `implement.md` and together address both model cost and review overhead; structure can split them into phases. Would narrow if research shows one lever (e.g. D11 offload) isn't feasible.

## D2: Quality bar
**Question:** How much review-quality risk is acceptable in exchange for savings?
**Depends on:** none
**Firmness:** Preference
**Options considered:**
- Cheap per task, strong at seams: per-task roles on cheaper models; phase Quality Gate and final whole-diff review on the session model.
- Cheaper implementer only: every review stays on the session model; much smaller savings.
- Cheap everywhere: Opus only via escalation; more bugs reach the PR.
**Chosen:** Cheap per task, strong at seams
**Rationale:** Per-task misses get caught at the phase boundary. Would change if the comparison run (D4) shows the phase gate missing issues that per-task review used to catch.

## D3: Where role models are specified
**Question:** Where should the model for each role be specified?
**Depends on:** none
**Firmness:** Preference
**Options considered:**
- Plugin agent files (`agents/*.md` with `model` and `tools` frontmatter), dispatched by name from `implement.md`: deterministic, allows read-only reviewers.
- Model named in `implement.md` prose: one file, but relies on the orchestrator following prose and gives no tool restriction.
- Model tagged per task in `plan.md`: most precise, but changes the plan format and `/qrspi:plan`.
**Chosen:** Plugin agent files
**Rationale:** Deterministic and supports tool restrictions. Would change if research shows plugin agents can't pin a model or can't be dispatched by name from a command.

## D4: Verification approach
**Question:** How should we confirm the change worked?
**Depends on:** none
**Firmness:** Preference
**Options considered:**
- Evals plus one before/after comparison run (cost, time, PR quality).
- Evals only: no evidence of actual savings.
- Judge on the PR: nothing guards against regressions.
**Chosen:** Evals plus one comparison run
**Rationale:** Evals guard dispatch behavior against future edits; the comparison run gives real numbers. Eval scope may shrink if research shows evals can't observe which agent/model was dispatched.

## D5: Implementer model
**Question:** Which model should the per-task implementer agent pin?
**Depends on:** D2, D3
**Firmness:** Preference
**Options considered:**
- Sonnet: strong at following detailed tasks, much cheaper and faster than Opus.
- Haiku: cheapest, but more fix loops and escalations on tasks needing reasoning.
- Inherit session model: no implementation-quality risk, gives up the biggest saving.
**Chosen:** Sonnet
**Rationale:** `/qrspi:plan` tasks are detailed and bite-sized; escalation (D8, D9) covers hard tasks. Would revisit if the comparison run shows frequent escalations.

## D6: Spec-compliance reviewer model
**Question:** Which model should the per-task spec-compliance reviewer pin?
**Depends on:** D2, D3
**Firmness:** Preference
**Options considered:**
- Haiku: near-mechanical diff-vs-task comparison, very cheap.
- Sonnet: more reliable on large diffs, several times the price per loop.
**Chosen:** Haiku
**Rationale:** The check is narrow and runs at least once per task, so savings compound; the phase gate is the backstop for subtle scope creep.

## D7: Per-task review shape
**Question:** What review should still run per task once the redundant layer is removed?
**Depends on:** D1, D2
**Firmness:** Preference
**Options considered:**
- Spec review + `/qrspi:code-review` checklist per task; `/code-review`'s correctness fleet only at the phase gate and final pass.
- Spec review only: fewest subagents; TDD order can't be checked after the fact.
- Keep both per-task reviews at low effort: keeps the nested reviewer fleet per task.
**Chosen:** Spec review + `/qrspi:code-review` checklist per task
**Rationale:** Catches TDD and Clean Code issues while they're cheap to fix, without starting `/code-review`'s reviewer fleet on every task.

## D8: Escalation target
**Question:** When an implementer escalates, which model takes the task over?
**Depends on:** D5
**Firmness:** Preference
**Options considered:**
- Opus, always: strong retry regardless of session model.
- Session model: respects the user's cost ceiling, but a Sonnet session escalates to Sonnet.
**Chosen:** Opus, always
**Rationale:** Escalation should mean a genuinely stronger attempt before blocking; it's rare enough that cost stays low. Reconfirmed after research: hardcoding is one per-call `model: opus` parameter, while session-model escalation would need a second `model: inherit` agent file because the per-call parameter accepts aliases only. Would change if sessions commonly run on Fable, where Opus escalation could be a step down.

## D9: Escalation trigger
**Question:** When should the implementer escalate to Opus instead of retrying on Sonnet?
**Depends on:** D5, D8
**Firmness:** Preference
**Options considered:**
- After 2 failed fix attempts: Sonnet gets a first try plus two fixes; then Opus with the failure history; Opus failing is a blocker.
- After first failed fix: faster to Opus, more Opus spend on trivial failures.
- Only when blocked: keeps today's undefined "repeated fix attempts".
**Chosen:** After 2 failed fix attempts
**Rationale:** Fixes transient mistakes cheaply and gives "repeated fix attempts" in Blockers a concrete definition.

## D10: Per-task checklist reviewer model
**Question:** Which model should the per-task `/qrspi:code-review` checklist reviewer pin?
**Depends on:** D2, D3, D7
**Firmness:** Preference
**Options considered:**
- Sonnet: reliable on judgment checks (abstraction levels, TDD order).
- Haiku: cheapest; weaker on judgment checks.
**Chosen:** Sonnet
**Rationale:** The checklist's most valuable checks need real reading of the code. Would revisit if the comparison run shows Haiku-level findings are sufficient.

## D11: /code-review effort levels at the seams
**Question:** Which `/code-review` effort levels should the phase Quality Gate and the final whole-diff pass pin?
**Depends on:** D7
**Firmness:** Preference
**Options considered:**
- Medium gate, high final.
- High gate, high final: strongest net; high fleet runs once per phase.
- Medium gate, medium final: cheapest; final pass may miss cross-phase bugs.
**Chosen:** Medium gate, high final
**Rationale:** With per-task correctness review gone (D7), the seams carry correctness; high effort is reserved for the last check before the PR.

## D12: Pinned model vs session model
**Question:** If the session runs on a cheaper model than a role's pin, which wins?
**Depends on:** D3, D8
**Firmness:** Preference
**Options considered:**
- Pin always wins: identical behavior for every user; consistent with D8.
- Session model is a ceiling: respects budget choice; behavior varies by session.
**Chosen:** Pin always wins
**Rationale:** Predictable, comparable runs. Would change if users report unexpected spend on cheap sessions.

## D13: Which seam reviews move into subagents
**Question:** Which seam reviews move out of the orchestrator's context into a fresh subagent on the session model?
**Depends on:** D1, D2
**Firmness:** Preference
**Options considered:**
- Phase gate and final pass: orchestrator stays small; PR body relies on subagent summaries.
- Phase gate only: final pass's raw output lands in the orchestrator's largest context.
**Chosen:** Phase gate and final pass
**Rationale:** Keeps orchestrator context flat across the whole run. Depends on research confirming a subagent can run `/simplify` and `/code-review` (including `/code-review` starting its own reviewer subagents); if nested subagents aren't possible, this lever must change shape.

## D14: Opt-out to previous behavior
**Question:** Should users get a way to switch back to every role inheriting the session model?
**Depends on:** D3, D12
**Firmness:** Preference
**Options considered:**
- No opt-out: new behavior documented in README, minor version bump.
- Add an opt-out switch: two behaviors to document and test.
**Chosen:** No opt-out
**Rationale:** Only build what's needed now; a switch is easy to add if requested.

## D15: Comparison run subject
**Question:** What should the before/after comparison run execute?
**Depends on:** D4
**Firmness:** Preference
**Options considered:**
- Replay an existing completed `docs/plans/` plan on a scratch branch from its starting commit, once with today's implement and once with the new one.
- Purpose-built small plan: cheap and repeatable, but understates savings.
**Chosen:** Replay an existing qrspi plan
**Rationale:** Realistic work with a known-good result. Research picks which plan.

## D16: Who dispatches per-task reviewers
**Question:** Who should dispatch the per-task spec and checklist reviewers: the main thread or the implementer?
**Depends on:** D7, D8, D9
**Firmness:** Preference
**Options considered:**
- Main thread: the orchestrator dispatches each reviewer from the task text and relays fixes via SendMessage; keeps reviews independent and lets the orchestrator count failures and escalate. Fix loops pass through the session-model context.
- Implementer dispatches them: smaller orchestrator context, but weaker independence, no way to self-escalate to Opus, and reviewers sit one nesting layer deeper.
**Chosen:** Main thread
**Rationale:** Escalation (D8, D9) requires a dispatcher above the implementer, since a subagent keeps its model across follow-ups. Would change if fix-loop traffic proves a significant share of orchestrator tokens.

## Research Focus Areas
- How `commands/implement.md` dispatches each role today (implementer, spec reviewer, quality reviewer, phase gate, final pass), and every place it references `/code-review`, `/simplify`, and `/qrspi:code-review`.
- Whether Claude Code plugins support an `agents/` directory, what frontmatter fields (`model`, `tools`, `description`) agent files accept, how plugin agents are named when dispatched (e.g. `qrspi:implementer`), and whether users can override a plugin agent's model (D3, D12, D14).
- Whether a subagent can invoke skills/commands like `/simplify`, `/code-review`, and `/qrspi:code-review`, and whether `/code-review` can start its own reviewer subagents from inside a subagent (D7, D13).
- How `/code-review`'s effort level is passed when invoked programmatically from a command or subagent (D11).
- How an escalated retry can run on Opus while keeping the failure history: re-dispatching a fresh Opus agent with the history vs. continuing the existing agent (D8, D9).
- What `claude plugin eval` can observe: whether graders can see which agent type/model was dispatched, and how existing evals in `evals/` are structured (D4).
- Which completed plan in `docs/plans/` is the best replay candidate and what its starting commit is (D15).
- Where the README and plugin version describe implement's behavior and need updating (D14).
