---
description: "QRSPI Phase 5: Execute the implementation plan"
argument-hint: "<path to plans folder, e.g. docs/plans/2026-03-31-my-feature>"
---

# /implement — QRSPI Phase 5: Implement

## Hard Gate

Before doing anything else:
- Use the Glob tool to find `$ARGUMENTS/plan.md`
- If it does NOT exist, STOP and tell the user: "No plan.md found in `$ARGUMENTS/`. Run `/plan` first."
- If it DOES exist, read it and proceed.

## Your Role

Execute the implementation plan directly, choosing one of the two approaches below.

## Steps

1. Present a summary of the plan: total phases, total tasks, estimated scope.
2. Ask the user which execution approach they prefer (details below): **Option A (Subagent-Driven)** or **Option B (Batch Execution)**.
3. Execute the chosen approach. **Run the Quality Gate (below) at every phase boundary**, regardless of which option is chosen.
4. As tasks complete, update the checkboxes in `$ARGUMENTS/plan.md` from `- [ ]` to `- [x]`.

### Option A: Subagent-Driven

Fresh subagent per task, with a two-stage review after each. Best for tasks that benefit from independent, isolated context.

1. Read the plan once; extract every task's full text and context up front; track them (e.g. via TodoWrite).
2. Per task: dispatch a fresh implementer subagent, handing it the full task text and context directly — never just a file path. If it asks questions, answer them before it proceeds. It implements, runs the task's verification, and self-reviews.
3. **Spec-compliance review, then code-quality review, in that order — never the reverse.** Dispatch an independent subagent to check the diff against the task's own text only: everything asked for is present, nothing extra was added. If it finds gaps, the same implementer subagent fixes them and it re-reviews — repeat until clean.
4. Once spec-compliant, dispatch an independent subagent to run `/code-review` on the diff. If it finds issues, the same implementer subagent fixes them and it re-reviews — repeat until approved.
5. Never move to the next task while either review still has open issues, and never dispatch multiple implementer subagents in parallel (they'll conflict).
6. After the last task in the plan, run one final `/code-review` pass over the entire implementation's diff, independent of the per-phase Quality Gate below.

### Option B: Batch Execution

Sequential execution in this session, checkpointing for review every 3 tasks. Best for smaller, tightly-sequenced plans.

1. Before starting, read the whole plan and review it critically — if it has gaps or something is unclear, raise it with the user before executing rather than guessing.
2. Execute tasks in batches of 3 (or as sized by the user): mark each in_progress, follow its steps exactly, run its verification, mark it completed.
3. After each batch, report what was implemented and the verification output, then say "Ready for feedback" and wait.
4. **Stop and ask, don't guess,** when: a task hits a blocker (missing dependency, unclear instruction), or verification fails repeatedly.
5. If the user updates the plan based on feedback, or the approach needs rethinking, re-review the updated plan (back to step 1) before continuing.

## Scope Changes Mid-Execution

If the user drops, defers, or trims a phase or task during execution, before continuing check `decisions.md` for which decisions that work served. If it carried a `Firm` decision, state how dropping it changes that decision (e.g. "dropping the approval phase turns Firm decision D1 'confirm before create' into 'refuse'") and confirm that's intended — do NOT let a Firm decision silently degrade into its opposite.

## Quality Gate (per phase)

After the last task of each plan phase is implemented and its tests pass — and **before** that phase is considered done — run this gate on the phase's accumulated diff. It is non-negotiable and applies to both Option A and Option B.

1. **Verify green.** Confirm the phase's tests pass first (the verification command from the phase's plan tasks). A failing suite is a blocker — stop and fix before gating.
2. **`/simplify`.** Run it to apply reuse/simplification/efficiency/altitude cleanups (it always auto-applies). This goes first so the next step isn't re-flagging the same cleanups.
3. **Re-run the test suite.** `/simplify` mutates the working tree — reconfirm green. If it broke something, fix or revert the offending cleanup before continuing.
4. **`/code-review --fix`.** Run it to catch correctness bugs plus any remaining quality issues and apply the fixes automatically.
5. **Re-run the test suite.** `/code-review --fix` also mutates the tree — reconfirm green. If a fix broke a test, resolve it before committing.
6. **Commit the phase**, including the gate's changes (fold into the phase commit, or add a follow-up `Phase N quality gate` commit if the phase was already committed task-by-task under Option A).

Notes:
- This gate runs at the **phase seam**, not per task. Under Option A it does not replace the per-task spec/quality reviewers — it adds a whole-phase pass (`/simplify`'s altitude view + `/code-review`'s correctness sweep) over the combined diff.
- If either step's fixes are large or surprising, surface a short summary to the user before committing rather than silently moving on.

## Prepare Pull Request

Applies regardless of which execution option was chosen. Runs once every phase's Quality Gate has passed and — under Option A — after its final whole-diff `/code-review` pass (step 6) has also completed. Draft the pull request body from this plan's artifacts. Do this automatically — do not ask for permission to draft it.

1. **Resolve link targets.**
   - Resolve the repo slug: `gh repo view --json owner,name`. If this fails (not authenticated, or no `gh` remote configured), stop and tell the user: "Can't resolve the GitHub repo — run `gh auth login` or check the remote, then retry." (Include the command's actual error output when reporting this.) Do not fall back to relative links.
   - Resolve the current branch: `git rev-parse --abbrev-ref HEAD`
   - Build a blob URL prefix: `https://github.com/{owner}/{repo}/blob/{branch}/`
   - For every link into `$ARGUMENTS/decisions.md`, `$ARGUMENTS/research.md`, `$ARGUMENTS/structure.md`, or `$ARGUMENTS/plan.md`, use `{prefix}{path relative to repo root}` — never a bare relative path. Relative links in PR bodies resolve against the repository's default branch, not the head branch, and will 404 pre-merge.
   - For links into a specific heading, derive the anchor from that heading's actual text using GitHub's slug rule (lowercase; strip punctuation except hyphens; spaces → hyphens) — read the heading from the file, don't guess it.

2. **Draft the body.** Write a PR body with this structure, using real content in place of every placeholder — no decision gets a footnote number reused for another:

```markdown
## Summary
<2-4 sentence prose: what changed and why, in plain language. Attach [^1] inline wherever a sentence reflects a Firm decision.>

## Scope
- [Phase 1: <name>](<structure.md blob URL>#phase-1-name) — <one-line what it did>[^2]
- [Phase 2: <name>](<structure.md blob URL>#phase-2-name) — <one-line what it did>

---

**Artifacts:** [Decisions](<decisions.md blob URL>) · [Structure](<structure.md blob URL>) · [Research](<research.md blob URL>) · [Plan](<plan.md blob URL>)

[^1]: [D1: <Decision Title>](<decisions.md blob URL>#d1-decision-title)
[^2]: [D2: <Decision Title>](<decisions.md blob URL>#d2-decision-title)
```

   - Every `[^n]` marker in the Summary or Scope must have a matching `[^n]:` definition at the bottom, numbered in the order the markers appear — never leave an orphaned definition with no reference, and never reuse a number for a different decision. This marker numbering tracks the order footnotes appear in the body, not the decision's own `D<n>` number — footnote `[^1]` can point at `D3` if D3 is the first Firm decision actually mentioned.
   - Attach a footnote only to a `Firm` decision from `$ARGUMENTS/decisions.md`, and only where the Summary or a Scope line actually reflects that decision — do not manufacture a mention just to attach a footnote, and do not footnote `Preference` or `Open` decisions. If no Firm decision is reflected in the Summary or Scope, omit the footnote markers and the definitions block entirely.
   - Do not duplicate `plan.md`'s checklist or copy decision rationale into the body — link to the artifact instead.

3. **Write the draft to a temporary file.** Save the body to a temp path via `mktemp` (e.g. `pr_body_path=$(mktemp)`).

4. **Offer to open the PR.** Print the drafted body to the output, then ask the user: "Open this as a PR with `gh pr create --body-file <temp path>`, or would you like changes first?" Only run `gh pr create` after explicit confirmation — never open the PR unattended.
