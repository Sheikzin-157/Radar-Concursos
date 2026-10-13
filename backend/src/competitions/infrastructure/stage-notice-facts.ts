import type { Pool } from 'pg';
import { extractEditalFactCandidates } from '../application/extract-edital-facts';

/** Idempotently stages extracted candidate facts for human moderation. */
export async function stageNoticeFacts(pool: Pool, evidenceId: string): Promise<number> {
  if (!/^[0-9a-f]{8}-[0-9a-f]{4}-[1-8][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i.test(evidenceId)) {
    throw new TypeError('Invalid evidence ID');
  }
  const evidence = await pool.query<{extracted_text: string}>(
    'SELECT extracted_text FROM public_data.notice_evidence WHERE id=$1',
    [evidenceId],
  );
  if (!evidence.rows[0]) throw new Error('Evidence not found');
  const facts = extractEditalFactCandidates(evidence.rows[0].extracted_text);
  let staged = 0;
  for (const fact of facts) {
    const result = await pool.query(
      `INSERT INTO public_data.notice_fact_candidates
       (evidence_id,kind,value,evidence_excerpt,source_line)
       VALUES ($1,$2,$3,$4,$5)
       ON CONFLICT (evidence_id,kind,source_line,value) DO NOTHING`,
      [evidenceId,fact.kind,fact.value,fact.evidence,fact.line],
    );
    staged += result.rowCount ?? 0;
  }
  return staged;
}

export async function reviewNoticeFact(
  pool: Pool, factId: string, decision: 'confirmed' | 'rejected', reviewer: string,
): Promise<boolean> {
  if (!/^[0-9a-f]{8}-[0-9a-f]{4}-[1-8][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i.test(factId)) {
    throw new TypeError('Invalid fact ID');
  }
  if (decision !== 'confirmed' && decision !== 'rejected') throw new TypeError('Invalid decision');
  if (!reviewer.trim()) throw new TypeError('Reviewer required');
  const result = await pool.query(
    `UPDATE public_data.notice_fact_candidates
     SET review_status=$2,reviewed_by=$3,reviewed_at=now()
     WHERE id=$1 AND review_status='pending'`,
    [factId,decision,reviewer.trim()],
  );
  return result.rowCount === 1;
}
