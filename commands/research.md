---
description: "QRSPI Phase 2: Research the codebase based on scoped questions from /question decisions"
argument-hint: "<path to decisions folder, e.g. docs/plans/2026-03-31-my-feature>"
---

# /research — QRSPI Phase 2: Research

## Hard Gate

Before doing anything else, check that the decisions artifact exists:
- Use the Glob tool to find `$ARGUMENTS/decisions.md`
- If it does NOT exist, STOP and tell the user: "No decisions.md found in `$ARGUMENTS/`. Run `/qrspi:question` first."
- If it DOES exist, read it, noting the "Research Focus Areas" section, and proceed.

## Your Role

Map the relevant codebase based on the "Research Focus Areas" from the decisions artifact. You are a documentary researcher — record what exists, not what should exist.

## Rules

- For EACH focus area, dispatch a parallel Explore agent with a focused prompt.
- Be strictly documentary: no opinions, no suggestions, no "you should."
- Capture findings with `file:line` references.
- Compress findings — distill truth, don't dump raw file contents.
- **Own the Open decisions.** For every decision marked `Firmness: Open` in decisions.md, gather the codebase evidence needed to resolve it and lay out the viable options with grounded tradeoffs. Do NOT silently pick one, and do NOT let it pass through unaddressed — an unowned Open decision is what later gets resolved arbitrarily. Surface each in the "Open Decisions" output section below so the user (not `/structure`) resolves it deliberately.

## Output

Write the artifact automatically — do NOT ask for permission to write. Write `$ARGUMENTS/research.md` with this format:

```
# Research: <topic>
Date: YYYY-MM-DD
Decisions: [decisions.md](decisions.md)

## <Focus Area 1 title>
**Findings:**
- <what exists, where, how it works>
- Reference: `src/path/file.ts:42`

## <Focus Area 2 title>
**Findings:**
- ...

## Patterns Observed
- <naming conventions, error handling patterns, architectural patterns found>

## Constraints Discovered
- <things the decisions phase didn't anticipate>
- <technical limitations found>

## Open Decisions (must be resolved before /structure)
- **D<n> <title>:** <the viable options, with tradeoffs grounded in the findings above>. Still unresolved — recommend the user pick before structuring.
- (one entry per `Firmness: Open` decision; omit this section only if there were none)
```

Research findings are usually too long to dump inline. Print an outline instead: each focus area title with its finding count (e.g. `Rate limiting middleware — 4 findings`), plus whether Patterns Observed / Constraints Discovered sections have entries — not the finding bodies. Tell the user the file path (`$ARGUMENTS/research.md`) to read the full detail.

If there are Open Decisions, print those in full (title, options, tradeoffs) regardless of the outline-only rule above — the user needs that detail to resolve them — and tell the user which ones still need a call before `/qrspi:structure`, offering to record their answers back into `decisions.md` (flipping those entries from `Open` to `Firm`/`Preference`) before running the Continue Gate.

Run the Continue Gate below.

## Continue Gate

Ask with the `AskUserQuestion` tool (fall back to a plain-text yes/no/revise prompt if that tool isn't available in this session), presenting exactly these 2 labeled options:

- **"Continue to `/qrspi:structure`"** (recommended, default) — no changes needed. If unresolved Open Decisions remain, note them as a caveat in this option's text. Immediately continue in this same turn: read `${CLAUDE_PLUGIN_ROOT}/commands/structure.md` and follow its instructions, passing through this phase's own `$ARGUMENTS` (the plans folder path) as its argument. Do not end the turn, and do not wait for the user to type the command themselves.
- **"Stop here for now"** — acknowledge and end the turn.

If the user selects **Other** (or, in the plain-text fallback, answers with anything besides a clear continue/stop), treat the typed text as the revision — unless it's blank or whitespace-only, in which case re-run this gate unchanged. Otherwise, apply it as an edit to `research.md` in place (do not ask before saving), re-print the updated outline, then run this gate again.
