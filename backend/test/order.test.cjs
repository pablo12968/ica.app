const { strict: assert } = require('node:assert');
const { test } = require('node:test');
const { validateOrder, priceOrder } = require('../dist/order.js');
const input = () => ({ customer: ' Ana ', expectedTotal: 800000, items: [{ productId: 1, quantity: 2, size: 'Dos bolas', topping: 'Chocolate' }] });
test('recalcula con precios del servidor y extras', () => {
  const order = validateOrder(input());
  const lines = priceOrder(order.items, [{ id: 1, name: 'Fresa', price: 2500 }]);
  assert.equal(order.customer, 'Ana');
  assert.equal(lines[0].unitPrice * lines[0].quantity, 800000);
});
test('rechaza carrito vacío, cantidades inválidas y extras desconocidos', () => {
  assert.throws(() => validateOrder({ ...input(), items: [] }));
  for (const quantity of [-1, 0, 1.5, 21, '2']) assert.throws(() => validateOrder({ ...input(), items: [{ ...input().items[0], quantity }] }));
  assert.throws(() => validateOrder({ ...input(), items: [{ ...input().items[0], topping: '__proto__' }] }));
  assert.throws(() => validateOrder({ ...input(), expectedTotal: -1 }));
});
test('rechaza productos no disponibles y precios corruptos', () => {
  assert.throws(() => priceOrder(validateOrder(input()).items, []));
  assert.throws(() => priceOrder(validateOrder(input()).items, [{ id: 1, name: 'Fresa', price: 'NaN' }]));
});
test('ignora precios manipulados por el cliente', () => {
  const payload = { ...input(), items: [{ ...input().items[0], unitPrice: 1 }] };
  assert.equal(priceOrder(validateOrder(payload).items, [{ id: 1, name: 'Fresa', price: 2500 }])[0].unitPrice, 400000);
});
test('API responde y rechaza JSON o pedidos inválidos sin tocar la base de datos', async () => {
  const app = require('../dist/app.js').default;
  const server = app.listen(0, '127.0.0.1');
  await new Promise(resolve => server.once('listening', resolve));
  const url = `http://127.0.0.1:${server.address().port}`;
  try {
    assert.equal((await fetch(url)).status, 200);
    assert.equal((await fetch(`${url}/no-existe`)).status, 404);
    assert.equal((await fetch(`${url}/api/orders`, { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: '{' })).status, 400);
    assert.equal((await fetch(`${url}/api/orders`, { method: 'POST', headers: { 'Content-Type': 'application/json', 'Idempotency-Key': 'test-order-0001' }, body: JSON.stringify({ ...input(), items: [] }) })).status, 400);
    assert.equal((await fetch(`${url}/api/orders`, { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify(input()) })).status, 400);
  } finally { await new Promise(resolve => server.close(resolve)); }
});



