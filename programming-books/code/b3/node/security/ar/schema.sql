CREATE TABLE users (
  id            bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  name          text NOT NULL,
  email         text NOT NULL UNIQUE,
  role          text NOT NULL DEFAULT 'customer',
  password_hash text NOT NULL
);
CREATE TABLE products (
  id    bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  name  text NOT NULL,
  price integer NOT NULL
);
INSERT INTO users (name, email, role, password_hash) VALUES
  ('سارة', 'sara@example.com', 'admin', 'scrypt$32768$nNSMalEv_zb9$Kj18iYtLJHiZb'),
  ('عمر', 'omar@example.com', 'customer', 'scrypt$32768$j84P2D9FMN8n$6kpcvb9TyJSt0');
INSERT INTO products (name, price) VALUES ('عدة الروبوت', 45000), ('عجلات احتياطية', 6000);
