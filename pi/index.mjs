// Pi adapter for the QRSPI commands and skills.
//
// The commands are written for Claude Code and stay that way: one source for
// both harnesses. Pi loads them as prompt templates and skills through this
// package's manifest, so the only thing missing is the vocabulary difference —
// what each Claude-only name in them means in Pi. That mapping is all this
// file knows.

import { fileURLToPath } from 'node:url';
import { dirname } from 'node:path';

const PACKAGE_ROOT = dirname(dirname(fileURLToPath(import.meta.url)));

export function claudeVocabularyInPi(packageRoot) {
  return `QRSPI's commands and skills were written for Claude Code. In Pi, read their Claude vocabulary this way:
- \`\${CLAUDE_PLUGIN_ROOT}\` is \`${packageRoot}\`.
- \`/qrspi:<phase>\` is the prompt template \`/<phase>\`. To continue into the next phase in the same turn, read \`${packageRoot}/commands/<phase>.md\` and follow it.
- \`/qrspi:code-review\` is the \`code-review\` skill: read \`${packageRoot}/skills/code-review/SKILL.md\` and review the diff against it.
- \`AskUserQuestion\`: call it if a tool by that name is available; otherwise use the command's plain-text fallback and end the turn to wait for the answer.
- \`TodoWrite\`: track tasks with the plan's own checkboxes.
- Subagents: dispatch them with the \`subagent\` tool when it is available; otherwise do that work yourself, one task at a time, re-reading the task's full text before each review.
- \`/simplify\` is a Claude Code built-in. Do the pass yourself: review the diff for reuse, simplification, efficiency and altitude cleanups, and apply them.
- \`/code-review\` (with or without \`--fix\`) is a Claude Code built-in. Do the pass yourself: review the diff for correctness bugs and apply the fixes.`;
}

export default function registerQrspi(pi) {
  pi.on('before_agent_start', (event) => {
    event.systemPromptOptions.sections.qrspi = claudeVocabularyInPi(PACKAGE_ROOT);
  });
}
