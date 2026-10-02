---
type: llm
---

The final message is a round of design questions about renaming the default git branch from master to main across a team's repos. Most of these options are already concrete, so examples should be used sparingly.

A placeholder example names a generic stand-in instead of a specific case, so it only restates the option. Examples: "rename repo A, then repo B", "an active service repo is included, an archived one is not", "the service repo is included only if you list it". An example that names something specific the description didn't (a particular file, trigger, value, or duration) is not a placeholder.

PASS if both hold:
- At least one question has no example in any of its options.
- No option contains a placeholder example.

FAIL if every question has an example in at least one option, or if any option contains a placeholder example.
