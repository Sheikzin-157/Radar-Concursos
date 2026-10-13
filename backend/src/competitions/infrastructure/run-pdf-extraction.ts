import { Pool } from 'pg';
import { extractOfficialPdf } from './extract-official-pdf';

async function main(): Promise<void> {
  const source = process.env.OFFICIAL_PDF_URL;
  if (!source || source !== process.env.OFFICIAL_PDF_ALLOWLIST_URL) {
    throw new Error('PDF URL must match the operator allowlist exactly');
  }
  const dryRun = process.argv.includes('--dry-run');
  if (!dryRun && process.env.ENABLE_PDF_STAGING !== 'true') {
    throw new Error('PDF evidence writes are disabled by default');
  }
  const title = process.env.OFFICIAL_PDF_TITLE;
  if (!title) throw new Error('OFFICIAL_PDF_TITLE is required');
  if (!process.env.DATABASE_URL) throw new Error('DATABASE_URL is required');
  const pool = new Pool({
    connectionString: process.env.DATABASE_URL,
    ssl: process.env.DATABASE_SSL === 'true' ? {rejectUnauthorized:false} : undefined,
    max: 2,
  });
  try {
    const result = await extractOfficialPdf(pool,source,title,{dryRun});
    process.stdout.write(JSON.stringify(result) + '\n');
  } finally {
    await pool.end();
  }
}
void main().catch((error: unknown) => {
  process.stderr.write((error instanceof Error ? error.message : 'PDF extraction failed') + '\n');
  process.exitCode = 1;
});
