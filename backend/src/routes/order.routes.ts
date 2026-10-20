import { Router } from 'express';
import { createHash, randomUUID } from 'node:crypto';
import pool from '../config/database';
import { priceOrder, validateOrder, ValidationError } from '../order';
const router = Router();
router.post('/', async (req, res) => {
  const key = req.get('Idempotency-Key');
  if (!key || !/^[a-zA-Z0-9-]{8,100}$/.test(key)) { res.status(400).json({ message: 'Falta una referencia válida de pedido.' }); return; }
  let input;
  try { input = validateOrder(req.body); } catch (error) { res.status(400).json({ message: (error as Error).message }); return; }
  const hash = createHash('sha256').update(JSON.stringify(input)).digest('hex');
  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    // Serializa los reintentos con la misma clave, incluso entre varias instancias.
    await client.query('SELECT pg_advisory_xact_lock(hashtextextended($1, 0))', [key]);
    const previous = await client.query('SELECT request_hash, payload FROM ica_orders WHERE request_key=$1', [key]);
    if (previous.rowCount) {
      await client.query('COMMIT');
      if (previous.rows[0].request_hash !== hash) { res.status(409).json({ message: 'La referencia pertenece a otro pedido.' }); return; }
      res.status(200).json(previous.rows[0].payload); return;
    }
    const products = await client.query('SELECT id, name, base_price AS price FROM products WHERE available=TRUE AND id=ANY($1::int[]) FOR SHARE', [input.items.map(i => i.productId)]);
    const items = priceOrder(input.items, products.rows);
    const total = items.reduce((sum, item) => sum + item.unitPrice * item.quantity, 0);
    if (total !== input.expectedTotal) throw new ValidationError('El precio cambió. Actualiza el catálogo y revisa tu carrito.');
    const order = { id: randomUUID(), createdAt: new Date().toISOString(), customer: input.customer, note: input.note, status: 'Recibido', total, items };
    await client.query('INSERT INTO ica_orders(id, request_key, request_hash, payload) VALUES($1,$2,$3,$4)', [order.id, key, hash, JSON.stringify(order)]);
    await client.query('COMMIT');
    res.status(201).json(order);
  } catch (error) {
    await client.query('ROLLBACK');
    if (error instanceof ValidationError) res.status(400).json({ message: error.message });
    else { console.error('No se pudo guardar el pedido'); res.status(503).json({ message: 'No se pudo guardar el pedido. Reintenta con la misma referencia.' }); }
  } finally { client.release(); }
});
export default router;

