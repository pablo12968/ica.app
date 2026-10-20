import express from 'express';
import cors from 'cors';
import productRoutes from './routes/product.routes';
import orderRoutes from './routes/order.routes';
const app = express();
app.disable('x-powered-by');
app.use(cors({ origin: process.env.CORS_ORIGIN || false }));
app.use(express.json({ limit: '32kb' }));
const requests = new Map<string, { start: number; count: number }>();
app.use('/api/orders', (req, res, next) => {
  const now = Date.now();
  for (const [key, value] of requests) if (now - value.start > 60000) requests.delete(key);
  const ip = req.ip || 'unknown';
  const bucket = requests.get(ip) || { start: now, count: 0 };
  bucket.count++;
  requests.set(ip, bucket);
  if (bucket.count > 30) { res.status(429).json({ message: 'Demasiados intentos. Espera un minuto.' }); return; }
  next();
});
app.get('/', (_req, res) => res.json({ message: 'Ice Cream App API', version: '1.0.0' }));
app.use('/api/products', productRoutes);
app.use('/api/orders', orderRoutes);
app.use((_req, res) => { res.status(404).json({ message: 'Ruta no encontrada.' }); });
app.use((error: any, _req: express.Request, res: express.Response, _next: express.NextFunction) => {
  const status = error?.type === 'entity.parse.failed' ? 400 : error?.type === 'entity.too.large' ? 413 : 503;
  res.status(status).json({ message: status === 400 ? 'JSON no válido.' : 'No se pudo completar la solicitud.' });
});
export default app;
