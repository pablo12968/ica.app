import { Router } from 'express';
import { randomBytes, randomUUID } from 'node:crypto';
import pool from '../config/database';
import { checkPassword, hashPassword, publicUser, requireUser, tokenHash } from '../auth';
const router = Router();
router.use((_req, res, next) => { res.set('Cache-Control', 'no-store'); next(); });
for (const action of ['register', 'login']) {
  router.post(`/${action}`, async (req, res) => {
    const { password, name } = req.body ?? {};
    const email = typeof req.body?.email === 'string' ? req.body.email.trim().toLowerCase() : '';
    if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email) || email.length > 254 ||
      typeof password !== 'string' || password.length < 10 || password.length > 128 ||
      (action === 'register' && (typeof name !== 'string' || name.trim().length < 2 || name.trim().length > 80))) {
      res.status(400).json({ message: 'Revisa el nombre, el correo y la contraseña (10 a 128 caracteres).' }); return;
    }
    // Derive outside the transaction to avoid holding a connection during hashing.
    const encoded = action === 'register' ? await hashPassword(password) : null;
    let user: any;
    if (action === 'login') {
      const found = await pool.query('SELECT * FROM ica_users WHERE email=$1', [email]);
      user = found.rows[0];
      const valid = await checkPassword(password, user?.password_hash ?? `${'0'.repeat(32)}:${'0'.repeat(128)}`);
      if (!user || !valid) { res.status(401).json({ message: 'Correo o contraseña incorrectos.' }); return; }
    }
    const client = await pool.connect();
    try {
      await client.query('BEGIN');
      if (action === 'register') {
        const created = await client.query(`INSERT INTO ica_users(id,name,email,password_hash)
          VALUES($1,$2,$3,$4) RETURNING *`, [randomUUID(), name.trim(), email, encoded]);
        user = created.rows[0];
      }
      const token = randomBytes(32).toString('hex');
      await client.query('DELETE FROM ica_sessions WHERE user_id=$1 AND expires_at<=NOW()', [user.id]);
      await client.query(`INSERT INTO ica_sessions(token_hash,user_id,expires_at) VALUES($1,$2,NOW()+INTERVAL '7 days')`, [tokenHash(token), user.id]);
      await client.query('UPDATE ica_users SET last_login_at=NOW() WHERE id=$1', [user.id]);
      await client.query('INSERT INTO ica_activity(user_id,event) VALUES($1,$2)', [user.id, action === 'register' ? 'account_registered' : 'session_started']);
      await client.query('COMMIT');
      res.status(action === 'register' ? 201 : 200).json({ token, user: publicUser(user) });
    } catch (error: any) {
      await client.query('ROLLBACK');
      if (error.code === '23505') { res.status(409).json({ message: 'No se pudo registrar ese correo. Intenta iniciar sesión.' }); return; }
      throw error;
    } finally { client.release(); }
  });
}
router.get('/me', requireUser, (_req, res) => { res.json(res.locals.user); });
router.post('/logout', requireUser, async (_req, res) => {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    await client.query('DELETE FROM ica_sessions WHERE token_hash=$1', [res.locals.tokenHash]);
    await client.query("INSERT INTO ica_activity(user_id,event) VALUES($1,'session_ended')", [res.locals.user.id]);
    await client.query('COMMIT');
    res.sendStatus(204);
  } catch (e) { await client.query('ROLLBACK'); throw e; }
  finally { client.release(); }
});
export default router;
