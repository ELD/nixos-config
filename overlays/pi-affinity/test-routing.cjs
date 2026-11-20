// Run against the actual published JS after patching, before Bun embeds it.
const assert = require('node:assert/strict');
const { readFileSync } = require('node:fs');
const source = readFileSync(process.argv[2], 'utf8');
const start = source.indexOf('function buildBaseCodexHeaders(');
assert.notEqual(start, -1, 'Codex header builders moved; review the patch');
const builders = source.slice(start).replace(/\/\/# sourceMappingURL=.*$/, '');
const { buildSSEHeaders, buildWebSocketHeaders } = new Function(
  'OPENAI_BETA_RESPONSES_WEBSOCKETS',
  `${builders}\nreturn { buildSSEHeaders, buildWebSocketHeaders };`,
)('responses_websockets=test');

for (const build of [buildSSEHeaders, buildWebSocketHeaders]) {
  for (const routing of [undefined, 'root-session']) {
    const headers = build({}, {}, routing ? { 'SeSsIoN-Id': routing } : {}, 'account', 'token', 'child-session');
    assert.equal(headers.get('session-id'), routing ?? 'child-session');
    assert.equal(headers.get('x-client-request-id'), 'child-session');
    assert.equal(headers.get('Authorization'), 'Bearer token');
    assert.equal(headers.get('chatgpt-account-id'), 'account');
  }
  // Defaults and model headers are explicit routing choices too. A null caller
  // header removes a default and restores the ordinary per-child fallback.
  assert.equal(build({ 'session-id': 'default' }, {}, {}, 'a', 't', 'child').get('session-id'), 'default');
  assert.equal(build({}, { 'session-id': 'model' }, {}, 'a', 't', 'child').get('session-id'), 'model');
  assert.equal(build({ 'session-id': 'default' }, {}, { 'session-id': null }, 'a', 't', 'child').get('session-id'), 'child');
}
assert.equal(buildSSEHeaders({}, {}, {}, 'a', 't', undefined).has('session-id'), false);
console.log('Codex SSE/WebSocket routing and independent request identity: OK');
