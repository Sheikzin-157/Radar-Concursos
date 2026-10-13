import type { Pool } from 'pg';
import { stageOfficialCompetition } from './stage-official-competition';

describe('stage official competition', () => {
  const draft = {
    organizationName: 'Órgão de teste',
    title: 'Concurso público de teste',
    officialUrl: 'https://example.gov.br/edital',
    status: 'open',
    stateCode: 'CE',
    sourceCheckedAt: '2026-10-11T12:00:00Z',
  };

  it('stages records without publishing and passes parametrized values', async () => {
    const row = { id: 'test-id', review_status: 'pending' };
    const query = jest.fn().mockResolvedValue({ rows: [row] });
    const result = await stageOfficialCompetition({ query } as unknown as Pool, draft);
    expect(result).toBe(row);
    const [sql, values] = query.mock.calls[0] as [string, unknown[]];
    expect(sql).toContain('public_data.competition_intake');
    expect(sql).toContain("review_status = 'pending'");
    expect(sql).toContain('reviewed_at = NULL');
    expect(sql).toContain('reviewed_by = NULL');
    expect(sql).not.toContain('public_data.competitions ');
    expect(values).toContain(draft.officialUrl);
  });

  it('rejects invalid records before touching the database', async () => {
    const query = jest.fn();
    await expect(stageOfficialCompetition(
      { query } as unknown as Pool, { ...draft, officialUrl: 'http://example.org' },
    )).rejects.toThrow();
    expect(query).not.toHaveBeenCalled();
  });
});
