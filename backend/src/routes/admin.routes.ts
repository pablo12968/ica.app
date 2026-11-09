import { Router } from 'express';
import pool from '../config/database';
import { requireUser, requireAdmin } from '../auth';
const router = Router();
router.use(requireUser, requireAdmin);
router.get('/:section', async (req, res) => {
  const page = Number(req.query.page ?? 0);
  if (!Number.isSafeInteger(page) || page < 0 || page > 100000) { res.sendStatus(400); return; }
  const queries: Record<string, string> = {
    users: 'SELECT id,name,email,role,created_at,last_login_at FROM ica_users ORDER BY created_at DESC,id DESC',
    orders: 'SELECT o.id,o.user_id,u.email,o.payload,o.created_at FROM ica_orders o LEFT JOIN ica_users u ON u.id=o.user_id ORDER BY o.created_at DESC,o.id DESC',
    activity: 'SELECT a.id,a.event,a.details,a.created_at,u.email FROM ica_activity a LEFT JOIN ica_users u ON u.id=a.user_id ORDER BY a.id DESC',
  };
  const query = queries[req.params.section as string];
  if (!query) { res.sendStatus(404); return; }
  const result = await pool.query(`${query} LIMIT 51 OFFSET $1`, [page * 50]);
  res.json({ rows: result.rows.slice(0, 50), hasMore: result.rows.length > 50, page });
});
export default router;
