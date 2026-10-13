import { ServiceUnavailableException } from '@nestjs/common';
import type { Pool } from 'pg';
import { HealthController } from './health.controller';

describe('HealthController readiness', () => {
  it('checks the real public catalog table, not only process uptime', async () => {
    const query = jest.fn().mockResolvedValue({ rows: [] });
    const health = new HealthController({ query } as unknown as Pool);
    expect(health.getHealth()).toEqual({ status: 'ok' });
    await expect(health.getReadiness()).resolves.toEqual({
      status: 'ready', database: 'ok', catalog: 'ok',
    });
    expect(query).toHaveBeenCalledWith('SELECT id FROM public_data.competitions LIMIT 1');
  });

  it('reports unavailable when schema or database cannot be queried', async () => {
    const query = jest.fn().mockRejectedValue(new Error('database unavailable'));
    const health = new HealthController({ query } as unknown as Pool);
    await expect(health.getReadiness()).rejects.toBeInstanceOf(ServiceUnavailableException);
  });
});
