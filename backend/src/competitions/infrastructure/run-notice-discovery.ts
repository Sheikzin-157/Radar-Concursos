import { discoverOfficialNoticeLinks } from './discover-official-notices';

async function main(): Promise<void> {
  const raw = process.env.OFFICIAL_NOTICE_PAGE_URL;
  const allowed = process.env.OFFICIAL_NOTICE_ALLOWED_URL;
  if (!raw || raw !== allowed) {
    throw new Error('Official notice page must exactly match the configured allowed URL.');
  }
  const url = new URL(raw);
  if (url.protocol !== 'https:' || !url.hostname.endsWith('.gov.br') ||
      url.username || url.password || url.port) {
    throw new TypeError('Only public HTTPS .gov.br notice pages are supported.');
  }
  const response = await fetch(url, {
    headers: {Accept: 'text/html'},
    redirect: 'error',
    signal: AbortSignal.timeout(10000),
  });
  if (!response.ok) throw new Error(`Official page returned HTTP ${response.status}`);
  const mime = response.headers.get('content-type') ?? '';
  if (!mime.includes('text/html')) throw new TypeError('Expected an HTML page');
  const body = await response.text();
  const candidates = discoverOfficialNoticeLinks(body, url.toString());
  process.stdout.write(JSON.stringify({
    source: url.toString(),
    checkedAt: new Date().toISOString(),
    candidates,
    requiresHumanReview: true,
  },null,2) + '\n');
}

void main().catch((error: unknown) => {
  process.stderr.write((error instanceof Error ? error.message : 'Notice discovery failed') + '\n');
  process.exitCode = 1;
});
