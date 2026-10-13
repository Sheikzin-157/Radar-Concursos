import { Pool } from 'pg';
import { listPendingIntake, reviewCompetitionIntake } from './review-competition-intake';
import { publishReviewedCompetition } from './publish-reviewed-competition';

const HELP = 'Usage: npm run catalog:admin -- <list|approve|reject|publish> [intake-uuid]';
async function main(): Promise<void> {
  if (process.env.ENABLE_CATALOG_ADMIN !== 'true') {
    throw new Error('Catalog administration disabled. Set ENABLE_CATALOG_ADMIN=true explicitly.');
  }
  const reviewer = process.env.CATALOG_REVIEWER?.trim();
  if (!reviewer) throw new Error('CATALOG_REVIEWER is required');
  if (!process.env.DATABASE_URL) throw new Error('DATABASE_URL is required');
  const [action, id] = process.argv.slice(2);
  if (!['list','approve','reject','publish'].includes(action) || (action !== 'list' && !id)) {
    throw new Error(HELP);
  }
  const pool = new Pool({
    connectionString: process.env.DATABASE_URL,
    ssl: process.env.DATABASE_SSL === 'true' ? { rejectUnauthorized: false } : undefined,
    max: 2,
  });
  try {
    switch (action) {
      case 'list': {
        const results = await listPendingIntake(pool);
        process.stdout.write(JSON.stringify(results) + '\n');
        break;
      }
      case 'approve':
      case 'reject': {
        const changed = await reviewCompetitionIntake(
          pool, id, action === 'approve' ? 'approved' : 'rejected', reviewer,
        );
        if (!changed) throw new Error('No pending review found for the given ID');
        process.stdout.write('Review decision saved\n');
        break;
      }
      case 'publish': {
        if (process.env.CONFIRM_CATALOG_PUBLICATION !== 'true') {
          throw new Error('Publication requires CONFIRM_CATALOG_PUBLICATION=true');
        }
        const competitionId = await publishReviewedCompetition(pool, id, reviewer);
        process.stdout.write(JSON.stringify({ competitionId }) + '\n');
        break;
      }
    }
  } finally {
    await pool.end();
  }
}
void main().catch((error: unknown) => {
  process.stderr.write((error instanceof Error ? error.message : 'Admin operation failed') + '\n');
  process.exitCode = 1;
});
