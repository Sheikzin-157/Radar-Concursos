import type { Pool } from 'pg';
import { listPendingIntake, reviewCompetitionIntake } from './review-competition-intake';

describe('catalog moderation', () => {
  const id = '11111111-1111-4111-8111-111111111111';

  it('allows only valid decisions and reviewer identifiers', async () => {
    const query = jest.fn();
    const pool = { query } as unknown as Pool;
    await expect(reviewCompetitionIntake(pool, id, 'other' as never, 'admin')).rejects.toThrow();
    await expect(reviewCompetitionIntake(pool, id, 'approved', ' ')).rejects.toThrow();
    await expect(reviewCompetitionIntake(pool, 'bad', 'approved', 'admin')).rejects.toThrow();
    expect(query).not.toHaveBeenCalled();
  });

  it('only reviews pending submissions', async () => {
    const query = jest.fn().mockResolvedValue({rowCount: 1});
    const changed = await reviewCompetitionIntake(
      {query} as unknown as Pool, id, 'approved', 'admin',
    );
    expect(changed).toBe(true);
    expect(query.mock.calls[0][0]).toContain("review_status='pending'");
    expect(query.mock.calls[0][1]).toEqual([id,'approved']);
  });

  it('bounds pending queue and does not expose unreviewed entries publicly', async () => {
    const query = jest.fn().mockResolvedValue({rows:[]});
    const pool = {query} as unknown as Pool;
    await expect(listPendingIntake(pool,101)).rejects.toThrow(RangeError);
    await expect(listPendingIntake(pool,25)).resolves.toEqual([]);
    expect(query.mock.calls[0][0]).toContain("review_status='pending'");
    expect(query.mock.calls[0][1]).toEqual([25]);
  });
});
