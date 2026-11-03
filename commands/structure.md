---
description: "QRSPI Phase 3: Break work into 3-5 independently testable vertical-slice phases based on research findings"
argument-hint: "<path to plans folder, e.g. docs/plans/2026-03-31-my-feature>"
---

# /structure — QRSPI Phase 3: Structure

## Hard Gate

Before doing anything else:
- Use the Glob tool to find `$ARGUMENTS/research.md`
- If it does NOT exist, STOP and tell the user: "No research.md found in `$ARGUMENTS/`. Run `/qrspi:research` first."
- If it DOES exist, read both `$ARGUMENTS/decisions.md` and `$ARGUMENTS/research.md`, then proceed.

## Your Role

Break the work into 3-5 independently testable, revertable phases, shaped as vertical slices. This is "how we get there" — a high-level roadmap, NOT the detailed task list. Don't list the files each phase touches; exact file paths are /plan's job.

## Rules

- Each phase must be independently shippable and testable.
- **Prefer vertical slices.** Each phase should ship one behavior a user or caller can exercise end to end, cutting through every layer that behavior needs (storage, logic, interface, tests, and the docs for it), not one layer at a time (schema, then API, then UI). Put foundation work like a schema change or a data migration in the first slice that needs it. Vertical slices prove the whole path works early, make every phase verifiable by using it, and keep docs from lagging behind the code. If a phase genuinely can't be a vertical slice (a pure refactor with no visible behavior, say), state that in its Goal and why.
- **Docs and release ride along.** Update the docs for a behavior in the phase that ships it. Release bookkeeping (a version bump, a changelog entry) is a step in the last slice, not a phase of its own.
- Phases should have clear dependencies (Phase 2 depends on Phase 1, etc.).
- Keep it to MAX 2 pages. If it's longer, phases are too granular.
- Write the artifact automatically — do NOT ask for permission to write.
- Include an "Out of Scope" section for things explicitly excluded from this change. It is not where decisions.md's `## Deferred` bullets go.
- **Respect firmness from decisions.md.** Only `Firm` decisions are fixed constraints. A `Preference` is the default but stays revisitable — do NOT harden it into a rigid scope boundary or push it to "Out of Scope" as if it were settled; if you narrow one, say so and flag it. A still-unresolved `Open` decision is a blocker: surface it, don't resolve it arbitrarily-minimal to keep moving.
- **Flag phases driven by loosely-held decisions.** If a phase exists mainly to honor a `Preference` or `Open` decision, mark it (`Serves Preference decision D<n> — confirm it's worth building`) instead of presenting it as required. Do not manufacture a whole phase out of a batch/aside answer.

## Output

Write `$ARGUMENTS/structure.md` automatically (no confirmation step) with this format:

```
# Structure: <topic>
Date: YYYY-MM-DD
Decisions: [decisions.md](decisions.md)
Research: [research.md](research.md)

## Phase 1: <name>
**Goal:** <the behavior a user or caller can exercise end to end once this phase ships>
**Depends on:** nothing
**Verification:** <how to confirm this phase works — specific test commands or manual checks>

## Phase 2: <name>
**Goal:** <the next behavior this slice adds>
**Depends on:** Phase 1
**Verification:** <how to confirm>

## Phase 3: ...

## Out of Scope
- <things explicitly excluded>
```

Then print the full contents of the written `structure.md` to the output so the user can review it inline.

Run the Continue Gate below.

## Continue Gate

Ask with the `AskUserQuestion` tool (fall back to a plain-text yes/no/revise prompt if that tool isn't available in this session), presenting exactly these 2 labeled options:

- **"Continue to `/qrspi:plan`"** (recommended, default) — no changes needed. Immediately continue in this same turn: read `${CLAUDE_PLUGIN_ROOT}/commands/plan.md` and follow its instructions, passing through this phase's own `$ARGUMENTS` (the plans folder path) as its argument. Do not end the turn, and do not wait for the user to type the command themselves.
- **"Stop here for now"** — acknowledge and end the turn.

If the user selects **Other** (or, in the plain-text fallback, answers with anything besides a clear continue/stop), treat the typed text as the revision — unless it's blank or whitespace-only, in which case re-run this gate unchanged. Otherwise, apply it as an edit to `structure.md` in place (do not ask before saving), re-print the updated contents, then run this gate again.
