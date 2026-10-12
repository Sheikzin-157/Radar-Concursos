import { Pool } from 'pg';
import { collectOfficialSource } from './collect-official-source';

async function main(): Promise<void> {
  const dryRun = process.argv.includes('--dry-run');
  if (!dryRun && process.env.ENABLE_OFFICIAL_SOURCE_INTAKE !== 'true') {
    throw new Error('Intake writes disabled. Explicitly enable ENABLE_OFFICIAL_SOURCE_INTAKE=true.');
  }
  const sourceUrl = process.env.OFFICIAL_SOURCE_URL;
  const allowedUrl = process.env.OFFICIAL_SOURCE_ALLOWLIST_URL;
  if (!sourceUrl || !allowedUrl || sourceUrl !== allowedUrl) {
    throw new Error('Source must exactly match OFFICIAL_SOURCE_ALLOWLIST_URL.');
  }
  const organizationName = process.env.OFFICIAL_SOURCE_ORGANIZATION;
  const stateCode = process.env.OFFICIAL_SOURCE_STATE;
  const status = process.env.OFFICIAL_SOURCE_STATUS;
  if (!organizationName || !stateCode || !status) {
    throw new Error('Source organization, state and status must be configured.');
  }
  if (!process.env.DATABASE_URL) throw new Error('DATABASE_URL is required');
  const pool = new Pool({
    connectionString: process.env.DATABASE_URL,
    ssl: process.env.DATABASE_SSL === 'true' ? { rejectUnauthorized: false } : undefined,
    max: 2,
  });
  try {
    const result = await collectOfficialSource(pool, {
      name: organizationName, url: sourceUrl, organizationName, stateCode, status,
    }, {dryRun});
    process.stdout.write(JSON.stringify(result) + '\n');
  } finally {
    await pool.end();
  }
}

void main().catch((error: unknown) => {
  process.stderr.write((error instanceof Error ? error.message : 'Source ingestion failed') + '\n');
  process.exitCode = 1;
});
