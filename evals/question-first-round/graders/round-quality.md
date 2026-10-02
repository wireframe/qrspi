---
type: llm
---

The final message is the first round of a design interview about adding rate limiting to a REST API.

PASS if all of these hold:
- It asks two or more numbered questions in this one message.
- No question depends on another question in the same message. A question depends on another only if its options or its recommendation would change based on that other answer, or if the message says one answer shapes or overrides another.
- Every question is followed by a recommended answer.
- Each question asks one thing, and its recommendation is not conditional (no "X if …, otherwise Y").
- No question asks the user for a fact about the existing codebase, such as which web framework, middleware, or datastore is in use.

FAIL if it asks only one question, if any question hinges on another question in the same message, if any question lacks a recommendation, if any question bundles several asks or hedges its recommendation, or if it asks the user for a codebase fact.
