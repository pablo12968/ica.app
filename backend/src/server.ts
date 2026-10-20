import app from './app';
import pool from './config/database';
const port = Number(process.env.PORT) || 3000;
async function start() {
  await pool.query('SELECT 1 FROM products LIMIT 1');
  await pool.query('SELECT 1 FROM ica_orders LIMIT 1');
  const server = app.listen(port, '0.0.0.0', () => console.log(`Ice Cream App API: puerto ${port}`));
  const close = () => server.close(() => { void pool.end(); });
  process.on('SIGINT', close);
  process.on('SIGTERM', close);
}
start().catch(() => { console.error('No se pudo iniciar. Comprueba PostgreSQL, .env y ejecuta npm run db:setup.'); process.exitCode = 1; void pool.end(); });
