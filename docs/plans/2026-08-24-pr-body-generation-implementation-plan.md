# PR Body Generation Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Append a final step to `/implement` that drafts a PR body from this plan's QRSPI artifacts (linking, not duplicating) and offers to open it with `gh pr create`.

**Architecture:** Single markdown edit to `commands/implement.md`, appended after its existing "Quality Gate" section. No new command, no script — this is a prompt instruction like every other QRSPI phase. Verification is manual: retrofit a real QRSPI artifact folder for this feature, then walk the new instructions against it and confirm the generated body matches the design doc's template and its links resolve.

**Tech Stack:** Markdown (Claude Code slash command file), `gh` CLI, `git`.

---

## Task 1: Retrofit a QRSPI artifact folder for this feature

We built this feature's design via `superpowers:brainstorming` + `superpowers:writing-plans`, not QRSPI's own `/question` → `/research` → `/structure` → `/plan` pipeline — so there's no `decisions.md`/`research.md`/`structure.md`/`plan.md` folder for the new step to dogfood against. Create one now, translating decisions already made (nothing new to decide).

**Files:**
- Create: `docs/plans/2026-08-24-pr-body-generation/decisions.md`
- Create: `docs/plans/2026-08-24-pr-body-generation/research.md`
- Create: `docs/plans/2026-08-24-pr-body-generation/structure.md`
- Create: `docs/plans/2026-08-24-pr-body-generation/plan.md`

**Step 1: Write `decisions.md`**

Format per `commands/question.md`'s output spec. Capture these four decisions from the brainstorming conversation, each `Firmness: Firm` (the user gave a direct, non-hedged answer to each):

- **D1 — Integration point:** end of `/implement`, not a new command or `bin/` script.
- **D2 — Automation level:** draft the body, then offer to run `gh pr create --body-file` after explicit confirmation — never unattended.
- **D3 — Checklist granularity:** no duplicated checklist; link to `plan.md`/`structure.md` as source of truth instead of re-rendering tasks.
- **D4 — Decision footnotes:** link into `decisions.md` rather than copying decision text; footnote only `Firm` decisions.

Include a "Research Focus Areas" section listing: "How do GitHub relative links resolve in PR/issue bodies when the target file only exists on the head branch?"

**Step 2: Write `research.md`**

Format per `commands/research.md`'s output spec. Record as findings:
- `commands/implement.md:51-64` — existing Quality Gate section or a plan, this is the insertion point for the new step.
- `commands/plan.md:34-67`, `commands/structure.md:31-55`, `commands/question.md:40-66` — the artifact formats the new step reads from (heading conventions, cross-links).
- The GitHub relative-link finding: relative links in PR/issue bodies resolve against the repository's default branch, not the head branch, so a link to a file that only exists on the feature branch 404s until merge. Cite `https://github.com/github/markup/issues/576` and `https://github.com/github/markup/issues/84`.
- No "Open Decisions" section needed — nothing was left `Open`.

**Step 3: Write `structure.md`**

Format per `commands/structure.md`'s output spec. Single phase:

```
## Phase 1: Append PR body generation step to /implement
**Goal:** commands/implement.md drafts a PR body from the plan's artifacts and offers to open it via gh, after the last plan phase's quality gate.
**Files touched:** commands/implement.md
**Depends on:** nothing
**Verification:** Manually walk the new instructions against docs/plans/2026-08-24-pr-body-generation/ and confirm the drafted body matches the template in docs/plans/2026-08-24-pr-body-generation-design.md and every link resolves.
```

Include an "Out of Scope" section: "A `bin/` script or standalone `/qrspi:pr` command — deferred per D1."

**Step 4: Write `plan.md`**

Format per `commands/plan.md`'s output spec, single phase, referencing Task 2 below as its task list.

**Step 5: Commit**

```bash
git add docs/plans/2026-08-24-pr-body-generation/
git commit -m "Add QRSPI artifacts for the PR-body-generation feature itself"
```

---

## Task 2: Write the new "Prepare Pull Request" section

**Files:**
- Modify: `commands/implement.md` (append after the file's final line, which currently ends "...before silently moving on.")

**Step 1: Append this section to the end of `commands/implement.md`**

```markdown

## Prepare Pull Request

After the last plan phase is committed and its quality gate has passed, draft the pull request body from this plan's artifacts. Do this automatically — do not ask for permission to draft it.

### 1. Resolve link targets

- Resolve the repo slug: `gh repo view --json owner,name`
- Resolve the current branch: `git rev-parse --abbrev-ref HEAD`
- Build a blob URL prefix: `https://github.com/{owner}/{repo}/blob/{branch}/`
- For every link into `decisions.md`, `research.md`, `structure.md`, or `plan.md`, use `{prefix}{path relative to repo root}` — never a bare relative path. Relative links in PR bodies resolve against the repository's default branch, not the head branch, and will 404 pre-merge.
- For links into a specific heading, derive the anchor from that heading's actual text using GitHub's slug rule (lowercase; strip punctuation except hyphens; spaces → hyphens) — read the heading from the file, don't guess it.

### 2. Draft the body

Write a PR body with this structure:

\`\`\`markdown
## Summary
<2-4 sentence prose: what changed and why, in plain language>

## Scope
- [Phase 1: <name>](<structure.md blob URL>#phase-1-name) — <one-line what it did>
- [Phase 2: <name>](<structure.md blob URL>#phase-2-name) — <one-line what it did>

---

**Artifacts:** [Decisions](<decisions.md blob URL>) · [Structure](<structure.md blob URL>) · [Research](<research.md blob URL>) · [Plan](<plan.md blob URL>)

[^1]: [D<n>: <Decision Title>](<decisions.md blob URL>#d<n>-decision-title)
\`\`\`

- Attach a footnote (`[^n]`) only to a `Firm` decision from `decisions.md`, and only where the Summary or a Scope line actually reflects that decision — do not manufacture a mention just to attach a footnote, and do not footnote `Preference` or `Open` decisions.
- Do not duplicate `plan.md`'s checklist or copy decision rationale into the body — link to the artifact instead.

### 3. Offer to open the PR

Print the drafted body to the output, then ask the user: "Open this as a PR with `gh pr create --body-file`, or would you like changes first?" Only run `gh pr create` after explicit confirmation — never open the PR unattended.
```

**Step 2: Verify the file reads correctly**

Run: `tail -40 commands/implement.md`
Expected: the new "Prepare Pull Request" section, properly fenced, with no broken markdown nesting (the inner ` ```markdown ` fence must not collide with the outer fence — check it renders as one clean code block when previewed).

**Step 3: Commit**

```bash
git add commands/implement.md
git commit -m "Add PR body generation step to /implement"
```

---

## Task 3: Dogfood — walk the new step against this feature's own artifacts

This is the live test: manually execute the instructions just written, against the artifact folder from Task 1, for this real branch (`pr-body-generation`).

**Step 1: Resolve link targets per the new section's own instructions**

Run:
```bash
gh repo view --json owner,name
git rev-parse --abbrev-ref HEAD
```
Expected: an `owner/name` pair and `pr-body-generation`. Build the blob prefix from these.

**Step 2: Draft the PR body**

Follow "2. Draft the body" from the new section, using `docs/plans/2026-08-24-pr-body-generation/structure.md`'s single phase for Scope and `decisions.md`'s D1-D4 (all Firm) for candidate footnotes.

**Step 3: Check the draft against the design doc**

Compare the draft against the template in `docs/plans/2026-08-24-pr-body-generation-design.md` section 3. Confirm:
- Summary is prose, not a link list.
- Scope links point at `structure.md`'s phase heading anchor, not `plan.md`.
- Every artifact link is a full blob URL (paste one into a browser or `curl -I` it if `gh` auth allows, to confirm it 200s rather than 404s).
- The Artifacts line is ordered decisions → structure → research → plan.

**Step 4: Confirm with the user, then open the PR**

Present the drafted body, then ask before running `gh pr create --body-file`. This is the real end-to-end dogfood — it opens an actual PR against `wireframe/qrspi` on branch `pr-body-generation`.

---

## Execution Handoff

Plan complete and saved to `docs/plans/2026-08-24-pr-body-generation-implementation-plan.md`. Two execution options:

1. **Subagent-Driven (this session)** — I dispatch a fresh subagent per task, review between tasks, fast iteration.
2. **Parallel Session (separate)** — Open a new session with `superpowers:executing-plans`, batch execution with checkpoints.

Which approach?
