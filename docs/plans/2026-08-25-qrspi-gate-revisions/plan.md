# Plan: QRSPI phase-transition gate — inline revisions
Date: 2026-08-25
Decisions: [decisions.md](decisions.md)
Research: [research.md](research.md)
Structure: [structure.md](structure.md)

> **For Claude:** Execute this plan task-by-task, phase by phase — see `/qrspi:implement`'s execution options.

**Goal:** Collapse each QRSPI Continue Gate's "I have revisions" branch into a single AskUserQuestion turn, by relying on the tool's built-in "Other" free-text field instead of a separate labeled option plus a follow-up question.
**Architecture:** Markdown-only edits to the Continue Gate section of `commands/question.md`, `commands/research.md`, `commands/structure.md`, `commands/plan.md`, and the equivalent PR-open gate in `commands/implement.md`. No new command, no `bin/` script, no version bump beyond what's noted in Phase 4's commit.
**Tech Stack:** Markdown (Claude Code slash command files).

---

## Phase 1: Confirm the editable source (already resolved during planning)

- [x] Task 1.1: Locate and sync the real plugin source
  - File: none (investigation)
  - Change: Confirmed this repository (`wireframe/qrspi`, current branch `refine-flow`) — not `~/.claude/plugins/cache/qrspi/qrspi/0.3.1/` — is the editable source. Discovered `refine-flow` and local `main` were 2 commits behind `origin/main`, missing an already-merged PR (#3, `auto-transition`, commit `b3015b5`) that changed the same Continue Gate text this plan edits. Fast-forwarded both local `main` and `refine-flow` to `origin/main` (`e46ce3d`) to reconcile — a plain fast-forward, no conflicts, since neither local branch had diverging commits.
  - Test: `diff -rq commands/ /Users/ryansonnek/.claude/plugins/cache/qrspi/qrspi/0.3.1/commands/` — confirmed empty (already run; worktree now matches the installed 0.3.1 cache exactly).

(No commit needed — the fast-forward introduced no new local changes; `git status` shows only the untracked `docs/plans/2026-08-25-qrspi-gate-revisions/` artifacts.)

## Phase 2: Collapse the revision branch to one turn

> **Note (post-implementation):** Tasks 2.1-2.5 were applied together with Phase 4's blank-input handling in a single edit per file, since both touch the same paragraph — the "Change:" blocks below show the intermediate (pre-Phase-4) text for traceability, but the actual shipped wording is the amended form from Phase 4. The quality gate's `/simplify` pass then tightened all 5 files further (dropped the redundant "do not add a third ... option" clause, shortened the Other-paragraph, normalized "treat the typed text" wording), and `/code-review --fix` added plain-text-fallback coverage to the Other-paragraph. See the actual files for final wording; the Test commands below are updated to match what shipped.

- [x] Task 2.1: Update `question.md`'s Continue Gate
  - File: `commands/question.md:70-74`
  - Change: Replace the 3-bullet option list with 2 labeled options (drop `"I have revisions"`) plus a new paragraph describing the "Other" free-text path:
    ```
    Ask with the `AskUserQuestion` tool (fall back to a plain-text yes/no/revise prompt if that tool isn't available in this session), presenting exactly these 2 labeled options — do not add a third "I have revisions" option:

    - **"Continue to `/qrspi:research`"** (recommended, default) — no changes needed. Immediately continue in this same turn: read `${CLAUDE_PLUGIN_ROOT}/commands/research.md` and follow its instructions, using `docs/plans/YYYY-MM-DD-<topic>` as its `$ARGUMENTS`. Do not end the turn, and do not wait for the user to type the command themselves.
    - **"Stop here for now"** — acknowledge and end the turn.

    If the user selects **Other** and types text instead of picking a labeled option, treat that text as the revision to make: apply it as an edit to `decisions.md` in place (do not ask before saving), re-print the updated contents, then run this gate again.
    ```
  - Test: `grep -c '"I have revisions"' commands/question.md` returns `0`; `grep -c 'selects \*\*Other\*\*' commands/question.md` returns `1`. (Confirmed against shipped file.)

- [x] Task 2.2: Update `research.md`'s Continue Gate
  - File: `commands/research.md:65-69`
  - Change: Same restructuring as Task 2.1, preserving `research.md`'s existing Open-Decisions caveat clause on the Continue option (out of scope per structure.md) and its "re-print the updated outline" phrasing (this file prints an outline, not full contents):
    ```
    Ask with the `AskUserQuestion` tool (fall back to a plain-text yes/no/revise prompt if that tool isn't available in this session), presenting exactly these 2 labeled options — do not add a third "I have revisions" option:

    - **"Continue to `/qrspi:structure`"** (recommended, default) — no changes needed. If unresolved Open Decisions remain, note them as a caveat in this option's text. Immediately continue in this same turn: read `${CLAUDE_PLUGIN_ROOT}/commands/structure.md` and follow its instructions, passing through this phase's own `$ARGUMENTS` (the plans folder path) as its argument. Do not end the turn, and do not wait for the user to type the command themselves.
    - **"Stop here for now"** — acknowledge and end the turn.

    If the user selects **Other** and types text instead of picking a labeled option, treat that text as the revision to make: apply it as an edit to `research.md` in place (do not ask before saving), re-print the updated outline, then run this gate again.
    ```
  - Test: `grep -c '"I have revisions"' commands/research.md` returns `0`; `grep -c 'selects \*\*Other\*\*' commands/research.md` returns `1`. (Confirmed against shipped file.)

- [x] Task 2.3: Update `structure.md`'s Continue Gate
  - File: `commands/structure.md:63-67`
  - Change: Same restructuring, "re-print the updated contents" phrasing (this file prints in full):
    ```
    Ask with the `AskUserQuestion` tool (fall back to a plain-text yes/no/revise prompt if that tool isn't available in this session), presenting exactly these 2 labeled options — do not add a third "I have revisions" option:

    - **"Continue to `/qrspi:plan`"** (recommended, default) — no changes needed. Immediately continue in this same turn: read `${CLAUDE_PLUGIN_ROOT}/commands/plan.md` and follow its instructions, passing through this phase's own `$ARGUMENTS` (the plans folder path) as its argument. Do not end the turn, and do not wait for the user to type the command themselves.
    - **"Stop here for now"** — acknowledge and end the turn.

    If the user selects **Other** and types text instead of picking a labeled option, treat that text as the revision to make: apply it as an edit to `structure.md` in place (do not ask before saving), re-print the updated contents, then run this gate again.
    ```
  - Test: `grep -c '"I have revisions"' commands/structure.md` returns `0`; `grep -c 'selects \*\*Other\*\*' commands/structure.md` returns `1`. (Confirmed against shipped file.)

- [x] Task 2.4: Update `plan.md`'s Continue Gate
  - File: `commands/plan.md:75-79`
  - Change: Same restructuring, "re-print the updated outline" phrasing (this file prints an outline):
    ```
    Ask with the `AskUserQuestion` tool (fall back to a plain-text yes/no/revise prompt if that tool isn't available in this session), presenting exactly these 2 labeled options — do not add a third "I have revisions" option:

    - **"Continue to `/qrspi:implement`"** (recommended, default) — no changes needed. Immediately continue in this same turn: read `${CLAUDE_PLUGIN_ROOT}/commands/implement.md` and follow its instructions, passing through this phase's own `$ARGUMENTS` (the plans folder path) as its argument. Do not end the turn, and do not wait for the user to type the command themselves.
    - **"Stop here for now"** — acknowledge and end the turn.

    If the user selects **Other** and types text instead of picking a labeled option, treat that text as the revision to make: apply it as an edit to `plan.md` in place (do not ask before saving), re-print the updated outline, then run this gate again.
    ```
  - Test: `grep -c '"I have revisions"' commands/plan.md` returns `0`; `grep -c 'selects \*\*Other\*\*' commands/plan.md` returns `1`. (Confirmed against shipped file.)

- [x] Task 2.5: Update `implement.md`'s PR-open gate
  - File: `commands/implement.md:103-109`
  - Change: Drop the `"I want to edit the body first"` labeled option, keep the fallback phrase as `yes/no` for now (Phase 3 fixes it), and add the "Other" paragraph:
    ```
    4. **Offer to open the PR.** Print the drafted body to the output, then ask with the `AskUserQuestion` tool (fall back to a plain-text yes/no prompt if that tool isn't available in this session), presenting exactly these 2 labeled options — do not add a third "I want to edit the body first" option:

       - **"Open the PR now"** (recommended, default) — run `gh pr create --body-file <temp path>`.
       - **"Don't open a PR"** — acknowledge and end the turn.

       If the user selects **Other** and types text instead of picking a labeled option, treat that text as the revision to make: apply it to the temp file, re-print the body, then run this gate again.

       Only run `gh pr create` after explicit confirmation via this gate — never open the PR unattended.
    ```
  - Test: `grep -c '"I want to edit the body first"' commands/implement.md` returns `0`; `grep -c 'selects \*\*Other\*\*' commands/implement.md` returns `1`. (Confirmed against shipped file.)

- [x] Task 2.6: Verify all 5 gates dropped their explicit revision option consistently
  - File: `commands/question.md`, `commands/research.md`, `commands/structure.md`, `commands/plan.md`, `commands/implement.md` (read-only check)
  - Change: none — verification only.
  - Test: `grep -rn 'I have revisions\|I want to edit the body first' commands/` returns no matches. (Confirmed.)

- [x] Commit Phase 2 (combined with Phases 3-4 into a single commit; see note at end of Phase 4)

## Phase 3: Bring implement.md's fallback phrasing in line

- [x] Task 3.1: Fix the AskUserQuestion-unavailable fallback phrase in `implement.md`'s PR gate
  - File: `commands/implement.md:103` (within Task 2.5's edited block)
  - Change: Changed `"fall back to a plain-text yes/no prompt if that tool isn't available in this session"` to `"fall back to a plain-text yes/no/revise prompt if that tool isn't available in this session"`, matching the phrasing already used in `question.md`, `research.md`, `structure.md`, `plan.md`.
  - Test: `grep -c 'yes/no/revise' commands/implement.md` returns `1`; `grep -c 'yes/no prompt' commands/implement.md` returns `0`. (Confirmed against shipped file.)

- [x] Commit Phase 3 (combined; see note below)

## Phase 4: Handle a blank "Other" answer

- [x] Task 4.1: Add blank-input handling to `question.md`
  - File: `commands/question.md`
  - Change: Applied together with Task 2.1 (same paragraph), then tightened by `/simplify`. Shipped wording: `...unless it's blank or whitespace-only, in which case re-run this gate unchanged...`, and extended by `/code-review --fix` to also cover the plain-text fallback path (see note below).
  - Test: `grep -c 'blank or whitespace-only' commands/question.md` returns `1`. (Corrected from the original plan's `'blank or only whitespace'` string, which doesn't match the shipped wording — flagged by `/code-review`.)

- [x] Task 4.2: Add blank-input handling to `research.md`
  - File: `commands/research.md`
  - Change: Same as Task 4.1, applied to `research.md`.
  - Test: `grep -c 'blank or whitespace-only' commands/research.md` returns `1`.

- [x] Task 4.3: Add blank-input handling to `structure.md`
  - File: `commands/structure.md`
  - Change: Same as Task 4.1, applied to `structure.md`.
  - Test: `grep -c 'blank or whitespace-only' commands/structure.md` returns `1`.

- [x] Task 4.4: Add blank-input handling to `plan.md`
  - File: `commands/plan.md`
  - Change: Same as Task 4.1, applied to `plan.md`.
  - Test: `grep -c 'blank or whitespace-only' commands/plan.md` returns `1`.

- [x] Task 4.5: Add blank-input handling to `implement.md`'s PR gate
  - File: `commands/implement.md`
  - Change: Same as Task 4.1, applied to `implement.md`'s PR-open gate.
  - Test: `grep -c 'blank or whitespace-only' commands/implement.md` returns `1`.

- [x] Task 4.6: Verify blank-handling wording is consistent across all 5 files
  - File: `commands/question.md`, `commands/research.md`, `commands/structure.md`, `commands/plan.md`, `commands/implement.md` (read-only check)
  - Change: none — verification only.
  - Test: `grep -c 'blank or whitespace-only' commands/*.md` — each of the 5 files returns `1`. (Confirmed.)

- [x] Task 4.7: Bump plugin version
  - File: `.claude-plugin/plugin.json:3`
  - Change: Bumped `"version"` from `"0.3.1"` to `"0.3.2"`, following the convention set by commit `d67faa8` (bumped to 0.3.0) and PR #3 (bumped to 0.3.1).
  - Test: `jq .version .claude-plugin/plugin.json` returns `"0.3.2"`. (Confirmed.)

- [x] Commit Phase 4

> **Quality gate notes:** `/simplify` (4 parallel reviewers: reuse, simplification, efficiency, altitude) found the "Other"/blank-input paragraph duplicated near-verbatim across all 5 files with minor wording drift. Applied the cheap fixes — dropped the redundant "do not add a third ... option" clause, shortened the paragraph, normalized "treat the typed text" wording, added one canonical note to `README.md` about the underlying `AskUserQuestion` "Other" assumption. Skipped the suggestion to extract the shared paragraph into a separate referenced file: these command files must stay self-contained (each is read independently at runtime), and extraction would add a new file-read per phase transition rather than removing one. `/code-review --fix` then found the plain-text fallback path (used when `AskUserQuestion` is unavailable) had no defined revision-handling behavior — the "selects **Other**" instruction is meaningless there — fixed by extending that clause to also cover "or, in the plain-text fallback, answers with anything besides a clear continue/stop" across all 5 files. It also flagged this plan's own Task 4.x test strings as out of sync with the shipped wording; corrected above.
>
> Phases 2-4 ended up as one combined edit per file (since Phase 2's option-list change and Phase 4's blank-handling clause share the same paragraph) plus the quality-gate fixes, committed together as a single commit rather than three.
