BEGIN;
CREATE TABLE IF NOT EXISTS products (
  id SERIAL PRIMARY KEY,
  name TEXT NOT NULL,
  description TEXT NOT NULL DEFAULT '',
  category TEXT NOT NULL DEFAULT 'Clásicos',
  base_price NUMERIC(12,2) NOT NULL CHECK(base_price >= 0),
  available BOOLEAN NOT NULL DEFAULT TRUE
);
ALTER TABLE products ADD COLUMN IF NOT EXISTS description TEXT NOT NULL DEFAULT '';
ALTER TABLE products ADD COLUMN IF NOT EXISTS category TEXT NOT NULL DEFAULT 'Clásicos';
CREATE TABLE IF NOT EXISTS ica_orders (
  id UUID PRIMARY KEY,
  request_key VARCHAR(100) UNIQUE NOT NULL,
  request_hash TEXT NOT NULL,
  payload JSONB NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
INSERT INTO products(name, description, category, base_price)
SELECT name, description, category, price FROM (VALUES
('Fresa de temporada', 'Cremoso helado con fresas y un toque de vainilla.', 'Clásicos', 2500),
('Chocolate intenso', 'Cacao, textura suave y mucho chocolate.', 'Clásicos', 2500),
('Vainilla artesanal', 'El clásico que combina con todo.', 'Clásicos', 2500),
('Mango tropical', 'Sorbete refrescante de mango. Sin lácteos.', 'Frutales', 2500),
('Limón fresco', 'Sorbete cítrico y ligero. Sin lácteos.', 'Frutales', 2500),
('Pistacho especial', 'Helado cremoso con pistacho. Contiene frutos secos.', 'Especiales', 3500)
) AS seeds(name, description, category, price)
WHERE NOT EXISTS (SELECT 1 FROM products);
CREATE TABLE IF NOT EXISTS ica_users (
  id UUID PRIMARY KEY,
  name VARCHAR(80) NOT NULL,
  email VARCHAR(254) UNIQUE NOT NULL,
  password_hash TEXT NOT NULL,
  role TEXT NOT NULL DEFAULT 'customer' CHECK(role IN ('customer','admin')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  last_login_at TIMESTAMPTZ
);
CREATE TABLE IF NOT EXISTS ica_sessions (
  token_hash TEXT PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES ica_users(id),
  expires_at TIMESTAMPTZ NOT NULL
);
CREATE INDEX IF NOT EXISTS ica_sessions_user ON ica_sessions(user_id);
ALTER TABLE ica_orders ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES ica_users(id);
CREATE INDEX IF NOT EXISTS ica_orders_user ON ica_orders(user_id,created_at DESC);
CREATE TABLE IF NOT EXISTS ica_activity (
  id BIGSERIAL PRIMARY KEY,
  user_id UUID REFERENCES ica_users(id),
  event TEXT NOT NULL,
  details JSONB NOT NULL DEFAULT '{}',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
COMMIT;



