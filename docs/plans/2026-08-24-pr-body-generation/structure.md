# Structure: PR Body Generation
Date: 2026-08-24
Decisions: [decisions.md](decisions.md)
Research: [research.md](research.md)

## Phase 1: Append PR body generation step to /implement
**Goal:** `commands/implement.md` drafts a PR body from the plan's artifacts and offers to open it via `gh`, after the last plan phase's quality gate.
**Files touched:** `commands/implement.md`
**Depends on:** nothing
**Verification:** Manually walk the new instructions against `docs/plans/2026-08-24-pr-body-generation/` and confirm the drafted body matches the template in `docs/plans/2026-08-24-pr-body-generation-design.md` and every link resolves.

## Out of Scope
- A `bin/` script or standalone `/qrspi:pr` command — deferred per D1.
