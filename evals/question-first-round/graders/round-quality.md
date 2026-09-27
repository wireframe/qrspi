---
type: llm
---

The final message is the first round of a design interview about adding rate limiting to a REST API.

PASS if all of these hold:
- It asks two or more numbered questions in this one message.
- No question's answer depends on the answer to another question in the same message.
- Every question is followed by a recommended answer.
- No question asks the user for a fact about the existing codebase, such as which web framework, middleware, or datastore is in use.

FAIL if it asks only one question, if any question hinges on another question in the same message, if any question lacks a recommendation, or if it asks the user for a codebase fact.
