import type { Pool } from 'pg';
import {
  validateOfficialCompetitionDraft,
  type OfficialCompetitionDraft,
} from '../application/official-source-validator';

export interface StagedCompetition {
  id: string;
  organization_name: string;
  title: string;
  official_url: string;
  status: string;
  state_code: string;
  source_checked_at: Date;
  review_status: string;
}

/** Stages verified-source metadata without publishing it in the public catalog. */
export async function stageOfficialCompetition(
  pool: Pool,
  input: unknown,
): Promise<StagedCompetition> {
  const draft: OfficialCompetitionDraft = validateOfficialCompetitionDraft(input);
  const result = await pool.query<StagedCompetition>(
    `INSERT INTO public_data.competition_intake
      (organization_name, title, official_url, status, state_code, source_checked_at)
     VALUES ($1, $2, $3, $4, $5, $6)
     ON CONFLICT (official_url) DO UPDATE SET
       organization_name = EXCLUDED.organization_name,
       title = EXCLUDED.title, status = EXCLUDED.status,
       state_code = EXCLUDED.state_code,
       source_checked_at = EXCLUDED.source_checked_at,
       review_status = 'pending', reviewed_at = NULL
     RETURNING id, organization_name, title, official_url, status,
       state_code, source_checked_at, review_status`,
    [draft.organizationName, draft.title, draft.officialUrl, draft.status,
      draft.stateCode, draft.sourceCheckedAt],
  );
  return result.rows[0];
}
