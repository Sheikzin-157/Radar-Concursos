import { createHash } from 'node:crypto';

export interface NoticeEvidence {
  sourceUrl: string;
  title: string;
  documentSha256: string;
  extractedText: string;
  observedAt: string;
}

/** Preserve provenance; extracted fields are evidence, not validated facts. */
export function buildNoticeEvidence(input: {
  sourceUrl: string; title: string; bytes: Buffer;
  text: string; observedAt?: string;
}): NoticeEvidence {
  const url = new URL(input.sourceUrl);
  if (url.protocol !== 'https:' || !url.hostname.endsWith('.gov.br') ||
      url.username || url.password || url.port) {
    throw new TypeError('Notice must come from an HTTPS .gov.br URL');
  }
  if (!input.title.trim() || input.title.length > 255) throw new TypeError('Invalid notice title');
  if (input.bytes.length === 0 || input.bytes.length > 10_000_000) {
    throw new RangeError('Document size outside supported limits');
  }
  if (input.text.length > 500_000) throw new RangeError('Extracted text exceeds limit');
  return {
    sourceUrl: url.toString(),
    title: input.title.trim(),
    documentSha256: createHash('sha256').update(input.bytes).digest('hex'),
    extractedText: input.text,
    observedAt: input.observedAt ?? new Date().toISOString(),
  };
}
