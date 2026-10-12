import pdfParse from 'pdf-parse';
import { buildNoticeEvidence } from '../application/notice-evidence';
import { stageNoticeEvidence } from './stage-notice-evidence';
import type { Pool } from 'pg';

export async function extractOfficialPdf(
  pool: Pool,
  documentUrl: string,
  title: string,
  options: { dryRun?: boolean; fetcher?: typeof fetch } = {},
): Promise<{ pages: number; characters: number; sha256: string; staged: boolean }> {
  const url = new URL(documentUrl);
  if (url.protocol !== 'https:' || !url.hostname.endsWith('.gov.br') ||
      url.username || url.password || url.port || url.hash) {
    throw new TypeError('PDF source must be a public HTTPS .gov.br URL');
  }
  const response = await (options.fetcher ?? fetch)(url.toString(), {
    method: 'GET', redirect: 'error', headers: { Accept: 'application/pdf' },
    signal: AbortSignal.timeout(20000),
  });
  if (!response.ok) throw new Error(`Official PDF returned HTTP ${response.status}`);
  const length = Number(response.headers.get('content-length') || 0);
  if (length > 10_000_000) throw new RangeError('PDF too large');
  const bytes = Buffer.from(await response.arrayBuffer());
  if (bytes.length === 0 || bytes.length > 10_000_000 ||
      bytes.subarray(0,5).toString() !== '%PDF-') {
    throw new TypeError('Response is not a supported PDF document');
  }
  const parsed = await pdfParse(bytes);
  if (!parsed.text.trim()) throw new TypeError('PDF contains no extractable text');
  if (parsed.text.length > 500_000 || parsed.numpages > 500) {
    throw new RangeError('PDF exceeds supported extraction limits');
  }
  const evidence = buildNoticeEvidence({
    sourceUrl: url.toString(), title, bytes, text: parsed.text,
  });
  if (!options.dryRun) {
    await stageNoticeEvidence(pool, {sourceUrl: evidence.sourceUrl,title,bytes,text:parsed.text});
  }
  return {
    pages: parsed.numpages, characters: parsed.text.length,
    sha256: evidence.documentSha256, staged: !options.dryRun,
  };
}
