import { BadRequestException } from '@nestjs/common';
import type { Pool } from 'pg';
import { CompetitionEventsController } from './competition-events.controller';

describe('CompetitionEventsController', () => {
  const query = jest.fn().mockResolvedValue({ rows: [] });
  const controller = new CompetitionEventsController({ query } as unknown as Pool);

  beforeEach(() => query.mockClear());

  it('lists only events of published competitions within a bounded interval', async () => {
    const result = await controller.list('2026-11-01', '2026-12-01');
    expect(result.items).toEqual([]);
    const [sql, params] = query.mock.calls[0] as [string, Date[]];
    expect(sql).toContain('c.published_at IS NOT NULL');
    expect(sql).toContain('e.starts_at >= $1');
    expect(sql).toContain('e.starts_at < $2');
    expect(params[0].toISOString()).toBe('2026-11-01T00:00:00.000Z');
  });

  it('rejects invalid and excessively long ranges', async () => {
    await expect(controller.list('not-a-date', '2026-11-02'))
      .rejects.toBeInstanceOf(BadRequestException);
    await expect(controller.list('2026-11-01', '2028-12-01'))
      .rejects.toBeInstanceOf(BadRequestException);
    expect(query).not.toHaveBeenCalled();
  });
});
