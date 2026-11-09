const { test } = require('node:test');
const assert = require('node:assert/strict');
const { randomUUID } = require('node:crypto');
const { readFileSync } = require('node:fs');
const path = require('node:path');

test('hash de contraseña con sal y comprobación', async () => {
  const { hashPassword, checkPassword } = require('../dist/auth');
  const first = await hashPassword('una-clave-larga');
  const second = await hashPassword('una-clave-larga');
  assert.notEqual(first, second);
  assert.equal(await checkPassword('una-clave-larga', first), true);
  assert.equal(await checkPassword('otra-clave-larga', first), false);
});

test('cuentas, aislamiento, pedidos idempotentes, auditoría y administración en PostgreSQL', { skip: process.env.TEST_DATABASE !== '1' }, async () => {
  // Dedicated random schema; does not alter the owner's tables or catalogue.
  const schema = 'ica_test_' + randomUUID().replaceAll('-', '');
  const pool = require('../dist/config/database').default;
  // All connections in this test use the isolated search path.
  pool.options.options = `-c search_path=${schema}`;
  let server;
  try {
    await pool.query(`CREATE SCHEMA ${schema}`);
    await pool.query(readFileSync(path.resolve(__dirname, '../schema.sql'), 'utf8'));
    await pool.query(readFileSync(path.resolve(__dirname, '../schema.sql'), 'utf8'));
    const app = require('../dist/app').default;
    server = app.listen(0, '127.0.0.1');
    await new Promise(resolve => server.once('listening', resolve));
    const base = `http://127.0.0.1:${server.address().port}/api`;
    const call = async (route, body, token, key) => {
      const response = await fetch(base + route, { method: body === undefined ? 'GET' : 'POST',
        headers: { 'Content-Type': 'application/json', ...(token ? { Authorization: `Bearer ${token}` } : {}), ...(key ? { 'Idempotency-Key': key } : {}) },
        body: body === undefined ? undefined : JSON.stringify(body) });
      return { status: response.status, data: await response.json().catch(() => null) };
    };
    assert.equal((await call('/orders')).status, 401);
    assert.equal((await call('/auth/register', { name: 'Ana', email: 'bad', password: 'short' })).status, 400);
    const credentials = { name: 'Ana', email: 'ANA@example.test', password: 'password-test-123' };
    const a = await call('/auth/register', { ...credentials, role: 'admin' });
    assert.equal(a.status, 201); assert.equal(a.data.user.role, 'customer');
    assert.equal(a.data.user.email, 'ana@example.test'); assert.equal(a.data.user.password_hash, undefined);
    const b = await call('/auth/register', { ...credentials, name: 'Bea', email: 'bea@example.test' });
    assert.equal(b.status, 201);
    assert.equal((await call('/auth/register', credentials)).status, 409);
    assert.equal((await call('/auth/login', { ...credentials, password: 'wrong-password' })).status, 401);
    assert.equal((await call('/auth/login', credentials)).status, 200);
    assert.equal((await call('/admin/users', undefined, a.data.token)).status, 403);
    const body = { customer: 'Forged identity', expectedTotal: 250000, items: [{ productId: 1, quantity: 1, size: 'Una bola', toppings: [] }] };
    const first = await call('/orders', body, a.data.token, 'order-test-0001');
    assert.equal(first.status, 201); assert.equal(first.data.customer, 'Ana');
    const repeat = await call('/orders', body, a.data.token, 'order-test-0001');
    assert.equal(repeat.status, 200); assert.equal(repeat.data.id, first.data.id);
    assert.equal((await call('/orders', body, b.data.token, 'order-test-0001')).status, 409);
    assert.equal((await call('/orders', { ...body, expectedTotal: 1 }, a.data.token, 'order-test-0002')).status, 400);
    assert.equal((await call('/orders', undefined, a.data.token)).data.length, 1);
    assert.deepEqual((await call('/orders', undefined, b.data.token)).data, []);
    await pool.query("UPDATE ica_users SET role='admin' WHERE id=$1", [a.data.user.id]);
    const users = await call('/admin/users', undefined, a.data.token);
    assert.equal(users.status, 200); assert.equal(users.data.rows.length, 2);
    assert.equal(JSON.stringify(users.data).includes('password'), false);
    assert.equal((await call('/admin/orders', undefined, a.data.token)).data.rows.length, 1);
    const activity = (await call('/admin/activity', undefined, a.data.token)).data.rows;
    assert.equal(activity.filter(e => e.event === 'order_created').length, 1);
    assert.equal(activity.filter(e => e.event === 'account_registered').length, 2);
    assert.equal((await call('/activity', { event: 'order_created' }, b.data.token)).status, 400);
    assert.equal((await call('/auth/logout', {}, b.data.token)).status, 204);
    assert.equal((await call('/orders', undefined, b.data.token)).status, 401);
    await pool.query('UPDATE ica_sessions SET expires_at=NOW()-INTERVAL \'1 second\'');
    assert.equal((await call('/orders', undefined, a.data.token)).status, 401);
  } finally {
    if (server) await new Promise(resolve => server.close(resolve));
    await pool.query(`DROP SCHEMA IF EXISTS ${schema} CASCADE`);
    await pool.end();
  }
});
