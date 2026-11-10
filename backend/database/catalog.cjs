const fs = require('node:fs/promises');
const path = require('node:path');
const snapshotPath = path.join(__dirname, 'catalog.json');

function validate(rows) {
  if (!Array.isArray(rows) || !rows.length) throw new Error('El catálogo está vacío o no es una lista.');
  const ids = new Set();
  for (const r of rows) {
    if (!Number.isSafeInteger(r.id) || r.id < 1 || ids.has(r.id) ||
      typeof r.name !== 'string' || !r.name.trim() ||
      typeof r.description !== 'string' || typeof r.category !== 'string' ||
      typeof r.available !== 'boolean' || !/^\d{1,10}(\.\d{1,2})?$/.test(String(r.base_price))) {
      throw new Error('Producto inválido o identificador repetido. No se importó el catálogo.');
    }
    ids.add(r.id);
  }
}

async function importCatalog(client, rows) {
  validate(rows);
  await client.query('BEGIN');
  try {
    for (const r of rows) {
      await client.query(`INSERT INTO products(id,name,description,category,base_price,available)
        VALUES($1,$2,$3,$4,$5,$6) ON CONFLICT(id) DO UPDATE SET
        name=EXCLUDED.name,description=EXCLUDED.description,category=EXCLUDED.category,
        base_price=EXCLUDED.base_price,available=EXCLUDED.available`,
      [r.id,r.name,r.description,r.category,r.base_price,r.available]);
    }
    await client.query("SELECT setval(pg_get_serial_sequence('products','id'), (SELECT MAX(id) FROM products), true)");
    await client.query('COMMIT');
  } catch (error) { await client.query('ROLLBACK'); throw error; }
}

async function main() {
  const mode = process.argv[2];
  if (mode !== 'export' && !(mode === 'import' && process.argv[3] === '--apply')) {
    throw new Error('Uso: npm run db:catalog:export | npm run db:catalog:import -- --apply');
  }
  const pool = require('../dist/config/database').default;
  try {
    if (mode === 'export') {
      // Explicit public catalogue fields only; never export users, orders or sessions.
      const result = await pool.query('SELECT id,name,description,category,base_price,available FROM products ORDER BY id');
      validate(result.rows);
      await fs.writeFile(snapshotPath, JSON.stringify(result.rows, null, 2) + '\n', 'utf8');
      console.log(`Catálogo exportado: ${result.rows.length} productos.`);
    } else {
      const rows = JSON.parse(await fs.readFile(snapshotPath, 'utf8'));
      const client = await pool.connect();
      try { await importCatalog(client, rows); } finally { client.release(); }
      console.log(`Catálogo importado: ${rows.length} productos. Usuarios y pedidos conservados.`);
    }
  } finally { await pool.end(); }
}
module.exports = { importCatalog, validate };
if (require.main === module) main().catch(e => { console.error(e.message); process.exitCode = 1; });
