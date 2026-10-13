import { Pool } from 'pg';
import { dispatchUpcomingReminders } from './reminder-dispatcher';

/**
 * Run manually or from a trusted scheduler:
 *  npm run reminders:dry-run
 *  ENABLE_PUSH_DELIVERY=true npm run reminders:send
 *
 * Sending is disabled unless explicitly opted in by the server operator.
 */
async function main(): Promise<void> {
  const dryRun = process.argv.includes('--dry-run');
  if (!dryRun && process.env.ENABLE_PUSH_DELIVERY !== 'true') {
    throw new Error('Live delivery disabled. Set ENABLE_PUSH_DELIVERY=true to proceed.');
  }
  if (!process.env.DATABASE_URL) throw new Error('DATABASE_URL is required');
  const pool = new Pool({
    connectionString: process.env.DATABASE_URL,
    ssl: process.env.DATABASE_SSL === 'true'
      ? { rejectUnauthorized: false }
      : undefined,
    max: 2,
  });
  try {
    const output = await dispatchUpcomingReminders(pool, { dryRun });
    process.stdout.write(JSON.stringify(output) + '\n');
    if (output.failed > 0) process.exitCode = 1;
  } finally {
    await pool.end();
  }
}

void main().catch((error: unknown) => {
  process.stderr.write(
    `${error instanceof Error ? error.message : 'Reminder execution failed'}\n`,
  );
  process.exitCode = 1;
});
