import { PostgresCompetitionRepository } from './postgres-competition.repository';
import type { Pool } from 'pg';

describe('PostgresCompetitionRepository search', () => {
  it('searches published competitions using bound SQL parameters', async () => {
    const query = jest.fn().mockResolvedValue({ rows: [] });
    const repository = new PostgresCompetitionRepository(
      { query } as unknown as Pool,
    );

    await repository.listPublic({
      search: 'Tribunal',
      state: 'pi',
      limit: 20,
    });

    const [sql, values] = query.mock.calls[0] as [string, unknown[]];
    expect(sql).toContain('c.published_at IS NOT NULL');
    expect(sql).toContain('c.title ILIKE $1');
    expect(sql).toContain('o.official_name ILIKE $1');
    expect(sql).toContain('o.acronym ILIKE $1');
    expect(sql).toContain('o.state_code = $2');
    expect(sql).toContain('LIMIT $3');
    expect(values).toEqual(['%Tribunal%', 'PI', 20]);
    expect(sql).not.toContain('Tribunal');
  });
});
