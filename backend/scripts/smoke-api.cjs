#!/usr/bin/env node
// Smoke test for a deployed backend and its real catalog. No credentials or writes.
const base = process.env.API_BASE_URL;
if (!base || !/^https?:\/\/[^\s]+\/v1\/?$/.test(base)) {
  process.stderr.write('Set API_BASE_URL to an actual backend URL ending in /v1\n');
  process.exit(1);
}
async function main() {
  const root = base.replace(/\/v1\/?$/, '');
  const targets = [
    { path: root + '/health/ready', check: value => value.status === 'ready' },
    { path: base.replace(/\/$/, '') + '/competitions?limit=1',
      check: value => Array.isArray(value.items) && value.page && typeof value.page.hasMore === 'boolean' },
  ];
  for (const target of targets) {
    const response = await fetch(target.path, {signal:AbortSignal.timeout(15000)});
    if (!response.ok) throw new Error(`HTTP ${response.status} at ${target.path}`);
    const body = await response.json();
    if (!target.check(body)) throw new Error(`Unexpected contract at ${target.path}`);
    process.stdout.write('OK ' + target.path + '\n');
  }
}
main().catch(error => {
  process.stderr.write((error instanceof Error ? error.message : String(error)) + '\n');
  process.exitCode = 1;
});
