#!/usr/bin/env bash
# Builds a tiny layered notes CLI with a QRSPI plan for /qrspi:structure.
set -euo pipefail

git init -q -b main
git config user.name "Fixture"
git config user.email "fixture@example.com"

cat > store.sh <<'S'
# Storage layer: one note per line in notes.txt as "<id>\t<text>".
store_add() { local id=$(( $(wc -l < notes.txt 2>/dev/null || echo 0) + 1 )); printf '%s\t%s\n' "$id" "$1" >> notes.txt; echo "$id"; }
store_list() { cat notes.txt 2>/dev/null || true; }
S

cat > notes.sh <<'S'
#!/usr/bin/env bash
# CLI layer: notes add <text> | notes list
source "$(dirname "$0")/store.sh"
case "${1:-}" in
  add) store_add "$2" ;;
  list) store_list ;;
  *) echo "usage: notes.sh add <text> | list" >&2; exit 1 ;;
esac
S

cat > test.sh <<'S'
#!/usr/bin/env bash
set -eu
rm -f notes.txt
bash notes.sh add "buy milk" >/dev/null
bash notes.sh list | grep -q "buy milk" && echo PASS
S

cat > README.md <<'S'
# notes
`notes.sh add <text>` adds a note. `notes.sh list` lists notes.
S

echo "1.0.0" > VERSION

cat > CHANGELOG.md <<'S'
# Changelog
## 1.0.0
- add and list notes
S

plan_dir=docs/plans/2026-01-01-note-tags
mkdir -p "$plan_dir"

cat > "$plan_dir/decisions.md" <<'MD'
# Decisions: note tags
Date: 2026-01-01

## D1: What tagging covers
**Question:** Which tag operations does this change include?
**Depends on:** none
**Firmness:** Preference
**Options considered:** Add + list only; add, list, filter by tag, and remove.
**Chosen:** Add a tag to a note, show tags when listing, filter the list by tag, and remove a tag.
**Rationale:** Filtering is the point of tags; remove keeps mistakes fixable.

## D2: Existing notes
**Question:** What happens to notes saved before tags existed?
**Depends on:** none
**Firmness:** Firm
**Options considered:** Migrate notes.txt to the new format; leave old lines untagged and parse both formats.
**Chosen:** Migrate existing notes.txt files to the new line format on first run.
**Rationale:** Users have real notes; none may be lost or misparsed.

## D3: Release
**Question:** How does this ship?
**Depends on:** D1
**Firmness:** Preference
**Options considered:** Bump VERSION to 1.1.0 with a CHANGELOG entry and README updates; no release bookkeeping.
**Chosen:** Bump VERSION to 1.1.0, add a CHANGELOG entry, and update the README.
**Rationale:** Keeps the release history honest.

## Research Focus Areas
- How are notes stored and listed today?
MD

cat > "$plan_dir/research.md" <<'MD'
# Research: note tags
Date: 2026-01-01
Decisions: [decisions.md](decisions.md)

## Storage
**Findings:**
- `store.sh` keeps one note per line in `notes.txt` as `<id>\t<text>`; there is no field for tags.
- Reference: `store.sh:2-3`

## Command line
**Findings:**
- `notes.sh` dispatches `add` and `list` to the storage functions; there is no `tag`, `untag` or filter flag.
- Reference: `notes.sh:4-8`

## Docs, release and tests
**Findings:**
- `README.md` documents `add` and `list` only.
- `VERSION` holds `1.0.0`; `CHANGELOG.md` has one entry per release.
- `test.sh` covers add + list with plain Bash assertions, run with `bash test.sh`.

## Patterns Observed
- Layers: storage functions in `store.sh`, CLI dispatch in `notes.sh`, usage docs in `README.md`.

## Constraints Discovered
- Adding a tag column to `notes.txt` changes the line format that `store_list` prints, so every tag feature depends on the new format.
- Existing `notes.txt` files use the old two-column format and must be migrated (D2) before any tag command can read them.
MD

git add -A
git -c commit.gpgsign=false commit -qm "fixture"
