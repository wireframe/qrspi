#!/usr/bin/env bash
# Builds a tiny git repo with a QRSPI plan for /qrspi:implement to execute.
set -euo pipefail

git init -q -b main
git config user.name "Fixture"
git config user.email "fixture@example.com"

cat > greet.sh <<'SH'
echo "Hello, ${1}"
SH

cat > test.sh <<'SH'
#!/usr/bin/env bash
set -u
actual=$(bash greet.sh Ann)
if [ "$actual" != "Hello, Ann" ]; then
  echo "FAIL: expected 'Hello, Ann', got '$actual'"
  exit 1
fi
echo "PASS"
SH

plan_dir=docs/plans/2026-01-01-greeting
mkdir -p "$plan_dir"

cat > "$plan_dir/decisions.md" <<'MD'
# Decisions: greeting
Date: 2026-01-01

## D1: Option style
**Question:** How should greeting options be passed?
**Depends on:** none
**Firmness:** Preference
**Options considered:** Plain shell arguments (no dependencies); getopts (heavier for one flag).
**Chosen:** Plain shell arguments
**Rationale:** The script is one line; a different choice only matters if options multiply.

## Research Focus Areas
- How does `greet.sh` handle its arguments today?
MD

cat > "$plan_dir/research.md" <<'MD'
# Research: greeting
Date: 2026-01-01
Decisions: [decisions.md](decisions.md)

## Argument handling in greet.sh
**Findings:**
- `greet.sh` prints `Hello, ${1}` and has no option parsing.
- Reference: `greet.sh:1`

## Patterns Observed
- Tests are plain Bash assertions in `test.sh`, run with `bash test.sh`.

## Constraints Discovered
- No test framework is installed; only Bash is available.
MD

cat > "$plan_dir/structure.md" <<'MD'
# Structure: greeting
Date: 2026-01-01
Decisions: [decisions.md](decisions.md)
Research: [research.md](research.md)

## Phase 1: Greeting options
**Goal:** `greet.sh` supports `--shout` and a default name.
**Files touched:** `greet.sh`, `test.sh`
**Depends on:** nothing
**Verification:** bash test.sh

## Out of Scope
- Any other options or localization.
MD

cat > "$plan_dir/plan.md" <<'MD'
# Plan: greeting
Date: 2026-01-01
Decisions: [decisions.md](decisions.md)
Research: [research.md](research.md)
Structure: [structure.md](structure.md)

> **For Claude:** Execute this plan task-by-task, phase by phase — see `/qrspi:implement`'s execution options.

**Goal:** Add a `--shout` flag and a default name to `greet.sh`.
**Architecture:** `greet.sh` stays a single Bash script; `test.sh` holds the assertions.
**Tech Stack:** Bash

---

## Phase 1: Greeting options

- [ ] Task 1.1: Add --shout
  - File: `greet.sh:1`, `test.sh`
  - Change: `bash greet.sh --shout Ann` prints `HELLO, ANN`. Add this assertion to `test.sh` first, watch it fail, then implement.
  - Test: bash test.sh

- [ ] Task 1.2: Default name
  - File: `greet.sh:1`, `test.sh`
  - Change: `bash greet.sh` with no argument prints `Hello, world`. Add this assertion to `test.sh` first, watch it fail, then implement.
  - Test: bash test.sh

- [ ] Commit Phase 1
MD

git add -A
git -c commit.gpgsign=false commit -qm "fixture"
