import { BadRequestException, Controller, Get, Inject, Query } from '@nestjs/common';
import type { Pool } from 'pg';
import { DATABASE_POOL } from '../../shared/infrastructure/database/database.module';

interface EventRow {
  id: string;
  competition_id: string;
  competition_title: string;
  event_type: string;
  title: string;
  starts_at: Date;
  ends_at: Date | null;
  official_url: string | null;
}

@Controller('competition-events')
export class CompetitionEventsController {
  constructor(@Inject(DATABASE_POOL) private readonly pool: Pool) {}

  @Get()
  async list(@Query('from') from?: string, @Query('to') to?: string) {
    const start = from ? new Date(from) : new Date();
    const end = to ? new Date(to) : new Date(start.getTime() + 90 * 86400000);
    if (
      !Number.isFinite(start.getTime()) ||
      !Number.isFinite(end.getTime()) ||
      end.getTime() <= start.getTime() ||
      end.getTime() - start.getTime() > 366 * 86400000
    ) {
      throw new BadRequestException({
        code: 'INVALID_DATE_RANGE',
        message: 'Intervalo de datas inválido.',
      });
    }

    const result = await this.pool.query<EventRow>(
      `SELECT e.id, e.competition_id, c.title AS competition_title,
         e.event_type, e.title, e.starts_at, e.ends_at, e.official_url
       FROM public_data.competition_events e
       JOIN public_data.competitions c ON c.id = e.competition_id
       WHERE c.published_at IS NOT NULL
         AND e.starts_at >= $1 AND e.starts_at < $2
       ORDER BY e.starts_at ASC, e.id ASC
       LIMIT 200`,
      [start, end],
    );
    return {
      items: result.rows.map((row) => ({
        id: row.id,
        competitionId: row.competition_id,
        competitionTitle: row.competition_title,
        eventType: row.event_type,
        title: row.title,
        startsAt: row.starts_at.toISOString(),
        endsAt: row.ends_at?.toISOString() ?? null,
        officialUrl: row.official_url,
      })),
    };
  }
}
