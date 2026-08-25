# Structure: QRSPI phase-transition gate — inline revisions
Date: 2026-08-25
Decisions: [decisions.md](decisions.md)
Research: [research.md](research.md)

## Phase 1: Locate the real plugin source
**Goal:** Determine where the QRSPI plugin's editable source actually lives, distinct from the read-only install at `~/.claude/plugins/cache/qrspi/qrspi/0.3.1/`, so later phases edit a location that (a) is git-tracked and reviewable, and (b) actually reaches users on the next plugin update/reinstall — rather than silently editing a cache copy that gets overwritten. Serves the constraint found in research.md, not any single decision — this is a prerequisite for every other phase touching command files.
**Files touched:** none (investigation only; confirms the target path for Phases 2-4)
**Depends on:** nothing
**Verification:** A git-tracked source directory for the plugin's `commands/*.md` files is identified and confirmed distinct from the cache path; a trivial test edit there is confirmed to be the version that gets installed to cache (via the plugin's own install/update mechanism, or documented as a manual sync step if none exists).

## Phase 2: Collapse the revision branch to one turn
**Goal:** Change the "I have revisions" branch in `question.md`, `research.md`, `structure.md`, `plan.md`, and `implement.md`'s PR-gate equivalent so the gate's AskUserQuestion call captures revision text inline via the tool's built-in "Other" field, instead of asking a separate free-text question in a following turn — per D2 (Preference, but the only mechanism research confirmed is possible; the explicit "I have revisions" label is dropped since AskUserQuestion can't attach a custom label to a free-text-capable option). Applied to all five files per D1's "all QRSPI gates" scope (Preference — narrow to a subset only if Phase 1 reveals reasons to stage the rollout).
**Files touched:** `question.md`, `research.md`, `structure.md`, `plan.md`, `implement.md`
**Depends on:** Phase 1
**Verification:** Manually trigger each gate; selecting "Other" and typing revision text applies the edit and re-prints the file in the same turn, with no intervening plain-chat question.

## Phase 3: Bring implement.md's terminal gate in line
**Goal:** Reconcile `implement.md`'s PR-open gate (which already has the same 3-option Continue/Revise/Stop shape but different labels and a "yes/no" instead of "yes/no/revise" fallback phrase) with the Phase 2 change, without altering its Continue/Stop semantics — Continue still runs `gh pr create`, Stop still just ends the turn, per D3 (Preference: keep Continue/Stop as-is). This phase exists specifically because research found `implement.md` structurally diverges from the other four gates; it's the concrete resolution of that divergence for D1's consistency goal.
**Files touched:** `implement.md`
**Depends on:** Phase 2
**Verification:** Read `implement.md`'s PR gate end to end; confirm the revision path now matches Phase 2's one-turn pattern, and the AskUserQuestion-unavailable fallback wording matches the other four files' "yes/no/revise" phrasing.

## Phase 4: Handle a blank "Other" answer
**Goal:** Add explicit, identical guidance across all five gates for what happens if the user picks "Other" but leaves it blank or trivial (e.g., re-ask rather than silently apply an empty edit) — per D3's research focus area, which found no existing behavior for this case anywhere. Serves a research-identified gap, not an explicit user requirement — confirm it's worth building before treating it as done.
**Files touched:** `question.md`, `research.md`, `structure.md`, `plan.md`, `implement.md`
**Depends on:** Phase 2
**Verification:** Simulate selecting "Other" with an empty/whitespace-only answer at each gate; confirm the documented behavior (re-prompt, not a silent no-op edit) fires consistently across all five files.

## Out of Scope
- Changing what "Continue" or "Stop here for now" do (D3 — kept as-is).
- Fixing `research.md`'s Continue option having an extra "unresolved Open Decisions" caveat clause not present in the other three phase-to-phase gates — a pre-existing inconsistency research surfaced, unrelated to the revision-branch redesign this work is scoped to.
- Adding a CHANGELOG/HISTORY file or any other plugin version-history mechanism beyond the existing version-bump-in-commit-message convention.
- Retroactively migrating or auditing any already-run QRSPI sessions/artifacts created under the old two-turn revision flow.
