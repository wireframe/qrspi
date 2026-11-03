# Structure: make /qrspi:question less exhaustive before research
Date: 2026-11-02
Decisions: [decisions.md](decisions.md)
Research: [research.md](research.md)

## Phase 1: /question asks only what's yours to answer and defers the rest
**Goal:** /question puts a decision to the user only if the user alone can answer it and the answer changes where research looks. Every other decision goes into a `## Deferred` bullet list in decisions.md (D1, D3, D7, D8).
- The two-part test replaces the "Ask about" list.
- The recommendation-hinging rule and the delegation rule route to Deferred.
- The empty-frontier stop and Open propagation stay as they are (D2, D4).
- The decisions.md template gains the Deferred section.

**Depends on:** nothing
**Verification:** Write the eval changes first and see them fail against the current `question.md`. Then `claude plugin eval . --ablation none --no-publish --allow-tools Write --case <case>` passes for the new case and for `question-decisions-output`. `question-first-round` passes at least as often as its recorded baseline of 1 in 3. Run `question-examples-*` with `--judge-model opus` to show they haven't regressed.

## Phase 2: /research owns Deferred decisions
**Goal:** /research reads decisions.md's Deferred list and writes a `## Deferred Decisions` section next to Open Decisions, with the evidence and options for each item, printed in full. When the user picks, research writes the pick back into decisions.md as a new D-entry (Preference). The Continue Gate caveat also covers unresolved Deferred items (D5, D9).
**Depends on:** Phase 1, for the Deferred section format
**Verification:** Write the new eval first and see it fail against the current `research.md`. Then it passes: research.md has a Deferred Decisions section with one entry per Deferred bullet, and it is separate from Open Decisions.

## Phase 3: /structure leaves file choices to /plan
**Goal:** /structure's phases describe goals, dependencies and verification without listing files. The per-phase files field goes away, and file paths stay /plan's job (D13).
**Depends on:** nothing
**Verification:** Write the new eval first, give it a decisions.md and research.md fixture, and see it fail against the current `structure.md`. Then it passes: the written structure.md has no files field in any phase.

## Phase 4: Old vs new delegation replay
**Goal:** Measure whether the new /question asks less (D6, D10).
- Run about 4 real topics (gpa-evals, agent-calendar, question-burster, scheduled-tasks) through the 0.6.0 and new plugin arms.
- Each run is a one-shot `claude -p` with "go with your recommendations", using the `--plugin-dir` and `--settings` method from the 2026-11-01 comparison.
- Record D-entries vs Deferred bullets and the round-1 question count per arm in `comparison.md`.
- Keep the transcript extractor from the usage analysis as a reusable tool, so the measurement can be repeated.

**Depends on:** Phase 1
**Verification:** comparison.md has a row per topic and arm, with numbers taken from the run outputs. The extractor reproduces the earlier counts on one known transcript (e.g. gpa-evals: 12 questions asked before decisions.md, 14 decisions).
**Note:** This phase serves Preference decisions D6 and D10. Confirm it's worth building. It's a measurement, not a product change.

## Phase 5: Docs and release
**Goal:** Keep the docs in sync with the new behavior and ship it as 0.7.0 (D12).
- The user-facing and eval docs describe the filter, the Deferred section, the leaner /structure and the new eval cases.
- The frontier-rounds design doc points to this change where its stop and asking rules no longer apply.
- The plugin version is 0.7.0.

**Depends on:** Phases 1-4
**Verification:** The plugin reports version 0.7.0. The docs describe the new behavior. The full eval suite runs green, or matches the recorded baselines for the known-flaky cases.

## Out of Scope
- A question or round budget. Rejected (D2).
- Pruning a whole branch on a "not sure / defer" answer. Rejected (D4).
- Teaching /structure, /plan or /implement about Deferred items. The bulleted Deferred format avoids that (D8). This is a Preference, so revisit it if replays show Deferred items slipping past research.
- A Continue Gate callout for Deferred items (D11, Claude's default).
- A simulated-user, multi-round replay. Delegation replay was picked (D10).
