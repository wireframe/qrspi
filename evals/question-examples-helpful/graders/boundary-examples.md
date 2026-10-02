---
type: llm
---

The final message is a round of design questions about flagging duplicate contacts during a CSV import.

Find the question about what counts as a duplicate (how strict the match is, or which fields are compared).

PASS if, in that question, two or more options each name specific example values, such as an actual email, name, or record, and say whether that option treats it as a duplicate.

FAIL if there is no such question, or if its options describe matching only in general terms ("similar names", "minor differences", "exact match") without naming any specific value.
