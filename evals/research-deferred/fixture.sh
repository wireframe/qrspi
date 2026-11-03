#!/usr/bin/env bash
# Builds a tiny git repo with a decisions.md that has Deferred decisions for /qrspi:research.
set -euo pipefail

git init -q -b main
git config user.name "Fixture"
git config user.email "fixture@example.com"

cat > greet.sh <<'SH'
echo "Hello, ${1}"
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

## Deferred
- How `--shout` should combine with a missing name
- Whether options use getopts or manual parsing

## Research Focus Areas
- How does `greet.sh` handle its arguments today?
MD

git add -A
git -c commit.gpgsign=false commit -qm "fixture"
