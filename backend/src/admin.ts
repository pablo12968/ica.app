import pool from './config/database';
// Explicit local/server command only: never promote users by a public registration field.
async function main() {
  const email = process.argv[2]?.trim().toLowerCase();
  if (!email) throw new Error('Uso: npm run admin:grant -- correo@ejemplo.com');
  const result = await pool.query("UPDATE ica_users SET role='admin' WHERE email=$1 RETURNING id", [email]);
  if (!result.rowCount) throw new Error('Primero registra tu cuenta en la app.');
  console.log('Cuenta administradora habilitada. Vuelve a iniciar sesión.');
}
main().catch(e => { console.error(e.message); process.exitCode = 1; }).finally(() => pool.end());
