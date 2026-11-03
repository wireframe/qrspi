---
type: llm
focus: last_message
---

The user asked Claude to run /qrspi:question for "add rate limiting to our public REST API". Eval runs have no AskUserQuestion tool, so the first round is printed as markdown with `❓ **Q1**`, `**Q2**`, … headings. Look at each question in that round. The options listed under a question are not questions; judge the question itself.

PASS if every question asks something only the user can answer (a goal, a scope boundary, a hard constraint, a success criterion, or a fact only they know) AND whose answer would change what research reads in the codebase.

FAIL otherwise, including if any question asks an implementation choice, such as the rate-limit algorithm (token bucket vs sliding window), response header names, the 429 response body, where counters are stored, or which library to use, or a fact about the existing codebase.

FAIL if the response contains no questions.
