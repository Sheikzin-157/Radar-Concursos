import type { Pool } from 'pg';
import { dispatchUpcomingReminders } from './reminder-dispatcher';

describe('reminder dispatcher safeguards', () => {
  const original = process.env.FCM_PROJECT_ID;

  afterEach(() => {
    if (original === undefined) delete process.env.FCM_PROJECT_ID;
    else process.env.FCM_PROJECT_ID = original;
  });

  it('supports dry-run without credentials or device deliveries', async () => {
    const query = jest.fn().mockResolvedValue({ rows: [
      { user_id: 'u1', event_id: 'e1', push_token: 'test-token' },
    ] });
    const result = await dispatchUpcomingReminders(
      { query } as unknown as Pool, { dryRun: true },
    );
    expect(result).toEqual({ eligible: 1, sent: 0, failed: 0 });
    expect(query).toHaveBeenCalledTimes(1);
    const sql = query.mock.calls[0][0] as string;
    expect(sql).toContain('p.notify_updates = true');
    expect(sql).toContain('d.enabled = true');
    expect(sql).toContain("l.delivery_type = 'reminder'");
    expect(sql).not.toContain("l.status IN ('pending', 'sent')");
  });

  it('rejects invalid batch sizes before querying', async () => {
    const query = jest.fn();
    for (const batchSize of [0, -1, 101, 1.5, Number.NaN]) {
      await expect(dispatchUpcomingReminders(
        { query } as unknown as Pool, { dryRun: true, batchSize },
      )).rejects.toThrow(RangeError);
    }
    expect(query).not.toHaveBeenCalled();
  });

  it('never calls the database for live sends without credentials', async () => {
    delete process.env.FCM_PROJECT_ID;
    const query = jest.fn();
    await expect(dispatchUpcomingReminders(
      { query } as unknown as Pool,
    )).rejects.toThrow('FCM credentials are not configured');
    expect(query).not.toHaveBeenCalled();
  });
});
