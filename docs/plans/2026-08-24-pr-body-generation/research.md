# Research: PR Body Generation
Date: 2026-08-24
Decisions: [decisions.md](decisions.md)

## GitHub relative link resolution in PR/issue bodies
**Findings:**
- Relative markdown links inside a PR or issue body resolve against the repository's **default branch**, not the pull request's head branch. A link to a file that exists only on the feature branch renders as a 404 until that branch is merged into the default branch.
- Reference: https://github.com/github/markup/issues/576
- Reference: https://github.com/github/markup/issues/84
- Consequence: artifact links in the PR body must be full `https://github.com/{owner}/{repo}/blob/{branch}/{path}` URLs with the head branch baked in — not bare relative paths — so they resolve correctly while the PR is still open.

## Insertion point: /implement's Quality Gate section
**Findings:**
- `commands/implement.md`'s Quality Gate section is the last section in the file: header `## Quality Gate (per phase)` at `commands/implement.md:51`, running through `commands/implement.md:64`.
- The gate is described as running "at every phase boundary" (`commands/implement.md:23`) and "at the phase seam, not per task" (`commands/implement.md:63`); its final step is "Commit the phase" (`commands/implement.md:60`).
- The gate runs once per plan phase, not once per plan. A PR-body-generation step must fire only after the *last* plan phase's gate and commit — appending after `commands/implement.md:64` places it correctly as a one-time, end-of-plan step rather than a per-phase one.

## Artifact formats: heading and cross-link conventions
**Findings:**
- `commands/question.md:38-63` — `decisions.md` format: top heading `# Decisions: <topic>`; each decision is `## D<n>: <Decision Title>` with fields `**Question:**`, `**Firmness:**`, `**Options considered:**`, `**Chosen:**`, `**Rationale:**`; a trailing `## Research Focus Areas` bullet list. `decisions.md` is the first artifact in the chain and does not cross-link to any other artifact.
- `commands/research.md:31-55` — `research.md` format: top heading `# Research: <topic>`; a `Decisions: [decisions.md](decisions.md)` cross-link (`commands/research.md:34`); one `## <Focus Area title>` section per decisions.md focus area with `**Findings:**` bullets; then `## Patterns Observed`, `## Constraints Discovered`, and an optional `## Open Decisions (must be resolved before /structure)` section (`commands/research.md:52-54`), included only if a decision was left `Open`.
- `commands/structure.md:33-55` — `structure.md` format: top heading `# Structure: <topic>`; cross-links `Decisions: [decisions.md](decisions.md)` and `Research: [research.md](research.md)` (`commands/structure.md:36-37`); one `## Phase N: <name>` section per phase with `**Goal:**`, `**Files touched:**`, `**Depends on:**`, `**Verification:**`; a trailing `## Out of Scope` section.
- `commands/plan.md:36-67` — `plan.md` format: top heading `# Plan: <topic>`; cross-links to Decisions, Research, and Structure (`commands/plan.md:39-41`); a "For Claude" execution note; summary fields `**Goal:**`, `**Architecture:**`, `**Tech Stack:**`; one `## Phase N: <name>` section per phase containing `- [ ] Task N.M: <description>` items, each with `File:`, `Change:`, `Test:` sub-bullets, closed by a plain `- [ ] Commit Phase N` line.
- Every cross-link across all four artifacts uses the bare relative filename form — `[decisions.md](decisions.md)`, `[research.md](research.md)`, `[structure.md](structure.md)` — never a path with directories, since the link always targets a sibling file in the same artifact folder.

## Patterns Observed
- All five QRSPI phase files (`commands/question.md`, `commands/research.md`, `commands/structure.md`, `commands/plan.md`, `commands/implement.md`) are single self-contained prompt files (YAML frontmatter + instructions), not scripts — consistent with D1's choice to append to `/implement` rather than add a `bin/` script.
- Each phase after the first opens with a "Hard Gate" that Globs for the prior artifact and stops if it's missing (`commands/research.md:8-13`, `commands/structure.md:8-13`, `commands/plan.md:8-13`), and each phase's Output section ends by printing the full artifact inline and naming the next command to run.

## Constraints Discovered
- GitHub's anchor-slug rule (lowercase; strip punctuation except hyphens; spaces to hyphens) must be applied to the *actual* heading text read from the target file, not guessed independently — otherwise the anchor won't match the heading GitHub renders it to.
- None of D1-D4 were left `Open` (all four are `Firm` in `decisions.md`), so no "Open Decisions" section is needed here.
