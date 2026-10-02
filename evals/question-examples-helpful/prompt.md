---
description: /qrspi:question gives options concrete include/exclude examples when they draw a line the user can't picture
max_turns: 10
allowed_tools: [Read, Glob, Grep, Skill, AskUserQuestion]
---

/qrspi:question flag duplicate contacts when importing a CSV into our CRM

Already settled: the goal is to stop sending the same person two emails, and each row is checked against existing CRM contacts and other rows in the same file. Flagged rows still import, with a "possible duplicate" marker. Start with what counts as a duplicate.
