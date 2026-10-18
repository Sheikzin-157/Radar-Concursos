import type { Pool } from 'pg';

export interface VerifiedEdictSummary {
  sourceUrl: string;
  documentSha256: string;
  title: string;
  verifiedFacts: Array<{
    kind: string; value: string; evidence: string; line: number;
  }>;
  disclaimer: string;
}

/**
 * Deterministic, citation-first summary. Only moderator-confirmed claims
 * are included; no generative guesses or publication side effects.
 */
export async function buildVerifiedEdictSummary(
  pool: Pool, evidenceId: string,
): Promise<VerifiedEdictSummary> {
  if (!/^[0-9a-f]{8}-[0-9a-f]{4}-[1-8][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i.test(evidenceId)) {
    throw new TypeError('Invalid evidence ID');
  }
  const result = await pool.query<{
    source_url: string; document_sha256: string; title: string;
    kind: string | null; value: string | null; evidence_excerpt: string | null;
    source_line: number | null;
  }>(
    `SELECT e.source_url, e.document_sha256, e.title,
            f.kind, f.value, f.evidence_excerpt, f.source_line
       FROM public_data.notice_evidence e
       LEFT JOIN public_data.notice_fact_candidates f
         ON f.evidence_id=e.id AND f.review_status='confirmed'
       WHERE e.id=$1 AND e.review_status='reviewed'
       ORDER BY f.source_line ASC NULLS LAST, f.id ASC`,
    [evidenceId],
  );
  if (!result.rows.length) throw new Error('Reviewed edital evidence not found');
  const first = result.rows[0];
  return {
    sourceUrl:first.source_url,documentSha256:first.document_sha256,
    title:first.title,
    verifiedFacts:result.rows
      .filter((r) => r.kind !== null && r.value !== null &&
        r.evidence_excerpt !== null && r.source_line !== null)
      .map((r) => ({
        kind:r.kind!,value:r.value!,evidence:r.evidence_excerpt!,line:r.source_line!,
      })),
    disclaimer:'Resumo composto exclusivamente de trechos confirmados na revisão humana. Consulte o edital original.',
  };
}
