CREATE TABLE users (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  email text NOT NULL UNIQUE,
  password_hash text NOT NULL
);
CREATE TABLE sessions (
  token_hash text PRIMARY KEY,
  user_id bigint NOT NULL REFERENCES users (id) ON DELETE CASCADE,
  expires_at timestamptz NOT NULL
);
CREATE TABLE products (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  name text NOT NULL,
  price integer NOT NULL CHECK (price > 0),
  stock integer NOT NULL CHECK (stock >= 0)
);
CREATE INDEX products_price_id ON products (price, id);
CREATE TABLE orders (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  user_id bigint NOT NULL REFERENCES users (id),
  idempotency_key text NOT NULL,
  request_hash text NOT NULL,
  total integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (user_id, idempotency_key)
);
CREATE TABLE order_items (
  order_id bigint NOT NULL REFERENCES orders (id),
  product_id bigint NOT NULL REFERENCES products (id),
  quantity integer NOT NULL CHECK (quantity > 0),
  price integer NOT NULL,
  PRIMARY KEY (order_id, product_id)
);
CREATE TABLE outbox (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  topic text NOT NULL,
  payload jsonb NOT NULL,
  sent_at timestamptz
);
INSERT INTO products (name, price, stock) VALUES
  ('عدة الروبوت', 45000, 5), ('عجلات احتياطية', 6000, 50), ('كاوية لحام', 18000, 12),
  ('حزمة بطاريات', 9000, 30), ('طقم حساسات', 25000, 8);
