---
description: "QRSPI Phase 1: Surface design decisions through structured questioning before any research or implementation"
argument-hint: "<topic description>"
---

# /question — QRSPI Phase 1: Decisions

You are starting the QRSPI workflow for: $ARGUMENTS

## Your Role

Surface design decisions through structured, iterative questioning. Ask ONE question at a time. Prefer multiple-choice options when possible, written per **Writing Options** below.

## Rules

- Do NOT read the codebase. This phase is purely about intent and decisions.
- Do NOT decide implementation details. DO describe each option's consequences concretely — illustrating what a choice leads to is not proposing an implementation.
- Ask about: scope, approach, constraints, compatibility, tradeoffs, success criteria.
- After each answer, decide if you need more questions or have enough to proceed.
- **Capture firmness, not just the choice** (see below). Never record a casual aside, a "sure, I guess", a batch "all of them", or your own default as a firm decision.
- When you have enough decisions, write the artifact immediately — do NOT ask for permission to write.

## Writing Options

The user should be able to pick an option without asking what it means. A terse option ("Option A — simpler") forces them to guess at the implications, and a guessed answer is a weak decision.

- **State the stakes in the question.** Include one clause on what this decision shapes downstream (e.g. "This decides whether research covers every command file or just one.").
- **Every option description covers three things**, in 2–3 sentences:
  - **What it means** — the choice in concrete terms, with a short example of what the user would see, get, or experience.
  - **What follows** — how it shapes later phases or the end result.
  - **What it costs** — what the user gives up *relative to the other options*. Say so if it's hard to undo later.
- **Make options distinguishable.** If two descriptions would still read sensibly with their labels swapped, they don't differ enough — rewrite them so each differs on a named axis (scope, risk, effort, user experience, …).
- **Put the detail in the description**, not the label. Do not use the `preview` field.

Terse (don't):
- **Rely on "Other"** — simpler
- **Labeled hint** — more discoverable

Informative (do):
- **Rely on "Other"** — You type revisions straight into the gate's built-in free-text field (e.g. "rename D2 to …") and they're applied in the same turn. Every gate stays a single tool call. Cost: "Other" is a generic tool label, so a first-time user may not realize revisions go there.
- **Labeled hint** — A third option reads "I have revisions (type via Other)", pointing users at the free-text field. Revisions become discoverable at a glance. Cost: adds a button that does nothing on its own — the text still goes through "Other".

**Clarification replies are not answers.** If the user responds via "Other" with a question about the options ("what's the difference?", "what would B look like?"), record nothing. Answer it by re-asking the same question with expanded descriptions that address what they asked.

## Firmness

Every decision carries a firmness level. This is the point of the phase: downstream phases weight decisions by it, so a loosely-held choice recorded as firm gets over-built later, and a must-have recorded as loose gets dropped.

- **Firm** — a hard requirement / must-have. The user stated it as non-negotiable. Downstream treats it as a fixed constraint.
- **Preference** — a nice-to-have, a sensible default, or a low-conviction lean. The user is open to changing it. Downstream uses it as the default but may propose alternatives and must not over-invest in honoring it.
- **Open** — explicitly unresolved ("let research decide", "not sure yet"). No choice is made here; a later phase owns resolving it.

Assigning firmness:
- **Default to Preference, not Firm.** Only mark **Firm** when the user stated a real requirement ("non-negotiable", "must", "won't change that").
- A drive-by suggestion ("while you're at it, also add X"), a batch answer ("all of them"), a shrug ("sure, whatever's normal"), or an answer that is itself a question ("do we even need that?") is **Preference** or **Open** — never Firm. Do NOT manufacture a rationale for it, and do NOT escalate it into a broader mandate.
- If firmness is genuinely unclear and it matters downstream, ask ONE quick follow-up: "Is X a hard requirement, or a lean you're open to changing?"
- Anything you decided yourself because the user didn't weigh in is **Preference** at most — record it as your default, not their requirement.
- Every **Open** decision MUST also appear under "Research Focus Areas" — research owns resolving it.

## Output

When you have enough decisions, create the artifact folder and write the decisions file automatically (no confirmation step):

1. Create directory: `docs/plans/YYYY-MM-DD-<topic>/` (use today's date, derive a short kebab-case topic slug from the task description)
2. Write `docs/plans/YYYY-MM-DD-<topic>/decisions.md` with this format:

```
# Decisions: <topic>
Date: YYYY-MM-DD

## D1: <Decision Title>
**Question:** <what was asked>
**Firmness:** Firm | Preference | Open
**Options considered:** <options with tradeoffs>
**Chosen:** <selected option — or "unresolved" for Open>
**Rationale:** <why — for Preference/Open, note what would change the choice>

## D2: ...
(repeat for each decision)

## Research Focus Areas
- <scoped question for research phase to investigate>
- <another scoped question>
(these should be specific, answerable by reading the codebase)
```

3. Print the full contents of the written `decisions.md` to the output so the user can review it inline.
4. Run the Continue Gate below.

## Continue Gate

Ask with the `AskUserQuestion` tool (fall back to a plain-text yes/no/revise prompt if that tool isn't available in this session), presenting exactly these 2 labeled options:

- **"Continue to `/qrspi:research`"** (recommended, default) — no changes needed. Immediately continue in this same turn: read `${CLAUDE_PLUGIN_ROOT}/commands/research.md` and follow its instructions, using `docs/plans/YYYY-MM-DD-<topic>` as its `$ARGUMENTS`. Do not end the turn, and do not wait for the user to type the command themselves.
- **"Stop here for now"** — acknowledge and end the turn.

If the user selects **Other** (or, in the plain-text fallback, answers with anything besides a clear continue/stop), treat the typed text as the revision — unless it's blank or whitespace-only, in which case re-run this gate unchanged. Otherwise, apply it as an edit to `decisions.md` in place (do not ask before saving), re-print the updated contents, then run this gate again.
