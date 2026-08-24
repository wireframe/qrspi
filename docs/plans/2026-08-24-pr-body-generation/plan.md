# Plan: PR Body Generation
Date: 2026-08-24
Decisions: [decisions.md](decisions.md)
Research: [research.md](research.md)
Structure: [structure.md](structure.md)

> **For Claude:** Execute this plan task-by-task, phase by phase — see `/implement`'s execution options.

**Goal:** Append a step to `/implement` that drafts a PR body from a plan's QRSPI artifacts (linking, not duplicating them) and offers to open it with `gh pr create`.
**Architecture:** A single markdown edit to `commands/implement.md`, appended immediately after its existing Quality Gate section. No new command, no `bin/` script — this stays a prompt instruction like every other QRSPI phase.
**Tech Stack:** Markdown (Claude Code slash command file), `gh` CLI, `git`.

---

## Phase 1: Append PR body generation step to /implement

- [ ] Task 1.1: Append the "Prepare Pull Request" section to `commands/implement.md`
  - File: `commands/implement.md:64` (append after the Quality Gate section's final line)
  - Change: Add a new `## Prepare Pull Request` section instructing `/implement` to, after the last plan phase's quality gate and commit: (1) resolve link targets via `gh repo view --json owner,name` and `git rev-parse --abbrev-ref HEAD` to build full `https://github.com/{owner}/{repo}/blob/{branch}/{path}` URLs per the link-resolution finding in [research.md](research.md#github-relative-link-resolution-in-prissue-bodies), deriving heading anchors from actual heading text; (2) draft the body with `## Summary` prose, a `## Scope` list built from `structure.md`'s phase headings (not `plan.md`'s tasks, per D3), an `**Artifacts:**` appendix linking Decisions → Structure → Research → Plan, and footnotes only for `Firm` decisions per D4; (3) print the drafted body and ask for explicit confirmation before running `gh pr create --body-file`, per D2.
  - Test: `tail -40 commands/implement.md` — confirm the new section appears, is properly fenced, and renders as one clean code block with no collision between its inner and outer code fences.

- [ ] Task 1.2: Verify the drafted-body template matches the design doc
  - File: `docs/plans/2026-08-24-pr-body-generation-design.md` (read-only check against the new section written in Task 1.1)
  - Change: none — this is a verification task, not an edit.
  - Test: Manually compare the new section's body template against `docs/plans/2026-08-24-pr-body-generation-design.md`'s "PR body structure" template; confirm Summary/Scope/Artifacts/footnote structure matches.

- [ ] Commit Phase 1
