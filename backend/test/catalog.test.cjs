const { test } = require('node:test');
const assert = require('node:assert/strict');
const { randomUUID } = require('node:crypto');
const { readFileSync } = require('node:fs');
const path = require('node:path');
const { validate, importCatalog } = require('../database/catalog.cjs');
const snapshot = require('../database/catalog.json');

test('catálogo válido y rechazo de IDs repetidos o precios inválidos', () => {
  validate(snapshot);
  assert.throws(() => validate([]));
  assert.throws(() => validate([snapshot[0], snapshot[0]]));
  assert.throws(() => validate([{ ...snapshot[0], base_price: '-1' }]));
  assert.throws(() => validate([{ ...snapshot[0], base_price: '0; DELETE FROM products' }]));
});

test('restauración repetible del catálogo en PostgreSQL aislado', { skip: process.env.TEST_DATABASE !== '1' }, async () => {
  const pool = require('../dist/config/database').default;
  const client = await pool.connect();
  const schema = 'ica_catalog_test_' + randomUUID().replaceAll('-', '');
  try {
    await client.query(`CREATE SCHEMA ${schema}`);
    await client.query(`SET search_path TO ${schema}`);
    await client.query(readFileSync(path.resolve(__dirname, '../schema.sql'), 'utf8'));
    await importCatalog(client, snapshot);
    await importCatalog(client, snapshot);
    const result = await client.query('SELECT id,name,description,category,base_price,available FROM products ORDER BY id');
    assert.deepEqual(result.rows, snapshot);
    assert.equal((await client.query('SELECT * FROM ica_users')).rowCount, 0);
    assert.equal((await client.query('SELECT * FROM ica_orders')).rowCount, 0);
    const next = await client.query("INSERT INTO products(name,base_price) VALUES('Producto de prueba',1000) RETURNING id");
    assert.ok(next.rows[0].id > Math.max(...snapshot.map(r => r.id)));
  } finally {
    await client.query('ROLLBACK');
    await client.query('SET search_path TO public');
    await client.query(`DROP SCHEMA IF EXISTS ${schema} CASCADE`);
    client.release();
    await pool.end();
  }
});
