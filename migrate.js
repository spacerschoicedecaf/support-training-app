#!/usr/bin/env node

/**
 * STURNUS migration runner
 *
 * Usage:
 *   node migrate.js            — apply any pending migrations
 *   node migrate.js --baseline — mark all migrations as applied without running them
 *                                (use once on an existing DB to initialize tracking)
 *   node migrate.js --status   — show which migrations have and haven't been applied
 *
 * Requires DATABASE_URL in .env or environment.
 */

import { readdir, readFile } from 'fs/promises';
import { join, dirname } from 'path';
import { fileURLToPath } from 'url';
import pg from 'pg';

const __dirname = dirname(fileURLToPath(import.meta.url));

// Load .env manually (no dotenv dependency needed)
try {
  const env = await readFile(join(__dirname, '.env'), 'utf8');
  for (const line of env.split('\n')) {
    const [key, ...rest] = line.split('=');
    if (key && rest.length && !key.startsWith('#')) {
      process.env[key.trim()] ??= rest.join('=').trim();
    }
  }
} catch {
  // .env is optional — DATABASE_URL can come from the environment directly
}

const DATABASE_URL = process.env.DATABASE_URL;
if (!DATABASE_URL) {
  console.error('ERROR: DATABASE_URL is not set. Add it to your .env file.');
  console.error('Find it in Supabase → Settings → Database → Connection string → URI');
  process.exit(1);
}

const MIGRATIONS_DIR = join(__dirname, 'migrations');
const mode = process.argv[2]; // --baseline | --status | undefined

const client = new pg.Client({ connectionString: DATABASE_URL, ssl: { rejectUnauthorized: false } });
await client.connect();

// Ensure tracking table exists
await client.query(`
  CREATE TABLE IF NOT EXISTS schema_migrations (
    filename   text        PRIMARY KEY,
    applied_at timestamptz NOT NULL DEFAULT now()
  );
`);

// Load migration files in order
const files = (await readdir(MIGRATIONS_DIR))
  .filter(f => f.endsWith('.sql'))
  .sort();

// Load already-applied set
const { rows } = await client.query('SELECT filename FROM schema_migrations');
const applied = new Set(rows.map(r => r.filename));

// ── Status mode ────────────────────────────────────────────────────────────────
if (mode === '--status') {
  console.log('\nMigration status:\n');
  for (const file of files) {
    const mark = applied.has(file) ? '✓' : '○';
    console.log(`  ${mark}  ${file}`);
  }
  console.log();
  await client.end();
  process.exit(0);
}

// ── Baseline mode ──────────────────────────────────────────────────────────────
if (mode === '--baseline') {
  console.log('\nBaselining — marking all migrations as applied without running them:\n');
  for (const file of files) {
    if (applied.has(file)) {
      console.log(`  already recorded  ${file}`);
    } else {
      await client.query(
        'INSERT INTO schema_migrations (filename) VALUES ($1) ON CONFLICT DO NOTHING',
        [file]
      );
      console.log(`  baselined         ${file}`);
    }
  }
  console.log('\nDone. Future migrations will be applied normally.\n');
  await client.end();
  process.exit(0);
}

// ── Normal mode ────────────────────────────────────────────────────────────────
const pending = files.filter(f => !applied.has(f));

if (pending.length === 0) {
  console.log('\nAll migrations are up to date.\n');
  await client.end();
  process.exit(0);
}

console.log(`\nApplying ${pending.length} pending migration(s):\n`);

for (const file of pending) {
  const sql = await readFile(join(MIGRATIONS_DIR, file), 'utf8');
  try {
    await client.query('BEGIN');
    await client.query(sql);
    await client.query(
      'INSERT INTO schema_migrations (filename) VALUES ($1)',
      [file]
    );
    await client.query('COMMIT');
    console.log(`  ✓  ${file}`);
  } catch (err) {
    await client.query('ROLLBACK');
    console.error(`  ✗  ${file}`);
    console.error(`     ${err.message}`);
    console.error('\nMigration failed. All subsequent migrations were skipped.');
    await client.end();
    process.exit(1);
  }
}

console.log('\nDone.\n');
await client.end();
