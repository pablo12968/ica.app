import express from 'express';
import cors from 'cors';
import productRoutes from './routes/product.routes';
import orderRoutes from './routes/order.routes';
import authRoutes from './routes/auth.routes';
import adminRoutes from './routes/admin.routes';
import { requireUser } from './auth';
import pool from './config/database';
const app = express();
if (process.env.TRUST_PROXY_HOPS) app.set('trust proxy', Number(process.env.TRUST_PROXY_HOPS));
app.disable('x-powered-by');
app.use(cors({ origin: process.env.CORS_ORIGIN || false }));
app.use(express.json({ limit: '32kb' }));
const requests = new Map<string, { start: number; count: number }>();
app.use(['/api/orders', '/api/auth', '/api/activity'], (req, res, next) => {
  const now = Date.now();
  for (const [key, value] of requests) if (now - value.start > 60000) requests.delete(key);
  const ip = `${req.baseUrl}:${req.ip || 'unknown'}`;
  const bucket = requests.get(ip) || { start: now, count: 0 };
  bucket.count++;
  requests.set(ip, bucket);
  if (bucket.count > 30) { res.status(429).json({ message: 'Demasiados intentos. Espera un minuto.' }); return; }
  next();
});
app.get('/', (_req, res) => res.json({ message: 'Ice Cream App API', version: '1.0.0' }));
app.get('/health', async (_req, res) => {
  await pool.query('SELECT 1 FROM ica_users LIMIT 1');
  res.json({ status: 'ok' });
});
app.use('/api/products', productRoutes);
app.use('/api/orders', orderRoutes);
app.use('/api/auth', authRoutes);
app.use('/api/admin', adminRoutes);
app.post('/api/activity', requireUser, async (req, res) => {
  const allowed = ['favorite_added', 'favorite_removed', 'cart_updated'];
  if (!allowed.includes(req.body?.event)) { res.sendStatus(400); return; }
  // Client events are informational, not proof of a purchase or payment.
  await pool.query('INSERT INTO ica_activity(user_id,event,details) VALUES($1,$2,$3)',
    [res.locals.user.id, req.body.event, JSON.stringify({ source: 'app' })]);
  res.sendStatus(204);
});
app.use((_req, res) => { res.status(404).json({ message: 'Ruta no encontrada.' }); });
app.use((error: any, _req: express.Request, res: express.Response, _next: express.NextFunction) => {
  const status = error?.type === 'entity.parse.failed' ? 400 : error?.type === 'entity.too.large' ? 413 : 503;
  res.status(status).json({ message: status === 400 ? 'JSON no válido.' : 'No se pudo completar la solicitud.' });
});
export default app;
