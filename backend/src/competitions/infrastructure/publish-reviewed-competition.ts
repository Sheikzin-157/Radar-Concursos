import type { Pool, PoolClient } from 'pg';

export async function publishReviewedCompetition(
  pool: Pool,
  intakeId: string,
  reviewer: string,
): Promise<string> {
  if (!/^[0-9a-f]{8}-[0-9a-f]{4}-[1-8][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i.test(intakeId)) {
    throw new TypeError('Invalid intake ID');
  }
  if (!reviewer.trim()) throw new TypeError('Reviewer identity is required');
  const client: PoolClient = await pool.connect();
  try {
    await client.query('BEGIN');
    const staged = await client.query<{
      id: string; organization_name: string; title: string; official_url: string;
      status: string; state_code: string; source_checked_at: Date;
    }>(
      `SELECT id, organization_name, title, official_url, status, state_code, source_checked_at
       FROM public_data.competition_intake
       WHERE id=$1 AND review_status='approved'
       FOR UPDATE`, [intakeId],
    );
    if (staged.rows.length !== 1) throw new Error('Intake is not approved or does not exist');
    const item = staged.rows[0];
    if (item.status === 'requires_review' || !item.status.trim()) {
      throw new Error('Intake status requires review before publication');
    }
    const checkedAt = new Date(item.source_checked_at);
    if (!Number.isFinite(checkedAt.getTime()) ||
        checkedAt.getTime() > Date.now() ||
        Date.now() - checkedAt.getTime() > 30 * 24 * 60 * 60 * 1000) {
      throw new Error('Official source verification is missing, invalid or older than 30 days');
    }
    const org = await client.query<{id: string}>(
      `SELECT id FROM public_data.organizations
       WHERE official_name=$1 AND state_code=$2 ORDER BY created_at LIMIT 1`,
      [item.organization_name, item.state_code],
    );
    let organizationId = org.rows[0]?.id;
    if (!organizationId) {
      const created = await client.query<{id: string}>(
        `INSERT INTO public_data.organizations (official_name, state_code)
         VALUES ($1,$2) RETURNING id`,
        [item.organization_name, item.state_code],
      );
      organizationId = created.rows[0].id;
    }
    const existing = await client.query<{id: string}>(
      `SELECT id FROM public_data.competitions WHERE official_url=$1 LIMIT 1 FOR UPDATE`,
      [item.official_url],
    );
    let competitionId = existing.rows[0]?.id;
    if (competitionId) {
      await client.query(
        `UPDATE public_data.competitions
         SET organization_id=$2, title=$3, current_status=$4, last_validated_at=$5,
             updated_at=now()
         WHERE id=$1`,
        [competitionId, organizationId, item.title, item.status, item.source_checked_at],
      );
    } else {
      const inserted = await client.query<{id: string}>(
        `INSERT INTO public_data.competitions
         (organization_id,title,current_status,official_url,last_validated_at,published_at)
         VALUES ($1,$2,$3,$4,$5,now()) RETURNING id`,
        [organizationId,item.title,item.status,item.official_url,item.source_checked_at],
      );
      competitionId = inserted.rows[0].id;
    }
    await client.query(
      `UPDATE public_data.competition_intake
       SET updated_at=now() WHERE id=$1`, [intakeId],
    );
    await client.query(
      `INSERT INTO public_data.competition_publication_audit
       (intake_id,competition_id,reviewer,action)
       VALUES ($1,$2,$3,'publish')`,
      [intakeId, competitionId, reviewer.trim()],
    );
    await client.query('COMMIT');
    return competitionId;
  } catch (error) {
    await client.query('ROLLBACK');
    throw error;
  } finally {
    client.release();
  }
}
