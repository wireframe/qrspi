# Decisions: QRSPI phase-transition gate — inline revisions
Date: 2026-08-25

## D1: Scope of the gate redesign
**Question:** Which phase-transition gates are in scope for this redesign?
**Firmness:** Preference
**Options considered:**
- All QRSPI gates — apply one consistent gate design across every phase transition (question→research, research→structure, structure→plan, plan→implement).
- Just `/qrspi:question`'s gate — narrower, lower risk of touching other commands.
- Something else specific.
**Chosen:** All QRSPI gates. The same Continue / Revise / Stop pattern should behave consistently across every phase transition, not just the one in `/qrspi:question`.
**Rationale:** Preference — selected as the default scope, not stated as non-negotiable. Would narrow back to a single gate if applying the change to all phases turns out to be inconsistent with how each command currently works.

## D2: Revision-input mechanism — collapse to one turn
**Question:** For the "I have revisions" branch, should it stay free-text-in-a-separate-turn, or be redesigned so revision text is captured inline, in the same AskUserQuestion call as the gate itself?
**Firmness:** Preference (leaning strongly, explicitly conditional on research)
**Options considered:**
- (a) Drop the labeled "I have revisions" option; rely on AskUserQuestion's built-in "Other" free-text field so the user types revision text directly while answering the gate question itself — one tool call, one turn, no drop to plain chat. Tradeoff: "Other" is a generic label supplied by the tool and can't be renamed or given a custom description, so the revision path is less discoverable than an explicit option.
- (b) Keep a labeled third option purely as a discoverability hint (e.g. "I have revisions (type below via Other)"), but the actual free text still has to go through "Other" — doesn't reduce turns, just adds a pointer to it.
- (c) Leave unresolved.
**Chosen:** Leaning toward (a) — drop the explicit "I have revisions" label and rely on "Other" for inline revision text captured in the same tool call as the gate question. Not locked in: user wants research into whether other approaches exist before finalizing.
**Rationale:** Preference, explicitly gated on research. Would change if research turns up a way to attach a custom label/description to a free-text-capable option (avoiding the discoverability tradeoff), or if testing shows "Other" isn't found naturally by users.

## D3: Accept (Continue) and pause (Stop) branches
**Question:** Do the "Continue" and "Stop here" branches need any behavior changes as part of this redesign?
**Firmness:** Preference
**Options considered:**
- Keep both as-is — Continue proceeds immediately in the same turn into the next phase; Stop acknowledges and ends the turn.
- Change something about Continue.
- Change something about Stop.
**Chosen:** Keep both as-is. Only the revision branch is in scope for this redesign.
**Rationale:** Preference — no stated driver to change accept or pause behavior; would revisit only if the D2 redesign turns out to require touching the option list shape shared by all three branches.

## Research Focus Areas
- Read each QRSPI command file (`question.md`, `research.md`, `structure.md`, `plan.md`, `implement.md`) to confirm whether the Continue/Revise/Stop gate (added in d67faa8) is actually implemented consistently across all phase transitions, or varies — this determines how much D1's "all gates" scope actually requires touching.
- Investigate whether AskUserQuestion, or any other available tool, supports a labeled option that itself accepts inline free text (rather than only the generic "Other" fallback) — this could resolve D2's discoverability tradeoff without adding a turn.
- Determine how revision text captured via "Other" should be handled if the user selects it but leaves it blank or trivial, and whether that handling needs to be identical across all in-scope gates.
