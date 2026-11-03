---
type: llm
focus: trace
---

Look at the structure.md Claude wrote for adding tags to a notes CLI. The code has three layers: storage (`store.sh`), the command line (`notes.sh`), and docs (`README.md`), plus tests in `test.sh`.

PASS if both hold:
- Every phase is a vertical slice: it ships behavior a user can run end to end through `notes.sh` (for example "tag a note and see the tag when listing"), touching whatever layers that needs, with its own verification. A phase that only changes one layer — only storage/schema, only the migration, only CLI plumbing, only tests, or only docs — fails this, unless the phase is explicitly marked as enabling work with a stated reason why it can't be a vertical slice.
- README/doc updates for a behavior land in the phase that ships that behavior. There is no trailing phase whose main job is docs, release notes, a changelog, or a version bump; release bookkeeping (VERSION, CHANGELOG) rides along in the last slice or is spread across slices.

FAIL otherwise.
