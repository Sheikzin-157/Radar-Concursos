export interface OfficialCompetitionDraft {
  organizationName: string;
  title: string;
  officialUrl: string;
  status: string;
  stateCode: string;
  sourceCheckedAt: string;
}

const STATE_CODES = new Set([
  'AC','AL','AP','AM','BA','CE','DF','ES','GO','MA','MT','MS','MG',
  'PA','PB','PR','PE','PI','RJ','RN','RS','RO','RR','SC','SP','SE','TO',
]);

/**
 * Validate scraped or manually reviewed official records *before* database
 * persistence. This function never publishes or changes the catalog.
 */
export function validateOfficialCompetitionDraft(input: unknown): OfficialCompetitionDraft {
  if (!input || typeof input !== 'object' || Array.isArray(input)) {
    throw new TypeError('Official competition record must be an object');
  }
  const v = input as Record<string, unknown>;
  const required = ['organizationName','title','officialUrl','status','stateCode','sourceCheckedAt'];
  for (const key of required) {
    if (typeof v[key] !== 'string' || (v[key] as string).trim().length === 0) {
      throw new TypeError(`Missing official source field: ${key}`);
    }
  }
  const draft = Object.fromEntries(required.map(k => [k, (v[k] as string).trim()])) as unknown as OfficialCompetitionDraft;
  const url = new URL(draft.officialUrl);
  if (url.protocol !== 'https:' || !url.hostname.includes('.') || url.username || url.password) {
    throw new TypeError('Official source must have a public HTTPS URL');
  }
  if (!STATE_CODES.has(draft.stateCode)) throw new TypeError('Invalid Brazilian state code');
  if (draft.title.length > 255 || draft.organizationName.length > 255) {
    throw new TypeError('Catalog title or organization exceeds 255 characters');
  }
  const checked = new Date(draft.sourceCheckedAt);
  if (!Number.isFinite(checked.getTime()) || checked.getTime() > Date.now()) {
    throw new TypeError('Invalid official verification date');
  }
  return draft;
}
