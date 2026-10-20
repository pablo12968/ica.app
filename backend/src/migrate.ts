import { readFile } from 'node:fs/promises';
import path from 'node:path';
import pool from './config/database';
async function migrate() {
  try {
    await pool.query(await readFile(path.resolve(__dirname, '../schema.sql'), 'utf8'));
    console.log('Esquema y catálogo preparados.');
  } finally { await pool.end(); }
}
migrate().catch(() => { console.error('No se pudo preparar PostgreSQL. Revisa la configuración.'); process.exitCode = 1; });
