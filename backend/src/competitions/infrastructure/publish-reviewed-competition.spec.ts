import type { Pool } from 'pg';
import { publishReviewedCompetition } from './publish-reviewed-competition';

describe('reviewed competition publication', () => {
  const id = '11111111-1111-4111-8111-111111111111';

  it('never accesses the database with invalid authorization metadata', async () => {
    const connect = jest.fn();
    const pool = { connect } as unknown as Pool;
    await expect(publishReviewedCompetition(pool, 'invalid', 'operator'))
      .rejects.toThrow('Invalid intake ID');
    await expect(publishReviewedCompetition(pool, id, ' '))
      .rejects.toThrow('Reviewer identity is required');
    expect(connect).not.toHaveBeenCalled();
  });

  it('rolls back when no approved intake exists', async () => {
    const query = jest.fn()
      .mockResolvedValueOnce({})
      .mockResolvedValueOnce({ rows: [] })
      .mockResolvedValueOnce({});
    const release = jest.fn();
    const pool = { connect: jest.fn().mockResolvedValue({query,release}) } as unknown as Pool;
    await expect(publishReviewedCompetition(pool,id,'reviewer'))
      .rejects.toThrow('not approved');
    expect(query.mock.calls.map(args => args[0])).toEqual([
      'BEGIN', expect.stringContaining("review_status='approved'"), 'ROLLBACK',
    ]);
    expect(release).toHaveBeenCalledTimes(1);
  });

  it('publishes and audits approved intake within one transaction', async () => {
    const query = jest.fn()
      .mockResolvedValueOnce({})
      .mockResolvedValueOnce({rows:[{
        id, organization_name:'Órgão',title:'Concurso',official_url:'https://example.gov.br',
        status:'open',state_code:'CE',source_checked_at:new Date(),
      }]})
      .mockResolvedValueOnce({rows:[{id:'organization'}]})
      .mockResolvedValueOnce({rows:[]})
      .mockResolvedValueOnce({rows:[{id:'competition'}]})
      .mockResolvedValueOnce({})
      .mockResolvedValueOnce({})
      .mockResolvedValueOnce({});
    const release = jest.fn();
    const pool = { connect: jest.fn().mockResolvedValue({query,release}) } as unknown as Pool;
    await expect(publishReviewedCompetition(pool,id,'reviewer')).resolves.toBe('competition');
    expect(query.mock.calls.at(-1)?.[0]).toBe('COMMIT');
    expect(query.mock.calls.some(args=>String(args[0]).includes('competition_publication_audit'))).toBe(true);
    expect(release).toHaveBeenCalledTimes(1);
  });
});
