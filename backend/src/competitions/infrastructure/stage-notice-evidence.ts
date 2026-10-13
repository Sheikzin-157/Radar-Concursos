import type { Pool } from 'pg';
import { buildNoticeEvidence } from '../application/notice-evidence';

/** Private staging only: a human must review all extracted edital evidence. */
export async function stageNoticeEvidence(pool: Pool, input: {
  sourceUrl: string; title: string; bytes: Buffer; text: string;
}): Promise<{id: string; document_sha256: string}> {
  const evidence = buildNoticeEvidence(input);
  const result = await pool.query<{id: string; document_sha256: string}>(
    `INSERT INTO public_data.notice_evidence
      (source_url,title,document_sha256,extracted_text,observed_at)
     VALUES ($1,$2,$3,$4,$5)
     ON CONFLICT (source_url,document_sha256)
       DO UPDATE SET title=EXCLUDED.title
     RETURNING id,document_sha256`,
    [evidence.sourceUrl,evidence.title,evidence.documentSha256,
      evidence.extractedText,evidence.observedAt],
  );
  return result.rows[0];
}
