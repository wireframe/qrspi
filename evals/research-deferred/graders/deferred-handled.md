---
type: llm
focus: trace
---

PASS if the research.md Claude wrote has a `## Deferred Decisions` section, separate from any Open Decisions section, with one entry per Deferred bullet (both bullets), each giving at least two options with tradeoffs and neither picking nor leaning toward one (in the file or the reply). A lean is a recommendation, a ranking, or an evaluative judgment of one option as better or worse overall; a plain factual cost or benefit ("costs less code", "only supports short options") or a one-sentence statement of what an existing D-entry decided is NOT a lean; and the Deferred decisions are printed in full in the reply. FAIL otherwise.
