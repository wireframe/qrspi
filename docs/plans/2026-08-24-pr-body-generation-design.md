# Design: PR Body Generation from QRSPI Artifacts

Date: 2026-08-24

## Problem

QRSPI's five phases each write a markdown artifact (`decisions.md`, `research.md`,
`structure.md`, `plan.md`) and each artifact already links back to the ones before
it. None of that context currently reaches the pull request. `/implement` finishes
by committing the work, and the PR description is written from scratch by hand,
losing the paper trail the workflow already built.

## Goal

When `/implement` finishes a plan, generate a PR body that links to the existing
artifacts as the source of truth — summary and scope in the PR body itself,
everything else one click away — and offer to open the PR with `gh`.

## Non-goals

- No new command and no `bin/` script. This is a final step appended to
  `/implement`'s existing instructions, consistent with how every other QRSPI
  phase is a prompt file, not a script.
- No duplication of `plan.md`'s checklist or `decisions.md`'s rationale into the
  PR body. Artifacts stay the single source of truth; the PR body links to them.

## Design

### 1. Trigger point

Appended to `/implement` (Phase 5), after the last plan phase's quality gate and
commit — not a new command. The step needs to read artifact content and reason
about headings/anchors, so it stays a prompt instruction like the rest of QRSPI,
not a template-substitution script.

### 2. Link construction

Relative markdown links in GitHub PR/issue bodies resolve against the repository's
**default branch**, not the PR's head branch — a link to a file that only exists
on the feature branch 404s until merge. ([github/markup#576](https://github.com/github/markup/issues/576),
[github/markup#84](https://github.com/github/markup/issues/84))

To avoid that, every artifact link is a full `blob` URL with the branch baked in:

1. Resolve `owner/repo` via `gh repo view --json owner,name`.
2. Resolve the current branch via `git rev-parse --abbrev-ref HEAD`.
3. Build links as `https://github.com/{owner}/{repo}/blob/{branch}/{path}#{anchor}`.
4. Anchors are derived from the actual heading text already read from the file
   (GitHub's slug rules: lowercase, strip punctuation except hyphens, spaces→hyphens)
   — never guessed independent of the real heading.

### 3. PR body structure

```markdown
## Summary
<2-4 sentence prose: what changed and why, in plain language>

## Scope
- [Phase 1: <name>](structure.md blob URL#phase-1-name) — <one-line what it did>
- [Phase 2: <name>](structure.md blob URL#phase-2-name) — <one-line what it did>

<Firm-decision footnotes attach here or in Summary, wherever the prose reflects that decision>[^1]

---

**Artifacts:** [Decisions](decisions.md blob URL) · [Structure](structure.md blob URL) · [Research](research.md blob URL) · [Plan](plan.md blob URL)

[^1]: [D1: <Decision Title>](decisions.md blob URL#d1-decision-title)
```

Rationale for each choice, in the order they were settled:

- **Summary leads** — the single highest-priority thing a reviewer reads first.
- **Scope replaces a task checklist** and is built from `structure.md`'s phase
  headings, not `plan.md`'s tasks. A checklist of already-`[x]`'d tasks (everything
  is done by the time the PR is drafted) doesn't ask the reviewer for anything a
  phase-level Scope doesn't already say — and `structure.md`'s phases are what
  decisions actually shape, so that's where footnotes naturally land.
- **Footnotes cover Firm decisions only**, each linking straight to its anchor in
  `decisions.md`. Preference/Open decisions are noise for a reviewer skimming a PR.
- **Artifacts link is an appendix**, not a section, placed at the bottom, ordered
  by reviewer relevance: decisions → structure → research → plan.

### 4. gh integration

After drafting, ask the user to confirm, then run `gh pr create --body-file` if
approved — matches this project's default posture of confirming before actions
that touch shared/remote state, rather than auto-creating the PR unattended.

## Follow-ups / open questions

- Whether footnote markers should attach only where the summary/scope prose
  directly reflects a Firm decision (agent judges contextually) vs. one footnote
  per Firm decision regardless of whether it's mentioned, listed flatly at the end.
  Left as an implementation-time judgment call, not a hard rule, since forcing
  every Firm decision into a footnote risks manufacturing a mention just to attach one.
- No fallback behavior specified yet for `gh` being unauthenticated or the repo
  having no remote — implementation should decide whether that's a hard stop or a
  silent "print body only" degrade.
