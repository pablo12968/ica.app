import { createHash, randomBytes, scrypt, timingSafeEqual } from 'node:crypto';
import { promisify } from 'node:util';
import { RequestHandler } from 'express';
import pool from './config/database';
const derive = promisify(scrypt);
export const tokenHash = (token: string) => createHash('sha256').update(token).digest('hex');
export async function hashPassword(password: string) {
  const salt = randomBytes(16).toString('hex');
  const hash = await derive(password, salt, 64) as Buffer;
  return `${salt}:${hash.toString('hex')}`;
}
export async function checkPassword(password: string, encoded: string) {
  const [salt, hash] = encoded.split(':');
  const actual = await derive(password, salt, 64) as Buffer;
  const expected = Buffer.from(hash, 'hex');
  return actual.length === expected.length && timingSafeEqual(actual, expected);
}
export const publicUser = (u: any) => ({ id: u.id, name: u.name, email: u.email, role: u.role });
export const requireUser: RequestHandler = async (req, res, next) => {
  const token = req.get('Authorization')?.match(/^Bearer ([a-f0-9]{64})$/)?.[1];
  if (!token) { res.status(401).json({ message: 'Inicia sesión para continuar.' }); return; }
  const result = await pool.query(`SELECT u.* FROM ica_sessions s JOIN ica_users u ON u.id=s.user_id
    WHERE s.token_hash=$1 AND s.expires_at>NOW()`, [tokenHash(token)]);
  if (!result.rowCount) { res.status(401).json({ message: 'Tu sesión venció. Vuelve a iniciar sesión.' }); return; }
  res.locals.user = publicUser(result.rows[0]);
  res.locals.tokenHash = tokenHash(token);
  res.set('Cache-Control', 'no-store');
  next();
};
export const requireAdmin: RequestHandler = (_req, res, next) => {
  if (res.locals.user.role !== 'admin') { res.status(403).json({ message: 'Acceso solo para administración.' }); return; }
  next();
};
