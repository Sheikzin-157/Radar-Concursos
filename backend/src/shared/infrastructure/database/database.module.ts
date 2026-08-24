import { Global, Module } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { Pool } from 'pg';

export const DATABASE_POOL = Symbol('DATABASE_POOL');

@Global()
@Module({
  providers: [
    {
      provide: DATABASE_POOL,
      inject: [ConfigService],
      useFactory: (config: ConfigService) => {
        const connectionString = config.get<string>('DATABASE_URL');
        if (!connectionString) {
          throw new Error('DATABASE_URL is required');
        }

        return new Pool({
          connectionString,
          ssl: config.get<string>('DATABASE_SSL') === 'true'
            ? { rejectUnauthorized: false }
            : undefined,
          max: 10,
        });
      },
    },
  ],
  exports: [DATABASE_POOL],
})
export class DatabaseModule {}
