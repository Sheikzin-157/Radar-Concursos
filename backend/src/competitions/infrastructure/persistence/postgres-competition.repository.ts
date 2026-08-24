import { Inject, Injectable } from '@nestjs/common';
import type { Pool } from 'pg';
import { DATABASE_POOL } from '../../../shared/infrastructure/database/database.module';
import {
  CompetitionDetail,
  CompetitionRepository,
  CompetitionSummary,
  ListCompetitionsQuery,
} from '../../application/ports/competition.repository';

interface CompetitionRow {
  id: string;
  title: string;
  competition_type: string | null;
  current_status: string;
  competition_government_sphere: string | null;
  summary: string | null;
  total_vacancies: number | null;
  reserve_registration: boolean | null;
  salary_min: string | null;
  salary_max: string | null;
  registration_fee_min: string | null;
  registration_fee_max: string | null;
  official_url: string | null;
  last_official_update_at: Date | null;
  last_validated_at: Date | null;
  organization_id: string;
  organization_name: string;
  organization_acronym: string | null;
  government_sphere: string | null;
  state_code: string | null;
  exam_board_id: string | null;
  exam_board_name: string | null;
  exam_board_acronym: string | null;
  career_id: string | null;
  career_name: string | null;
}

@Injectable()
export class PostgresCompetitionRepository implements CompetitionRepository {
  constructor(@Inject(DATABASE_POOL) private readonly pool: Pool) {}

  async listPublic(query: ListCompetitionsQuery): Promise<CompetitionSummary[]> {
    const values: unknown[] = [];
    const filters = ['c.published_at IS NOT NULL'];

    const addFilter = (sql: string, value: unknown) => {
      values.push(value);
      filters.push(`${sql} $${values.length}`);
    };

    if (query.organizationId) addFilter('c.organization_id =', query.organizationId);
    if (query.examBoardId) addFilter('c.exam_board_id =', query.examBoardId);
    if (query.status) addFilter('c.current_status =', query.status);
    if (query.state) addFilter('o.state_code =', query.state.toUpperCase());

    values.push(query.limit);

    const result = await this.pool.query<CompetitionRow>(
      `SELECT
        c.id, c.title, c.competition_type, c.current_status,
        c.government_sphere AS competition_government_sphere,
        c.summary, c.total_vacancies, c.reserve_registration,
        c.salary_min, c.salary_max, c.registration_fee_min, c.registration_fee_max,
        c.official_url, c.last_official_update_at, c.last_validated_at,
        o.id AS organization_id, o.official_name AS organization_name,
        o.acronym AS organization_acronym, o.government_sphere, o.state_code,
        b.id AS exam_board_id, b.official_name AS exam_board_name,
        b.acronym AS exam_board_acronym,
        cc.id AS career_id, cc.name AS career_name
      FROM public_data.competitions c
      JOIN public_data.organizations o ON o.id = c.organization_id
      LEFT JOIN public_data.exam_boards b ON b.id = c.exam_board_id
      LEFT JOIN public_data.career_categories cc ON cc.id = c.career_category_id
      WHERE ${filters.join(' AND ')}
      ORDER BY c.last_official_update_at DESC NULLS LAST, c.id ASC
      LIMIT $${values.length}`,
      values,
    );

    return result.rows.map((row) => this.toSummary(row));
  }

  async findPublicById(id: string): Promise<CompetitionDetail | null> {
    const result = await this.pool.query<CompetitionRow>(
      `SELECT
        c.id, c.title, c.competition_type, c.current_status,
        c.government_sphere AS competition_government_sphere,
        c.summary, c.total_vacancies, c.reserve_registration,
        c.salary_min, c.salary_max, c.registration_fee_min, c.registration_fee_max,
        c.official_url, c.last_official_update_at, c.last_validated_at,
        o.id AS organization_id, o.official_name AS organization_name,
        o.acronym AS organization_acronym, o.government_sphere, o.state_code,
        b.id AS exam_board_id, b.official_name AS exam_board_name,
        b.acronym AS exam_board_acronym,
        cc.id AS career_id, cc.name AS career_name
      FROM public_data.competitions c
      JOIN public_data.organizations o ON o.id = c.organization_id
      LEFT JOIN public_data.exam_boards b ON b.id = c.exam_board_id
      LEFT JOIN public_data.career_categories cc ON cc.id = c.career_category_id
      WHERE c.id = $1
        AND c.published_at IS NOT NULL
      LIMIT 1`,
      [id],
    );

    const row = result.rows[0];
    if (!row) return null;

    return {
      ...this.toSummary(row),
      competitionType: row.competition_type,
      governmentSphere: row.competition_government_sphere,
      summary: row.summary,
      career: row.career_id && row.career_name
        ? { id: row.career_id, name: row.career_name }
        : null,
      registrationFee: {
        min: row.registration_fee_min === null ? null : Number(row.registration_fee_min),
        max: row.registration_fee_max === null ? null : Number(row.registration_fee_max),
        currency: 'BRL',
      },
      officialUrl: row.official_url,
    };
  }

  private toSummary(row: CompetitionRow): CompetitionSummary {
    return {
      id: row.id,
      title: row.title,
      organization: {
        id: row.organization_id,
        officialName: row.organization_name,
        acronym: row.organization_acronym,
        governmentSphere: row.government_sphere,
        state: row.state_code,
      },
      examBoard: row.exam_board_id && row.exam_board_name
        ? {
            id: row.exam_board_id,
            officialName: row.exam_board_name,
            acronym: row.exam_board_acronym,
          }
        : null,
      currentStatus: row.current_status,
      totalVacancies: row.total_vacancies,
      reserveRegistration: row.reserve_registration,
      salary: {
        min: row.salary_min === null ? null : Number(row.salary_min),
        max: row.salary_max === null ? null : Number(row.salary_max),
        currency: 'BRL',
      },
      lastOfficialUpdateAt: row.last_official_update_at?.toISOString() ?? null,
      lastValidatedAt: row.last_validated_at?.toISOString() ?? null,
    };
  }
}
