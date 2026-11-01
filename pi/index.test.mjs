import { test } from 'node:test';
import assert from 'node:assert/strict';
import { fileURLToPath } from 'node:url';
import { dirname } from 'node:path';
import registerQrspi, { claudeVocabularyInPi } from './index.mjs';

const packageRoot = dirname(dirname(fileURLToPath(import.meta.url)));

test('resolves CLAUDE_PLUGIN_ROOT to the package root', () => {
  assert.match(claudeVocabularyInPi('/opt/qrspi'), /`\$\{CLAUDE_PLUGIN_ROOT\}` is `\/opt\/qrspi`/);
});

test('maps each Claude-only name the commands use', () => {
  const vocabulary = claudeVocabularyInPi('/opt/qrspi');
  for (const name of ['/qrspi:', 'AskUserQuestion', 'TodoWrite', 'subagent', '/simplify', '/code-review']) {
    assert.ok(vocabulary.includes(name), `missing ${name}`);
  }
});

test('adds the vocabulary as a qrspi prompt section before every run', () => {
  const handlers = {};
  registerQrspi({ on: (event, handler) => { handlers[event] = handler; } });
  const event = { systemPromptOptions: { sections: {} } };

  handlers.before_agent_start(event);

  assert.equal(event.systemPromptOptions.sections.qrspi, claudeVocabularyInPi(packageRoot));
});
