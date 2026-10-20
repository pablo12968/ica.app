import { Pool } from 'pg';
import dotenv from 'dotenv';
dotenv.config();
const pool = new Pool({
  ...(process.env.DATABASE_URL ? { connectionString: process.env.DATABASE_URL } : {
    host: process.env.DB_HOST || 'localhost', port: Number(process.env.DB_PORT) || 5432,
    database: process.env.DB_NAME || 'ice_cream', user: process.env.DB_USER, password: process.env.DB_PASSWORD,
  }), connectionTimeoutMillis: 5000, max: 10,
});
export default pool;
