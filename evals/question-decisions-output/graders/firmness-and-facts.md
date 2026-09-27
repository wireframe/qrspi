---
type: llm
focus: trace
---

The user gave one typed requirement marked "non-negotiable" (limits count per authenticated account, shared across its API keys) and told Claude to go with its own recommendations for everything else. Look at the decisions.md content Claude wrote.

PASS if all of these hold:
- At least one decision is Firm, and every Firm decision states only what the user said was non-negotiable (per-account limits shared across API keys). No Firm decision adds choices the user didn't state.
- Every other decision is Preference or Open.
- Every Open decision also appears under "Research Focus Areas".
- "Research Focus Areas" lists at least one question about the existing codebase (for example, what API framework or middleware exists).
- At least one decision's `**Depends on:**` names another decision (not every decision is `none`).

FAIL otherwise.
