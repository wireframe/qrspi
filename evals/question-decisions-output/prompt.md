---
description: Answers given up front become decisions.md with Depends on fields and correct firmness
max_turns: 15
allowed_tools: [Read, Glob, Grep, Skill, Write]
---

/qrspi:question add rate limiting to our public REST API

I've thought this through already:
- Limits count per authenticated account, shared across all of that account's API keys, so rotating keys never resets a limit. This is non-negotiable.
- Everything else: go with your recommendations.

Don't ask me anything; write it up.
