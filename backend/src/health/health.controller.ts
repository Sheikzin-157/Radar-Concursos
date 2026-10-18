import { Controller, Get, Inject, ServiceUnavailableException } from '@nestjs/common';
import type { Pool } from 'pg';
import { DATABASE_POOL } from '../shared/infrastructure/database/database.module';

@Controller('health')
export class HealthController {
  constructor(@Inject(DATABASE_POOL) private readonly pool: Pool) {}

  @Get()
  getHealth(): { status: 'ok' } {
    return { status: 'ok' };
  }

  /** End-to-end readiness: the database and published catalog must be queryable. */
  @Get('ready')
  async getReadiness(): Promise<{ status: 'ready'; database: 'ok'; catalog: 'ok' }> {
    try {
      await this.pool.query('SELECT id FROM public_data.competitions LIMIT 1');
      return { status: 'ready', database: 'ok', catalog: 'ok' };
    } catch {
      throw new ServiceUnavailableException({
        code: 'SERVICE_NOT_READY',
        message: 'Banco de dados ou catálogo indisponível.',
      });
    }
  }
}
