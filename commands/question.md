---
description: "QRSPI Phase 1: Surface design decisions through structured questioning before any research or implementation"
argument-hint: "<topic description>"
---

# /question — QRSPI Phase 1: Decisions

You are starting the QRSPI workflow for: $ARGUMENTS

## Your Role

Surface design decisions by interviewing the user in **rounds**. Model the decisions as a **design tree**: a decision can depend on other decisions being settled first. Each round asks the **frontier**: every unsettled decision whose prerequisites are already settled. Write every option per **Writing Options** below.

## Rules

- Do NOT read the codebase. This phase is purely about intent and decisions.
- Do NOT decide implementation details. DO describe each option's consequences concretely — illustrating what a choice leads to is not proposing an implementation.
- Ask about: scope, approach, constraints, compatibility, tradeoffs, success criteria.
- **Never ask the user a codebase fact.** If a question is about what the existing system already is or does (framework, datastore, existing middleware), don't ask it — add it to "Research Focus Areas" instead. If a decision hinges on that fact, record the decision as **Open**. Facts only the user knows (business constraints, consumers, deadlines) are fair to ask.
- **Capture firmness, not just the choice** (see below). Never record a casual aside, a "sure, I guess", a batch "all of them", or your own default as a firm decision.
- When the interview stops (see Rounds), write the artifact immediately — do NOT ask for permission to write.

## Rounds

- Ask each round with one `AskUserQuestion` call of at most 4 questions. Give each question 2-4 mutually exclusive options for that one decision, with their tradeoffs in the option descriptions (see Writing Options) — no "several of these" option and no "also tell me…" add-ons. Put your recommended option first and end its label with "(Recommended)".
- Each question asks exactly one thing and carries one unconditional recommendation. If your recommendation would hinge on something unknown, that unknown is either a codebase fact (don't ask it; record the decision Open, see Rules) or a prerequisite that belongs in an earlier round — not a hedge inside the recommendation. Anything the user must answer separately is its own question.
- Hold a question for a later round if its options or recommendation would change based on another unsettled answer; ask shaping questions (a primary goal, an urgency driver) first. Two questions in one round never offer the same choice or cross-reference each other ("this decides…", "could override Q3").
- If the frontier has more than 4 questions, ask the 4 most foundational now; the rest stay on the frontier for the next round.
- After each round, recompute the frontier. Answers unblock new questions, and a surprising answer can reopen an earlier branch. A decision recorded **Open** counts as settled: record each decision that depends on it as **Open** too, with `Depends on:` pointing at it, instead of asking it.
- If `AskUserQuestion` isn't available in this session, ask the round as numbered markdown in this format, with the recommendation only on the ➡️ line, then end the turn and wait for the user to answer by number:

  ```
  ❓ **Q1** - **<question title>**: <question body, with options and tradeoffs>

  ➡️ <your recommended answer>

  ---

  ❓ **Q2** - **<question title>**: ...

  ➡️ ...
  ```

- **Stop when the frontier is empty**: every branch of the design tree visited, nothing silently assumed.

## Writing Options

The user should be able to pick an option without asking what it means. A terse option ("Option A — simpler") forces them to guess at the implications, and a guessed answer is a weak decision.

- **State the stakes in the question.** Include one clause on what this decision shapes in later phases or the end result (e.g. "Research will cover every command file or just one, depending on this answer."). Stakes point downstream, never at another question in the round.
- **Every option description covers three things**, in 2–3 sentences:
  - **What it means** — the choice in concrete terms.
  - **What follows** — how it shapes later phases or the end result.
  - **What it costs** — what the user gives up *relative to the other options*. Say so if it's hard to undo later.
- **Add an example when the description leaves the edge cases ambiguous** — fuzzy matching rules, thresholds, formats, categories with blurry edges. Name one specific case the option includes *and* one it excludes (e.g. "matches 2.4.1, not 2.5.0"), and reuse the same cases across every option in the question so they compare side by side. Skip the example when the description already states the rule crisply (e.g. "non-archived repos only", "all repos at once"). An example that just names a placeholder instance of the rule ("an active repo is included, an archived one is not") restates the option and is noise.
- **Make options distinguishable.** If two descriptions would still read sensibly with their labels swapped, they don't differ enough — rewrite them so each differs on a named axis (scope, risk, effort, user experience, …).
- **Put the detail in the description**, not the label. Do not use the `preview` field.

Question: "Which plugin versions should the compatibility check accept for a plugin built against 2.4.0? Research will look at either version parsing or just string comparison, depending on this answer."

Terse (don't):
- **Exact match** — strictest
- **Same major** — more flexible

Informative (do):
- **Exact match** — Only the exact version the plugin was built against passes. E.g. rejects 2.4.1, 2.5.0, and 3.0.0. Research only needs to find where versions are compared as strings. Cost: every patch release forces users to rebuild their plugins.
- **Same minor** — Any patch release within the same minor version passes. E.g. accepts 2.4.1; rejects 2.5.0 and 3.0.0. Research has to find how versions are parsed. Cost: assumes patch releases never break plugins, and nothing enforces that.
- **Same major** — Any release within the same major version passes. E.g. accepts 2.4.1 and 2.5.0; rejects 3.0.0. Research has to find how versions are parsed. Cost: a minor release that changes the plugin API would break plugins without warning; tightening the check later rejects plugins that already passed.

No example needed — "Who gets the new CSV export button?" Each description already states the rule, so an example ("an admin sees it, a viewer doesn't") would only restate it:
- **Admins only** — Only users with the admin role see the button. Research only needs to find where admin-only UI is gated. Cost: everyone else has to ask an admin for exports.
- **Every signed-in user** — Anyone who can view the data can export it. Cost: exports leave the app with no review, so this is hard to walk back once people depend on it.

**Clarification replies are not answers.** If the user responds via "Other" with a question about the options ("what's the difference?", "what would B look like?"), record nothing. Answer it by re-asking the same question with expanded descriptions that address what they asked.

## Firmness

Every decision carries a firmness level. This is the point of the phase: downstream phases weight decisions by it, so a loosely-held choice recorded as firm gets over-built later, and a must-have recorded as loose gets dropped.

- **Firm** — a hard requirement / must-have. The user stated it as non-negotiable. Downstream treats it as a fixed constraint.
- **Preference** — a nice-to-have, a sensible default, or a low-conviction lean. The user is open to changing it. Downstream uses it as the default but may propose alternatives and must not over-invest in honoring it.
- **Open** — explicitly unresolved ("let research decide", "not sure yet"). No choice is made here; a later phase owns resolving it.

Assigning firmness:
- **Default to Preference, not Firm.** Only mark **Firm** when the user stated a real requirement ("non-negotiable", "must", "won't change that").
- **Picking an option is Preference.** On a decision question, a clicked option (recommended or not) or a bare "yes" or number reply to a markdown round records as **Preference**, because it carries no signal of conviction. Infer firmness from typed text, including "Other" answers, with the rules here. The answer to a firmness follow-up (below) sets firmness directly.
- A drive-by suggestion ("while you're at it, also add X"), a batch answer ("all of them"), a shrug ("sure, whatever's normal"), or an answer that is itself a question ("do we even need that?") is **Preference** or **Open** — never Firm. Do NOT manufacture a rationale for it, and do NOT escalate it into a broader mandate.
- If firmness is genuinely unclear and it matters downstream, ask ONE quick follow-up: "Is X a hard requirement, or a lean you're open to changing?"
- Anything you decided yourself because the user didn't weigh in is **Preference** at most — record it as your default, not their requirement.
- **Delegation settles the rest.** If the user hands the remaining decisions to you ("go with your recommendations", "wrap it up"), settle each remaining decision with your recommendation as **Preference**, or **Open** if it genuinely needs research, until the frontier is empty. Don't ask firmness follow-ups for delegated decisions.
- Every **Open** decision MUST also appear under "Research Focus Areas" — research owns resolving it.

## Output

When the interview stops (see Rounds), create the artifact folder and write the decisions file automatically (no confirmation step):

1. Create directory: `docs/plans/YYYY-MM-DD-<topic>/` (use today's date, derive a short kebab-case topic slug from the task description)
2. Write `docs/plans/YYYY-MM-DD-<topic>/decisions.md` with this format:

```
# Decisions: <topic>
Date: YYYY-MM-DD

## D1: <Decision Title>
**Question:** <what was asked>
**Depends on:** D<n>[, D<m>] | none
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
