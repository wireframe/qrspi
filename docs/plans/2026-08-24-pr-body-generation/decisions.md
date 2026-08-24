# Decisions: PR Body Generation
Date: 2026-08-24

## D1: Integration point
**Question:** Where should PR body generation live — a new command, a `bin/` script, or appended to an existing command?
**Firmness:** Firm
**Options considered:**
- A new `/qrspi:pr` command — discoverable, but adds a phase outside the five-phase Q-R-S-P-I sequence.
- A `bin/` script — scriptable, but loses the ability to reason over artifact headings/content and requires template substitution instead of prose judgment.
- Appended to the end of `/implement` — reuses `/implement`'s existing context (finished plan, working tree, artifact folder) and stays consistent with every other QRSPI phase being a prompt file, not a script.
**Chosen:** Appended to the end of `/implement`, not a new command or `bin/` script.
**Rationale:** `/implement` already has the plan and artifact context loaded when the work finishes, and drafting the body requires reasoning about heading text and anchors, which a template script can't do well. Keeping every QRSPI phase as a prompt instruction (not a script) matches the project's existing architecture.

## D2: Automation level
**Question:** Should the PR be opened automatically once the body is drafted, or does it need explicit confirmation first?
**Firmness:** Firm
**Options considered:**
- Draft the body and run `gh pr create` unattended.
- Draft the body, print it, and only run `gh pr create --body-file` after the user explicitly confirms.
**Chosen:** Draft, then offer to run `gh pr create --body-file` after explicit confirmation — never unattended.
**Rationale:** Opening a PR is a visible, remote-state-changing action. This matches the project's default posture of confirming before actions that touch shared or remote state rather than auto-creating a PR unattended.

## D3: Checklist granularity
**Question:** Should the PR body re-render the plan's task checklist, or link to the artifacts that already hold it?
**Firmness:** Firm
**Options considered:**
- Duplicate `plan.md`'s task checklist inline in the PR body.
- Duplicate `structure.md`'s phase list inline in the PR body.
- Link to `plan.md`/`structure.md` as source of truth, without re-rendering either.
**Chosen:** No duplicated checklist; link to `plan.md`/`structure.md` as source of truth instead of re-rendering tasks.
**Rationale:** By the time a PR is drafted, every task is already checked off, so re-rendering the checklist tells a reviewer nothing new and risks drifting out of sync with the artifact over time. Linking keeps the artifacts as the single source of truth.

## D4: Decision footnotes
**Question:** How should the PR body reference the decisions that shaped the work — inline text, or footnotes/links?
**Firmness:** Firm
**Options considered:**
- Copy each decision's rationale text directly into the PR body.
- Footnote every decision (Firm, Preference, and Open), linking to `decisions.md`.
- Footnote only `Firm` decisions, linking into `decisions.md` rather than copying its text.
**Chosen:** Link into `decisions.md` rather than copying decision text; footnote only `Firm` decisions.
**Rationale:** Copying text duplicates `decisions.md` and can drift from it. Footnoting every decision would surface `Preference`/`Open` noise to a reviewer who only needs to know what's non-negotiable. Restricting footnotes to `Firm` decisions keeps the PR body focused while still giving a reviewer a path to the reasoning.

## Research Focus Areas
- How do GitHub relative links resolve in PR/issue bodies when the target file only exists on the head branch?
