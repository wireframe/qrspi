#!/usr/bin/env bash
# Builds a tiny git repo with a QRSPI plan for /qrspi:structure.
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

git add -A
git -c commit.gpgsign=false commit -qm "fixture"
