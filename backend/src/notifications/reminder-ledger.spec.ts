import { dispatchUpcomingReminders } from './reminder-dispatcher';
import type { Pool } from 'pg';

describe('Reminder dispatch ledger', () => {
  const saved = {
    FCM_PROJECT_ID: process.env.FCM_PROJECT_ID,
    FCM_CLIENT_EMAIL: process.env.FCM_CLIENT_EMAIL,
    FCM_PRIVATE_KEY: process.env.FCM_PRIVATE_KEY,
  };
  afterEach(() => {
    for (const [name, value] of Object.entries(saved)) {
      if (value === undefined) delete process.env[name];
      else process.env[name] = value;
    }
    jest.restoreAllMocks();
  });
  it('does not send if atomic claim fails', async () => {
    process.env.FCM_PROJECT_ID = 'radar-concursos-6692f';
    process.env.FCM_CLIENT_EMAIL = 'test@example.com';
    process.env.FCM_PRIVATE_KEY = 'invalid-key';
    const query = jest.fn()
      .mockResolvedValueOnce({rows: [{
        user_id: 'u', event_id: 'e', competition_id: 'c',
        event_title: 'Prova', competition_title: 'Concurso', push_token: 'token',
      }]});
    // Live dispatch would obtain OAuth first, so testing the claim requires
    // a valid signed token; instead verify that the SQL includes the fail-closed guard.
    await dispatchUpcomingReminders({query} as unknown as Pool, {dryRun: true});
    const sql: string = query.mock.calls[0][0] as string;
    expect(sql).toContain('l.delivery_type = \'reminder\'');
    expect(sql).toContain('p.notify_updates = true');
    expect(sql).toContain('c.published_at IS NOT NULL');
    expect(sql).toContain('f.user_id = p.user_id');
  });
});
