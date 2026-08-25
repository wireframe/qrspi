---
description: "QRSPI Phase 4: Create detailed implementation plan with bite-sized tasks grouped by structure phases"
argument-hint: "<path to plans folder, e.g. docs/plans/2026-03-31-my-feature>"
---

# /plan — QRSPI Phase 4: Plan

## Hard Gate

Before doing anything else:
- Use the Glob tool to find `$ARGUMENTS/structure.md`
- If it does NOT exist, STOP and tell the user: "No structure.md found in `$ARGUMENTS/`. Run `/qrspi:structure` first."
- If it DOES exist, read all prior artifacts: `$ARGUMENTS/decisions.md`, `$ARGUMENTS/research.md`, and `$ARGUMENTS/structure.md`, then proceed.

## Your Role

Create a detailed implementation plan with bite-sized tasks (2-5 minutes each) grouped by the phases defined in the structure artifact. This plan must be executable by someone with zero context about the codebase.

## Rules

- Group tasks by phase from the structure artifact.
- Each task must have: exact file paths, what to change, how to verify.
- Include `file:line` references from the research artifact.
- Follow TDD: for each feature task, write the failing test first, then implement.
- Include commit steps at natural boundaries.
- Plan must use a bite-sized, phase-grouped checkbox task format executable by `/implement`.
- No open questions allowed — if something is unclear, resolve it now by reading code.
- **Weight effort by firmness.** Don't spend heavy task breakdown on a phase driven by a `Preference` or `Open` decision — keep it minimal and flag it for confirmation before expanding. Reserve full detail for `Firm` decisions.
- **A still-`Open` decision is a blocker, not something to default.** If any decision that this plan depends on is still unresolved, STOP and get it decided before writing tasks that assume an answer.
- **Decision continuity when a phase is dropped.** If a structure phase is dropped or deferred during planning, check which decisions it served. If it carried a `Firm` decision, state the consequence explicitly (e.g. "dropping Phase 3 turns Firm decision D1 'confirm before create' into 'refuse' — confirm that's intended") rather than silently narrowing the decision.

## Output

Write the artifact automatically — do NOT ask for permission to write. Write `$ARGUMENTS/plan.md` with this format:

```
# Plan: <topic>
Date: YYYY-MM-DD
Decisions: [decisions.md](decisions.md)
Research: [research.md](research.md)
Structure: [structure.md](structure.md)

> **For Claude:** Execute this plan task-by-task, phase by phase — see `/qrspi:implement`'s execution options.

**Goal:** <one sentence>
**Architecture:** <2-3 sentences>
**Tech Stack:** <key technologies>

---

## Phase 1: <name from structure>

- [ ] Task 1.1: <description>
  - File: `src/path/file.ts:42`
  - Change: <specific change to make>
  - Test: <exact command to verify>

- [ ] Task 1.2: ...

- [ ] Commit Phase 1

## Phase 2: <name from structure>

- [ ] Task 2.1: ...

...
```

The plan is usually too long to dump inline. Print an outline instead: the Goal/Architecture/Tech Stack lines, then each phase's name and task count (e.g. `Phase 1: Auth setup — 5 tasks`) — not the task-by-task body. Tell the user the file path (`$ARGUMENTS/plan.md`) to read the full detail.

Run the Continue Gate below.

## Continue Gate

Ask with the `AskUserQuestion` tool (fall back to a plain-text yes/no/revise prompt if that tool isn't available in this session), presenting exactly these 2 labeled options:

- **"Continue to `/qrspi:implement`"** (recommended, default) — no changes needed. Immediately continue in this same turn: read `${CLAUDE_PLUGIN_ROOT}/commands/implement.md` and follow its instructions, passing through this phase's own `$ARGUMENTS` (the plans folder path) as its argument. Do not end the turn, and do not wait for the user to type the command themselves.
- **"Stop here for now"** — acknowledge and end the turn.

If the user selects **Other** (or, in the plain-text fallback, answers with anything besides a clear continue/stop), treat the typed text as the revision — unless it's blank or whitespace-only, in which case re-run this gate unchanged. Otherwise, apply it as an edit to `plan.md` in place (do not ask before saving), re-print the updated outline, then run this gate again.
