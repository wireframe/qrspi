---
description: "QRSPI Phase 5: Execute the implementation plan"
argument-hint: "<path to plans folder, e.g. docs/plans/2026-03-31-my-feature>"
---

# /implement — QRSPI Phase 5: Implement

## Hard Gate

Before doing anything else:
- Use the Glob tool to find `$ARGUMENTS/plan.md`
- If it does NOT exist, STOP and tell the user: "No plan.md found in `$ARGUMENTS/`. Run `/qrspi:plan` first."
- If it DOES exist, read it and proceed.

## Your Role

Execute the implementation plan end to end without pausing for feedback. The pull request review is the feedback loop: run every task, every phase's Quality Gate, and the PR step in one unattended pass, ending with an open PR.

**Do not stop to report progress, ask for approval, or say "Ready for feedback".** Stop and ask only when a task is truly blocked (see Blockers below).

## Steps

1. Print a summary of the plan: total phases, total tasks, estimated scope. Record the starting commit once (`git rev-parse HEAD`) as the base SHA. Then proceed immediately.
2. Execute the plan with subagent-driven development (below). **Run the Quality Gate (below) at every phase boundary.**
3. As tasks complete, update the checkboxes in `$ARGUMENTS/plan.md` from `- [ ]` to `- [x]`.
4. Once every phase has passed its Quality Gate and the final pass has passed (Quality Gate, Final row), run Open Pull Request (below).

### Subagent-Driven Development

Fresh subagent per task, with a two-stage review after each. Never implement, edit code, or debug a task yourself, even when it looks impossible: a task's test failing before any implementer runs is the expected TDD red, not a blocker, and a failing Test becomes a blocker only through step 3's escalation — even when an implementer reports the check itself can't pass.

1. Read the plan once; extract every task's full text and context up front; track them (e.g. via TodoWrite).
2. Per task: dispatch `qrspi:implementer` (Agent tool `subagent_type`), handing it the full task text and context directly — never just a file path. If it returns `QUESTION`, answer it yourself from the plan and its artifacts (`decisions.md`, `research.md`, `structure.md`) via `SendMessage` to that same implementer — don't relay it to the user unless it's a blocker. It implements, runs the task's verification, and self-reviews, then returns `DONE` with its files changed, or `FAILED` (see step 3).
3. **Escalate a failing implementer.** Each `FAILED` reply counts against that implementer, including replies to review-fix follow-ups, and so does a `DONE` whose Test output doesn't show a pass; `QUESTION` doesn't count. On its first or second `FAILED`, `SendMessage` "fix and re-run" (plus any open review findings) to the same implementer. After three `FAILED` replies, dispatch a fresh `qrspi:implementer` with `model: opus` — a subagent keeps its model across follow-ups, so this must be a new dispatch. Its prompt holds the task text, the files the earlier implementer changed, one line per failed attempt on what it tried, the latest failing output, and any open review findings; reviews then proceed against it. It gets two `FAILED` replies. Don't stop early: repeated or identical failures, or an implementer concluding the plan can't be satisfied, are not blockers until the Opus implementer's second `FAILED`.
4. **Spec-compliance review, then quality review, in that order — never the reverse.** Dispatch a fresh `qrspi:spec-reviewer` with the task's full text and the implementer's latest file list (from its most recent `DONE`); it checks the change against the task's own text only. On `GAPS`, `SendMessage` the findings to the same implementer, then dispatch a fresh `qrspi:spec-reviewer` — repeat until `COMPLIANT`.
5. Once `COMPLIANT`, dispatch a fresh `qrspi:quality-reviewer` with the same inputs. On `request changes` or `block`, `SendMessage` the findings to the same implementer, then dispatch a fresh `qrspi:quality-reviewer` — repeat until `approve`. Then stage the task's files (`git add -- <file list>`) so the next task's reviewers see only that task's changes in `git diff`. Per-task review does not run a correctness code-review pass; that happens at the Quality Gate and the final pass.
6. Never move to the next task while either review still has open issues (a review that won't converge is a blocker — see Blockers below), and never dispatch multiple implementers in parallel (they'll conflict).
7. After the last phase's Quality Gate, run the final pass: the Quality Gate below with its Final row.

### Blockers

The only reason to stop before the PR is opened. Stop and ask the user when:
- an implementer reports a task can't proceed: a `QUESTION` the plan and its artifacts can't answer, or a missing dependency,
- the Opus implementer returns its second `FAILED` (see Subagent-Driven Development step 3),
- a spec or quality review still has open issues after three fix rounds, or
- a Quality Gate (phase or final) still fails after Quality Gate step 3's re-dispatches.

Ambiguity you can resolve from the plan's artifacts is not a blocker — resolve it, and note the call you made in the PR body's Summary.

## Scope Changes Mid-Execution

If the user drops, defers, or trims a phase or task during execution, before continuing check `decisions.md` for which decisions that work served. If it carried a `Firm` decision, state how dropping it changes that decision (e.g. "dropping the approval phase turns Firm decision D1 'confirm before create' into 'refuse'") and confirm that's intended — do NOT let a Firm decision silently degrade into its opposite.

## Quality Gate

One gate, run after each phase and once more after the last phase as the final pass. It is non-negotiable. Only the inputs differ:

| Gate | Diff range | Test command | Review steps, in order | Fix commit title |
|---|---|---|---|---|
| Phase | `<phase start>..HEAD` | the phase's verification commands, joined with `&&` | `/simplify <range>`, `/code-review medium --fix <range>`, `/qrspi:code-review <range>` | `Phase N quality gate` |
| Final | `<base SHA>..HEAD` | every phase's verification commands, joined with `&&` | `/code-review high --fix <range>`, `/qrspi:code-review <range>` | `Final review fixes` |

Record `<phase start>` (`git rev-parse HEAD`) before each phase's first task; `<range>` is the row's diff range, passed to each skill as its target.

1. **Commit first.** For a phase gate, commit the phase's staged tasks as `Phase N: <name>` (they're staged per task in Subagent-Driven Development step 5; don't `git add -A`, so stray untracked files stay out), so the gate reviews a committed range on a clean tree.
2. **Dispatch `qrspi:quality-gate`** (Agent tool `subagent_type`) with the row's diff range, test command and review steps.
3. **Act on its reply.** `PASSED`: go to step 4. `FAILED`: pick the task from the files or tests in the failing output and dispatch a fresh `qrspi:implementer` with that task's text, the failing output and the files changed; it gets a fresh budget and the same escalation as Subagent-Driven Development step 3 — never fix it yourself. If no task can be identified, it's a blocker. Then commit the fix and the gate's passing edits as in step 4, so the re-dispatched gate starts on a clean tree, and re-dispatch the gate. `FAILED: missing input`: re-dispatch with all three inputs. Re-dispatch at most twice after `FAILED` and once after `FAILED: missing input`; after that it's a blocker.
4. **Commit the gate's fixes.** If the gate changed files, stage the tracked changes (`git add -u`) plus any new files its summary names, and commit with the row's title. The body takes the gate's applied, skipped and reverted lines and its flagged large or surprising fixes, not raw test output — don't pause for confirmation.

Notes:
- The phase gate adds a whole-phase pass over the per-task reviews; the final pass adds a cross-phase correctness sweep at `high` effort.
- The gate runs three subagent layers deep (gate → `/code-review` fork → its reviewers), exactly the default `CLAUDE_CODE_MAX_SUBAGENT_SPAWN_DEPTH` limit of 3. If the dispatch fails at depth, follow `agents/quality-gate.md`'s steps in the main thread, applying the review skills' edits and fixing what `/qrspi:code-review` flags; red tests still go to an implementer as in step 3. Say so in the PR body's Summary.

## Open Pull Request

Runs once every phase's Quality Gate has passed and the final whole-diff review pass has completed. Draft the pull request body from this plan's artifacts and open the PR. Do this automatically — do not ask for permission to draft or open it. For review fixes and the gate's judgment calls, draw on the quality-gate summaries rather than raw review output, alongside any calls you made yourself.

1. **Resolve link targets.**
   - Resolve the repo slug: `gh repo view --json owner,name`. If this fails (not authenticated, or no `gh` remote configured), stop and tell the user: "Can't resolve the GitHub repo — run `gh auth login` or check the remote, then retry." (Include the command's actual error output when reporting this.) Do not fall back to relative links.
   - Resolve the current branch: `git rev-parse --abbrev-ref HEAD`
   - Build a blob URL prefix: `https://github.com/{owner}/{repo}/blob/{branch}/`
   - For every link into `$ARGUMENTS/decisions.md`, `$ARGUMENTS/research.md`, `$ARGUMENTS/structure.md`, or `$ARGUMENTS/plan.md`, use `{prefix}{path relative to repo root}` — never a bare relative path. Relative links in PR bodies resolve against the repository's default branch, not the head branch, and will 404 pre-merge.
   - For links into a specific heading, derive the anchor from that heading's actual text using GitHub's slug rule (lowercase; strip punctuation except hyphens; spaces → hyphens) — read the heading from the file, don't guess it.

2. **Draft the body.** Write a PR body with this structure, using real content in place of every placeholder:

```markdown
## Summary
<2-4 sentence prose: what changed and why, in plain language>

## Scope
- [Phase 1: <name>](<structure.md blob URL>#phase-1-name) — <one-line what it did>
- [Phase 2: <name>](<structure.md blob URL>#phase-2-name) — <one-line what it did>

## Decisions
- [D1: <Decision Title>](<decisions.md blob URL>#d1-decision-title)
- [D2: <Decision Title>](<decisions.md blob URL>#d2-decision-title)

---

**Artifacts:** [Decisions](<decisions.md blob URL>) · [Structure](<structure.md blob URL>) · [Research](<research.md blob URL>) · [Plan](<plan.md blob URL>)
```

   - Do NOT use markdown footnote syntax (`[^n]` / `[^n]:`) anywhere in the body — GitHub auto-appends a "↩" back-reference arrow to every footnote definition, which is unhelpful noise here. Use plain markdown links instead.
   - List under `## Decisions`, in `decisions.md`'s own order, only the `Firm` decisions that the Summary or a Scope line actually reflects — do not list a decision the body doesn't actually reflect, and do not list `Preference` or `Open` decisions. If no Firm decision is reflected in the Summary or Scope, omit the `## Decisions` heading and list entirely.
   - `**Artifacts:**` is the literal last line of the body — nothing follows it.
   - Do not duplicate `plan.md`'s checklist or copy decision rationale into the body — link to the artifact instead.

3. **Write the draft to a temporary file.** Save the body to a temp path via `mktemp` (e.g. `pr_body_path=$(mktemp)`).

4. **Push and open the PR.** Push the branch (`git push -u origin HEAD`), then run `gh pr create --body-file <temp path>`. Do not ask first — the PR is where review happens. Print the PR URL as the final output.
