import type { Pool } from 'pg';

export type ReviewDecision = 'approved' | 'rejected';

export async function reviewCompetitionIntake(
  pool: Pool,
  intakeId: string,
  decision: ReviewDecision,
  reviewer: string,
): Promise<boolean> {
  if (!/^[0-9a-f]{8}-[0-9a-f]{4}-[1-8][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i.test(intakeId)) {
    throw new TypeError('Invalid intake ID');
  }
  if (!['approved', 'rejected'].includes(decision)) {
    throw new TypeError('Invalid review decision');
  }
  if (!reviewer.trim()) throw new TypeError('Reviewer identity is required');

  const result = await pool.query(
    `UPDATE public_data.competition_intake
       SET review_status=$2, reviewed_by=$3, reviewed_at=now(), updated_at=now()
       WHERE id=$1 AND review_status='pending'
       RETURNING id`,
    [intakeId, decision, reviewer.trim()],
  );
  return result.rowCount === 1;
}

export async function listPendingIntake(pool: Pool, limit = 30) {
  if (!Number.isInteger(limit) || limit < 1 || limit > 100) {
    throw new RangeError('limit must be between 1 and 100');
  }
  const result = await pool.query(
    `SELECT id, title, organization_name, official_url, state_code,
            status, source_checked_at, created_at
       FROM public_data.competition_intake
       WHERE review_status='pending'
       ORDER BY created_at ASC, id ASC LIMIT $1`,
    [limit],
  );
  return result.rows;
}
