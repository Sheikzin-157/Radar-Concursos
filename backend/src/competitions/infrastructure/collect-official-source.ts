import type { Pool } from 'pg';
import { stageOfficialCompetition } from './stage-official-competition';
import type { OfficialCompetitionDraft } from '../application/official-source-validator';

export interface OfficialSource {
  name: string;
  url: string;
  organizationName: string;
  stateCode: string;
  status: string;
}

/**
 * Controlled JSON intake from explicit allowlisted government endpoints.
 * A source response is untrusted and each record remains pending review.
 */
export async function collectOfficialSource(
  pool: Pool,
  source: OfficialSource,
  options: { dryRun?: boolean; fetcher?: typeof fetch } = {},
): Promise<{ examined: number; staged: number }> {
  const url = new URL(source.url);
  if (url.protocol !== 'https:' || !url.hostname.endsWith('.gov.br') ||
      url.username || url.password || url.port || url.hash) {
    throw new TypeError('Source URL must be a public .gov.br HTTPS endpoint');
  }
  const fetcher = options.fetcher ?? fetch;
  const response = await fetcher(url.toString(), {
    method: 'GET',
    headers: { Accept: 'application/json' },
    redirect: 'error',
    signal: AbortSignal.timeout(10000),
  });
  if (!response.ok) throw new Error(`Official source returned HTTP ${response.status}`);
  const contentType = response.headers.get('content-type') ?? '';
  if (!contentType.includes('application/json')) {
    throw new TypeError('Official source must return JSON');
  }
  const body: unknown = await response.json();
  if (!Array.isArray(body) || body.length > 100) {
    throw new TypeError('Official source must return at most 100 entries');
  }
  let staged = 0;
  for (const item of body) {
    if (!item || typeof item !== 'object' || Array.isArray(item)) continue;
    const record = item as Record<string, unknown>;
    if (typeof record.title !== 'string' || typeof record.officialUrl !== 'string') continue;
    const draft: OfficialCompetitionDraft = {
      organizationName: source.organizationName,
      title: record.title,
      officialUrl: record.officialUrl,
      status: source.status,
      stateCode: source.stateCode,
      sourceCheckedAt: new Date().toISOString(),
    };
    // Validates input even in dry-run. Does not publish.
    if (options.dryRun) {
      const { validateOfficialCompetitionDraft } = await import('../application/official-source-validator');
      validateOfficialCompetitionDraft(draft);
    } else {
      await stageOfficialCompetition(pool, draft);
      staged++;
    }
  }
  return { examined: body.length, staged };
}
